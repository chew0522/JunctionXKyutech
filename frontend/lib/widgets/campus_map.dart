import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme.dart';

const busColors = [Color(0xFF2B3A8F), Color(0xFF2E8B57), Color(0xFFD9730D), Color(0xFF8E3FA8)];

Color busColor(int index) => busColors[index % busColors.length];

double _worldX(double lng, double zoom) => (lng + 180) / 360 * 256 * math.pow(2, zoom);

double _worldY(double lat, double zoom) {
  final s = math.sin(lat * math.pi / 180);
  return (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * 256 * math.pow(2, zoom);
}

/// Mock live campus map: a drawn background with bus routes as roads and moving buses.
class CampusMapView extends StatelessWidget {
  final Map<String, dynamic> campus;
  final List<dynamic> buses;
  final String? fromId;
  final String? toId;
  final String? selectedBusId;
  final void Function(String busId) onBusTap;
  final double height;

  const CampusMapView({
    super.key,
    required this.campus,
    required this.buses,
    required this.onBusTap,
    this.fromId,
    this.toId,
    this.selectedBusId,
    this.height = 340,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final zoom = (campus['zoom'] as num).toDouble();
            final centerLat = (campus['center']['lat'] as num).toDouble();
            final centerLng = (campus['center']['lng'] as num).toDouble();
            final cx = _worldX(centerLng, zoom);
            final cy = _worldY(centerLat, zoom);
            Offset project(double lat, double lng) =>
                Offset(_worldX(lng, zoom) - cx + w / 2, _worldY(lat, zoom) - cy + height / 2);

            final routes = (campus['routes'] as List);
            final selectedRoute = selectedBusId == null
                ? null
                : routes.cast<Map<String, dynamic>>().where((r) => r['id'] == selectedBusId).firstOrNull;
            final visibleStops = selectedRoute == null
                ? null
                : {...(selectedRoute['stops'] as List).cast<String>(), if (fromId != null) fromId!, if (toId != null) toId!};
            final buildings = (campus['buildings'] as List)
                .where((b) => visibleStops == null || visibleStops.contains(b['id']))
                .toList();

            return Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Color(0xFFE9EEE3))),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoutePainter(
                      routes: [
                        for (final r in routes)
                          [for (final p in r['path']) project((p[0] as num).toDouble(), (p[1] as num).toDouble())],
                      ],
                      onlyIndex: selectedRoute == null ? null : routes.indexOf(selectedRoute),
                    ),
                  ),
                ),
                for (final b in buildings)
                  _buildingMarker(b, project((b['lat'] as num).toDouble(), (b['lng'] as num).toDouble())),
                for (int i = 0; i < buses.length; i++)
                  if (selectedBusId == null || buses[i]['id'] == selectedBusId) _busMarker(i, buses[i], project),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildingMarker(Map<String, dynamic> b, Offset p) {
    final isFrom = b['id'] == fromId;
    final isTo = b['id'] == toId;
    final highlighted = isFrom || isTo;
    return Positioned(
      left: p.dx - 40,
      top: p.dy - 6,
      width: 80,
      child: Column(
        children: [
          Container(
            width: highlighted ? 14 : 9,
            height: highlighted ? 14 : 9,
            decoration: BoxDecoration(
              color: isTo ? AppColors.danger : (isFrom ? AppColors.success : Colors.white),
              shape: BoxShape.circle,
              border: Border.all(color: highlighted ? Colors.white : AppColors.textMuted, width: highlighted ? 2 : 1.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            b['name'],
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 8.5,
              height: 1.05,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.text,
              shadows: const [
                Shadow(color: Colors.white, blurRadius: 3),
                Shadow(color: Colors.white, blurRadius: 3),
                Shadow(color: Colors.white, blurRadius: 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _busMarker(int index, Map<String, dynamic> bus, Offset Function(double, double) project) {
    final p = project((bus['lat'] as num).toDouble(), (bus['lng'] as num).toDouble());
    final selected = bus['id'] == selectedBusId;
    final size = selected ? 34.0 : 28.0;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.linear,
      left: p.dx - size / 2,
      top: p.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => onBusTap(bus['id']),
        child: Container(
          decoration: BoxDecoration(
            color: busColor(index),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: selected ? 3 : 2),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1))],
          ),
          child: Icon(LucideIcons.bus, size: selected ? 18 : 15, color: Colors.white),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<List<Offset>> routes;
  final int? onlyIndex;

  _RoutePainter({required this.routes, this.onlyIndex});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < routes.length; i++) {
      if (onlyIndex != null && i != onlyIndex) continue;
      final path = Path()..moveTo(routes[i].first.dx, routes[i].first.dy);
      for (final p in routes[i].skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = busColor(i).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.routes != routes || old.onlyIndex != onlyIndex;
}
