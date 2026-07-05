// lib/widgets/standings_list_view.dart
//
// Classifica condivisa: usata nella pagina Classifica, nei match programmati e
// nei match live/finiti. Riceve la lista TeamStanding gia' caricata (il
// caricamento resta nei genitori) e mostra tabella + filtri Totale/Casa/Trasferta
// + Rendimento. Parametro opzionale highlightTeams per evidenziare squadre.
//
// [FAV-standings-unified]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../utils/l10n_helper.dart';
import '../models/team_standing.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../generated/l10n.dart';
import '../pages/team_detail_screen.dart';
import '../widgets/dialogs/rendimento_dialog.dart';

class StandingsListView extends StatefulWidget {
  /// Classifica gia' caricata.
  final List<TeamStanding> standings;

  /// Nomi squadre da evidenziare (es. le due del match). Vuoto = nessuna.
  final List<String> highlightTeams;

  /// Se true mostra la legenda/regolamento in fondo (default true).
  final bool showLegend;

  const StandingsListView({
    super.key,
    required this.standings,
    this.highlightTeams = const [],
    this.showLegend = true,
  });

  @override
  State<StandingsListView> createState() => _StandingsListViewState();
}

class _StandingsListViewState extends State<StandingsListView> {
  final HapticService _haptic = HapticService();
  int _filterIndex = 0; // 0=Totale, 1=Casa, 2=Trasferta

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final favoritesService = context.watch<FavoritesService>();
    final divider =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1);

    final standings = widget.standings;
    if (standings.isEmpty) {
      return Center(
          child: Text(S.of(context)!.nessunDato, style: TextStyle(color: lb)));
    }

    return Column(children: [
      // Filtro Casa/Trasferta + Rendimento
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        child: Row(children: [
          ...List.generate(
              3,
              (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        _haptic.lightImpact();
                        setState(() => _filterIndex = i);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _filterIndex == i
                              ? theme.primaryColor
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.grey.withValues(alpha: 0.08)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            [
                              S.of(context)!.totale,
                              S.of(context)!.casa,
                              S.of(context)!.trasferta
                            ][i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _filterIndex == i ? Colors.white : lb,
                            )),
                      ),
                    ),
                  )),
          GestureDetector(
            onTap: () {
              _haptic.lightImpact();
              showRendimento(context, theme, isDark, tx, lb,
                  highlightTeams: widget.highlightTeams);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up_rounded,
                    size: 14, color: theme.primaryColor),
                const SizedBox(width: 4),
                Text(S.of(context)!.rendimento,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor)),
              ]),
            ),
          ),
          const Spacer(),
        ]),
      ),
      // Header tabella
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.grey.withValues(alpha: 0.05),
          border: const Border(
              left: BorderSide(width: 3, color: Colors.transparent)),
        ),
        child: Row(children: [
          SizedBox(
              width: 24,
              child: Center(
                  child: Text("#",
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: lb)))),
          const SizedBox(width: 4),
          Expanded(
              child: Text(S.of(context)!.squadra,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: lb))),
          _hdr(standingsAbbr(context, "G"), lb),
          _hdr(standingsAbbr(context, "V"), lb),
          _hdr(standingsAbbr(context, "P"), lb),
          _hdr(standingsAbbr(context, "S"), lb),
          _hdr(standingsAbbr(context, "GF"), lb),
          _hdr(standingsAbbr(context, "GS"), lb),
          SizedBox(
              width: 34,
              child: Center(
                  child: Text(standingsAbbr(context, "DR"),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: lb)))),
          SizedBox(
              width: 32,
              child: Center(
                  child: Text(standingsAbbr(context, "Pt"),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryColor)))),
          const SizedBox(width: 4),
          SizedBox(
              width: 90,
              child: Center(
                  child: Text(tr(context, "Forma"),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: lb)))),
        ]),
      ),
      // Righe
      Expanded(
        child: Builder(builder: (ctx) {
          final sorted = List<TeamStanding>.from(standings);
          if (_filterIndex != 0) {
            sorted.sort((a, b) {
              final aPts = _filterIndex == 1
                  ? (a.home.win * 3 + a.home.draw)
                  : (a.away.win * 3 + a.away.draw);
              final bPts = _filterIndex == 1
                  ? (b.home.win * 3 + b.home.draw)
                  : (b.away.win * 3 + b.away.draw);
              if (bPts != aPts) return bPts.compareTo(aPts);
              final aDR = _filterIndex == 1
                  ? (a.home.goalsFor - a.home.goalsAgainst)
                  : (a.away.goalsFor - a.away.goalsAgainst);
              final bDR = _filterIndex == 1
                  ? (b.home.goalsFor - b.home.goalsAgainst)
                  : (b.away.goalsFor - b.away.goalsAgainst);
              return bDR.compareTo(aDR);
            });
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: sorted.length + (widget.showLegend ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (widget.showLegend && i == sorted.length) {
                return _buildLegend(isDark, tx, lb, divider);
              }
              final t = sorted[i];
              final posColor = _posColor(i + 1);
              final isFav = favoritesService.isTeamFavorite(t.teamId);
              final isHighlight = widget.highlightTeams.any((h) =>
                  h == t.teamName ||
                  t.teamName.contains(h) ||
                  h.contains(t.teamName));
              final form = (t.form ?? 'WDLWW').split('').take(5).toList();
              final fPlayed = _filterIndex == 1
                  ? t.home.played
                  : _filterIndex == 2
                      ? t.away.played
                      : t.played;
              final fWins = _filterIndex == 1
                  ? t.home.win
                  : _filterIndex == 2
                      ? t.away.win
                      : t.wins;
              final fDraws = _filterIndex == 1
                  ? t.home.draw
                  : _filterIndex == 2
                      ? t.away.draw
                      : t.draws;
              final fLosses = _filterIndex == 1
                  ? t.home.lose
                  : _filterIndex == 2
                      ? t.away.lose
                      : t.losses;
              final fGF = _filterIndex == 1
                  ? t.home.goalsFor
                  : _filterIndex == 2
                      ? t.away.goalsFor
                      : t.goalsFor;
              final fGA = _filterIndex == 1
                  ? t.home.goalsAgainst
                  : _filterIndex == 2
                      ? t.away.goalsAgainst
                      : t.goalsAgainst;
              final fDR = fGF - fGA;
              final fPts = fWins * 3 + fDraws;

              // Background: highlight (squadra del match) ha priorita', poi preferito
              Color? rowBg;
              if (isHighlight) {
                rowBg = theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.13);
              } else if (isFav) {
                rowBg = isDark
                    ? Colors.amber.withValues(alpha: 0.04)
                    : Colors.amber.withValues(alpha: 0.03);
              }

              // Bordo sinistro: spesso e colorato per le squadre del match.
              final leftBorder = isHighlight
                  ? BorderSide(width: 5, color: theme.primaryColor)
                  : BorderSide(width: 3, color: posColor);

              return InkWell(
                onTap: () {
                  _haptic.lightImpact();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              TeamDetailScreen(teamStanding: t)));
                },
                onLongPress: () {
                  _haptic.lightImpact();
                  favoritesService.toggleTeamFavorite(t.teamId);
                  setState(() {});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: rowBg,
                    border: Border(
                      left: leftBorder,
                      bottom: BorderSide(width: 0.5, color: divider),
                    ),
                  ),
                  child: Row(children: [
                    SizedBox(
                        width: 24,
                        child: Center(
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: posColor)),
                        )),
                    const SizedBox(width: 8),
                    if (t.teamLogo != null)
                      CachedNetworkImage(
                          imageUrl: t.teamLogo!,
                          width: 28,
                          height: 28,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.shield, size: 28))
                    else
                      const Icon(Icons.shield, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(children: [
                        Flexible(
                            child: Text(t.teamName,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isHighlight
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: tx),
                                overflow: TextOverflow.ellipsis)),
                        if (isFav) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.favorite,
                              size: 12, color: Colors.red),
                        ],
                      ]),
                    ),
                    _cell('$fPlayed', tx),
                    _cell('$fWins', tx),
                    _cell('$fDraws', tx),
                    _cell('$fLosses', tx),
                    _cell('$fGF', tx),
                    _cell('$fGA', tx),
                    SizedBox(
                        width: 34,
                        child: Center(
                            child: Text(
                          '${fDR > 0 ? '+' : ''}$fDR',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: fDR > 0
                                  ? Colors.green
                                  : fDR < 0
                                      ? Colors.red
                                      : lb),
                        ))),
                    SizedBox(
                        width: 32,
                        child: Center(
                            child: Text(
                          '$fPts',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: tx),
                        ))),
                    const SizedBox(width: 4),
                    SizedBox(
                        width: 90,
                        child: Row(
                            children: form.asMap().entries.map((entry) {
                          final fi = entry.key;
                          final c = entry.value;
                          Color fc;
                          String fl;
                          if (c == 'W') {
                            fc = Colors.green;
                            fl = formInitial(context, 'W');
                          } else if (c == 'D') {
                            fc = Colors.orange;
                            fl = formInitial(context, 'D');
                          } else {
                            fc = Colors.red;
                            fl = formInitial(context, 'L');
                          }
                          final resultText = c == 'W'
                              ? 'Vittoria'
                              : c == 'D'
                                  ? 'Pareggio'
                                  : 'Sconfitta';
                          return Tooltip(
                            message:
                                '$resultText\nGiornata ${t.played - fi}',
                            decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(
                                color: Colors.white, fontSize: 11),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                  color: fc,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Center(
                                  child: Text(fl,
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white))),
                            ),
                          );
                        }).toList())),
                  ]),
                ),
              );
            },
          );
        }),
      ),
    ]);
  }

  Widget _buildLegend(bool isDark, Color tx, Color lb, Color divider) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: divider),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Regolamento',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
        const SizedBox(height: 10),
        _legendRow(const Color(0xFF4CAF50), 'Champions League'),
        const SizedBox(height: 6),
        _legendRow(const Color(0xFF2196F3), 'UEFA Europa League'),
        const SizedBox(height: 6),
        _legendRow(const Color(0xFFFFA726), 'Conference League Qualification'),
        const SizedBox(height: 6),
        _legendRow(const Color(0xFFE53935), 'Retrocessione'),
        const SizedBox(height: 12),
        Divider(height: 1, color: divider),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 6, children: [
          _legendAbbr2(standingsAbbr(context, 'G'), tr(context, 'Partite giocate'), lb),
          _legendAbbr2(standingsAbbr(context, 'V'), tr(context, 'Vittorie'), lb),
          _legendAbbr2(standingsAbbr(context, 'P'), tr(context, 'Pareggi'), lb),
          _legendAbbr2(standingsAbbr(context, 'S'), tr(context, 'Sconfitte'), lb),
          _legendAbbr2(standingsAbbr(context, 'GF'), tr(context, 'Gol fatti'), lb),
          _legendAbbr2(standingsAbbr(context, 'GS'), tr(context, 'Gol subiti'), lb),
          _legendAbbr2(standingsAbbr(context, 'DR'), tr(context, 'Differenza reti'), lb),
          _legendAbbr2(standingsAbbr(context, 'Pt'), tr(context, 'Punti'), lb),
        ]),
      ]),
    );
  }

  Widget _hdr(String t, Color lb) => SizedBox(
      width: 28,
      child: Center(
          child: Text(t,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: lb))));

  Widget _cell(String t, Color tx) => SizedBox(
      width: 28,
      child: Center(
          child: Text(t,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500, color: tx))));

  Color _posColor(int pos) {
    if (pos <= 4) return const Color(0xFF4CAF50);
    if (pos == 5 || pos == 6) return const Color(0xFF2196F3);
    if (pos == 7) return const Color(0xFFFFA726);
    if (pos >= 18) return const Color(0xFFE53935);
    return Colors.grey;
  }

  Widget _legendRow(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
    ]);
  }

  Widget _legendAbbr2(String abbr, String label, Color lb) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(abbr,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: lb)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    ]);
  }
}
