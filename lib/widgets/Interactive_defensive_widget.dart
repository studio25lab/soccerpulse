import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../painters/advanced_stats_painters.dart';

// ========================================
// MODELLO DATI AZIONE DIFENSIVA
// ========================================
class DefensiveActionData {
  final String playerName;
  final String? playerPhoto;
  final int minute;
  final int? addedTime;
  final double fieldX;
  final double fieldY;
  final String type; // 'tackle', 'interception', 'clearance'
  final bool won;
  final String? detail;
  final bool isHomeTeam;

  DefensiveActionData({
    required this.playerName,
    this.playerPhoto,
    required this.minute,
    this.addedTime,
    required this.fieldX,
    required this.fieldY,
    required this.type,
    this.won = true,
    this.detail,
    required this.isHomeTeam,
  });

  String get typeLabel {
    switch (type) {
      case 'tackle':
        return 'Contrasto';
      case 'interception':
        return 'Intercetto';
      case 'clearance':
        return 'Rinvio';
      default:
        return type;
    }
  }

  String get resultLabel => won ? 'Vinto' : 'Perso';

  String get minuteDisplay =>
      addedTime != null ? "$minute'+$addedTime" : "$minute'";

  Color get typeColor {
    switch (type) {
      case 'tackle':
        return const Color(0xFFE53935);
      case 'interception':
        return const Color(0xFFFF9800);
      case 'clearance':
        return const Color(0xFFFDD835);
      default:
        return Colors.grey;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case 'tackle':
        return Icons.close;
      case 'interception':
        return Icons.change_history;
      case 'clearance':
        return Icons.arrow_upward;
      default:
        return Icons.circle;
    }
  }

  bool get isFirstHalf =>
      minute <= 45 ||
      (minute == 45 && (addedTime ?? 0) > 0 && (addedTime ?? 0) <= 5);
}

// ========================================
// STATISTICHE DIFENSIVE SQUADRA
// ========================================
class DefensiveStats {
  final int tacklesWon;
  final int tacklesTotal;
  final int interceptions;
  final int rinvii;

  const DefensiveStats({
    required this.tacklesWon,
    required this.tacklesTotal,
    required this.interceptions,
    required this.rinvii,
  });

  double get tacklesWonPct => tacklesTotal > 0 ? tacklesWon / tacklesTotal : 0;
}

enum _TeamFilter { all, home, away }

enum _TimeFilter { all, first, second }

// ========================================
// WIDGET PRINCIPALE
// ========================================
class InteractiveDefensiveWidget extends StatefulWidget {
  final List<DefensiveActionData> homeActions;
  final List<DefensiveActionData> awayActions;
  final DefensiveStats homeStats;
  final DefensiveStats awayStats;
  final String homeTeamName;
  final String awayTeamName;
  final Color homeColor;
  final Color awayColor;
  final bool isDark;
  final void Function(String name, bool isHome, bool isDark)? openPlayerProfile;

  const InteractiveDefensiveWidget({
    super.key,
    required this.homeActions,
    required this.awayActions,
    required this.homeStats,
    required this.awayStats,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeColor = const Color(0xFF4CAF50),
    this.awayColor = const Color(0xFF1565C0),
    this.isDark = false,
    this.openPlayerProfile,
  });

  @override
  State<InteractiveDefensiveWidget> createState() =>
      _InteractiveDefensiveWidgetState();
}

