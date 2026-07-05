// lib/widgets/tabs/pre_match_info_tab.dart
//
// Tab "Informazioni" pre-match: dati anagrafici della partita
// (competizione, stadio, arbitro, ecc.) + confronto stagionale
// delle due squadre. Estratta da match_detail_screen.dart.
//
// La tab include i dati mock per 20 squadre di Serie A.
// Quando l-API sara attiva, si potranno passare i dati gia caricati
// via costruttore al posto di usare la mappa interna.
//
// // [FAV-prematch-info]

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';

class PreMatchInfoTab extends StatelessWidget {
  final String homeTeamName;
  final String awayTeamName;
  final Color homeColor;
  final Color awayColor;
  final String? leagueName;
  final DateTime date;
  final String time;
  final String? venue;
  final String? round;
  final String? referee;

  const PreMatchInfoTab({
    Key? key,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.homeColor,
    required this.awayColor,
    required this.date,
    required this.time,
    this.leagueName,
    this.venue,
    this.round,
    this.referee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.withValues(alpha: 0.1);

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Match info card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: divider),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: lb),
                  const SizedBox(width: 8),
                  Text(tr(context, 'Informazioni Partita'),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: lb,
                          letterSpacing: 1)),
                ]),
                const SizedBox(height: 16),
                _preMatchInfoRow(
                    Icons.emoji_events_rounded,
                    tr(context, 'Competizione'),
                    leagueName ?? 'Serie A',
                    tx,
                    lb,
                    theme.primaryColor),
                _preMatchInfoRow(
                    Icons.calendar_today_rounded,
                    tr(context, 'Data'),
                    '${date.day}/${date.month}/${date.year}',
                    tx,
                    lb,
                    theme.primaryColor),
                _preMatchInfoRow(Icons.access_time_rounded,
                    tr(context, 'Orario'), time, tx, lb, theme.primaryColor),
                _preMatchInfoRow(Icons.stadium_rounded, tr(context, 'Stadio'),
                    venue ?? 'TBD', tx, lb, theme.primaryColor),
                if (round != null)
                  _preMatchInfoRow(
                      Icons.format_list_numbered_rounded,
                      tr(context, 'Giornata'),
                      round!,
                      tx,
                      lb,
                      theme.primaryColor),
                _preMatchInfoRow(
                    Icons.sports_rounded,
                    tr(context, 'Arbitro'),
                    referee ?? 'Daniele Orsato',
                    tx,
                    lb,
                    theme.primaryColor),
              ]),
        ),
        const SizedBox(height: 16),

        // Season stats comparison mini
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: divider),
          ),
          child: Column(children: [
            Row(children: [
              Icon(Icons.analytics_rounded, size: 16, color: lb),
              const SizedBox(width: 8),
              Text(tr(context, 'Confronto Squadre'),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: lb,
                      letterSpacing: 1)),
            ]),
            const SizedBox(height: 16),
            Builder(builder: (_) {
              final hStats = _getPreMatchTeamStats(homeTeamName);
              final aStats = _getPreMatchTeamStats(awayTeamName);
              return Column(children: [
                _preMatchStatRow(
                    tr(context, 'Gol fatti'),
                    '${hStats['gf']}',
                    '${aStats['gf']}',
                    tx,
                    lb,
                    homeColor,
                    awayColor),
                _preMatchStatRow(
                    tr(context, 'Gol subiti'),
                    '${hStats['ga']}',
                    '${aStats['ga']}',
                    tx,
                    lb,
                    homeColor,
                    awayColor),
                _preMatchStatRow(
                    tr(context, 'Precisione passaggi'),
                    '${hStats['pass']}%',
                    '${aStats['pass']}%',
                    tx,
                    lb,
                    homeColor,
                    awayColor),
                _preMatchStatRow(
                    tr(context, 'Tiri per partita'),
                    '${hStats['shots']}',
                    '${aStats['shots']}',
                    tx,
                    lb,
                    homeColor,
                    awayColor),
                _preMatchStatRow(
                    tr(context, 'Clean Sheet'),
                    '${hStats['cs']}',
                    '${aStats['cs']}',
                    tx,
                    lb,
                    homeColor,
                    awayColor),
              ]);
            }),
          ]),
        ),
      ]),
    );
  }

  Map<String, dynamic> _getPreMatchTeamStats(String teamName) {
    const teamStats = <String, Map<String, dynamic>>{
      'Lazio': {'gf': 49, 'ga': 39, 'pass': 85, 'shots': 14.2, 'cs': 10},
      'Milan': {'gf': 46, 'ga': 37, 'pass': 86, 'shots': 14.8, 'cs': 11},
      'AC Milan': {'gf': 46, 'ga': 37, 'pass': 86, 'shots': 14.8, 'cs': 11},
      'Inter': {'gf': 71, 'ga': 28, 'pass': 88, 'shots': 16.1, 'cs': 15},
      'Napoli': {'gf': 77, 'ga': 28, 'pass': 87, 'shots': 15.9, 'cs': 14},
      'Juventus': {'gf': 47, 'ga': 26, 'pass': 87, 'shots': 13.4, 'cs': 16},
      'AS Roma': {'gf': 47, 'ga': 38, 'pass': 84, 'shots': 14.1, 'cs': 9},
      'Atalanta': {'gf': 59, 'ga': 42, 'pass': 83, 'shots': 15.5, 'cs': 8},
      'Fiorentina': {'gf': 49, 'ga': 40, 'pass': 84, 'shots': 13.9, 'cs': 9},
      'Bologna': {'gf': 44, 'ga': 38, 'pass': 83, 'shots': 13.2, 'cs': 8},
      'Torino': {'gf': 36, 'ga': 36, 'pass': 81, 'shots': 12.1, 'cs': 7},
      'Monza': {'gf': 40, 'ga': 46, 'pass': 82, 'shots': 11.8, 'cs': 6},
      'Udinese': {'gf': 38, 'ga': 44, 'pass': 79, 'shots': 11.5, 'cs': 7},
      'Sassuolo': {'gf': 40, 'ga': 56, 'pass': 83, 'shots': 13.0, 'cs': 5},
      'Empoli': {'gf': 32, 'ga': 44, 'pass': 80, 'shots': 10.8, 'cs': 6},
      'Salernitana': {'gf': 33, 'ga': 62, 'pass': 78, 'shots': 10.2, 'cs': 4},
      'Lecce': {'gf': 30, 'ga': 42, 'pass': 79, 'shots': 10.5, 'cs': 7},
      'Verona': {'gf': 32, 'ga': 52, 'pass': 78, 'shots': 11.0, 'cs': 5},
      'Spezia': {'gf': 32, 'ga': 56, 'pass': 77, 'shots': 10.7, 'cs': 4},
      'Cremonese': {'gf': 27, 'ga': 56, 'pass': 80, 'shots': 10.0, 'cs': 3},
      'Sampdoria': {'gf': 25, 'ga': 56, 'pass': 78, 'shots': 9.8, 'cs': 3},
    };
    final stats = teamStats[teamName];
    if (stats != null) return stats;
    final hash = teamName.hashCode.abs();
    return {
      'gf': 30 + (hash % 50),
      'ga': 25 + (hash % 40),
      'pass': 78 + (hash % 12),
      'shots': (10 + (hash % 8)).toDouble(),
      'cs': 3 + (hash % 14)
    };
  }

  Widget _preMatchInfoRow(IconData icon, String label, String value,
      Color tx, Color lb, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(fontSize: 14, color: lb)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
      ]),
    );
  }

  Widget _preMatchStatRow(String label, String homeVal, String awayVal,
      Color tx, Color lb, Color homeColor, Color awayColor) {
    final hv = double.tryParse(homeVal.replaceAll('%', '')) ?? 0;
    final av = double.tryParse(awayVal.replaceAll('%', '')) ?? 0;
    final total = hv + av;
    final hPct = total > 0 ? hv / total : 0.5;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(children: [
        Row(children: [
          Text(homeVal,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 12, color: lb)),
          const Spacer(),
          Text(awayVal,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
              height: 4,
              child: Row(children: [
                Expanded(
                    flex: (hPct * 100).round(),
                    child: Container(color: homeColor.withValues(alpha: 0.7))),
                Expanded(
                    flex: ((1 - hPct) * 100).round(),
                    child: Container(color: awayColor.withValues(alpha: 0.7))),
              ])),
        ),
      ]),
    );
  }
}
