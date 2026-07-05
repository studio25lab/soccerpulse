// lib/widgets/dialogs/rendimento_dialog.dart
//
// Dialog "Rendimento Serie A" - filtra la classifica per range di giornate.
// Estratto da standings_screen.dart per riuso anche in match detail.
//
// Uso:
//   showRendimento(context, theme, isDark, tx, lb);
//
// [FAV-rendimento-extract]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../utils/l10n_helper.dart';
import '../../services/haptic_service.dart';
import '../../generated/l10n.dart';

void showRendimento(
  BuildContext context,
  ThemeData theme,
  bool isDark,
  Color tx,
  Color lb, {
  List<String>? highlightTeams,
  Color Function(String teamName)? getTeamColor,
}) {
  final haptic = HapticService();
  const int currentMatchday = 38; // TODO: da API
  // [FAV-rangeslider] range invece di singola giornata
  RangeValues selectedRange = RangeValues(1, currentMatchday.toDouble());
  final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
  final divider = isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.grey.withValues(alpha: 0.1);

  // Dati reali Serie A 2023/24 (mock con totali finali)
  final teamsData = <Map<String, dynamic>>[
    {'team': 'Inter', 'logo': 'https://media.api-sports.io/football/teams/505.png', 'finalPts': 94, 'w': 29, 'd': 7, 'l': 2},
    {'team': 'Milan', 'logo': 'https://media.api-sports.io/football/teams/489.png', 'finalPts': 75, 'w': 22, 'd': 9, 'l': 7},
    {'team': 'Juventus', 'logo': 'https://media.api-sports.io/football/teams/496.png', 'finalPts': 71, 'w': 19, 'd': 14, 'l': 5},
    {'team': 'Atalanta', 'logo': 'https://media.api-sports.io/football/teams/499.png', 'finalPts': 69, 'w': 21, 'd': 6, 'l': 11},
    {'team': 'Bologna', 'logo': 'https://media.api-sports.io/football/teams/500.png', 'finalPts': 68, 'w': 18, 'd': 14, 'l': 6},
    {'team': 'Roma', 'logo': 'https://media.api-sports.io/football/teams/497.png', 'finalPts': 63, 'w': 18, 'd': 9, 'l': 11},
    {'team': 'Lazio', 'logo': 'https://media.api-sports.io/football/teams/487.png', 'finalPts': 61, 'w': 18, 'd': 7, 'l': 13},
    {'team': 'Fiorentina', 'logo': 'https://media.api-sports.io/football/teams/502.png', 'finalPts': 60, 'w': 17, 'd': 9, 'l': 12},
    {'team': 'Napoli', 'logo': 'https://media.api-sports.io/football/teams/492.png', 'finalPts': 53, 'w': 13, 'd': 14, 'l': 11},
    {'team': 'Torino', 'logo': 'https://media.api-sports.io/football/teams/503.png', 'finalPts': 53, 'w': 13, 'd': 14, 'l': 11},
    {'team': 'Monza', 'logo': 'https://media.api-sports.io/football/teams/1579.png', 'finalPts': 49, 'w': 12, 'd': 13, 'l': 13},
    {'team': 'Genoa', 'logo': 'https://media.api-sports.io/football/teams/495.png', 'finalPts': 49, 'w': 12, 'd': 13, 'l': 13},
    {'team': 'Lecce', 'logo': 'https://media.api-sports.io/football/teams/867.png', 'finalPts': 42, 'w': 9, 'd': 15, 'l': 14},
    {'team': 'Cagliari', 'logo': 'https://media.api-sports.io/football/teams/490.png', 'finalPts': 42, 'w': 10, 'd': 12, 'l': 16},
    {'team': 'Verona', 'logo': 'https://media.api-sports.io/football/teams/504.png', 'finalPts': 41, 'w': 10, 'd': 11, 'l': 17},
    {'team': 'Udinese', 'logo': 'https://media.api-sports.io/football/teams/494.png', 'finalPts': 40, 'w': 9, 'd': 13, 'l': 16},
    {'team': 'Empoli', 'logo': 'https://media.api-sports.io/football/teams/511.png', 'finalPts': 36, 'w': 7, 'd': 15, 'l': 16},
    {'team': 'Sassuolo', 'logo': 'https://media.api-sports.io/football/teams/488.png', 'finalPts': 20, 'w': 3, 'd': 11, 'l': 24},
    {'team': 'Frosinone', 'logo': 'https://media.api-sports.io/football/teams/512.png', 'finalPts': 32, 'w': 7, 'd': 11, 'l': 20},
    {'team': 'Salernitana', 'logo': 'https://media.api-sports.io/football/teams/514.png', 'finalPts': 17, 'w': 3, 'd': 8, 'l': 27},
  ];

  // Genera risultati giornata per giornata per ogni squadra (W/D/L)
  Map<String, Map<String, List<int>>> generateResults() {
    final results = <String, Map<String, List<int>>>{};
    for (final td in teamsData) {
      final team = td['team'] as String;
      int w = td['w'] as int;
      int d = td['d'] as int;
      int l = td['l'] as int;

      final matchResults = <int>[];
      for (int i = 0; i < w; i++) {
        matchResults.add(3);
      }
      for (int i = 0; i < d; i++) {
        matchResults.add(1);
      }
      for (int i = 0; i < l; i++) {
        matchResults.add(0);
      }

      final seed = team.hashCode.abs();
      for (int i = matchResults.length - 1; i > 0; i--) {
        final j = (seed + i * 7) % (i + 1);
        final tmp = matchResults[i];
        matchResults[i] = matchResults[j];
        matchResults[j] = tmp;
      }

      final cumulative = <int>[];
      final perMatch = <int>[];
      int total = 0;
      for (int i = 0; i < matchResults.length && i < 38; i++) {
        perMatch.add(matchResults[i]);
        total += matchResults[i];
        cumulative.add(total);
      }
      results[team] = {'cumulative': cumulative, 'perMatch': perMatch};
    }
    return results;
  }

  final allResults = generateResults();

  // Ranking per range di giornate [start, end] (estremi inclusi)
  List<Map<String, dynamic>> getRankingForRange(int start, int end) {
    final ranking = <Map<String, dynamic>>[];
    for (final td in teamsData) {
      final team = td['team'] as String;
      final perMatch = allResults[team]!['perMatch']!;
      int pts = 0;
      for (int i = start - 1; i < end && i < perMatch.length; i++) {
        pts += perMatch[i];
      }
      ranking.add({
        'team': team,
        'logo': td['logo'],
        'pts': pts,
        'played': end - start + 1,
      });
    }
    ranking.sort((a, b) {
      final cmp = (b['pts'] as int).compareTo(a['pts'] as int);
      if (cmp != 0) return cmp;
      return (a['team'] as String).compareTo(b['team'] as String);
    });
    return ranking;
  }

  // Color per posizione classifica
  Color posColor(int pos) {
    if (pos <= 4) return const Color(0xFF4CAF50); // Champions League
    if (pos == 5 || pos == 6) return const Color(0xFF2196F3); // Europa League
    if (pos == 7) return const Color(0xFFFFA726); // Conference League
    if (pos >= 18) return const Color(0xFFE53935); // Retrocessione
    return Colors.grey;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setSheetState) {
        final startMd = selectedRange.start.round();
        final endMd = selectedRange.end.round();
        final ranking = getRankingForRange(startMd, endMd);
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2))),
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(children: [
                  Icon(Icons.trending_up_rounded,
                      size: 22, color: theme.primaryColor),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(S.of(context)!.rendimentoSerieA,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: tx)),
                        Text(
                            '${tr(context, "Classifica giornate")} $startMd–$endMd',
                            style: TextStyle(fontSize: 12, color: lb)),
                      ]),
                ])),
            // [FAV-rangeslider] RangeSlider con due manopole
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(children: [
                  Text(tr(context, 'Giornata 1'),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: lb)),
                  Expanded(
                      child: SliderTheme(
                          data: SliderThemeData(
                              activeTrackColor: theme.primaryColor,
                              inactiveTrackColor:
                                  isDark ? Colors.white12 : Colors.grey[200],
                              thumbColor: theme.primaryColor,
                              rangeThumbShape: const RoundRangeSliderThumbShape(
                                  enabledThumbRadius: 8),
                              trackHeight: 4),
                          child: RangeSlider(
                              values: selectedRange,
                              min: 1,
                              max: currentMatchday.toDouble(),
                              divisions:
                                  (currentMatchday - 1).clamp(1, 37),
                              onChanged: (val) {
                                haptic.lightImpact();
                                setSheetState(() {
                                  selectedRange = RangeValues(
                                    val.start.roundToDouble(),
                                    val.end.roundToDouble(),
                                  );
                                });
                              }))),
                  Text(
                      '${tr(context, 'Giornata')} $currentMatchday',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: lb)),
                ])),
            // Badge giornata
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                          '${tr(context, 'Giornate')} $startMd–$endMd',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: theme.primaryColor)),
                    ])),
            const SizedBox(height: 8),
            // Header colonne
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(children: [
                  const SizedBox(width: 28),
                  const SizedBox(width: 10),
                  const SizedBox(width: 28),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(S.of(context)!.squadra,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: lb))),
                  SizedBox(
                      width: 34,
                      child: Center(
                          child: Text(standingsAbbr(context, 'G'),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: lb)))),
                  const SizedBox(width: 16),
                  SizedBox(
                      width: 48,
                      child: Center(
                          child: Text(tr(context, 'Punti'),
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.primaryColor)))),
                ])),
            Divider(height: 1, color: divider),
            // Lista
            Expanded(
                child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: ranking.length,
                    itemBuilder: (ctx, i) {
                      final r = ranking[i];
                      final isTop3 = i < 3;
                      final pColor = posColor(i + 1);
                      final isRetro = i >= 17;
                      // [FAV-rendimento-highlight] evidenzia squadre match
                      final teamName = r['team'] as String;
                      final isMatchTeam = highlightTeams != null &&
                          highlightTeams.any((h) =>
                              h == teamName ||
                              teamName.contains(h) ||
                              h.contains(teamName));
                      final matchColor = isMatchTeam
                          ? (getTeamColor != null
                              ? getTeamColor(teamName)
                              : theme.primaryColor)
                          : null;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                            color: isMatchTeam && matchColor != null
                                ? matchColor.withValues(alpha: isDark ? 0.24 : 0.14)
                                : isTop3
                                    ? pColor.withValues(alpha: isDark ? 0.06 : 0.03)
                                    : isRetro
                                        ? Colors.red
                                            .withValues(alpha: isDark ? 0.04 : 0.02)
                                        : null,
                            border: Border(
                                left: BorderSide(
                                    width: isMatchTeam && matchColor != null ? 5 : 3,
                                    color: isMatchTeam && matchColor != null
                                        ? matchColor
                                        : pColor),
                                bottom:
                                    BorderSide(width: 0.5, color: divider))),
                        child: Row(children: [
                          SizedBox(
                              width: 28,
                              child: Center(
                                  child: isTop3
                                      ? Container(
                                          width: 24,
                                          height: 24,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: i == 0
                                                  ? const Color(0xFFFFD700)
                                                  : i == 1
                                                      ? const Color(0xFFC0C0C0)
                                                      : const Color(0xFFCD7F32),
                                              shape: BoxShape.circle),
                                          child: Text('${i + 1}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white)))
                                      : Text('${i + 1}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: pColor)))),
                          const SizedBox(width: 10),
                          CachedNetworkImage(
                              imageUrl: r['logo'] as String,
                              width: 28,
                              height: 28,
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.shield, size: 28)),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(r['team'] as String,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isMatchTeam
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isMatchTeam && matchColor != null
                                          ? matchColor
                                          : tx))),
                          SizedBox(
                              width: 34,
                              child: Center(
                                  child: Text('${r['played']}',
                                      style: TextStyle(
                                          fontSize: 12, color: lb)))),
                          const SizedBox(width: 16),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                  color: pColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Text('${r['pts']}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: pColor))),
                        ]),
                      );
                    })),
          ]),
        );
      },
    ),
  );
}
