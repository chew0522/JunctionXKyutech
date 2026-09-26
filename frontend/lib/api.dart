import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'models.dart';

// The Android emulator's "localhost" is the emulator itself, not the host machine —
// 10.0.2.2 is the special alias Android emulators use to reach the host's localhost.
final String backendUrl =
    (!kIsWeb && Platform.isAndroid) ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

class ApiClient {
  Future<ChatMessage> sendMessage(String message) async {
    final res = await http.post(
      Uri.parse('$backendUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (res.statusCode != 200) {
      throw Exception('Backend returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    return ChatMessage(
      text: body['reply'] as String,
      fromAgent: true,
      choices: (body['choices'] as List?)?.cast<String>(),
    );
  }

  Future<List<ChatMessage>> fetchHistory() async {
    final res = await http.get(Uri.parse('$backendUrl/history'));
    if (res.statusCode != 200) {
      throw Exception('Backend returned ${res.statusCode}');
    }
    final list = jsonDecode(res.body)['messages'] as List;
    return list.map((m) => ChatMessage.fromJson(m)).toList();
  }

  Future<List<Nudge>> fetchNudges() async {
    final res = await http.get(Uri.parse('$backendUrl/nudges'));
    if (res.statusCode != 200) {
      throw Exception('Backend returned ${res.statusCode}');
    }
    final list = jsonDecode(res.body)['nudges'] as List;
    return list.map((n) => Nudge.fromJson(n)).toList();
  }

  // Generic helpers for the plain-data REST endpoints (Dashboard, Courses, Bookings,
  // and the drill-in pages) — these bypass the LLM entirely, since they're structured
  // lookups/actions, not natural-language questions.

  Future<List<dynamic>> _getList(String path) async {
    final res = await http.get(Uri.parse('$backendUrl$path'));
    if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');
    return jsonDecode(res.body) as List;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$backendUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<DateTime> fetchNow() async {
    final res = await http.get(Uri.parse('$backendUrl/api/now'));
    if (res.statusCode != 200) throw Exception('Backend returned ${res.statusCode}');
    return DateTime.parse(jsonDecode(res.body)['now']);
  }

  Future<List<dynamic>> fetchEvents() => _getList('/api/events');
  Future<List<dynamic>> fetchRooms() => _getList('/api/rooms');
  Future<Map<String, dynamic>> bookRoom(String roomId) =>
      _post('/api/rooms/book', {'room_id': roomId});

  Future<List<dynamic>> fetchBus() => _getList('/api/bus');
  Future<List<dynamic>> fetchCafes() => _getList('/api/cafes');

  Future<List<dynamic>> fetchClinicSlots() => _getList('/api/clinic-slots');
  Future<Map<String, dynamic>> bookClinicSlot(String slotId) =>
      _post('/api/clinic-slots/book', {'slot_id': slotId});

  Future<List<dynamic>> fetchCourses() => _getList('/api/courses');
  Future<List<dynamic>> fetchMaterials(String courseId) =>
      _getList('/api/materials?course_id=$courseId');
  Future<List<dynamic>> fetchAssignments({bool pendingOnly = false}) =>
      _getList('/api/assignments?pending_only=$pendingOnly');
  Future<Map<String, dynamic>> submitAssignment(String assignmentId) =>
      _post('/api/assignments/submit', {'assignment_id': assignmentId});

  Future<List<dynamic>> fetchFacilities({String? category}) =>
      _getList(category == null ? '/api/facilities' : '/api/facilities?category=$category');
  Future<Map<String, dynamic>> bookFacility(String facilityId) =>
      _post('/api/facilities/book', {'facility_id': facilityId});

  Future<List<dynamic>> fetchMyBookings() => _getList('/api/my-bookings');
}
