// lib/widgets/tabs/h2h_tab.dart
//
// Tab "Scontri Diretti" (Head To Head): mostra storico tra le due squadre,
// statistiche aggregate, lista degli ultimi 10 precedenti.
// Estratta da match_detail_screen.dart.
//
// // [FAV-h2h-tab]

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/l10n_helper.dart';
import '../../generated/l10n.dart';
import '../../models/soccer_match.dart';
import '../../services/favorites_service.dart';
import '../../services/haptic_service.dart';

class H2HTab extends StatelessWidget {
  final String homeName;
  final String awayName;
  final Color homeColor;
  final Color awayColor;
  final void Function(SoccerMatch) onMatchTap;

  const H2HTab({
    super.key,
    required this.homeName,
    required this.awayName,
    required this.homeColor,
    required this.awayColor,
    required this.onMatchTap,
  });

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

    final h2hMatches = _getH2HMatches(homeName, awayName);

    int homeWins = 0, draws = 0, awayWins = 0, homeGoals = 0, awayGoals = 0;
    for (final m in h2hMatches) {
      final hs = m['hScore'] as int;
      final as_ = m['aScore'] as int;
      final mHome = m['home'] as String;
      if (mHome == homeName) {
        homeGoals += hs;
        awayGoals += as_;
        if (hs > as_) {
          homeWins++;
        } else if (hs < as_) {
          awayWins++;
        } else {
          draws++;
        }
      } else {
        homeGoals += as_;
        awayGoals += hs;
        if (as_ > hs) {
          homeWins++;
        } else if (as_ < hs) {
          awayWins++;
        } else {
          draws++;
        }
      }
    }
    final total = h2hMatches.length;

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                _teamGradient(homeName)[0].withValues(alpha: isDark ? 0.22 : 0.18),
                _teamGradient(homeName)[1].withValues(alpha: isDark ? 0.10 : 0.08),
                cardBg,
                _teamGradient(awayName)[0].withValues(alpha: isDark ? 0.10 : 0.08),
                _teamGradient(awayName)[1].withValues(alpha: isDark ? 0.22 : 0.18),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: divider),
          ),
          child: Column(children: [
            Row(children: [
              Icon(Icons.compare_arrows_rounded, size: 14, color: lb),
              const SizedBox(width: 6),
              Text(tr(context, 'SCONTRI DIRETTI'),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: lb,
                      letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 4),
            Text('${tr(context, 'Ultimi')} $total ${tr(context, 'incontri')}',
                style: TextStyle(fontSize: 12, color: lb)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: homeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: homeColor.withValues(alpha: 0.25)),
                  ),
                  child: Text('$homeWins',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: homeColor)),
                ),
                const SizedBox(height: 8),
                Text(tr(context, 'Vittorie'),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: homeColor.withValues(alpha: 0.8))),
                const SizedBox(height: 2),
                Text(homeName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tx)),
              ])),
              Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: divider),
                  ),
                  child: Text('$draws',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: lb)),
                ),
                const SizedBox(height: 6),
                Text(tr(context, 'Pareggi'),
                    style: TextStyle(fontSize: 10, color: lb)),
              ]),
              Expanded(
                  child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: awayColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: awayColor.withValues(alpha: 0.25)),
                  ),
                  child: Text('$awayWins',
                      style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: awayColor)),
                ),
                const SizedBox(height: 8),
                Text(tr(context, 'Vittorie'),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: awayColor.withValues(alpha: 0.8))),
                const SizedBox(height: 2),
                Text(awayName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tx)),
              ])),
            ]),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 10,
                child: Row(children: [
                  if (homeWins > 0)
                    Expanded(
                        flex: homeWins,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              homeColor,
                              homeColor.withValues(alpha: 0.7)
                            ]),
                          ),
                        )),
                  if (draws > 0)
                    Expanded(
                        flex: draws,
                        child: Container(
                            color: Colors.grey.withValues(alpha: 0.5))),
                  if (awayWins > 0)
                    Expanded(
                        flex: awayWins,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              awayColor.withValues(alpha: 0.7),
                              awayColor
                            ]),
                          ),
                        )),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      Text('$homeGoals',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: homeColor)),
                      const SizedBox(height: 2),
                      Text(S.of(context)!.gol,
                          style: TextStyle(fontSize: 10, color: lb)),
                    ]),
                    Container(width: 1, height: 28, color: divider),
                    Column(children: [
                      Text(
                          (homeGoals + awayGoals) / total > 0 ? ((homeGoals + awayGoals) / total).toStringAsFixed(1) : "0",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: tx)),
                      const SizedBox(height: 2),
                      Text(tr(context, 'Media gol'),
                          style: TextStyle(fontSize: 10, color: lb)),
                    ]),
                    Container(width: 1, height: 28, color: divider),
                    Column(children: [
                      Text('$awayGoals',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: awayColor)),
                      const SizedBox(height: 2),
                      Text(S.of(context)!.gol,
                          style: TextStyle(fontSize: 10, color: lb)),
                    ]),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: divider),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                Icon(Icons.history_rounded, size: 15, color: lb),
                const SizedBox(width: 8),
                Text(tr(context, 'PRECEDENTI'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: lb,
                        letterSpacing: 1.2)),
              ]),
            ),
            ...h2hMatches.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final isLast = i == h2hMatches.length - 1;
              final hs = m['hScore'] as int;
              final as_ = m['aScore'] as int;
              final mHome = m['home'] as String;
              final mAway = m['away'] as String;
              final isHomeWin = hs > as_;
              final isAwayWin = as_ > hs;

              return GestureDetector(
                onTap: () {
                  onMatchTap(SoccerMatch(
                    id: (2000 + i),
                    date: DateTime.now(),
                    time: '20:45',
                    status: 'FT',
                    venue: mHome == 'Lazio' ? 'Stadio Olimpico' : 'San Siro',
                    homeTeamId: 0,
                    homeTeamName: mHome,
                    awayTeamId: 0,
                    awayTeamName: mAway,
                    homeScore: hs,
                    awayScore: as_,
                    leagueName: m['comp'] as String,
                    season: 2023,
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : Border(bottom: BorderSide(color: divider)),
                  ),
                  child: Row(children: [
                    SizedBox(
                        width: 60,
                        child: Column(children: [
                          Text(m['date'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: tx)),
                          Text(m['comp'] as String,
                              style: TextStyle(fontSize: 9, color: lb)),
                        ])),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: Text(mHome,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isHomeWin
                                        ? FontWeight.w800
                                        : FontWeight.w400,
                                    color: isHomeWin
                                        ? (mHome == homeName
                                            ? homeColor
                                            : awayColor)
                                        : tx),
                                textAlign: TextAlign.right)),
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('$hs - $as_',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: hs == as_
                                      ? tx
                                      : (hs > as_
                                          ? homeColor
                                          : awayColor)),
                              textAlign: TextAlign.center),
                        ),
                        Expanded(
                            child: Text(mAway,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isAwayWin
                                        ? FontWeight.w800
                                        : FontWeight.w400,
                                    color: isAwayWin
                                        ? (mAway == homeName
                                            ? homeColor
                                            : awayColor)
                                        : tx))),
                      ]),
                    ])),
                    _buildH2HHeart(context, (2000 + i), m, isDark, lb),
                  ]),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _buildH2HHeart(BuildContext context, int matchId,
      Map<String, dynamic> m, bool isDark, Color lb) {
    return Builder(builder: (ctx) {
      final favSvc = ctx.read<FavoritesService>();
      final isFav = favSvc.isMatchFavorite(matchId);
      return GestureDetector(
        onTap: () {
          HapticService().lightImpact();
          favSvc.toggleMatchFavorite(matchId, status: 'FT');
          (ctx as Element).markNeedsBuild();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isFav
                ? tr(context, 'Rimossa dai preferiti')
                : tr(context, 'Aggiunta ai preferiti')),
            duration: const Duration(seconds: 1),
          ));
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFav
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            size: 16,
            color: isFav ? Colors.red : lb.withValues(alpha: 0.3),
          ),
        ),
      );
    });
  }

  List<Color> _teamGradient(String teamName) {
    const gradients = {
      'Roma': [Color(0xFFAD1A1A), Color(0xFFF5C518)],
      'Lazio': [Color(0xFF87CEEB), Color(0xFFFFFFFF)],
      'Inter': [Color(0xFF003DA5), Color(0xFF000000)],
      'Milan': [Color(0xFFE3001B), Color(0xFF000000)],
      'Juventus': [Color(0xFF000000), Color(0xFFFFFFFF)],
      'Napoli': [Color(0xFF009FE3), Color(0xFFFFFFFF)],
      'Atalanta': [Color(0xFF1A1A6C), Color(0xFF000000)],
      'Bologna': [Color(0xFFD32F2F), Color(0xFF1A2B6D)],
      'Fiorentina': [Color(0xFF6F2DA8), Color(0xFFFFFFFF)],
      'Torino': [Color(0xFF8B1A1A), Color(0xFFFFFFFF)],
      'Verona': [Color(0xFF003DA5), Color(0xFFFFD700)],
      'Monza': [Color(0xFFCE0120), Color(0xFFFFFFFF)],
    };
    return gradients[teamName] ??
        [const Color(0xFF1565C0), const Color(0xFFFFFFFF)];
  }

  List<Map<String, dynamic>> _getH2HMatches(String home, String away) {
    final rng = (home.hashCode ^ away.hashCode).abs();
    final scores = [
      [2, 1], [0, 0], [1, 3], [2, 2], [1, 0],
      [3, 1], [0, 1], [2, 0], [1, 1], [0, 2],
    ];
    final dates = [
      '10/03/23', '28/10/22', '15/05/22', '20/11/21', '03/04/21',
      '18/10/20', '25/01/20', '15/09/19', '02/03/19', '30/10/18',
    ];
    final comps = [
      'Serie A', 'Serie A', 'Serie A', 'Serie A', 'Serie A',
      'Serie A', 'Coppa Italia', 'Serie A', 'Serie A', 'Serie A',
    ];
    final matches = <Map<String, dynamic>>[];
    for (int i = 0; i < 10; i++) {
      final isHomeFirst = (rng + i) % 2 == 0;
      final s = scores[(rng + i) % scores.length];
      matches.add({
        'date': dates[i],
        'home': isHomeFirst ? home : away,
        'away': isHomeFirst ? away : home,
        'hScore': s[0],
        'aScore': s[1],
        'comp': comps[i],
      });
    }
    return matches;
  }
}
