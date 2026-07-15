import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ========================================
// MODELLO DATI TIRO
// ========================================
class ShotData {
  final String playerName;
  final String playerPhoto;
  final int minute;
  final int? addedTime;
  final double startX;
  final double startY;
  final double? goalX;
  final double? goalY;
  final String type;
  final double xG;
  final double? xGOT;
  final String? situation;
  final String? shotType;
  final String? goalZone;

  ShotData({
    required this.playerName,
    required this.playerPhoto,
    required this.minute,
    this.addedTime,
    required this.startX,
    required this.startY,
    this.goalX,
    this.goalY,
    required this.type,
    required this.xG,
    this.xGOT,
    this.situation,
    this.shotType,
    this.goalZone,
  });

  String get esito {
    switch (type) {
      case 'goal':
        return 'Goal';
      case 'on_target':
        return 'Saved';
      case 'off_target':
        return 'Fuori'; // kept Italian, translated at display
      case 'blocked':
        return 'Blocked';
      default:
        return type;
    }
  }

  String get minuteDisplay =>
      addedTime != null ? "$minute'+$addedTime" : "$minute'";
}

// ========================================
// WIDGET PRINCIPALE
// ========================================
class InteractiveShotMapWidget extends StatefulWidget {
  final List<ShotData> shots;
  final Color teamColor;
  final bool isDark;
  final void Function(String playerName)? onPlayerTap;

  const InteractiveShotMapWidget({
    super.key,
    required this.shots,
    required this.teamColor,
    this.isDark = false,
    this.onPlayerTap,
  });

  @override
  State<InteractiveShotMapWidget> createState() =>
      _InteractiveShotMapWidgetState();
}

