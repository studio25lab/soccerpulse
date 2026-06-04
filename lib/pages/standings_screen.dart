// lib/pages/standings_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/team_standing.dart';
import '../models/soccer_match.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../generated/l10n.dart';
import 'team_detail_screen.dart';
import 'settings_screen.dart';
import '../main.dart';
import 'match_detail_screen.dart';
import 'match_player_profile_screen.dart'; // [FAV-extract4]
import 'package:soccerpulse/models/local_match_models.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({Key? key}) : super(key: key);
  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  late TabController _tabController;
  late FavoritesService _favoritesService;

  Future<List<TeamStanding>>? _standingsFuture;
  int _filterIndex = 0; // 0=Totale, 1=Casa, 2=Trasferta

  // Filter labels are now localized in build

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _favoritesService = context.read<FavoritesService>();
    _loadStandings();
    // Check if navigated from search with specific sub-tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MainScreen.pendingStandingsTab != null) {
        _tabController.animateTo(MainScreen.pendingStandingsTab!);
        MainScreen.pendingStandingsTab = null;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStandings() {
    setState(() {
      _standingsFuture = _apiService.fetchStandings(135);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Row(children: [
          Image.network('https://media.api-sports.io/football/leagues/135.png',
              width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events, size: 28)),
          const SizedBox(width: 10),
          const Text('Serie A'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('2023/24', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ]),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : theme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _haptic.lightImpact(); _loadStandings(); },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: isDark ? const Color(0xFF1A1A2E) : theme.primaryColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: tr(context, 'Classifica')),
                Tab(text: S.of(context)!.marcatori),
                Tab(text: S.of(context)!.assistman),
                Tab(text: S.of(context)!.gPlusA),
                Tab(text: S.of(context)!.cleanSheetTab),
                Tab(text: S.of(context)!.cartelliniTab),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClassificaTab(theme, isDark, tx, lb, cardBg),
          _buildPlayerRankingTab('goals', theme, isDark, tx, lb, cardBg),
          _buildPlayerRankingTab('assists', theme, isDark, tx, lb, cardBg),
          _buildPlayerRankingTab('ga', theme, isDark, tx, lb, cardBg),
          _buildPlayerRankingTab('cleanSheet', theme, isDark, tx, lb, cardBg),
          _buildPlayerRankingTab('cards', theme, isDark, tx, lb, cardBg),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB CLASSIFICA
  // ═══════════════════════════════════════════════════════════
  Widget _buildClassificaTab(ThemeData theme, bool isDark, Color tx, Color lb, Color cardBg) {
    return FutureBuilder<List<TeamStanding>>(
      future: _standingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Errore: ${snapshot.error}', style: TextStyle(color: lb)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadStandings, child: const Text('Riprova')),
          ]));
        }

        final standings = snapshot.data ?? [];
        if (standings.isEmpty) return Center(child: Text(S.of(context)!.nessunDato, style: TextStyle(color: lb)));

        final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);

        return Column(children: [
          // Filtro Casa/Trasferta
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            child: Row(children: [
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () { _haptic.lightImpact(); setState(() => _filterIndex = i); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _filterIndex == i
                          ? theme.primaryColor
                          : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text([S.of(context)!.totale, S.of(context)!.casa, S.of(context)!.trasferta][i], style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: _filterIndex == i ? Colors.white : lb,
                    )),
                  ),
                ),
              )),
              GestureDetector(
                onTap: () { _haptic.lightImpact(); _showRendimento(theme, isDark, tx, lb); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.trending_up_rounded, size: 14, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text(S.of(context)!.rendimento, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.primaryColor)),
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
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
              border: const Border(left: BorderSide(width: 3, color: Colors.transparent)),
            ),
            child: Row(children: [
              SizedBox(width: 24, child: Center(child: Text("#", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb)))),
              const SizedBox(width: 4),
              const SizedBox(width: 0),
              const SizedBox(width: 0),
              Expanded(child: Text(S.of(context)!.squadra, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb))),
              _hdr(standingsAbbr(context, "G"), lb), _hdr(standingsAbbr(context, "V"), lb), _hdr(standingsAbbr(context, "P"), lb), _hdr(standingsAbbr(context, "S"), lb), _hdr(standingsAbbr(context, "GF"), lb), _hdr(standingsAbbr(context, "GS"), lb),
              SizedBox(width: 34, child: Center(child: Text(standingsAbbr(context, "DR"), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb)))),
              SizedBox(width: 32, child: Center(child: Text(standingsAbbr(context, "Pt"), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryColor)))),
              const SizedBox(width: 4),
              SizedBox(width: 90, child: Center(child: Text(tr(context, "Forma"), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb)))),
            ]),
          ),
          // Righe
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async { _loadStandings(); await _standingsFuture; },
              child: Builder(builder: (ctx) {
                // Ordina per punti filtrati
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
                itemCount: sorted.length + 1, // +1 for legend footer
                itemBuilder: (ctx, i) {
                  // Legend footer
                  if (i == sorted.length) {
                    return Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E2A) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: divider),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Regolamento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
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
                  final t = sorted[i];
                  final posColor = _posColor(i + 1);
                  final isFav = _favoritesService.isTeamFavorite(t.teamId);
                  final form = (t.form ?? 'WDLWW').split('').take(5).toList();
                  // Stats filtrate
                  final fPlayed = _filterIndex == 1 ? t.home.played : _filterIndex == 2 ? t.away.played : t.played;
                  final fWins = _filterIndex == 1 ? t.home.win : _filterIndex == 2 ? t.away.win : t.wins;
                  final fDraws = _filterIndex == 1 ? t.home.draw : _filterIndex == 2 ? t.away.draw : t.draws;
                  final fLosses = _filterIndex == 1 ? t.home.lose : _filterIndex == 2 ? t.away.lose : t.losses;
                  final fGF = _filterIndex == 1 ? t.home.goalsFor : _filterIndex == 2 ? t.away.goalsFor : t.goalsFor;
                  final fGA = _filterIndex == 1 ? t.home.goalsAgainst : _filterIndex == 2 ? t.away.goalsAgainst : t.goalsAgainst;
                  final fDR = fGF - fGA;
                  final fPts = fWins * 3 + fDraws;

                  return InkWell(
                    onTap: () {
                      _haptic.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(teamStanding: t)));
                    },
                    onLongPress: () {
                      _haptic.lightImpact();
                      _favoritesService.toggleTeamFavorite(t.teamId);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: isFav ? (isDark ? Colors.amber.withOpacity(0.04) : Colors.amber.withOpacity(0.03)) : null,
                        border: Border(
                          left: BorderSide(width: 3, color: posColor),
                          bottom: BorderSide(width: 0.5, color: divider),
                        ),
                      ),
                      child: Row(children: [
                        SizedBox(width: 24, child: Center(
                          child: Text('${i + 1}', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: posColor)),
                        )),
                        const SizedBox(width: 8),
                        if (t.teamLogo != null)
                          CachedNetworkImage(imageUrl: t.teamLogo!, width: 28, height: 28,
                              errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 28))
                        else
                          const Icon(Icons.shield, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(children: [
                            Flexible(child: Text(t.teamName, style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: tx),
                                overflow: TextOverflow.ellipsis)),
                            if (isFav) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.favorite, size: 12, color: Colors.red),
                            ],
                          ]),
                        ),
                        _cell('$fPlayed', tx), _cell('$fWins', tx),
                        _cell('$fDraws', tx), _cell('$fLosses', tx), _cell('$fGF', tx), _cell('$fGA', tx),
                        SizedBox(width: 34, child: Center(child: Text(
                          '${fDR > 0 ? '+' : ''}$fDR',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: fDR > 0 ? Colors.green : fDR < 0 ? Colors.red : lb),
                        ))),
                        SizedBox(width: 32, child: Center(child: Text(
                          '$fPts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx),
                        ))),
                        const SizedBox(width: 4),
                        // Forma recente
                        SizedBox(width: 90, child: Row(children: form.asMap().entries.map((entry) {
                          final fi = entry.key;
                          final c = entry.value;
                          Color fc; String fl;
                          if (c == 'W') { fc = Colors.green; fl = formInitial(context, 'W'); }
                          else if (c == 'D') { fc = Colors.orange; fl = formInitial(context, 'D'); }
                          else { fc = Colors.red; fl = formInitial(context, 'L'); }
                          final resultText = c == 'W' ? 'Vittoria' : c == 'D' ? 'Pareggio' : 'Sconfitta';
                          return Tooltip(
                            message: '$resultText\nGiornata ${t.played - fi}',
                            decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
                            textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Container(
                              width: 16, height: 16, margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(color: fc, borderRadius: BorderRadius.circular(4)),
                              child: Center(child: Text(fl, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white))),
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
          ),
        ]);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  void _showRendimento(ThemeData theme, bool isDark, Color tx, Color lb) {
    final int currentMatchday = 38; // TODO: da API
    // [FAV-rangeslider] range invece di singola giornata
    RangeValues selectedRange = RangeValues(1, currentMatchday.toDouble());
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);

    // ── Dati reali Serie A 2023/24 — punti finali + risultati per giornata ──
    // Ogni squadra ha: nome, logo, punti finali, wins, draws, losses
    // I risultati giornata per giornata sono generati realisticamente
    // con la regola: V=3, P=1, S=0, coerenti con i totali finali
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

    // Genera risultati giornata per giornata per ogni squadra
    // Distribuisce W/D/L realisticamente su 38 giornate
    // [FAV-rangeslider] ora ritorna anche perMatch (punti per
    // singola giornata, 3/1/0) per supportare il filtro a range.
    Map<String, Map<String, List<int>>> _generateResults() {
      final results = <String, Map<String, List<int>>>{};
      for (final td in teamsData) {
        final team = td['team'] as String;
        int w = td['w'] as int;
        int d = td['d'] as int;
        int l = td['l'] as int;

        final matchResults = <int>[];
        for (int i = 0; i < w; i++) matchResults.add(3);
        for (int i = 0; i < d; i++) matchResults.add(1);
        for (int i = 0; i < l; i++) matchResults.add(0);

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

    final allResults = _generateResults();

    // [FAV-rangeslider] resta per compatibilita interna ma non usata
    // direttamente dall-UI (la modale ora usa getRankingForRange).
    // ignore: unused_element
    List<Map<String, dynamic>> getRankingForMatchday(int md) {
      final ranking = <Map<String, dynamic>>[];
      for (final td in teamsData) {
        final team = td['team'] as String;
        final pts = allResults[team]!['cumulative']![md - 1];
        ranking.add({
          'team': team,
          'logo': td['logo'],
          'pts': pts,
          'played': md,
        });
      }
      ranking.sort((a, b) {
        final cmp = (b['pts'] as int).compareTo(a['pts'] as int);
        if (cmp != 0) return cmp;
        return (a['team'] as String).compareTo(b['team'] as String);
      });
      return ranking;
    }

    // [FAV-rangeslider] Ranking per range di giornate [start, end].
    // I punti partono da zero: somma SOLO i match nel range.
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

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final startMd = selectedRange.start.round();
          final endMd = selectedRange.end.round();
          final ranking = getRankingForRange(startMd, endMd);
          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
                Icon(Icons.trending_up_rounded, size: 22, color: theme.primaryColor),
                SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(S.of(context)!.rendimentoSerieA, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                  Text('${tr(context, "Classifica giornate")} $startMd–$endMd', style: TextStyle(fontSize: 12, color: lb)),
                ]),
              ])),
              // [FAV-rangeslider] RangeSlider con due manopole
              Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [
                Text(tr(context, 'Giornata 1'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb)),
                Expanded(child: SliderTheme(
                  data: SliderThemeData(activeTrackColor: theme.primaryColor, inactiveTrackColor: isDark ? Colors.white12 : Colors.grey[200],
                      thumbColor: theme.primaryColor, rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 8), trackHeight: 4),
                  child: RangeSlider(
                      values: selectedRange,
                      min: 1,
                      max: currentMatchday.toDouble(),
                      divisions: (currentMatchday - 1).clamp(1, 37),
                      onChanged: (val) {
                        _haptic.lightImpact();
                        setSheetState(() {
                          selectedRange = RangeValues(
                            val.start.roundToDouble(),
                            val.end.roundToDouble(),
                          );
                        });
                      }),
                )),
                Text('${tr(context, 'Giornata')} $currentMatchday', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb)),
              ])),
              // Badge giornata
              Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text('${tr(context, 'Giornate')} $startMd–$endMd', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: theme.primaryColor)),
                  ])),
              const SizedBox(height: 8),
              // Header colonne
              Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6), child: Row(children: [
                const SizedBox(width: 28),
                const SizedBox(width: 10),
                const SizedBox(width: 28),
                const SizedBox(width: 10),
                Expanded(child: Text(S.of(context)!.squadra, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: lb))),
                SizedBox(width: 34, child: Center(child: Text(standingsAbbr(context, 'G'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: lb)))),
                SizedBox(width: 16),
                SizedBox(width: 48, child: Center(child: Text(tr(context, 'Punti'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.primaryColor)))),
              ])),
              Divider(height: 1, color: divider),
              // Lista
              Expanded(child: ListView.builder(
                physics: const BouncingScrollPhysics(), padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: ranking.length, itemBuilder: (ctx, i) {
                  final r = ranking[i]; final isTop3 = i < 3; final posColor = _posColor(i + 1);
                  final isRetro = i >= 17;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isTop3 ? posColor.withOpacity(isDark ? 0.06 : 0.03)
                          : isRetro ? Colors.red.withOpacity(isDark ? 0.04 : 0.02) : null,
                      border: Border(
                        left: BorderSide(width: 3, color: posColor),
                        bottom: BorderSide(width: 0.5, color: divider))),
                    child: Row(children: [
                      SizedBox(width: 28, child: Center(child: isTop3
                          ? Container(width: 24, height: 24, alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i == 0 ? const Color(0xFFFFD700) : i == 1 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
                                shape: BoxShape.circle),
                              child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)))
                          : Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: posColor)))),
                      const SizedBox(width: 10),
                      CachedNetworkImage(imageUrl: r['logo'] as String, width: 28, height: 28,
                          errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 28)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(r['team'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx))),
                      SizedBox(width: 34, child: Center(child: Text('${r['played']}', style: TextStyle(fontSize: 12, color: lb)))),
                      const SizedBox(width: 16),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: posColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                          child: Text('${r['pts']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: posColor))),
                    ]),
                  );
                },
              )),
            ]),
          );
        },
      ),
    );
  }

  Widget _buildPlayerRankingTab(String type, ThemeData theme, bool isDark, Color tx, Color lb, Color cardBg) {
    final players = _getPlayerRanking(type);
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);

    String title;
    String statLabel;
    IconData statIcon;
    Color accentColor;
    switch (type) {
      case 'goals': title = S.of(context)!.classificaMarcatori; statLabel = S.of(context)!.gol; statIcon = Icons.sports_soccer; accentColor = const Color(0xFF4CAF50); break;
      case 'assists': title = S.of(context)!.classificaAssistman; statLabel = S.of(context)!.assistNotif; statIcon = Icons.assistant_rounded; accentColor = Color(0xFF2196F3); break;
      case 'ga': title = 'Gol + Assist'; statLabel = 'G+A'; statIcon = Icons.star_rounded; accentColor = Color(0xFFFFA726); break;
      case 'cleanSheet': title = 'Clean Sheet'; statLabel = 'CS'; statIcon = Icons.shield_rounded; accentColor = Color(0xFF7E57C2); break;
      default: title = tr(context, 'Cartellini'); statLabel = 'Cart.'; statIcon = Icons.style_rounded; accentColor = Color(0xFFE53935); break;
    }

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        child: Row(children: [
          Icon(statIcon, size: 18, color: accentColor),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tx)),
          const Spacer(),
          Text('Serie A 2023/24', style: TextStyle(fontSize: 11, color: lb)),
        ]),
      ),
      // Colonne header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.withOpacity(0.05),
        child: Row(children: [
          SizedBox(width: 28, child: Center(child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb)))),
          SizedBox(width: 48), // foto
          SizedBox(width: 10),
          Expanded(child: Text(tr(context, 'Giocatore'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb))),
          if (type == 'cards') ...[
            SizedBox(width: 36, child: Center(child: Container(width: 10, height: 14,
                decoration: BoxDecoration(color: const Color(0xFFFFCA28), borderRadius: BorderRadius.circular(2))))),
            SizedBox(width: 36, child: Center(child: Container(width: 10, height: 14,
                decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(2))))),
          ] else if (type == 'ga') ...[
            SizedBox(width: 32, child: Center(child: Text(tr(context, 'Gol'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb)))),
            SizedBox(width: 32, child: Center(child: Text(tr(context, 'Ass'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb)))),
            SizedBox(width: 34, child: Center(child: Text(tr(context, 'G+A'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accentColor)))),
          ] else ...[
            SizedBox(width: 34, child: Center(child: Text(tr(context, 'Pres.'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb)))),
            SizedBox(width: 40, child: Center(child: Text(statLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accentColor)))),
          ],
        ]),
      ),
      // Lista
      Expanded(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: players.length,
          itemBuilder: (ctx, i) {
            final p = players[i];
            final isTop3 = i < 3;
            return InkWell(
              onTap: () {
                _haptic.lightImpact();
                _openPlayerProfile(p);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isTop3 ? accentColor.withOpacity(isDark ? 0.06 : 0.03) : null,
                  border: Border(bottom: BorderSide(width: 0.5, color: divider)),
                ),
                child: Row(children: [
                // Posizione
                SizedBox(width: 28, child: Center(
                  child: isTop3
                      ? Container(
                          width: 24, height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: i == 0 ? const Color(0xFFFFD700) : i == 1 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
                            shape: BoxShape.circle,
                          ),
                          child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                        )
                      : Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: lb)),
                )),
                const SizedBox(width: 8),
                // Foto
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: p['photo'] as String? ?? '',
                    width: 36, height: 36, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withOpacity(0.15)),
                      child: Icon(Icons.person, size: 20, color: lb),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Nome + squadra
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name'] as String, style: TextStyle(
                        fontSize: 13, fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w600, color: tx),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(children: [
                      if (p['teamLogo'] != null)
                        CachedNetworkImage(imageUrl: p['teamLogo'] as String, width: 14, height: 14,
                            errorWidget: (_, __, ___) => const SizedBox()),
                      const SizedBox(width: 4),
                      Text(p['team'] as String, style: TextStyle(fontSize: 11, color: lb)),
                    ]),
                  ]),
                ),
                // Stats
                if (type == 'cards') ...[
                  SizedBox(width: 34, child: Center(child: Text('${p['yellow']}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx)))),
                  SizedBox(width: 34, child: Center(child: Text('${p['red']}',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                          color: (p['red'] as int) > 0 ? Colors.red : tx)))),
                ] else if (type == 'ga') ...[
                  SizedBox(width: 32, child: Center(child: Text('${p['goals']}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)))),
                  SizedBox(width: 32, child: Center(child: Text('${p['assists']}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)))),
                  SizedBox(width: 34, child: Center(child: Text('${p['ga']}',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: accentColor)))),
                ] else ...[
                  SizedBox(width: 34, child: Center(child: Text('${p['appearances']}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: lb)))),
                  SizedBox(width: 40, child: Center(child: Text('${p['stat']}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: accentColor)))),
                ],
              ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  void _openPlayerProfile(Map<String, dynamic> p) {
    final name = p['name'] as String;
    final team = p['team'] as String;
    String pos = 'F';
    if (_tabController.index == 4) pos = 'G';
    final llp = LocalLineupPlayer(
      number: name.hashCode.abs() % 99 + 1,
      name: name,
      position: pos,
      rating: 7.0,
      goals: (p['goals'] as int?) ?? (p['stat'] as int?) ?? 0,
      assists: (p['assists'] as int?) ?? 0,
      yellowCards: (p['yellow'] as int?) ?? 0,
      redCards: (p['red'] as int?) ?? 0,
      minutesPlayed: ((p['appearances'] as int?) ?? 30) * 78,
    );
    Color teamColor;
    switch (team) {
      case 'Inter': teamColor = const Color(0xFF0068A8); break;
      case 'Milan': teamColor = const Color(0xFFE5193E); break;
      case 'Juventus': teamColor = const Color(0xFF000000); break;
      case 'Napoli': teamColor = const Color(0xFF004B87); break;
      case 'Lazio': teamColor = const Color(0xFF87CEEB); break;
      case 'Roma': teamColor = const Color(0xFFAA1E22); break;
      case 'Atalanta': teamColor = const Color(0xFF1B3B6F); break;
      case 'Fiorentina': teamColor = const Color(0xFF5B2C8A); break;
      case 'Genoa': teamColor = const Color(0xFF9B1B30); break;
      case 'Monza': teamColor = const Color(0xFFCE1126); break;
      default: teamColor = const Color(0xFF2196F3); break;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MatchPlayerProfileScreen(
        player: llp,
        teamName: team,
        teamColor: teamColor,
      ),
    ));
  }

  // ═══════════════════════════════════════════════════════════
  //  MOCK DATA GIOCATORI
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _getPlayerRanking(String type) {
    switch (type) {
      case 'goals': return _topScorers;
      case 'assists': return _topAssists;
      case 'ga': return _topGA;
      case 'cleanSheet': return _topCleanSheets;
      case 'cards': return _topCards;
      default: return [];
    }
  }

  static final List<Map<String, dynamic>> _topScorers = [
    {'name': 'Lautaro Martinez', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/753.png', 'stat': 24, 'appearances': 33},
    {'name': 'Dusan Vlahovic', 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': 'https://media.api-sports.io/football/players/48444.png', 'stat': 16, 'appearances': 33},
    {'name': 'Marcus Thuram', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/23474.png', 'stat': 13, 'appearances': 34},
    {'name': 'Ademola Lookman', 'team': 'Atalanta', 'teamLogo': 'https://media.api-sports.io/football/teams/499.png', 'photo': 'https://media.api-sports.io/football/players/18921.png', 'stat': 11, 'appearances': 35},
    {'name': 'Rafael Leao', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/162028.png', 'stat': 15, 'appearances': 34},
    {'name': 'Victor Osimhen', 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': 'https://media.api-sports.io/football/players/48809.png', 'stat': 15, 'appearances': 25},
    {'name': 'Olivier Giroud', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/2295.png', 'stat': 10, 'appearances': 31},
    {'name': 'Artem Dovbyk', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': '', 'stat': 10, 'appearances': 28},
    {'name': 'Paulo Dybala', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': 'https://media.api-sports.io/football/players/1102.png', 'stat': 13, 'appearances': 29},
    {'name': 'Matteo Retegui', 'team': 'Genoa', 'teamLogo': 'https://media.api-sports.io/football/teams/495.png', 'photo': '', 'stat': 9, 'appearances': 31},
    {'name': 'Ciro Immobile', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': 'https://media.api-sports.io/football/players/30924.png', 'stat': 12, 'appearances': 31},
    {'name': 'Federico Chiesa', 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': 'https://media.api-sports.io/football/players/31077.png', 'stat': 9, 'appearances': 22},
    {'name': 'Noah Okafor', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': '', 'stat': 7, 'appearances': 27},
    {'name': 'Albert Gudmundsson', 'team': 'Genoa', 'teamLogo': 'https://media.api-sports.io/football/teams/495.png', 'photo': '', 'stat': 14, 'appearances': 33},
    {'name': 'Romelu Lukaku', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': '', 'stat': 13, 'appearances': 32},
  ];

  static final List<Map<String, dynamic>> _topAssists = [
    {'name': 'Hakan Calhanoglu', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2931.png', 'stat': 10, 'appearances': 35},
    {'name': 'Nicolo Barella', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2464.png', 'stat': 9, 'appearances': 33},
    {'name': 'Federico Dimarco', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': '', 'stat': 8, 'appearances': 34},
    {'name': 'Rafael Leao', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/162028.png', 'stat': 9, 'appearances': 34},
    {'name': 'Khvicha Kvaratskhelia', 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': 'https://media.api-sports.io/football/players/292462.png', 'stat': 8, 'appearances': 34},
    {'name': 'Theo Hernandez', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/5996.png', 'stat': 8, 'appearances': 33},
    {'name': 'Paulo Dybala', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': 'https://media.api-sports.io/football/players/1102.png', 'stat': 7, 'appearances': 29},
    {'name': 'Luis Alberto', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': '', 'stat': 7, 'appearances': 32},
    {'name': 'Ademola Lookman', 'team': 'Atalanta', 'teamLogo': 'https://media.api-sports.io/football/teams/499.png', 'photo': 'https://media.api-sports.io/football/players/18921.png', 'stat': 6, 'appearances': 35},
    {'name': 'Mattia Zaccagni', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': '', 'stat': 6, 'appearances': 35},
    {'name': 'Lautaro Martinez', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/753.png', 'stat': 5, 'appearances': 33},
    {'name': 'Lorenzo Pellegrini', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': 'https://media.api-sports.io/football/players/30928.png', 'stat': 5, 'appearances': 34},
  ];

  static final List<Map<String, dynamic>> _topGA = [
    {'name': 'Lautaro Martinez', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/753.png', 'goals': 24, 'assists': 5, 'ga': 29},
    {'name': 'Rafael Leao', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/162028.png', 'goals': 15, 'assists': 9, 'ga': 24},
    {'name': 'Paulo Dybala', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': 'https://media.api-sports.io/football/players/1102.png', 'goals': 13, 'assists': 7, 'ga': 20},
    {'name': 'Hakan Calhanoglu', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2931.png', 'goals': 8, 'assists': 10, 'ga': 18},
    {'name': 'Ademola Lookman', 'team': 'Atalanta', 'teamLogo': 'https://media.api-sports.io/football/teams/499.png', 'photo': 'https://media.api-sports.io/football/players/18921.png', 'goals': 11, 'assists': 6, 'ga': 17},
    {'name': 'Nicolo Barella', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2464.png', 'goals': 5, 'assists': 9, 'ga': 14},
    {'name': 'Dusan Vlahovic', 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': 'https://media.api-sports.io/football/players/48444.png', 'goals': 16, 'assists': 0, 'ga': 16},
    {'name': 'Marcus Thuram', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/23474.png', 'goals': 13, 'assists': 4, 'ga': 17},
    {'name': 'Khvicha Kvaratskhelia', 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': 'https://media.api-sports.io/football/players/292462.png', 'goals': 7, 'assists': 8, 'ga': 15},
    {'name': 'Theo Hernandez', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/5996.png', 'goals': 5, 'assists': 8, 'ga': 13},
    {'name': 'Ciro Immobile', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': 'https://media.api-sports.io/football/players/30924.png', 'goals': 12, 'assists': 3, 'ga': 15},
    {'name': 'Albert Gudmundsson', 'team': 'Genoa', 'teamLogo': 'https://media.api-sports.io/football/teams/495.png', 'photo': '', 'goals': 14, 'assists': 4, 'ga': 18},
  ];

  static final List<Map<String, dynamic>> _topCleanSheets = [
    {'name': 'Yann Sommer', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': '', 'stat': 17, 'appearances': 36},
    {'name': 'Michele Di Gregorio', 'team': 'Monza', 'teamLogo': 'https://media.api-sports.io/football/teams/1579.png', 'photo': '', 'stat': 11, 'appearances': 38},
    {'name': 'Marco Carnesecchi', 'team': 'Atalanta', 'teamLogo': 'https://media.api-sports.io/football/teams/499.png', 'photo': '', 'stat': 10, 'appearances': 33},
    {'name': 'Mike Maignan', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/2932.png', 'stat': 10, 'appearances': 28},
    {'name': 'Ivan Provedel', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': 'https://media.api-sports.io/football/players/30630.png', 'stat': 9, 'appearances': 32},
    {'name': 'Alex Meret', 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': '', 'stat': 8, 'appearances': 30},
    {'name': 'Mattia Perin', 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': '', 'stat': 8, 'appearances': 22},
    {'name': 'Wojciech Szczesny', 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': '', 'stat': 7, 'appearances': 18},
    {'name': 'Mile Svilar', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': '', 'stat': 7, 'appearances': 36},
    {'name': 'David De Gea', 'team': 'Fiorentina', 'teamLogo': 'https://media.api-sports.io/football/teams/502.png', 'photo': '', 'stat': 6, 'appearances': 30},
  ];

  static final List<Map<String, dynamic>> _topCards = [
    {'name': 'Lorenzo Pellegrini', 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': 'https://media.api-sports.io/football/players/30928.png', 'yellow': 12, 'red': 1},
    {'name': 'Theo Hernandez', 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/5996.png', 'yellow': 11, 'red': 1},
    {'name': 'Hakan Calhanoglu', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2931.png', 'yellow': 10, 'red': 0},
    {'name': 'Nicolo Barella', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2464.png', 'yellow': 9, 'red': 0},
    {'name': 'Mattia Zaccagni', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': '', 'yellow': 9, 'red': 0},
    {'name': 'Marten De Roon', 'team': 'Atalanta', 'teamLogo': 'https://media.api-sports.io/football/teams/499.png', 'photo': '', 'yellow': 8, 'red': 1},
    {'name': 'Adam Marusic', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': '', 'yellow': 8, 'red': 0},
    {'name': 'Manuel Locatelli', 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': '', 'yellow': 8, 'red': 0},
    {'name': 'Matteo Darmian', 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': '', 'yellow': 7, 'red': 0},
    {'name': 'Victor Osimhen', 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': 'https://media.api-sports.io/football/players/48809.png', 'yellow': 7, 'red': 1},
    {'name': 'Danilo', 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': '', 'yellow': 7, 'red': 0},
    {'name': 'Sergej Milinkovic-Savic', 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': 'https://media.api-sports.io/football/players/30443.png', 'yellow': 7, 'red': 0},
  ];

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════
  Widget _hdr(String t, Color lb) => SizedBox(width: 28, child: Center(
      child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb))));

  Widget _cell(String t, Color tx) => SizedBox(width: 28, child: Center(
      child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tx))));

  Widget _legendDot(Color color, String label) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    ]),
  );

  Color _posColor(int pos) {
    if (pos <= 4) return const Color(0xFF4CAF50); // Champions League
    if (pos == 5 || pos == 6) return const Color(0xFF2196F3); // Europa League
    if (pos == 7) return const Color(0xFFFFA726); // Conference League
    if (pos >= 18) return const Color(0xFFE53935); // Retrocessione
    return Colors.grey;
  }


  String _formTooltipText(String teamName, String result, int index) {
    const opponents = ['Juventus', 'Milan', 'Inter', 'Napoli', 'Roma', 'Lazio', 'Atalanta', 'Bologna', 'Fiorentina', 'Torino'];
    final opp = opponents[(teamName.hashCode.abs() + index) % opponents.length];
    final actual = opp == teamName ? 'Monza' : opp;
    final isHome = index % 2 == 0;
    String score;
    if (result == 'W') { score = isHome ? '2:0' : '0:1'; }
    else if (result == 'D') { score = '1:1'; }
    else { score = isHome ? '0:2' : '1:3'; }
    final home = isHome ? teamName : actual;
    final away = isHome ? actual : teamName;
    final day = 28 - index * 7;
    final month = day > 0 ? '03' : '02';
    final d = day > 0 ? day : day + 28;
    return '$score ($home - $away)\n${d.toString().padLeft(2, "0")}.$month.2024';
  }

  void _navigateToFormMatch(BuildContext context, String teamName, String result, int index) {
    const opponents = ['Juventus', 'Milan', 'Inter', 'Napoli', 'Roma', 'Lazio', 'Atalanta', 'Bologna', 'Fiorentina', 'Torino'];
    final opp = opponents[(teamName.hashCode.abs() + index) % opponents.length];
    final actual = opp == teamName ? 'Monza' : opp;
    final isHome = index % 2 == 0;
    int hs, as_;
    if (result == 'W') { hs = isHome ? 2 : 0; as_ = isHome ? 0 : 1; }
    else if (result == 'D') { hs = 1; as_ = 1; }
    else { hs = isHome ? 0 : 1; as_ = isHome ? 2 : 3; }
    if (!isHome) { final tmp = hs; hs = as_; as_ = tmp; }
    final home = isHome ? teamName : actual;
    final away = isHome ? actual : teamName;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchDetailScreen(
      match: SoccerMatch(id: (teamName + actual + index.toString()).hashCode.abs(),
        date: DateTime.now(), time: '20:45', status: 'FT', venue: '',
        homeTeamId: 0, awayTeamId: 0, homeTeamName: home, awayTeamName: away,
        homeScore: hs, awayScore: as_, leagueName: 'Serie A', season: 2023, round: 'Giornata ${35 - index}'),
    )));
  }

  Widget _legendRow(Color color, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
    ]);
  }

  Widget _legendAbbr2(String abbr, String label, Color lb) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(abbr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: lb)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    ]);
  }
}