class _InteractiveDefensiveWidgetState
    extends State<InteractiveDefensiveWidget> {
  int? _selectedIndex;
  _TeamFilter _teamFilter = _TeamFilter.all;
  _TimeFilter _timeFilter = _TimeFilter.all;
  String? _playerFilter; // null = tutti, altrimenti nome giocatore

  // Filtri tipo azione (tutti attivi di default)
  bool _showTackles = true;
  bool _showInterceptions = true;

  List<DefensiveActionData> get _allTeamActions {
    switch (_teamFilter) {
      case _TeamFilter.home:
        return widget.homeActions;
      case _TeamFilter.away:
        return widget.awayActions;
      case _TeamFilter.all:
        final all = [...widget.homeActions, ...widget.awayActions];
        all.sort((a, b) {
          final cmp = a.minute.compareTo(b.minute);
          if (cmp != 0) return cmp;
          return (a.addedTime ?? 0).compareTo(b.addedTime ?? 0);
        });
        return all;
    }
  }

  List<DefensiveActionData> get _visibleActions {
    return _allTeamActions.where((a) {
      // Rinvii mai mostrati sul campo (solo nell'infografica)
      if (a.type == 'clearance') return false;
      // Filtro tipo
      if (a.type == 'tackle' && !_showTackles) return false;
      if (a.type == 'interception' && !_showInterceptions) return false;
      // Filtro tempo
      if (_timeFilter == _TimeFilter.first && a.minute > 45) return false;
      if (_timeFilter == _TimeFilter.second && a.minute <= 45) return false;
      // Filtro giocatore
      if (_playerFilter != null && a.playerName != _playerFilter) return false;
      return true;
    }).toList();
  }

  void _selectAction(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  void _prevAction() {
    if (_selectedIndex != null && _selectedIndex! > 0) {
      setState(() => _selectedIndex = _selectedIndex! - 1);
    }
  }

  void _nextAction() {
    if (_selectedIndex != null &&
        _selectedIndex! < _visibleActions.length - 1) {
      setState(() => _selectedIndex = _selectedIndex! + 1);
    }
  }

  void _setTeamFilter(_TeamFilter f) {
    if (_teamFilter == f) return;
    HapticFeedback.lightImpact();
    setState(() {
      _teamFilter = f;
      _selectedIndex = null;
      _playerFilter = null;
    });
  }

  void _setTimeFilter(_TimeFilter f) {
    if (_timeFilter == f) return;
    HapticFeedback.lightImpact();
    setState(() {
      _timeFilter = f;
      _selectedIndex = null;
    });
  }

  void _toggleType(String type) {
    HapticFeedback.lightImpact();
    setState(() {
      switch (type) {
        case 'tackle':
          _showTackles = !_showTackles;
          break;
        case 'interception':
          _showInterceptions = !_showInterceptions;
          break;
      }
      _selectedIndex = null;
    });
  }

  void _togglePlayerFilter(String name) {
    HapticFeedback.lightImpact();
    setState(() {
      _playerFilter = _playerFilter == name ? null : name;
      _selectedIndex = null;
    });
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    final actions = _visibleActions;
    final sel = _selectedIndex != null && _selectedIndex! < actions.length
        ? actions[_selectedIndex!]
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: Column(children: [
        _teamFilterBar(),
        const SizedBox(height: 10),
        _typeFilterRow(),
        const SizedBox(height: 10),
        _timeFilterRow(),
        const SizedBox(height: 12),
        _summaryBar(actions),
        const SizedBox(height: 12),
        Center(
          child: Text(
            tr(context, 'Mappa contrasti e intercetti'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: widget.isDark
                  ? Colors.white
                  : const Color(0xFF1A1A1A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _fieldMap(actions, sel),
        _legend(),
        if (sel != null) ...[const SizedBox(height: 12), _playerCard(sel)],
        const SizedBox(height: 20),
        _statsInfographic(),
        const SizedBox(height: 20),
        _topPlayersSection(),
        const SizedBox(height: 16),
      ]),
    );
  }

  // ===================== FILTRO SQUADRA =====================
  Widget _teamFilterBar() {
    final dk = widget.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: dk ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _teamTab(tr(context, 'Tutti'), _TeamFilter.all, null),
            const SizedBox(width: 4),
            _teamTab(widget.homeTeamName, _TeamFilter.home, widget.homeColor),
            const SizedBox(width: 4),
            _teamTab(widget.awayTeamName, _TeamFilter.away, widget.awayColor),
          ]),
        ),
      ),
    );
  }

  Widget _teamTab(String label, _TeamFilter f, Color? activeColor) {
    final active = _teamFilter == f;
    final dk = widget.isDark;
    final color = activeColor ?? (dk ? Colors.white : const Color(0xFF424242));

    return GestureDetector(
      onTap: () => _setTeamFilter(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        decoration: BoxDecoration(
          color: active
              ? (dk ? const Color(0xFF1A1A1A) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active
                    ? color
                    : (dk ? Colors.grey[500] : Colors.grey[600]))),
      ),
    );
  }

  // ===================== FILTRO TIPO AZIONE =====================
  Widget _typeFilterRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _typeChip(tr(context, 'Contrasti'), 'tackle', Color(0xFFE53935), _showTackles),
        SizedBox(width: 8),
        _typeChip(tr(context, 'Intercetti'), 'interception', Color(0xFFFF9800),
            _showInterceptions),
      ]),
    );
  }

  Widget _typeChip(String label, String type, Color color, bool active) {
    final dk = widget.isDark;
    return Expanded(
      child: GestureDetector(
        onTap: () => _toggleType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.15)
                : (dk ? Colors.grey[850] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? color.withValues(alpha: 0.5) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape:
                    type == 'clearance' ? BoxShape.rectangle : BoxShape.circle,
                borderRadius:
                    type == 'clearance' ? BorderRadius.circular(2) : null,
                color:
                    active ? color : (dk ? Colors.grey[700] : Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? color
                      : (dk ? Colors.grey[500] : Colors.grey[500]),
                )),
          ]),
        ),
      ),
    );
  }

  // ===================== FILTRO TEMPO =====================
  Widget _timeFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _timeChip(_TimeFilter.all),
        const SizedBox(width: 8),
        _timeChip(_TimeFilter.first),
        const SizedBox(width: 8),
        _timeChip(_TimeFilter.second),
        const Spacer(),
        if (_playerFilter != null)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _playerFilter = null;
                _selectedIndex = null;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_playerFilter!,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0))),
                const SizedBox(width: 4),
                const Icon(Icons.close, size: 14, color: Color(0xFF1565C0)),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _timeChip(_TimeFilter f) {
    final active = _timeFilter == f;
    final dk = widget.isDark;
    final label = f == _TimeFilter.all
        ? tr(context, 'Tutti')
        : (f == _TimeFilter.first ? tr(context, '1° Tempo') : tr(context, '2° Tempo'));

    return GestureDetector(
      onTap: () => _setTimeFilter(f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? (dk
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFF424242).withValues(alpha: 0.08))
              : (dk ? Colors.grey[850] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? (dk
                    ? Colors.white.withValues(alpha: 0.3)
                    : const Color(0xFF424242).withValues(alpha: 0.3))
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active
                  ? (dk ? Colors.white : const Color(0xFF424242))
                  : (dk ? Colors.grey[500] : Colors.grey[500]),
            )),
      ),
    );
  }

  // ===================== BARRA RIEPILOGO =====================
  Widget _summaryBar(List<DefensiveActionData> actions) {
    final tackles = actions.where((a) => a.type == 'tackle').length;
    final intercepts = actions.where((a) => a.type == 'interception').length;
    final won = actions.where((a) => a.won).length;
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
        _summaryItem(tr(context, 'Totali'), actions.length.toString(), tx, lb, null),
        _summaryDivider(dv),
        _summaryItem(
            tr(context, 'Contrasti'), tackles.toString(), tx, lb, Color(0xFFE53935)),
        _summaryDivider(dv),
        _summaryItem(tr(context, 'Intercetti'), intercepts.toString(), tx, lb,
            const Color(0xFFFF9800)),
        _summaryDivider(dv),
        _summaryItem(tr(context, 'Vinti'), won.toString(), tx, lb, const Color(0xFF4CAF50)),
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

  // ===================== CAMPO CON MARKER =====================
  Widget _fieldMap(
      List<DefensiveActionData> actions, DefensiveActionData? sel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (ctx, box) {
        final w = box.maxWidth;
        final h = w * 0.64;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(clipBehavior: Clip.hardEdge, children: [
              Positioned.fill(
                  child: CustomPaint(
                size: Size(w, h),
                painter: RealisticSoccerFieldPainter(isDark: widget.isDark),
              )),
              Positioned.fill(
                  child: CustomPaint(
                size: Size(w, h),
                painter: RealisticSoccerFieldPainter(
                    isDark: widget.isDark, linesOnly: true),
              )),
              ...actions
                  .asMap()
                  .entries
                  .map((e) => _marker(e.value, e.key, w, h)),
            ]),
          ),
        );
      }),
    );
  }

  Widget _marker(DefensiveActionData a, int i, double fw, double fh) {
    final isSel = i == _selectedIndex;
    final x = a.fieldX * fw;
    final y = a.fieldY * fh;
    final outerSize = isSel ? 52.0 : 36.0;

    return Positioned(
      left: x - outerSize / 2,
      top: y - outerSize / 2,
      child: GestureDetector(
        onTap: () => _selectAction(i),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: outerSize,
          height: outerSize,
          child: Center(child: _markerIcon(a, isSel)),
        ),
      ),
    );
  }

  Widget _markerIcon(DefensiveActionData a, bool sel) {
    final color = a.typeColor;
    final size = sel ? 34.0 : 22.0;
    // ④ Bordo verde/rosso per vinto/perso
    final resultBorderColor =
        a.won ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    final outerBorderWidth = sel ? 3.0 : 2.0;

    switch (a.type) {
      case 'tackle':
        return Container(
          width: size + outerBorderWidth * 2,
          height: size + outerBorderWidth * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border:
                Border.all(color: resultBorderColor, width: outerBorderWidth),
          ),
          child: Center(
              child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.8)]),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: sel ? 0.5 : 0.3),
                    blurRadius: sel ? 10 : 5)
              ],
            ),
            child: Center(
                child: Icon(Icons.close,
                    color: Colors.white, size: sel ? 18 : 12)),
          )),
        );

      case 'interception':
        return SizedBox(
          width: size + outerBorderWidth * 2,
          height: size + outerBorderWidth * 2,
          child: CustomPaint(
            size:
                Size(size + outerBorderWidth * 2, size + outerBorderWidth * 2),
            painter: _TriangleMarkerPainter(
              color: color,
              borderColor: resultBorderColor,
              borderWidth: outerBorderWidth,
              selected: sel,
            ),
          ),
        );

      case 'clearance':
        final inner = size * 0.85;
        return Container(
          width: inner + outerBorderWidth * 2 + 2,
          height: inner + outerBorderWidth * 2 + 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: resultBorderColor, width: outerBorderWidth),
          ),
          child: Center(
              child: Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: sel ? 0.5 : 0.3),
                    blurRadius: sel ? 10 : 5)
              ],
            ),
            child: Center(
                child: Icon(Icons.arrow_upward,
                    color: Colors.white, size: sel ? 16 : 10)),
          )),
        );

      default:
        return Container(width: size, height: size);
    }
  }

  // ===================== LEGENDA =====================
  Widget _legend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legItem(
            Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE53935),
                    border: Border.all(color: Colors.white, width: 1.5)),
                child: Center(
                    child: Icon(Icons.close, color: Colors.white, size: 9))),
            tr(context, 'Contrasti')),
        const SizedBox(width: 14),
        _legItem(
            CustomPaint(
                size: const Size(16, 16),
                painter: _TriangleMarkerPainter(
                    color: const Color(0xFFFF9800),
                    borderColor: Colors.white,
                    borderWidth: 1.5,
                    selected: false)),
            tr(context, 'Intercetti')),
        const SizedBox(width: 18),
        _legItem(
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF4CAF50), width: 2.5))),
            'Vinto'),
        const SizedBox(width: 12),
        _legItem(
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFE53935), width: 2.5))),
            'Perso'),
      ]),
    );
  }

  Widget _legItem(Widget icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        icon,
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
      ]);

  // ===================== CARD GIOCATORE =====================
  Widget _playerCard(DefensiveActionData a) {
    final dk = widget.isDark;
    final bg = dk ? const Color(0xFF1E1E1E) : Colors.white;
    final tx = dk ? Colors.white : const Color(0xFF1A1A1A);
    final lb = Colors.grey[500]!;
    final dv = dk ? Colors.white.withValues(alpha: 0.06) : Colors.grey[200]!;
    final teamColor = a.isHomeTeam ? widget.homeColor : widget.awayColor;
    final teamName = a.isHomeTeam ? widget.homeTeamName : widget.awayTeamName;

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
                _selectedIndex != null && _selectedIndex! > 0, _prevAction, dk),
            const SizedBox(width: 10),
            _avatar(a, dk),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(a.playerName,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: tx)),
                  const SizedBox(height: 3),
                  Row(children: [
                    _badge(a.typeLabel, a.typeColor),
                    const SizedBox(width: 5),
                    _badge(
                        a.resultLabel,
                        a.won
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935)),
                    const SizedBox(width: 5),
                    _badge(teamName, teamColor),
                  ]),
                ])),
            Text(a.minuteDisplay,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: tx)),
            const SizedBox(width: 10),
            _arrow(
                Icons.chevron_right,
                _selectedIndex != null &&
                    _selectedIndex! < _visibleActions.length - 1,
                _nextAction,
                dk),
          ]),
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: dv),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            _stat('Tipo', a.typeLabel, tx, lb),
            _div(dv),
            _stat('Esito', a.resultLabel, tx, lb),
            _div(dv),
            _stat(tr(context, 'Dettaglio'), a.detail ?? '-', tx, lb),
            _div(dv),
            _stat('Minuto', a.minuteDisplay, tx, lb),
          ]),
        ),
      ]),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      );

  Widget _arrow(IconData ic, bool on, VoidCallback fn, bool dk) =>
      GestureDetector(
          onTap: on ? fn : null,
          child: Icon(ic,
              color: on
                  ? const Color(0xFF1565C0)
                  : (dk ? Colors.grey[800] : Colors.grey[300]),
              size: 28));

  Widget _avatar(DefensiveActionData a, bool dk) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: a.typeColor.withValues(alpha: 0.15),
          border: Border.all(color: a.typeColor.withValues(alpha: 0.4), width: 1.5)),
      child: a.playerPhoto != null && a.playerPhoto!.isNotEmpty
          ? ClipOval(
              child: Image.network(a.playerPhoto!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(a.typeIcon, color: a.typeColor, size: 22)))
          : Icon(a.typeIcon, color: a.typeColor, size: 22));

  Expanded _stat(String l, String v, Color tx, Color lb) => Expanded(
          child: Column(children: [
        Text(l,
            style: TextStyle(
                fontSize: 11, color: lb, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(v,
            style:
                TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
      ]));

  Widget _div(Color c) => Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: c);

  // ===================== INFOGRAFICA STATISTICHE =====================
  Widget _statsInfographic() {
    final dk = widget.isDark;
    final bg = dk ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final tx = dk ? Colors.white : const Color(0xFF1A1A1A);
    final lb = dk ? Colors.grey[400]! : Colors.grey[600]!;

    final hStats = widget.homeStats;
    final aStats = widget.awayStats;
    final hPct = (hStats.tacklesWonPct * 100).round();
    final aPct = (aStats.tacklesWonPct * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Text(tr(context, 'Difesa'),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: tx)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _donutChart(hPct, widget.homeColor, tx)),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(tr(context, 'Contrasti vinti'),
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: tx),
                  textAlign: TextAlign.center)),
          Expanded(child: _donutChart(aPct, widget.awayColor, tx)),
        ]),
        SizedBox(height: 28),
        _compBar(tr(context, 'Contrasti'), hStats.tacklesTotal, aStats.tacklesTotal, tx, lb),
        SizedBox(height: 16),
        _compBar(
            tr(context, 'Contrasti vinti'), hStats.tacklesWon, aStats.tacklesWon, tx, lb),
        SizedBox(height: 16),
        _compBar(
            tr(context, 'Intercetti'), hStats.interceptions, aStats.interceptions, tx, lb),
        SizedBox(height: 16),
        _compBar(tr(context, 'Rinvii'), hStats.rinvii, aStats.rinvii, tx, lb),
      ]),
    );
  }

  Widget _donutChart(int pct, Color color, Color tx) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
                value: pct / 100,
                strokeWidth: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round)),
        Text('$pct%',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: tx)),
      ]),
    );
  }

  Widget _compBar(String label, int homeVal, int awayVal, Color tx, Color lb) {
    final maxVal = math.max(homeVal, awayVal).toDouble();
    final hFrac = maxVal > 0 ? homeVal / maxVal : 0.0;
    final aFrac = maxVal > 0 ? awayVal / maxVal : 0.0;

    return Column(children: [
      Row(children: [
        Text('$homeVal',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
        Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500, color: lb))),
        Text('$awayVal',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Expanded(
            child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                    widthFactor: hFrac,
                    child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                            color: widget.homeColor,
                            borderRadius: BorderRadius.circular(4)))))),
        const SizedBox(width: 8),
        Expanded(
            child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                    widthFactor: aFrac,
                    child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                            color: widget.awayColor.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(4)))))),
      ]),
    ]);
  }

  // ===================== TOP GIOCATORI =====================
  Widget _topPlayersSection() {
    final dk = widget.isDark;
    final bg = dk ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final tx = dk ? Colors.white : const Color(0xFF1A1A1A);
    final lb = dk ? Colors.grey[400]! : Colors.grey[600]!;

    // Calcola azioni per giocatore dall'intero set (non filtrato)
    final allActions = [...widget.homeActions, ...widget.awayActions];
    final playerMap = <String, _PlayerStat>{};

    for (final a in allActions) {
      // Solo azioni presenti sul campo (no rinvii)
      if (a.type == 'clearance') continue;
      playerMap.putIfAbsent(
          a.playerName,
          () => _PlayerStat(
                name: a.playerName,
                isHome: a.isHomeTeam,
              ));
      playerMap[a.playerName]!.total++;
      if (a.won) playerMap[a.playerName]!.won++;
      switch (a.type) {
        case 'tackle':
          playerMap[a.playerName]!.tackles++;
          break;
        case 'interception':
          playerMap[a.playerName]!.interceptions++;
          break;
      }
    }

    final sorted = playerMap.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final top = sorted.take(6).toList();
    if (top.isEmpty) return const SizedBox.shrink();

    final maxTotal = top.first.total.toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr(context, 'Top difensori'),
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: tx)),
        SizedBox(height: 4),
        Text(tr(context, 'Tocca un giocatore per filtrare il campo'),
            style: TextStyle(fontSize: 11, color: lb)),
        const SizedBox(height: 16),
        ...top.map((p) => _playerRow(p, maxTotal, tx, lb, dk)),
      ]),
    );
  }

  Widget _playerRow(
      _PlayerStat p, double maxTotal, Color tx, Color lb, bool dk) {
    final isFiltered = _playerFilter == p.name;
    final teamColor = p.isHome ? widget.homeColor : widget.awayColor;
    final barFrac = maxTotal > 0 ? p.total / maxTotal : 0.0;

    return GestureDetector(
      onTap: () => _togglePlayerFilter(p.name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFiltered
              ? teamColor.withValues(alpha: 0.10)
              : (dk ? Colors.grey[850] : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFiltered ? teamColor.withValues(alpha: 0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Avatar con iniziale
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teamColor.withValues(alpha: 0.15),
              ),
              child: Center(
                  child: Text(
                p.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: teamColor),
              )),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(p.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tx)),
                  const SizedBox(height: 2),
                  Row(children: [
                    _miniIcon(
                        BoxShape.circle, const Color(0xFFE53935), p.tackles),
                    const SizedBox(width: 10),
                    _miniIcon(null, const Color(0xFFFF9800), p.interceptions,
                        isTriangle: true),
                    const SizedBox(width: 10),
                    _miniIcon(BoxShape.circle, const Color(0xFF4CAF50), p.won,
                        isCheck: true),
                  ]),
                ])),
            Text('${p.total}',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: tx)),
            if (widget.openPlayerProfile != null) ...[
              const SizedBox(width: 10),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.openPlayerProfile!(
                      p.name, p.isHome, widget.isDark),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: teamColor.withValues(alpha: dk ? 0.18 : 0.10),
                    ),
                    child: Icon(Icons.person_outline,
                        size: 17, color: teamColor),
                  ),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          // Barra proporzionale
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 4,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: barFrac,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [teamColor, teamColor.withValues(alpha: 0.5)]),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _miniIcon(BoxShape? shape, Color color, int val,
      {bool isTriangle = false, bool isCheck = false}) {
    Widget icon;
    if (isCheck) {
      icon = Icon(Icons.check, size: 10, color: color);
    } else if (isTriangle) {
      icon = CustomPaint(
        size: const Size(9, 9),
        painter: _MiniTrianglePainter(color),
      );
    } else {
      icon = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: shape ?? BoxShape.circle,
          borderRadius:
              shape == BoxShape.rectangle ? BorderRadius.circular(1.5) : null,
          color: color,
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      icon,
      const SizedBox(width: 3),
      Text('$val',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600])),
    ]);
  }
}

// ========================================
// HELPER CLASS PER TOP GIOCATORI
// ========================================
class _PlayerStat {
  final String name;
  final bool isHome;
  int total = 0;
  int won = 0;
  int tackles = 0;
  int interceptions = 0;

  _PlayerStat({required this.name, required this.isHome});
}

// ========================================
// MINI TRIANGOLO PER STATS
// ========================================
class _MiniTrianglePainter extends CustomPainter {
  final Color color;
  _MiniTrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ========================================
// PAINTER TRIANGOLO (INTERCETTO)
// ========================================
class _TriangleMarkerPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final bool selected;

  _TriangleMarkerPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - borderWidth;

    final path = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - math.pi / 2;
      final x = cx + math.cos(angle) * r;
      final y = cy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    if (selected) {
      canvas.drawPath(
          path,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }

    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _TriangleMarkerPainter old) =>
      selected != old.selected || borderColor != old.borderColor;
}