class _InteractiveShotMapWidgetState extends State<InteractiveShotMapWidget>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late AnimationController _revealCtrl;
  late Animation<double> _revealAnim;

  static const double _goalSectionH = 175.0;
  static const double _goalFrameW = 0.20; // matcha pw=0.20 in _FieldPainter
  static const double _goalFrameH = 60.0;
  static const double _goalFrameT = 28.0;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _revealAnim =
        CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(InteractiveShotMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shots != widget.shots) {
      setState(() {
        _selectedIndex = null;
        _revealCtrl.reverse();
      });
    }
  }

  void _selectShot(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIndex == index) {
        _selectedIndex = null;
        _revealCtrl.reverse();
      } else {
        _selectedIndex = index;
        final shot = widget.shots[index];
        if (shot.type != 'blocked') {
          _revealCtrl.forward(
              from: _revealCtrl.value > 0 ? _revealCtrl.value : 0);
        } else {
          _revealCtrl.reverse();
        }
      }
    });
  }

  void _prevShot() {
    if (_selectedIndex != null && _selectedIndex! > 0) {
      setState(() {
        _selectedIndex = _selectedIndex! - 1;
        if (widget.shots[_selectedIndex!].type == 'blocked') {
          _revealCtrl.reverse();
        } else if (_revealCtrl.value == 0) {
          _revealCtrl.forward(from: 0);
        }
      });
    }
  }

  void _nextShot() {
    if (_selectedIndex != null && _selectedIndex! < widget.shots.length - 1) {
      setState(() {
        _selectedIndex = _selectedIndex! + 1;
        if (widget.shots[_selectedIndex!].type == 'blocked') {
          _revealCtrl.reverse();
        } else if (_revealCtrl.value == 0) {
          _revealCtrl.forward(from: 0);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.shots.isEmpty) return _emptyState();
    if (_selectedIndex != null && _selectedIndex! >= widget.shots.length) {
      _selectedIndex = null;
      _revealCtrl.value = 0;
    }
    final sel = _selectedIndex != null ? widget.shots[_selectedIndex!] : null;

    return Column(children: [
      _shotSummaryBar(),
      const SizedBox(height: 12),
      _unifiedMap(sel),
      _legend(),
      if (sel != null) ...[
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            if (widget.onPlayerTap != null) {
              widget.onPlayerTap!(sel.playerName);
            }
          },
          child: _playerCard(sel),
        ),
      ],
    ]);
  }

  Widget _shotSummaryBar() {
    final shots = widget.shots;
    final total = shots.length;
    final goals = shots.where((s) => s.type == 'goal').length;
    final saved = shots.where((s) => s.type == 'on_target').length;
    final offTarget = shots.where((s) => s.type == 'off_target').length;
    final blocked = shots.where((s) => s.type == 'blocked').length;
    final dk = widget.isDark;
    final bg = dk ? const Color(0xFF1E1E1E) : Colors.white;
    final tx = dk ? Colors.white : const Color(0xFF1A1A1A);
    final lb = Colors.grey[500]!;
    final dv = dk ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dv)),
      child: Row(children: [
        _summaryItem(tr(context, 'Totali'), total.toString(), tx, lb, null),
        _summaryDivider(dv),
        _summaryItem('Goal', goals.toString(), tx, lb, const Color(0xFF4CAF50)),
        _summaryDivider(dv),
        _summaryItem(
            tr(context, 'Parati'), saved.toString(), tx, lb, const Color(0xFF1B5E20)),
        _summaryDivider(dv),
        _summaryItem(
            tr(context, 'Fuori'), offTarget.toString(), tx, lb, const Color(0xFFE53935)),
        _summaryDivider(dv),
        _summaryItem(
            tr(context, 'Respinti'), blocked.toString(), tx, lb, const Color(0xFFFF9800)),
      ]),
    );
  }

  Expanded _summaryItem(
      String label, String value, Color tx, Color lb, Color? accent) {
    return Expanded(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: accent ?? tx)),
      const SizedBox(height: 2),
      Text(label,
          style:
              TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: lb)),
    ]));
  }

  Widget _summaryDivider(Color c) => Container(width: 1, height: 30, color: c);

  Widget _unifiedMap(ShotData? sel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (ctx, box) {
        final w = box.maxWidth;
        final fieldH = w * 0.78;
        final gW = w * _goalFrameW;
        final gL = (w - gW) / 2;

        return AnimatedBuilder(
          animation: _revealAnim,
          builder: (context, _) {
            final goalVis = _revealAnim.value;
            final currentGoalH = _goalSectionH * goalVis;
            final totalH = currentGoalH + fieldH;

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: w,
                height: totalH,
                child: Stack(clipBehavior: Clip.hardEdge, children: [
                  if (goalVis > 0)
                    Positioned(
                        left: 0,
                        top: 0,
                        width: w,
                        height: currentGoalH,
                        child: Opacity(
                            opacity: goalVis,
                            child: Container(color: const Color(0xFFEEEEEE)))),
                  if (goalVis > 0)
                    Positioned(
                        left: 0,
                        top: 0,
                        width: w,
                        height: currentGoalH,
                        child: Opacity(
                            opacity: goalVis,
                            child: CustomPaint(
                                size: Size(w, _goalSectionH),
                                painter: _GoalPainter(
                                    gL, gW, _goalFrameH, _goalFrameT, w)))),
                  Positioned(
                      left: 0,
                      top: currentGoalH,
                      width: w,
                      height: fieldH,
                      child: CustomPaint(
                          size: Size(w, fieldH), painter: _FieldPainter())),
                  if (sel != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _UnifiedLinePainter(
                          startX: sel.startX * w,
                          startY: currentGoalH +
                              (0.08 + sel.startY * 0.82) * fieldH,
                          endX: _lineEndX(sel, w, gL, gW, goalVis),
                          endY: _lineEndY(sel, currentGoalH, fieldH, goalVis),
                          type: sel.type,
                          // ── Linea parte dal BORDO del cerchio del tiro ──
                          startRadius: sel.type == 'goal'
                              ? (30.0 + (sel.xG * 18).clamp(0.0, 12.0)) / 2
                              : (20.0 + (sel.xG * 22).clamp(0.0, 18.0)) / 2,
                        ),
                      ),
                    ),
                  if (sel != null && sel.type != 'blocked' && goalVis > 0)
                    _impactDot(sel, _impactPixelX(sel, w, gL, gW),
                        _impactPixelY(sel), goalVis),
                  ...widget.shots.asMap().entries.map(
                      (e) => _marker(e.value, e.key, w, fieldH, currentGoalH)),
                ]),
              ),
            );
          },
        );
      }),
    );
  }

  double _impactPixelX(ShotData s, double w, double gL, double gW) {
    if (s.type == 'goal' || s.type == 'on_target') {
      final gx = (s.goalX ?? 0.5).clamp(0.0, 1.0);
      return gL + gx * gW;
    } else if (s.type == 'off_target') {
      final gx = s.goalX ?? 0.5;
      if (gx < 0) return gL - 18;
      if (gx > 1.0) return gL + gW + 18;
      return gL + gx.clamp(0.0, 1.0) * gW;
    }
    return s.startX * w;
  }

  double _impactPixelY(ShotData s) {
    if (s.type == 'goal' || s.type == 'on_target') {
      final gy = (s.goalY ?? 0.5).clamp(0.0, 1.0);
      return _goalFrameT + gy * _goalFrameH;
    } else if (s.type == 'off_target') {
      final gx = s.goalX ?? 0.5;
      if (gx < 0 || gx > 1.0) return _goalFrameT + _goalFrameH * 0.4;
      return _goalFrameT - 14;
    }
    return 0;
  }

  double _lineEndX(ShotData s, double w, double gL, double gW, double goalVis) {
    // ── La linea va SEMPRE al punto d'impatto preciso (A → B retto) ──
    // L'animazione `goalVis` riguarda la sezione porta, non il punto B.
    if (s.type == 'goal' || s.type == 'on_target' || s.type == 'off_target') {
      return _impactPixelX(s, w, gL, gW);
    }
    // Per i tiri "blocked" la linea finisce in mezzo al campo
    return s.startX * w + (((s.goalX ?? 0.5) - s.startX) * w * 0.3);
  }

  double _lineEndY(
      ShotData s, double currentGoalH, double fieldH, double goalVis) {
    // ── Stile SofaScore: la linea si ferma DENTRO il campo ──
    // Per i tiri che vanno alla porta (goal/on_target/off_target) la linea
    // arriva al bordo superiore del campo (sotto la linea bianca di fondo).
    // Il dot d'impatto sulla porta rimane ISOLATO sopra, non collegato.
    if (s.type == 'goal' || s.type == 'on_target' || s.type == 'off_target') {
      return currentGoalH + 4; // 4px sotto il top del campo
    }
    // Tiri "blocked" finiscono in mezzo al campo (non arrivano alla porta)
    return currentGoalH + fieldH * (0.15 + s.startY * 0.25);
  }

  Widget _impactDot(ShotData s, double px, double py, double opacity) {
    final Color c;
    if (s.type == 'goal') {
      c = const Color(0xFF4CAF50); // verde Material (= tabella Goal)
    } else if (s.type == 'on_target') {
      c = const Color(0xFF1B5E20); // verde scuro (= tabella Parati)
    } else {
      c = const Color(0xFFE53935); // rosso (= tabella Fuori)
    }
    // ── Stile SofaScore: tiri fuori = solo cerchio vuoto, no X ──
    return Positioned(
      left: px - 13,
      top: py - 13,
      child: Opacity(
          opacity: opacity,
          child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.type == 'off_target'
                      ? Colors.transparent
                      : c.withValues(alpha: 0.2),
                  border: Border.all(color: c, width: 2.5)),
              child: s.type == 'off_target'
                  ? null
                  : Center(
                      child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: c))))),
    );
  }

  Widget _marker(ShotData s, int i, double fw, double fh, double goalOffset) {
    final isSel = i == _selectedIndex;
    final x = s.startX * fw;
    final y = goalOffset + (0.08 + s.startY * 0.82) * fh;
    // ── Goals get a guaranteed visibility boost (min 30, max 42) ──
    // Other shots scale with xG (20 baseline + up to 18 from xG)
    final double base;
    if (s.type == 'goal') {
      base = (30.0 + (s.xG * 18).clamp(0.0, 12.0));
    } else {
      base = 20.0 + (s.xG * 22).clamp(0.0, 18.0);
    }
    final outer = isSel ? 48.0 : base;
    return Positioned(
      left: x - outer / 2,
      top: y - outer / 2,
      child: GestureDetector(
          onTap: () => _selectShot(i),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
              width: outer,
              height: outer,
              child: Center(child: _dot(s, isSel, base)))),
    );
  }

  Widget _dot(ShotData s, bool sel, double base) {
    // ── Palette allineata alla tabella di conteggio (_shotSummaryBar) ──
    final Color col;
    switch (s.type) {
      case 'goal':
        col = const Color(0xFF4CAF50); // verde Material (= tabella Goal)
        break;
      case 'on_target':
        col = const Color(0xFF1B5E20); // verde scuro (= tabella Parati)
        break;
      case 'blocked':
        col = const Color(0xFFFF9800); // arancio Material (= tabella Respinti)
        break;
      case 'off_target':
      default:
        col = const Color(0xFFE53935); // rosso (= tabella Fuori)
    }
    final sz = sel ? 38.0 : base;
    final bw = sel ? 3.5 : 2.0;
    final darken = HSLColor.fromColor(col)
        .withLightness(
            (HSLColor.fromColor(col).lightness * 0.65).clamp(0.0, 1.0))
        .toColor();

    if (s.type == 'goal') {
      // Filled circle with soccer ball icon
      return Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: col,
              border: Border.all(color: darken, width: bw),
              boxShadow: [
                BoxShadow(
                    color: col.withValues(alpha: sel ? 0.5 : 0.35),
                    blurRadius: sel ? 12 : 8)
              ]),
          child: Center(
              child: Icon(Icons.sports_soccer,
                  color: Colors.white, size: sel ? 20 : sz * 0.55)));
    } else if (s.type == 'on_target') {
      // Bordered circle with inner filled dot (saved)
      return Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: col, width: bw),
              boxShadow: sel
                  ? [BoxShadow(color: col.withValues(alpha: 0.4), blurRadius: 10)]
                  : null),
          child: Center(
              child: Container(
                  width: sel ? 14 : sz * 0.40,
                  height: sel ? 14 : sz * 0.40,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: col))));
    } else if (s.type == 'blocked') {
      // Bordered circle with ALWAYS-visible X
      return Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: col, width: bw),
              boxShadow: sel
                  ? [BoxShadow(color: col.withValues(alpha: 0.4), blurRadius: 10)]
                  : null),
          child: Center(
              child: Icon(Icons.close,
                  color: col, size: sel ? sz * 0.55 : sz * 0.50)));
    } else {
      // off_target: empty bordered circle
      return Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.0),
              border: Border.all(color: col, width: bw),
              boxShadow: sel
                  ? [BoxShadow(color: col.withValues(alpha: 0.3), blurRadius: 10)]
                  : null));
    }
  }

  Widget _legend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legItem(_goalDot(), tr(context, 'Goal')),
        const SizedBox(width: 14),
        _legItem(_onTargetDot(), tr(context, 'In Porta')),
        const SizedBox(width: 14),
        _legItem(_offDot(), tr(context, tr(context, 'Fuori'))),
        const SizedBox(width: 14),
        _legItem(_blockedDot(), tr(context, tr(context, 'Respinto'))),
      ]),
    );
  }

  Widget _legItem(Widget icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        icon,
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
      ]);

  Widget _goalDot() => Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF4CAF50),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                blurRadius: 4)
          ]),
      child: const Center(
          child: Icon(Icons.sports_soccer, color: Colors.white, size: 9)));

  Widget _onTargetDot() => Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFF1B5E20), width: 2)),
      child: Center(
          child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF1B5E20)))));

  Widget _offDot() => Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE53935), width: 2)));

  Widget _blockedDot() => Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFF9800), width: 2)),
      child: const Center(
          child: Icon(Icons.close, color: Color(0xFFFF9800), size: 10)));

  Widget _playerCard(ShotData s) {
    final dk = widget.isDark;
    final bg = dk ? const Color(0xFF1E1E1E) : Colors.white;
    final tx = dk ? Colors.white : const Color(0xFF1A1A1A);
    final lb = Colors.grey[500]!;
    final dv = dk ? Colors.white.withValues(alpha: 0.06) : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dv),
          boxShadow: [
            if (!dk)
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
          ]),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              _arrow(Icons.chevron_left,
                  _selectedIndex != null && _selectedIndex! > 0, _prevShot, dk),
              const SizedBox(width: 10),
              _avatar(s, dk),
              const SizedBox(width: 14),
              Expanded(
                  // [FIX-CLICKNOME] nome cliccabile: apre la scheda giocatore
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (widget.onPlayerTap != null) {
                        widget.onPlayerTap!(s.playerName);
                      }
                    },
                    child: Text(s.playerName,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tx,
                            decoration: TextDecoration.underline,
                            decorationColor: tx.withValues(alpha: 0.25))),
                  )),
              Text(s.minuteDisplay,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: tx)),
              const SizedBox(width: 10),
              _arrow(
                  Icons.chevron_right,
                  _selectedIndex != null &&
                      _selectedIndex! < widget.shots.length - 1,
                  _nextShot,
                  dk),
            ])),
        const SizedBox(height: 14),
        Container(height: 1, color: dv),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              _stat('xG', s.xG.toStringAsFixed(2), tx, lb),
              _div(dv),
              _stat('xGOT', s.xGOT?.toStringAsFixed(2) ?? '-', tx, lb),
              _div(dv),
              _stat(tr(context, 'Esito'), tr(context, s.esito), tx, lb),
            ])),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(children: [
              _stat(tr(context, 'Situazione'), tr(context, s.situation ?? 'Gioco aperto'), tx, lb),
              _div(dv),
              _stat(tr(context, 'Tipo di tiro'), tr(context, s.shotType ?? 'Destro'), tx, lb),
              _div(dv),
              _stat(tr(context, 'Zona gol'), tr(context, s.goalZone ?? '-'), tx, lb),
            ])),
      ]),
    );
  }

  Widget _arrow(IconData ic, bool on, VoidCallback fn, bool dk) =>
      GestureDetector(
          onTap: on ? fn : null,
          child: Icon(ic,
              color: on
                  ? const Color(0xFF1565C0)
                  : (dk ? Colors.grey[800] : Colors.grey[300]),
              size: 28));

  Widget _avatar(ShotData s, bool dk) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dk ? Colors.grey[800] : Colors.grey[200],
          border: Border.all(
              color: dk ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5)),
      child: s.playerPhoto.isNotEmpty
          ? ClipOval(
              child: Image.network(s.playerPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.person, color: Colors.grey[500], size: 24)))
          : Icon(Icons.person, color: Colors.grey[500], size: 24));

  Expanded _stat(String l, String v, Color tx, Color lb) => Expanded(
          child: Column(children: [
        Text(l,
            style: TextStyle(
                fontSize: 11, color: lb, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(v,
            style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ]));

  Widget _div(Color c) => Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: c);

  Widget _emptyState() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
            color: widget.isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(Icons.sports_soccer_outlined, size: 48, color: Colors.grey[500]),
          const SizedBox(height: 12),
          Text(tr(context, 'Nessun tiro disponibile'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ]),
      );
}

