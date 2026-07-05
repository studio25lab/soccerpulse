// lib/pages/team_detail_internals.dart
//
// Classi interne (delegate + painter) di team_detail_screen.dart,
// estratte per ridurre la dimensione del file.
//
// // [FAV-extract-td-internals]

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color bgColor;
  StickyTabBarDelegate(this.tabBar, this.bgColor);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant StickyTabBarDelegate oldDelegate) => false;
}


// ─── Mock matchday data generator ───
List<Map<String, dynamic>> generateMockMatchdays(int wins, int draws, int losses, int gf, int ga) {
  final total = wins + draws + losses;
  if (total == 0) return [];

  // Build result sequence with realistic form streaks
  final results = <String>[];
  int rW = wins, rD = draws, rL = losses;
  final seed = (wins * 7 + draws * 3 + losses * 11).abs();
  
  // Create streaks: teams tend to have runs of form
  String? lastResult;
  int streakLen = 0;
  
  for (int i = 0; i < total; i++) {
    final remaining = rW + rD + rL;
    if (remaining == 0) break;
    
    // Hash for deterministic pseudo-randomness
    final hash = ((i + 1) * 31 + seed * 17 + i * i * 7) % 100;
    
    // Bias toward continuing a streak (30% chance to continue)
    String pick;
    if (lastResult != null && streakLen < 4 && hash < 30) {
      // Try to continue streak if still available
      if (lastResult == 'W' && rW > 0) { pick = 'W'; }
      else if (lastResult == 'D' && rD > 0) { pick = 'D'; }
      else if (lastResult == 'L' && rL > 0) { pick = 'L'; }
      else { pick = _pickByProportion(rW, rD, rL, hash); }
    } else {
      pick = _pickByProportion(rW, rD, rL, hash);
    }
    
    if (pick == lastResult) { streakLen++; } else { streakLen = 1; }
    lastResult = pick;
    
    results.add(pick);
    if (pick == 'W') rW--;
    else if (pick == 'D') rD--;
    else rL--;
  }

  // Distribute goals per match, consistent with totals
  int remGF = gf, remGA = ga;
  final matchdays = <Map<String, dynamic>>[];
  int cumPts = 0;

  for (int i = 0; i < results.length; i++) {
    final left = results.length - i;
    final avgGF = left > 0 ? remGF / left : 0.0;
    final avgGA = left > 0 ? remGA / left : 0.0;
    int mGF, mGA;
    
    // Use hash for some variation
    final vHash = ((i + 1) * 13 + seed * 7) % 10;
    final variation = (vHash - 5) * 0.15; // -0.75 to +0.75

    if (results[i] == 'W') {
      mGF = (avgGF * (1.2 + variation)).round().clamp(1, 5);
      mGA = (avgGA * (0.7 + variation * 0.5)).round().clamp(0, (mGF - 1).clamp(0, 4));
      cumPts += 3;
    } else if (results[i] == 'D') {
      final avg = ((avgGF + avgGA) / 2).round().clamp(0, 3);
      mGF = avg;
      mGA = avg;
      cumPts += 1;
    } else {
      mGA = (avgGA * (1.2 + variation)).round().clamp(1, 5);
      mGF = (avgGF * (0.7 + variation * 0.5)).round().clamp(0, (mGA - 1).clamp(0, 4));
    }

    remGF = (remGF - mGF).clamp(0, 999);
    remGA = (remGA - mGA).clamp(0, 999);
    matchdays.add({'r': results[i], 'gf': mGF, 'ga': mGA, 'pts': cumPts});
  }

  // Distribute any remaining goals onto matches that can absorb them
  if (remGF > 0 && matchdays.isNotEmpty) {
    for (int i = matchdays.length - 1; i >= 0 && remGF > 0; i--) {
      if (matchdays[i]['r'] == 'W') {
        matchdays[i]['gf'] = (matchdays[i]['gf'] as int) + 1;
        remGF--;
      }
    }
    if (remGF > 0) matchdays.last['gf'] = (matchdays.last['gf'] as int) + remGF;
  }
  if (remGA > 0 && matchdays.isNotEmpty) {
    for (int i = matchdays.length - 1; i >= 0 && remGA > 0; i--) {
      if (matchdays[i]['r'] == 'L') {
        matchdays[i]['ga'] = (matchdays[i]['ga'] as int) + 1;
        remGA--;
      }
    }
    if (remGA > 0) matchdays.last['ga'] = (matchdays.last['ga'] as int) + remGA;
  }

  return matchdays;
}

