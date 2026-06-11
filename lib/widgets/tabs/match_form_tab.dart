// lib/widgets/tabs/match_form_tab.dart
//
// Tab "Forma" pre-match: mostra la forma recente di entrambe le squadre
// (ultime ~5 partite). Estratta da match_detail_screen.dart.
//
// La tab e' un widget puro: riceve dati gia calcolati via costruttore.
// I dati (forma, colori squadre, URL loghi) vengono preparati dallo state
// padre e passati come parametri. Per la navigazione su una partita della
// lista, riceve un callback onMatchTap.
//
// // [FAV-formtab]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/l10n_helper.dart';
import '../../models/soccer_match.dart';

class MatchFormTab extends StatefulWidget {
  final String homeName;
  final String awayName;
  final Color homeColor;
  final Color awayColor;
  final String homeLogoUrl;
  final String awayLogoUrl;
  final List<Map<String, dynamic>> homeForm;
  final List<Map<String, dynamic>> awayForm;

  // Helper opzionali per i loghi delle squadre AVVERSARIE nei singoli match.
  // Se non forniti, viene usato l-abbreviazione del nome.
  final String Function(String teamName)? opponentLogoUrl;
  final Color Function(String teamName)? opponentColor;

  // Callback chiamato quando si tappa una partita della forma.
  // Riceve un SoccerMatch costruito al volo dalla tab.
  final void Function(SoccerMatch) onMatchTap;

  const MatchFormTab({
    Key? key,
    required this.homeName,
    required this.awayName,
    required this.homeColor,
    required this.awayColor,
    required this.homeLogoUrl,
    required this.awayLogoUrl,
    required this.homeForm,
    required this.awayForm,
    required this.onMatchTap,
    this.opponentLogoUrl,
    this.opponentColor,
  }) : super(key: key);

  @override
  State<MatchFormTab> createState() => _MatchFormTabState();
}