// ========================================
// PAINTER: PORTA + AREA PICCOLA
// ========================================
class _GoalPainter extends CustomPainter {
  final double gL, gW, gH, gT, tW;
  _GoalPainter(this.gL, this.gW, this.gH, this.gT, this.tW);

  @override
  void paint(Canvas canvas, Size size) {
    final gR = gL + gW;
    final gB = gT + gH;
    final aW = tW * 0.60;
    final aL = (tW - aW) / 2;
    final aT = gB + 3;

    canvas.drawRect(Rect.fromLTRB(aL, aT, aL + aW, size.height - 6),
        Paint()..color = const Color(0xFFE8F5E9).withValues(alpha: 0.5));
    canvas.drawRect(
        Rect.fromLTRB(aL, aT, aL + aW, size.height - 6),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // ── Limita la linea ai confini dell'area (no sporgenza laterale) ──
    canvas.drawLine(
        Offset(aL, size.height - 6),
        Offset(aL + aW, size.height - 6),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 1.5);

    canvas.drawRect(Rect.fromLTRB(gL + 2, gT + 2, gR - 2, gB),
        Paint()..color = const Color(0xFFE0E0E0));

    final np = Paint()
      ..color = Colors.grey.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 16; i++) {
      final x = gL + (i / 16) * gW;
      canvas.drawLine(Offset(x, gT), Offset(x, gB), np);
    }
    for (int i = 1; i < 6; i++) {
      final y = gT + (i / 6) * gH;
      canvas.drawLine(Offset(gL, y), Offset(gR, y), np);
    }

    final pp = Paint()
      ..color = const Color(0xFF212121)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(gL, gT), Offset(gL, gB + 4), pp);
    canvas.drawLine(Offset(gR, gT), Offset(gR, gB + 4), pp);
    // ── Traversa allineata ai pali (no sporgenza) ──
    // Usa drawRect per allineamento perfetto con i pali esterni.
    canvas.drawRect(
        Rect.fromLTRB(gL - 2, gT - 2.5, gR + 2, gT + 2.5),
        Paint()..color = const Color(0xFF212121));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// PAINTER: METÀ CAMPO
// ========================================
class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const n = 8;
    final sh = size.height / n;
    const c1 = Color(0xFFD5ECD5);
    const c2 = Color(0xFFC5DFC5);
    for (int i = 0; i < n; i++) {
      canvas.drawRect(Rect.fromLTWH(0, i * sh, size.width, sh),
          Paint()..color = i % 2 == 0 ? c1 : c2);
    }