String _pickByProportion(int w, int d, int l, int hash) {
  final total = w + d + l;
  if (total == 0) return 'D';
  final wPct = (w * 100 ~/ total);
  final dPct = (d * 100 ~/ total);
  if (hash < wPct) return 'W';
  if (hash < wPct + dPct) return 'D';
  return 'L';
}

class MatchdayBarPainter extends CustomPainter {
  final bool isDark;
  final List<Map<String, dynamic>> matchdays;

  MatchdayBarPainter({required this.isDark, required this.matchdays});

  static const _barW = 10.0;
  static const _gap = 6.0;
  static const _step = _barW + _gap;
  static const _padLeft = 28.0; // room for Y-axis labels

  @override
  void paint(Canvas canvas, Size size) {
    if (matchdays.isEmpty) return;

    final labelColor = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.4);
    final faintGrid = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15);

    // Layout zones
    final baselineY = size.height * 0.46;
    final topZone = baselineY - 8;          // space for scored bars
    final bottomZone = size.height - baselineY - 32; // space for conceded bars + dots

    // Find max goals for scaling
    int maxGF = 1, maxGA = 1;
    for (final m in matchdays) {
      final g = m['gf'] as int;
      final a = m['ga'] as int;
      if (g > maxGF) maxGF = g;
      if (a > maxGA) maxGA = a;
    }

    final greenColor = const Color(0xFF4CAF50);
    final redColor = const Color(0xFFE53935);
    final yellowColor = const Color(0xFFF9A825);

    // ── Baseline ──
    canvas.drawLine(
      Offset(_padLeft - 4, baselineY),
      Offset(size.width, baselineY),
      Paint()..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12)..strokeWidth = 1,
    );

    // ── Y-axis labels + grid lines (goals scored - above baseline) ──
    for (int g = 1; g <= maxGF; g++) {
      final y = baselineY - (g / maxGF) * topZone;
      // Grid line
      canvas.drawLine(
        Offset(_padLeft, y), Offset(size.width, y),
        Paint()..color = faintGrid..strokeWidth = 0.8,
      );
      // Label
      final tp = TextPainter(
        text: TextSpan(text: '$g', style: TextStyle(fontSize: 9, color: labelColor, fontWeight: FontWeight.w500)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_padLeft - tp.width - 6, y - tp.height / 2));
    }

    // ── Y-axis labels + grid lines (goals conceded - below baseline) ──
    for (int g = 1; g <= maxGA; g++) {
      final y = baselineY + 2 + (g / maxGA) * bottomZone;
      // Grid line
      canvas.drawLine(
        Offset(_padLeft, y), Offset(size.width, y),
        Paint()..color = faintGrid..strokeWidth = 0.8,
      );
      // Label
      final tp = TextPainter(
        text: TextSpan(text: '$g', style: TextStyle(fontSize: 9, color: labelColor, fontWeight: FontWeight.w500)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(_padLeft - tp.width - 6, y - tp.height / 2));
    }

    // ── Bars for each matchday ──
    for (int i = 0; i < matchdays.length; i++) {
      final m = matchdays[i];
      final x = _padLeft + i * _step;
      final r = m['r'] as String;
      final gf = (m['gf'] as int).toDouble();
      final ga = (m['ga'] as int).toDouble();

      final resultColor = r == 'W' ? greenColor : r == 'D' ? yellowColor : redColor;

      // Goals scored bar (UP from baseline)
      if (gf > 0) {
        final h = (gf / maxGF) * topZone;
        final rect = Rect.fromLTWH(x, baselineY - h, _barW, h);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..shader = ui.Gradient.linear(
            Offset(x, baselineY - h), Offset(x, baselineY),
            [greenColor.withValues(alpha: 0.9), greenColor.withValues(alpha: 0.5)],
          ),
        );
      }

      // Goals conceded bar (DOWN from baseline)
      if (ga > 0) {
        final h = (ga / maxGA) * bottomZone;
        final rect = Rect.fromLTWH(x, baselineY + 2, _barW, h);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..shader = ui.Gradient.linear(
            Offset(x, baselineY + 2), Offset(x, baselineY + 2 + h),
            [redColor.withValues(alpha: 0.5), redColor.withValues(alpha: 0.9)],
          ),
        );
      }

      // Result dot
      final dotY = size.height - 18.0;
      canvas.drawCircle(
        Offset(x + _barW / 2, dotY),
        4.5,
        Paint()..color = resultColor,
      );

      // Matchday label (every 5th + first + last)
      if (i == 0 || (i + 1) % 5 == 0 || i == matchdays.length - 1) {
        final tp = TextPainter(
          text: TextSpan(text: '${i + 1}', style: TextStyle(fontSize: 8, color: labelColor)),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + _barW / 2 - tp.width / 2, size.height - 10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant MatchdayBarPainter old) => false;
}