class _MatchFormTabState extends State<MatchFormTab> {
  // [FAV-form-limit-filter]
  // null = mostra tutte; altrimenti limite al numero di partite mostrate
  // nella match list dettagliata. I form dots (chips V/P/S) restano sempre 5.
  int? _formLimit = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.grey.withOpacity(0.1);

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _buildLimitSelector(isDark, tx, lb),
        const SizedBox(height: 14),
        _buildFormSection(context, widget.homeName, widget.homeForm,
            widget.homeColor, cardBg, tx, lb, divider),
        const SizedBox(height: 16),
        _buildFormSection(context, widget.awayName, widget.awayForm,
            widget.awayColor, cardBg, tx, lb, divider),
      ]),
    );
  }

  // [FAV-form-limit-filter] selettore numero partite mostrate
  Widget _buildLimitSelector(bool isDark, Color tx, Color lb) {
    final bg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    Widget chip(String label, int? value) {
      final active = _formLimit == value;
      return GestureDetector(
        onTap: () => setState(() => _formLimit = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? tx : lb)),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          chip('5', 5),
          const SizedBox(width: 4),
          chip('10', 10),
          const SizedBox(width: 4),
          chip('20', 20),
          const SizedBox(width: 4),
          chip(tr(context, 'Tutte'), null),
        ]),
      ),
    );
  }

  Widget _buildFormSection(BuildContext context, String teamName,
      List<Map<String, dynamic>> form, Color color, Color cardBg,
      Color tx, Color lb, Color divider) {
    // [FAV-form-stats-on-filter]
    // Lista filtrata (in base a _formLimit) per i conteggi badge W/D/L
    // e per la match list dettagliata.
    final filteredForm =
        _formLimit == null ? form : form.take(_formLimit!).toList();
    // I form dots (chips V/P/S) restano sempre le ultime 5, sono icone visuali.
    final dotsForm = form.take(5).toList();

    int w = 0, d = 0, l = 0;
    for (final m in filteredForm) {
      if (m['result'] == 'W') {
        w++;
      } else if (m['result'] == 'D') {
        d++;
      } else {
        l++;
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header with team name and W/D/L
        Row(children: [
          Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(teamName,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
          const Spacer(),
          _formBadge('V', w, const Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          _formBadge('P', d, const Color(0xFFF57F17)),
          const SizedBox(width: 6),
          _formBadge('S', l, const Color(0xFFD32F2F)),
        ]),
        const SizedBox(height: 12),
        // Form dots - bigger - SEMPRE le ultime 5 partite
        Row(children: [
          const SizedBox(width: 14),
          ...dotsForm.map((m) {
            final r = m['result'] as String;
            final c = r == 'W'
                ? const Color(0xFF2E7D32)
                : r == 'D'
                    ? const Color(0xFFE9A800)
                    : const Color(0xFFD32F2F);
            final label = r == 'W' ? 'V' : r == 'D' ? 'P' : 'S';
            return Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: c.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Center(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white))),
            );
          }),
        ]),
        const SizedBox(height: 16),
        // Match list with logos and clickable - usa filteredForm
        ...filteredForm.asMap().entries.map((entry) {
          final i = entry.key;
          final m = entry.value;
          final isLast = i == filteredForm.length - 1;
          final r = m['result'] as String;
          final rc = r == 'W'
              ? const Color(0xFF2E7D32)
              : r == 'D'
                  ? const Color(0xFFE9A800)
                  : const Color(0xFFD32F2F);
          final rLabel = r == 'W' ? 'V' : r == 'D' ? 'P' : 'S';
          final oppName = m['opponent'] as String;
          final oppColor = widget.opponentColor?.call(oppName) ?? color;
          final oppAbbr = oppName.length > 3
              ? oppName.substring(0, 3).toUpperCase()
              : oppName.toUpperCase();
          final isHome = m['venue'] == 'Casa';
          final scores = (m['score'] as String).split('-');
          return GestureDetector(
            onTap: () {
              final hName = isHome ? teamName : oppName;
              final aName = isHome ? oppName : teamName;
              final demoMatch = SoccerMatch(
                id: (teamName + oppName).hashCode.abs(),
                date: DateTime.now(),
                time: '20:45',
                status: 'FT',
                venue: '',
                homeTeamId: 0,
                awayTeamId: 0,
                homeTeamName: hName,
                awayTeamName: aName,
                homeScore: int.tryParse(scores[0].trim()) ?? 0,
                awayScore: int.tryParse(scores[1].trim()) ?? 0,
                leagueName: m['comp'] as String,
                season: 2023,
                round: '',
              );
              widget.onMatchTap(demoMatch);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: divider)),
              ),
              child: Row(children: [
                // Result badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: rc.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rc.withOpacity(0.3)),
                  ),
                  child: Center(
                      child: Text(rLabel,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: rc))),
                ),
                const SizedBox(width: 12),
                // Opponent logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: CachedNetworkImage(
                    imageUrl: widget.opponentLogoUrl?.call(oppName) ?? '',
                    width: 28,
                    height: 28,
                    errorWidget: (_, __, ___) => Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: oppColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(
                          child: Text(oppAbbr,
                              style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: oppColor))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Match info
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(oppName,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tx)),
                      Row(children: [
                        Icon(isHome ? Icons.home_rounded : Icons.flight_rounded,
                            size: 11, color: lb),
                        const SizedBox(width: 4),
                        Text(
                            isHome
                                ? tr(context, 'Casa')
                                : tr(context, 'Trasferta'),
                            style: TextStyle(fontSize: 11, color: lb)),
                        Text(' · ', style: TextStyle(color: lb)),
                        Text(m['comp'] as String,
                            style: TextStyle(fontSize: 11, color: lb)),
                        if (m.containsKey('date')) ...[
                          Text(' · ', style: TextStyle(color: lb)),
                          Text(m['date'] as String? ?? '',
                              style: TextStyle(fontSize: 11, color: lb)),
                        ],
                      ]),
                    ])),
                // Score
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: rc.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(m['score'] as String,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: rc)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: lb),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _formBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text('$count$label',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