    final lp = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRect(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), lp);

    final pw = size.width * 0.20;
    final pl = (size.width - pw) / 2;
    final ph = size.height * 0.04;
    canvas.drawLine(
        Offset(pl, 1),
        Offset(pl + pw, 1),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    final mp = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pl, 1), Offset(pl, ph), mp);
    canvas.drawLine(Offset(pl + pw, 1), Offset(pl + pw, ph), mp);

    final rw = size.width * 0.60;
    final rh = size.height * 0.36;
    final rl = (size.width - rw) / 2;
    canvas.drawRect(Rect.fromLTWH(rl, 0, rw, rh), lp);

    final sw = size.width * 0.28;
    final ssh = size.height * 0.14;
    final sl = (size.width - sw) / 2;
    canvas.drawRect(Rect.fromLTWH(sl, 0, sw, ssh), lp);

    canvas.drawCircle(
        Offset(size.width / 2, rh * 0.70), 3, Paint()..color = Colors.white);

    final ar = size.width * 0.10;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, rh, size.width, size.height - rh));
    canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, rh), radius: ar),
        0,
        math.pi,
        false,
        lp);
    canvas.restore();

    final cr = size.width * 0.11;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width / 2, size.height), radius: cr),
        math.pi,
        math.pi,
        false,
        lp);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// PAINTER: LINEA TRATTEGGIATA UNIFICATA
