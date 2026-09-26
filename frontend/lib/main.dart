import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Placeholder plumbing only — design, navigation, and theming come later.
// Point this at your backend (use 10.0.2.2 instead of localhost on Android emulator).
const backendUrl = 'http://localhost:8000';

void main() {
  runApp(const CampusConciergeApp());
}

class CampusConciergeApp extends StatelessWidget {
  const CampusConciergeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final bool fromAgent;

  ChatMessage(this.text, this.fromAgent);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  Timer? _nudgeTimer;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _nudgeTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkNudges());
  }

  @override
  void dispose() {
    _nudgeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkNudges() async {
    try {
      final res = await http.get(Uri.parse('$backendUrl/nudges'));
      if (res.statusCode != 200) return;
      final nudges = List<String>.from(jsonDecode(res.body)['nudges']);
      setState(() {
        for (final n in nudges) {
          _messages.add(ChatMessage(n, true));
        }
      });
    } catch (_) {
      // Backend not reachable yet — ignore during early dev.
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text, false));
      _sending = true;
    });
    _controller.clear();

    try {
      final res = await http.post(
        Uri.parse('$backendUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );
      final reply = jsonDecode(res.body)['reply'] as String;
      setState(() => _messages.add(ChatMessage(reply, true)));
    } catch (e) {
      setState(() => _messages.add(ChatMessage('Error: could not reach backend.', true)));
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Campus Concierge')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return Align(
                  alignment: m.fromAgent ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: m.fromAgent ? Colors.grey[300] : Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(m.text),
                  ),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Ask something...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
