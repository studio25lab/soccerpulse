// lib/widgets/tabs/standings_comparison_tab.dart
//
// Tab "Classifica" che mostra la classifica completa Serie A
// evidenziando le 2 squadre della partita corrente.
// Estratta da match_detail_screen.dart.
//
// I dati standings sono inline (mock). Loghi e colori squadra vengono
// risolti tramite callback passati dal padre (helper condivisi).
//
// // [FAV-standings-tab]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/l10n_helper.dart';
import '../../models/soccer_match.dart';

class StandingsComparisonTab extends StatelessWidget {
  final String homeName;
  final String awayName;

  /// Callback per ottenere il colore di una squadra
  final Color Function(String teamName) getTeamColor;

  /// Callback per ottenere l-URL del logo di una squadra
  final String Function(String teamName) getTeamLogoUrl;

  /// Callback chiamato quando si tappa il NOME/LOGO di una squadra
  /// per aprire la sua pagina dettaglio.
  final void Function(int teamId, String teamName, String? teamLogo) onTeamTap;

  /// Callback chiamato quando si tappa una riga della classifica
  /// per aprire la partita corrispondente.
  final void Function(SoccerMatch match) onMatchTap;

  const StandingsComparisonTab({
    Key? key,
    required this.homeName,
    required this.awayName,
    required this.getTeamColor,
    required this.getTeamLogoUrl,
    required this.onTeamTap,
    required this.onMatchTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _buildStandingsComparisonTab(context, theme, isDark);
  }

  Widget _buildStandingsComparisonTab(BuildContext context, ThemeData theme, bool isDark) {
    final bg = isDark ? Colors.grey[900]! : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);

    // Full Serie A standings
    final standings = [
      {'pos': 1, 'team': 'Inter', 'pts': 83, 'p': 35, 'w': 26, 'd': 5, 'l': 4, 'gf': 78, 'ga': 25, 'gd': '+53', 'form': 'WWDWW'},
      {'pos': 2, 'team': 'Milan', 'pts': 72, 'p': 35, 'w': 22, 'd': 6, 'l': 7, 'gf': 65, 'ga': 38, 'gd': '+27', 'form': 'WLWWD'},
      {'pos': 3, 'team': 'Juventus', 'pts': 68, 'p': 35, 'w': 20, 'd': 8, 'l': 7, 'gf': 55, 'ga': 30, 'gd': '+25', 'form': 'DDWWL'},
      {'pos': 4, 'team': 'Atalanta', 'pts': 65, 'p': 35, 'w': 19, 'd': 8, 'l': 8, 'gf': 64, 'ga': 38, 'gd': '+26', 'form': 'WWWLW'},
      {'pos': 5, 'team': 'Bologna', 'pts': 62, 'p': 35, 'w': 18, 'd': 8, 'l': 9, 'gf': 49, 'ga': 32, 'gd': '+17', 'form': 'DWWLD'},
      {'pos': 6, 'team': 'Roma', 'pts': 58, 'p': 35, 'w': 17, 'd': 7, 'l': 11, 'gf': 52, 'ga': 42, 'gd': '+10', 'form': 'WLDWL'},
      {'pos': 7, 'team': 'Lazio', 'pts': 55, 'p': 35, 'w': 16, 'd': 7, 'l': 12, 'gf': 48, 'ga': 38, 'gd': '+10', 'form': 'LWWDL'},
      {'pos': 8, 'team': 'Fiorentina', 'pts': 51, 'p': 35, 'w': 14, 'd': 9, 'l': 12, 'gf': 44, 'ga': 40, 'gd': '+4', 'form': 'DLWLW'},
      {'pos': 9, 'team': 'Torino', 'pts': 49, 'p': 35, 'w': 13, 'd': 10, 'l': 12, 'gf': 36, 'ga': 36, 'gd': '0', 'form': 'DDLWD'},
      {'pos': 10, 'team': 'Napoli', 'pts': 49, 'p': 35, 'w': 14, 'd': 7, 'l': 14, 'gf': 52, 'ga': 48, 'gd': '+4', 'form': 'LWDLW'},
      {'pos': 11, 'team': 'Monza', 'pts': 45, 'p': 35, 'w': 12, 'd': 9, 'l': 14, 'gf': 38, 'ga': 44, 'gd': '-6', 'form': 'DLLWD'},
      {'pos': 12, 'team': 'Genoa', 'pts': 42, 'p': 35, 'w': 11, 'd': 9, 'l': 15, 'gf': 35, 'ga': 42, 'gd': '-7', 'form': 'LDWDL'},
      {'pos': 13, 'team': 'Lecce', 'pts': 38, 'p': 35, 'w': 9, 'd': 11, 'l': 15, 'gf': 30, 'ga': 44, 'gd': '-14', 'form': 'DLDLL'},
      {'pos': 14, 'team': 'Verona', 'pts': 37, 'p': 35, 'w': 9, 'd': 10, 'l': 16, 'gf': 32, 'ga': 48, 'gd': '-16', 'form': 'LLWDL'},
      {'pos': 15, 'team': 'Udinese', 'pts': 36, 'p': 35, 'w': 9, 'd': 9, 'l': 17, 'gf': 34, 'ga': 50, 'gd': '-16', 'form': 'DLLDW'},
      {'pos': 16, 'team': 'Empoli', 'pts': 34, 'p': 35, 'w': 8, 'd': 10, 'l': 17, 'gf': 28, 'ga': 44, 'gd': '-16', 'form': 'LDDLL'},
      {'pos': 17, 'team': 'Cagliari', 'pts': 33, 'p': 35, 'w': 8, 'd': 9, 'l': 18, 'gf': 32, 'ga': 52, 'gd': '-20', 'form': 'LDLWL'},
      {'pos': 18, 'team': 'Frosinone', 'pts': 28, 'p': 35, 'w': 6, 'd': 10, 'l': 19, 'gf': 36, 'ga': 58, 'gd': '-22', 'form': 'LLLDD'},
      {'pos': 19, 'team': 'Sassuolo', 'pts': 22, 'p': 35, 'w': 4, 'd': 10, 'l': 21, 'gf': 28, 'ga': 64, 'gd': '-36', 'form': 'LLDLL'},
      {'pos': 20, 'team': 'Salernitana', 'pts': 16, 'p': 35, 'w': 3, 'd': 7, 'l': 25, 'gf': 22, 'ga': 68, 'gd': '-46', 'form': 'LLLLL'},
    ];

    return Container(
      color: bg,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        // Filters row (flat, like main standings)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            _standingsFilterChip(tr(context, 'Totale'), true, theme),
            const SizedBox(width: 6),
            _standingsFilterChip(tr(context, 'Casa'), false, theme),
            const SizedBox(width: 6),
            _standingsFilterChip(tr(context, 'Trasferta'), false, theme),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up_rounded, size: 14, color: theme.primaryColor),
                const SizedBox(width: 4),
                Text(tr(context, 'Rendimento'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor)),
              ]),
            ),
          ]),
        ),
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
            border: Border(left: BorderSide(width: 3, color: Colors.transparent), bottom: BorderSide(width: 0.5, color: divider)),
          ),
          child: Row(children: [
            SizedBox(width: 24, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 4, child: Text(tr(context, 'Squadra'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb))),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'G'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'V'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'P'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'S'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'GF'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 26, child: Text(standingsAbbr(context, 'GS'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 30, child: Text(standingsAbbr(context, 'DR'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb), textAlign: TextAlign.center)),
            SizedBox(width: 30, child: Text(standingsAbbr(context, 'Pt'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: theme.primaryColor), textAlign: TextAlign.center)),
            SizedBox(width: 80, child: Text(tr(context, 'Forma'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb), textAlign: TextAlign.center)),
          ]),
        ),
        // Rows
        Container(
          color: cardBg,
          child: Column(children: [
            ...standings.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final teamName = s['team'] as String;
              final isMatch = teamName == homeName || teamName == awayName;
              final teamColor = getTeamColor(teamName);
              final pos = s['pos'] as int;
              final isLast = i == standings.length - 1;

              // Zone colors
              Color? zoneBg;
              Color? zoneBar;
              if (pos <= 4) { zoneBar = const Color(0xFF4CAF50); }
              else if (pos == 5 || pos == 6) { zoneBar = const Color(0xFF2196F3); }
              else if (pos == 7) { zoneBar = const Color(0xFFFFA726); }
              else if (pos >= 18) { zoneBar = const Color(0xFFE53935); }

              final abbr = teamName.length > 3 ? teamName.substring(0, 3).toUpperCase() : teamName.toUpperCase();

              return GestureDetector(
                onTap: () => onTeamTap(0, teamName, null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: isMatch ? (teamColor.withOpacity(isDark ? 0.15 : 0.08)) : null,
                    border: Border(
                      left: BorderSide(width: 3, color: zoneBar ?? Colors.transparent),
                      bottom: isLast ? BorderSide.none : BorderSide(width: 0.5, color: divider),
                    ),
                    borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : null,
                  ),
                  child: Row(children: [
                    // Position
                    SizedBox(width: 24, child: Center(child: Text('$pos', style: TextStyle(fontSize: 13, fontWeight: isMatch ? FontWeight.w900 : FontWeight.w600, color: tx)))),
                    const SizedBox(width: 8),
                    // Team logo
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: getTeamLogoUrl(teamName),
                        width: 24, height: 24,
                        errorWidget: (_, __, ___) => Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: teamColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: Text(abbr, style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: teamColor))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 4, child: Text(teamName,
                        style: TextStyle(fontSize: 13, fontWeight: isMatch ? FontWeight.w800 : FontWeight.w500, color: isMatch ? teamColor : tx),
                        overflow: TextOverflow.ellipsis)),
                    SizedBox(width: 26, child: Text('${s['p']}', style: TextStyle(fontSize: 11, color: lb), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['w']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['d'] ?? s['dd'] ?? 0}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['l']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['gf']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 26, child: Text('${s['ga']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: tx), textAlign: TextAlign.center)),
                    SizedBox(width: 30, child: Text('${s['gd']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: lb), textAlign: TextAlign.center)),
                    SizedBox(width: 30, child: Text('${s['pts']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: theme.primaryColor), textAlign: TextAlign.center)),
                    SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      for (int fi = 0; fi < (s['form'] as String? ?? 'DDDDD').split('').length; fi++) ...[
                        Builder(builder: (ctx) {
                          final f = (s['form'] as String? ?? 'DDDDD').split('')[fi];
                          final c = f == 'W' ? const Color(0xFF4CAF50) : f == 'D' ? const Color(0xFFF9A825) : const Color(0xFFE53935);
                          final label = f == 'W' ? 'V' : f == 'D' ? 'P' : 'S';
                          final resultText = f == 'W' ? 'Vittoria' : f == 'D' ? 'Pareggio' : 'Sconfitta';
                          return Tooltip(
                            message: '$resultText\nGiornata ${35 - fi}',
                            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Container(
                              width: 14, height: 14, margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                              child: Center(child: Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Colors.white))),
                            ),
                          );
                        }),
                      ],
                    ])),
                  ]),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 12),
        // Legend
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: divider)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr(context, 'Regolamento'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
            const SizedBox(height: 10),
            _legendItem(const Color(0xFF4CAF50), 'Champions League'),
            const SizedBox(height: 6),
            _legendItem(const Color(0xFF2196F3), 'UEFA Europa League'),
            const SizedBox(height: 6),
            _legendItem(const Color(0xFFFFA726), 'Conference League Qualification'),
            const SizedBox(height: 6),
            _legendItem(const Color(0xFFE53935), tr(context, 'Retrocessione')),
            const SizedBox(height: 14),
            Divider(height: 1, color: divider),
            const SizedBox(height: 10),
            Wrap(spacing: 16, runSpacing: 6, children: [
              _legendAbbr('G', tr(context, 'Partite giocate'), lb),
              _legendAbbr('V', tr(context, 'Vittorie'), lb),
              _legendAbbr('P', tr(context, 'Pareggi'), lb),
              _legendAbbr('S', tr(context, 'Sconfitte'), lb),
              _legendAbbr('GF', tr(context, 'Gol fatti'), lb),
              _legendAbbr('GS', tr(context, 'Gol subiti'), lb),
              _legendAbbr('DR', tr(context, 'Differenza reti'), lb),
              _legendAbbr(standingsAbbr(context, 'Pt'), tr(context, 'Punti'), lb),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _standingsFilterChip(String label, bool active, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: active ? theme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? theme.primaryColor : Colors.grey.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: active ? Colors.white : Colors.grey[500],
      )),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
    ]);
  }

  Widget _legendAbbr(String abbr, String label, Color lb) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(abbr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: lb)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    ]);
  }
}