// ========================================
class _UnifiedLinePainter extends CustomPainter {
  final double startX, startY, endX, endY;
  final String type;
  final double startRadius;

  _UnifiedLinePainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.type,
    this.startRadius = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF212121).withValues(alpha: 0.65)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    var sX = startX;
    var sY = startY;
    final rawDx = endX - startX;
    final rawDy = endY - startY;
    final rawDist = math.sqrt(rawDx * rawDx + rawDy * rawDy);
    if (rawDist < 1) return;

    // ── Stile SofaScore: la linea parte dal BORDO del cerchio del tiro ──
    if (startRadius > 0 && rawDist > startRadius + 2) {
      sX = startX + (rawDx / rawDist) * startRadius;
      sY = startY + (rawDy / rawDist) * startRadius;
    }

    final dx = endX - sX;
    final dy = endY - sY;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    const dl = 5.0;
    const gl = 4.0;
    var c = 0.0;

    while (c < dist) {
      final s = c / dist;
      final segEnd = c + dl;
      if (segEnd >= dist) {
        canvas.drawLine(
            Offset(sX + dx * s, sY + dy * s), Offset(endX, endY), p);
        break;
      }
      final e = segEnd / dist;
      canvas.drawLine(Offset(sX + dx * s, sY + dy * s),
          Offset(sX + dx * e, sY + dy * e), p);
      c += dl + gl;
    }

    if (type == 'blocked') {
      final bp = Paint()
        ..color = const Color(0xFF212121).withValues(alpha: 0.6)
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
          Offset(endX - 7, endY - 7), Offset(endX + 7, endY + 7), bp);
      canvas.drawLine(
          Offset(endX - 7, endY + 7), Offset(endX + 7, endY - 7), bp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
