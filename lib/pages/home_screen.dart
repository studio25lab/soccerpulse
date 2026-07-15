// lib/pages/home_screen.dart

import 'package:flutter/material.dart'; // [PULIZIA-WARN-A]
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/soccer_match.dart';
import '../services/live_match_simulator.dart'; // [TEST-LIVE]
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../services/match_notification_preferences_service.dart';
import '../models/match_notification_settings.dart';
import '../widgets/dialogs/match_notification_dialog.dart'; // [REFACTOR-STEP2]
import '../generated/l10n.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {

  // [TEST-LIVE] avvia la partita di test a copione e apre il dettaglio
  void _startTestMatch() {
    final testMatch = SoccerMatch(
      id: 9999,
      homeTeamId: 999001,
      awayTeamId: 999002,
      homeTeamName: 'Test United',
      awayTeamName: 'Demo City',
      homeScore: 0,
      awayScore: 0,
      status: 'LIVE',
      elapsed: 1,
      date: DateTime.now(),
      time: '20:45',
      venue: 'Stadio Simulazione',
      leagueId: 135,
      leagueName: 'Serie A',
      round: 'Test Live',
      homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png',
      awayTeamLogo: 'https://media.api-sports.io/football/teams/489.png',
    );
    LiveMatchSimulator().stopLiveSimulation(9999);
    LiveMatchSimulator().startScriptedSimulation(testMatch);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MatchDetailScreen(match: testMatch)),
    );
  }

  final HapticService _haptic = HapticService();
  late TabController _tabController;
  late FavoritesService _favoritesService;

  final Set<int> _manualNotifMatches = {}; // partite con notifiche impostate manualmente via campanella
  List<SoccerMatch> _liveMatches = [];
  List<SoccerMatch> _finishedMatches = [];
  List<SoccerMatch> _scheduledMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoritesService = context.read<FavoritesService>();
    _favoritesService.addListener(_onFavoritesChanged);
    _loadMockMatches();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    _tabController.dispose();
    super.dispose();
  }

  // TODO API: sostituire _loadMockMatches con chiamate al
  // repository:
  //   final repo = RepositoryProvider.matchRepository;
  //   _liveMatches = await repo.fetchLiveMatches();
  //   _finishedMatches = await repo.fetchFinishedMatches();
  //   _scheduledMatches = await repo.fetchScheduledMatches();
  // (il metodo diventera async; aggiornare anche initState.)
  void _loadMockMatches() {
    setState(() {
      _liveMatches = [
        SoccerMatch(
          id: 9001, homeTeamId: 487, awayTeamId: 489,
          homeTeamName: 'Lazio', awayTeamName: 'Milan',
          homeScore: 2, awayScore: 1, status: '1H',
          date: DateTime(2023, 5, 14), time: '20:45',
          venue: 'Stadio Olimpico', leagueId: 135,
          leagueName: 'Serie A', round: 'Giornata 35', elapsed: 45,
          homeTeamLogo: 'https://media.api-sports.io/football/teams/487.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/489.png',
        ),
      ];

      _finishedMatches = [
        SoccerMatch(
          id: 9009, homeTeamId: 502, awayTeamId: 499,
          homeTeamName: 'Fiorentina', awayTeamName: 'Atalanta',
          homeScore: 3, awayScore: 2, status: 'FT',
          date: DateTime(2023, 5, 14), time: '15:00',
          venue: 'Stadio Artemio Franchi', leagueId: 135,
          leagueName: 'Serie A', round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/502.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/499.png',
        ),
        SoccerMatch(
          id: 8008, homeTeamId: 492, awayTeamId: 496,
          homeTeamName: 'Napoli', awayTeamName: 'Juventus',
          homeScore: 1, awayScore: 1, status: 'FT',
          date: DateTime(2023, 5, 14), time: '18:00',
          venue: 'Stadio Diego Armando Maradona', leagueId: 135,
          leagueName: 'Serie A', round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/492.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/496.png',
        ),
        SoccerMatch(
          id: 8009, homeTeamId: 505, awayTeamId: 503,
          homeTeamName: 'Inter', awayTeamName: 'Torino',
          homeScore: 2, awayScore: 0, status: 'FT',
          date: DateTime(2023, 5, 14), time: '12:30',
          venue: 'San Siro', leagueId: 135,
          leagueName: 'Serie A', round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/503.png',
        ),
      ];

      _scheduledMatches = [
        SoccerMatch(
          id: 9007, homeTeamId: 497, awayTeamId: 500,
          homeTeamName: 'Roma', awayTeamName: 'Bologna',
          homeScore: 0, awayScore: 0, status: 'NS',
          date: DateTime(2023, 5, 21), time: '18:00',
          venue: 'Stadio Olimpico', leagueId: 135,
          leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/497.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/500.png',
        ),
        SoccerMatch(
          id: 9008, homeTeamId: 505, awayTeamId: 504,
          homeTeamName: 'Inter', awayTeamName: 'Verona',
          homeScore: 0, awayScore: 0, status: 'NS',
          date: DateTime(2023, 5, 21), time: '20:45',
          venue: 'San Siro', leagueId: 135,
          leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/504.png',
        ),
        SoccerMatch(
          id: 9003, homeTeamId: 489, awayTeamId: 492,
          homeTeamName: 'Milan', awayTeamName: 'Napoli',
          homeScore: 0, awayScore: 0, status: 'NS',
          date: DateTime(2023, 5, 21), time: '15:00',
          venue: 'San Siro', leagueId: 135,
          leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/489.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/492.png',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F6FA);

    return Scaffold(
      // [TEST-LIVE] tasto di prova — RIMUOVERE PRIMA DEL DEPLOY
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startTestMatch,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.science),
        label: const Text('TEST LIVE'),
      ),
      backgroundColor: bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              pinned: true,
              backgroundColor: isDark ? const Color(0xFF1A1A2E) : theme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.network(
                    'https://media.api-sports.io/football/leagues/135.png',
                    width: 22, height: 22,
                    errorBuilder: (_, __, ___) => const Icon(Icons.sports_soccer, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text('Serie A', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_todayFormatted(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ]),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              ),

            ),
          ];
        },
        body: Column(
          children: [
            _buildTabBar(theme, isDark, tx, lb),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMatchList(_liveMatches, theme, isDark, tx, lb, isLive: true),
                  _buildMatchList(_finishedMatches, theme, isDark, tx, lb),
                  _buildMatchList(_scheduledMatches, theme, isDark, tx, lb, isScheduled: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _todayFormatted() {
    final now = DateTime.now();
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final months = isEn
        ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
        : ['Gen','Feb','Mar','Apr','Mag','Giu','Lug','Ago','Set','Ott','Nov','Dic'];
    return '${now.day} ${months[now.month - 1]}';
  }

  Widget _buildTabBar(ThemeData theme, bool isDark, Color tx, Color lb) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.primaryColor,
        unselectedLabelColor: lb,
        indicatorColor: theme.primaryColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ).animate(onPlay: (c) => c.repeat())
                .fadeOut(duration: 600.ms).then().fadeIn(duration: 600.ms),
            const SizedBox(width: 6),
            Text(S.of(context)!.live),
            if (_liveMatches.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_liveMatches.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red)),
              ),
            ],
          ])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(S.of(context)!.finished),
            if (_finishedMatches.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_finishedMatches.length}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.primaryColor)),
              ),
            ],
          ])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(S.of(context)!.upcoming),
            if (_scheduledMatches.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${_scheduledMatches.length}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.primaryColor)),
              ),
            ],
          ])),
        ],
      ),
    );
  }

  Widget _buildMatchList(List<SoccerMatch> matches, ThemeData theme, bool isDark,
      Color tx, Color lb, {bool isLive = false, bool isScheduled = false}) {
    if (matches.isEmpty) {
      return _buildEmptyState(theme, isDark, tx, lb);
    }

    return RefreshIndicator(
      onRefresh: () async => _loadMockMatches(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        physics: const BouncingScrollPhysics(),
        itemCount: matches.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildMatchCard(matches[i], theme, isDark, tx, lb, i, isLive: isLive, isScheduled: isScheduled),
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(SoccerMatch match, ThemeData theme, bool isDark,
      Color tx, Color lb, int index, {bool isLive = false, bool isScheduled = false}) {
    final cardBg = isDark ? const Color(0xFF1E1E30) : Colors.white;
    final isFav = _favoritesService.isMatchFavorite(match.id);

    // Marcatori mock

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match))).then((_) { if (mounted) setState(() {}); });
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLive
                ? const Color(0xFFFF1744).withValues(alpha: 0.3)
                : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? const Color(0xFFFF1744).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
              blurRadius: isLive ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(children: [
          // ── Header: League + Heart + Bell ──
          Row(children: [
            Icon(Icons.emoji_events_rounded, size: 13, color: theme.primaryColor.withValues(alpha: 0.6)),
            const SizedBox(width: 5),
            Text('${match.leagueName ?? 'Serie A'} • ${(match.round ?? '').replaceAll('Giornata', Localizations.localeOf(context).languageCode == 'en' ? 'Matchday' : 'Giornata')}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: lb)),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _haptic.lightImpact();
                final wasFav = _favoritesService.isMatchFavorite(match.id);
                setState(() => _favoritesService.toggleMatchFavorite(match.id, status: match.status));
                if (!wasFav) {
                  _favoritesService.storeMatchDisplayData(match.id, {
                    'homeTeam': match.homeTeamName,
                    'awayTeam': match.awayTeamName,
                    'homeLogo': match.homeTeamLogo ?? '',
                    'awayLogo': match.awayTeamLogo ?? '',
                    'homeId': match.homeTeamId,
                    'awayId': match.awayTeamId,
                    'homeScore': match.homeScore,
                    'awayScore': match.awayScore,
                    'status': match.status,
                    'date': match.time,
                    'time': match.time,
                    'league': match.leagueName ?? 'Serie A',
                    'round': '',
                  });
                }
                final notifService = context.read<MatchNotificationPreferencesService>();
                if (!wasFav) {
                  // Aggiunge ai preferiti → attiva notifiche base
                  // Se ha notifiche manuali ATTIVE, non le sovrascrive
                  final current = notifService.getSettingsForMatch(match.id);
                  final hasActive = current.notifyHomeGoals || current.notifyMatchEnd || current.notifyRedCards;
                  if (!hasActive) {
                    notifService.saveSettingsForMatch(MatchNotificationSettings.minimal(match.id));
                    _manualNotifMatches.remove(match.id);
                  }
                } else {
                  // Rimuove dai preferiti → disattiva notifiche
                  // Se ha notifiche manuali ATTIVE, non le tocca
                  final current = notifService.getSettingsForMatch(match.id);
                  final hasManualActive = _manualNotifMatches.contains(match.id) && 
                      (current.notifyHomeGoals || current.notifyMatchEnd || current.notifyRedCards || 
                       current.notifyPenalties || current.notifyVarDecisions);
                  if (!hasManualActive) {
                    notifService.saveSettingsForMatch(MatchNotificationSettings.disabled(match.id));
                    _manualNotifMatches.remove(match.id);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20, color: isFav ? Colors.red : lb.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (isLive || isScheduled) ...[
            const SizedBox(width: 2),
            Builder(builder: (ctx) {
              final ns = ctx.read<MatchNotificationPreferencesService>();
              final s = ns.getSettingsForMatch(match.id);
              final hasNotif = s.enabled && (s.notifyHomeGoals || s.notifyAwayGoals || s.notifyPenalties || s.notifyVarDecisions || s.notifyMatchStart || s.notifyHalfTime || s.notifyMatchEnd || s.notifyYellowCards || s.notifyRedCards || s.notifySubstitutions || s.notifyCorners || s.notifyOffsides || s.notifyShotsOnTarget || s.notifyFouls);
              return GestureDetector(
                onTap: () {
                  _haptic.lightImpact();
                  _manualNotifMatches.add(match.id);
                  _openMatchNotifDialog(match); // [REFACTOR-STEP2]
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    hasNotif ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    size: 20, color: hasNotif ? const Color(0xFF4CAF50) : lb.withValues(alpha: 0.4),
                  ),
                ),
              );
            }),
            ],
          ]),
          const SizedBox(height: 14),
          // ── Match: Home | Score | Away ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Home
              Expanded(child: Column(children: [
                _teamLogo(match.homeTeamLogo, 60),
                const SizedBox(height: 8),
                Text(match.homeTeamName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              // Score / Time
              SizedBox(width: 100, child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (isLive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF1744),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${match.elapsed ?? ''}\'',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                      .fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
                  const SizedBox(height: 6),
                ],
                if (isScheduled) ...[
                  Text(match.time, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tx)),
                  const SizedBox(height: 3),
                  Text(_formatDate(match.date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lb)),
                ] else ...[
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${match.homeScore}', style: TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w800,
                        color: isLive ? const Color(0xFFFF1744) : tx)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: lb)),
                    ),
                    Text('${match.awayScore}', style: TextStyle(
                        fontSize: 34, fontWeight: FontWeight.w800,
                        color: isLive ? const Color(0xFFFF1744) : tx)),
                  ]),
                  if (!isLive) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('FT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: lb)),
                    ),
                    const SizedBox(height: 4),
                    Text(_formatDate(match.date), style: TextStyle(fontSize: 11, color: lb)),
                  ],
                ],
              ])),
              // Away
              Expanded(child: Column(children: [
                _teamLogo(match.awayTeamLogo, 60),
                const SizedBox(height: 8),
                Text(match.awayTeamName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx),
                    textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
            ],
          ),
          // ── Posizione classifica per prossime ──
          if (!isLive) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                _positionBadge(_getTeamPosition(match.homeTeamName), theme),
                Expanded(child: Center(child: Text('vs', style: TextStyle(fontSize: 11, color: lb)))),
                _positionBadge(_getTeamPosition(match.awayTeamName), theme),
              ]),
            ),
          ],
        ]),
      ),
    ).animate()
        .fadeIn(delay: Duration(milliseconds: index * 80), duration: const Duration(milliseconds: 350))
        .slideY(begin: 0.04, end: 0);
  }

  // [FAV-D2b] match sheet unificato
  // [REFACTOR-STEP2] usa il dialog UFFICIALE (niente piu' pannello duplicato).
  // Prima qui c'erano ~299 righe di pannello copiato,
  // con testi diversi da match_detail/calendar -> traduzioni incoerenti.
  Future<void> _openMatchNotifDialog(SoccerMatch match) async {
    final notifSvc = context.read<MatchNotificationPreferencesService>();
    await showMatchNotificationDialogV2(
      context,
      match: match,
      getSettings: () => notifSvc.getSettingsForMatch(match.id),
      setSettings: (s) {
        notifSvc.saveSettingsForMatch(s);
        if (mounted) setState(() {});
      },
      service: notifSvc,
      haptic: _haptic,
      onUpdateFromKey: (key, value) {
        // logica centralizzata nel modello (STEP 1)
        final cur = notifSvc.getSettingsForMatch(match.id);
        notifSvc.saveSettingsForMatch(cur.updateFromKey(key, value));
        if (mounted) setState(() {});
      },
      onSetAll: (value) {
        final cur = notifSvc.getSettingsForMatch(match.id);
        notifSvc.saveSettingsForMatch(cur.setAll(value));
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() {});
  }

  // ── Mock scorers ──
  int _getTeamPosition(String teamName) {
    final positions = {
      'Inter': 1, 'Milan': 2, 'Juventus': 3, 'Atalanta': 4, 'Bologna': 5,
      'Roma': 6, 'Lazio': 7, 'Fiorentina': 8, 'Torino': 9, 'Napoli': 10,
      'Verona': 15, 'Monza': 11, 'Genoa': 12,
    };
    return positions[teamName] ?? 10;
  }

  Widget _positionBadge(int pos, ThemeData theme) {
    Color color;
    if (pos <= 4) {
      color = const Color(0xFF4CAF50);
    } else if (pos <= 6) color = const Color(0xFF2196F3);
    else if (pos == 7) color = const Color(0xFFFFA726);
    else if (pos >= 18) color = const Color(0xFFE53935);
    else color = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$pos°', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _teamLogo(String? url, double size) {
    if (url == null || url.isEmpty) {
      return Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(size * 0.15),
        ),
        child: Icon(Icons.shield_rounded, size: size * 0.6, color: Colors.grey),
      );
    }
    return CachedNetworkImage(
      imageUrl: url, width: size, height: size, fit: BoxFit.contain,
      errorWidget: (_, __, ___) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(size * 0.15),
        ),
        child: Icon(Icons.shield_rounded, size: size * 0.6, color: Colors.grey),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final months = isEn
        ? ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
        : ['Gen','Feb','Mar','Apr','Mag','Giu','Lug','Ago','Set','Ott','Nov','Dic'];
    final days = isEn
        ? ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
        : ['Lun','Mar','Mer','Gio','Ven','Sab','Dom'];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark, Color tx, Color lb) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.sports_soccer_rounded, size: 48, color: theme.primaryColor.withValues(alpha: 0.4)),
        ),
        const SizedBox(height: 24),
        Text(tr(context, 'Nessuna partita'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tx)),
        const SizedBox(height: 8),
        Text(tr(context, 'Non ci sono partite in questa sezione'),
            style: TextStyle(fontSize: 13, color: lb), textAlign: TextAlign.center),
      ]),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}
