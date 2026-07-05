// lib/widgets/team_form_section.dart
//
// Widget riusabile per mostrare la "Forma" di una squadra.
// Mostra:
//   - Header con nome squadra + badge W/D/L (calcolato su partite filtrate)
//   - Form dots V/P/S (sempre ultime 5, indicatori visuali)
//   - Match list dettagliata (con filtro applicato)
//
// Il filtro [formLimit] e' un PARAM IN INPUT (null = tutte, altrimenti
// limite numerico). Il widget e' Stateless: il padre gestisce lo state.
//
// Usato da:
//   - MatchFormTab (lib/widgets/tabs/match_form_tab.dart): 2 istanze
//     (home + away) condividono lo stesso selettore.
//   - TeamDetailScreen (lib/pages/team_detail_screen.dart): 1 istanza.
//
// // [FAV-team-form-section]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/l10n_helper.dart';
import '../models/soccer_match.dart';

class TeamFormSection extends StatelessWidget {
  /// Nome della squadra (es. "Juventus").
  final String teamName;

  /// Lista delle partite (in formato Map). Ogni partita ha:
  ///   - 'opponent' (String): nome avversario
  ///   - 'score' (String): "2-1"
  ///   - 'result' (String): "W" / "D" / "L"
  ///   - 'venue' (String): "Casa" / "Trasferta"
  ///   - 'comp' (String): nome competizione (es. "Serie A")
  ///   - 'date' (String, opzionale): "02/03"
  final List<Map<String, dynamic>> form;

  /// Limite per la lista filtrata (null = tutte).
  /// Le card "match list" mostrano solo le prime [formLimit] partite.
  /// Anche il badge W/D/L viene calcolato sulle stesse.
  /// I form dots V/P/S restano sempre 5 indipendentemente.
  final int? formLimit;

  /// Colore identificativo della squadra (bordo header).
  final Color teamColor;

  /// Colori UI (passati dal padre per uniformita tema).
  final Color cardBg;
  final Color tx;
  final Color lb;
  final Color divider;

  /// Callback opzionale per ottenere il logo URL dell'avversario.
  final String Function(String teamName)? opponentLogoUrl;

  /// Callback opzionale per ottenere il colore identificativo dell'avversario.
  final Color Function(String teamName)? opponentColor;

  /// Callback chiamato al tap su una partita della lista.
  final void Function(SoccerMatch) onMatchTap;

  const TeamFormSection({
    super.key,
    required this.teamName,
    required this.form,
    required this.formLimit,
    required this.teamColor,
    required this.cardBg,
    required this.tx,
    required this.lb,
    required this.divider,
    required this.onMatchTap,
    this.opponentLogoUrl,
    this.opponentColor,
  });

  @override
  Widget build(BuildContext context) {
    // Lista filtrata in base a formLimit per badge W/D/L e match list.
    final filteredForm =
        formLimit == null ? form : form.take(formLimit!).toList();
    // Form dots: sempre le ultime 5 partite (indicatori visuali rapidi).
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
              color: teamColor.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header: nome squadra + badge W/D/L
        Row(children: [
          Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                  color: teamColor, borderRadius: BorderRadius.circular(2))),
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
        // Form dots: sempre le ultime 5 partite
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
                      color: c.withValues(alpha: 0.3),
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
        // Match list dettagliata (lista filtrata)
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
          final oppColor = opponentColor?.call(oppName) ?? teamColor;
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
              onMatchTap(demoMatch);
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
                    color: rc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: rc.withValues(alpha: 0.3)),
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
                    imageUrl: opponentLogoUrl?.call(oppName) ?? '',
                    width: 28,
                    height: 28,
                    errorWidget: (_, __, ___) => Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: oppColor.withValues(alpha: 0.12),
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
                    color: rc.withValues(alpha: 0.08),
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text('$count$label',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
