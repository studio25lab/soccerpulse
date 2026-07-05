// lib/pages/match_player_profile_internals.dart
//
// Classi interne (painter + delegate) di match_player_profile_screen.dart,
// estratte per ridurre la dimensione del file.
//
// // [FAV-extract-mpp-internals]

import 'package:flutter/material.dart';
import 'dart:math' as math;

class MPPRadarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values; // 0.0 to 1.0
  final Color color;
  final bool isDark;

  MPPRadarChartPainter(
      {required this.labels,
      required this.values,
      required this.color,
      required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;
    final n = labels.length;
    final angleStep = 2 * math.pi / n;
    final startAngle = -math.pi / 2;

    // Draw grid rings
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * ring / 4;
      final path = Path();
      for (int i = 0; i <= n; i++) {
        final angle = startAngle + angleStep * (i % n);
        final p = Offset(
            center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
        if (i == 0)
          path.moveTo(p.dx, p.dy);
        else
          path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw axes
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final end = Offset(center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle));
      canvas.drawLine(center, end, gridPaint);
    }

    // Draw value polygon
    final valuePath = Path();
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i <= n; i++) {
      final idx = i % n;
      final angle = startAngle + angleStep * idx;
      final r = radius * values[idx];
      final p = Offset(
          center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      if (i == 0)
        valuePath.moveTo(p.dx, p.dy);
      else
        valuePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(valuePath, fillPaint);
    canvas.drawPath(valuePath, strokePaint);

    // Draw dots on vertices
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final r = radius * values[i];
      final p = Offset(
          center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(
          p,
          4,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    // Draw labels
    final textPainterStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white70 : Colors.black87,
    );
    for (int i = 0; i < n; i++) {
      final angle = startAngle + angleStep * i;
      final lR = radius + 22;
      final p = Offset(
          center.dx + lR * math.cos(angle), center.dy + lR * math.sin(angle));
      final tp = TextPainter(
          text: TextSpan(text: labels[i], style: textPainterStyle),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── STICKY TAB BAR DELEGATE ──

class MPPStickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  MPPStickyTabBarDelegate(this.tabBar, this.bgColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: bgColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant MPPStickyTabBarDelegate oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════
// IN-APP NOTIFICATION SYSTEM
// ═══════════════════════════════════════════════════════════════════════════
