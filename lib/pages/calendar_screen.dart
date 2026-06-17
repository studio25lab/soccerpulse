// lib/pages/calendar_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/soccer_match.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../generated/l10n.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';
import '../services/favorites_service.dart';
import 'package:provider/provider.dart';
import '../services/match_notification_preferences_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();

  DateTime _focusedDay = DateTime(2023, 5, 14);
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Map<DateTime, List<SoccerMatch>> _matchEvents = {};
  List<SoccerMatch> _selectedMatches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMatchesForMonth(_focusedDay);
    // Seleziona il 14 maggio (Lazio-Milan)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _selectedDay = DateTime(2023, 5, 14);
          _selectedMatches = _getMatchesForDay(_selectedDay);
        });
      }
    });
  }

  Future<void> _loadMatchesForMonth(DateTime month) async {
    setState(() => _isLoading = true);
    try {
      final realMatches = await _apiService.fetchMatchesByDate(DateTime(2023, 5, 14));
      final Map<DateTime, List<SoccerMatch>> events = {};
      if (realMatches.isNotEmpty) {
        events[DateTime(2023, 5, 14)] = realMatches;
      }
      final demo = _generateMonthMatches(month.year, month.month);
      for (final entry in demo.entries) {
        events.putIfAbsent(entry.key, () => entry.value);
      }
      setState(() {
        _matchEvents = events;
        _selectedMatches = _getMatchesForDay(_selectedDay);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _matchEvents = _generateMonthMatches(month.year, month.month);
        _selectedMatches = _getMatchesForDay(_selectedDay);
        _isLoading = false;
      });
    }
  }

  Map<DateTime, List<SoccerMatch>> _generateMonthMatches(int year, int month) {
    final Map<DateTime, List<SoccerMatch>> events = {};
    if (year == 2023 && month == 5) {
      events[DateTime(2023, 5, 3)] = [
        _dm(3001, DateTime(2023,5,3), '20:45', 'FT', 'Napoli', 'Fiorentina', 1, 0, 'Stadio Maradona', 'Giornata 34'),
        _dm(3002, DateTime(2023,5,3), '20:45', 'FT', 'Roma', 'Juventus', 1, 1, 'Stadio Olimpico', 'Giornata 34'),
        _dm(3003, DateTime(2023,5,3), '18:30', 'FT', 'Inter', 'Sassuolo', 4, 2, 'San Siro', 'Giornata 34'),
      ];
      events[DateTime(2023, 5, 6)] = [
        _dm(3004, DateTime(2023,5,6), '15:00', 'FT', 'Atalanta', 'Milan', 1, 1, 'Gewiss Stadium', 'Giornata 35'),
        _dm(3005, DateTime(2023,5,6), '18:00', 'FT', 'Torino', 'Napoli', 0, 1, 'Olimpico Torino', 'Giornata 35'),
      ];
      events[DateTime(2023, 5, 7)] = [
        _dm(3006, DateTime(2023,5,7), '20:45', 'FT', 'Lazio', 'Fiorentina', 2, 1, 'Stadio Olimpico', 'Giornata 35'),
        _dm(3007, DateTime(2023,5,7), '15:00', 'FT', 'Bologna', 'Roma', 0, 2, 'Dall\'Ara', 'Giornata 35'),
      ];
      events[DateTime(2023, 5, 10)] = [
        _dm(3008, DateTime(2023,5,10), '20:45', 'FT', 'Juventus', 'Inter', 2, 0, 'Allianz Stadium', 'Giornata 35'),
      ];
      events[DateTime(2023, 5, 14)] = [
        _dm(3010, DateTime(2023,5,14), '15:00', 'FT', 'Napoli', 'Inter', 3, 1, 'Stadio Maradona', 'Giornata 36'),
        _dm(3011, DateTime(2023,5,14), '18:00', 'FT', 'Roma', 'Salernitana', 2, 0, 'Stadio Olimpico', 'Giornata 36'),
        _liveDm(9001, DateTime(2023,5,14), 'Lazio', 'Milan', 2, 1, 67, 'Stadio Olimpico', 'Giornata 36'),
      ];
      events[DateTime(2023, 5, 17)] = [
        _dm(3012, DateTime(2023,5,17), '20:45', 'NS', 'Monza', 'Lecce', 0, 0, 'U-Power Stadium', 'Giornata 36'),
      ];
      events[DateTime(2023, 5, 20)] = [
        _dm(3013, DateTime(2023,5,20), '20:45', 'NS', 'Milan', 'Sampdoria', 0, 0, 'San Siro', 'Giornata 37'),
        _dm(3014, DateTime(2023,5,20), '18:00', 'NS', 'Fiorentina', 'Roma', 0, 0, 'Franchi', 'Giornata 37'),
      ];
      events[DateTime(2023, 5, 21)] = [
        _dm(3015, DateTime(2023,5,21), '20:45', 'NS', 'Juventus', 'Lazio', 0, 0, 'Allianz Stadium', 'Giornata 37'),
        _dm(3016, DateTime(2023,5,21), '15:00', 'NS', 'Napoli', 'Verona', 0, 0, 'Stadio Maradona', 'Giornata 37'),
      ];
      events[DateTime(2023, 5, 24)] = [
        _dm(3017, DateTime(2023,5,24), '20:45', 'NS', 'Sassuolo', 'Udinese', 0, 0, 'Mapei Stadium', 'Giornata 37'),
      ];
      events[DateTime(2023, 5, 28)] = [
        _dm(3018, DateTime(2023,5,28), '20:45', 'NS', 'Lazio', 'Verona', 0, 0, 'Stadio Olimpico', 'Giornata 38'),
        _dm(3019, DateTime(2023,5,28), '20:45', 'NS', 'Milan', 'Juventus', 0, 0, 'San Siro', 'Giornata 38'),
        _dm(3020, DateTime(2023,5,28), '20:45', 'NS', 'Napoli', 'Sampdoria', 0, 0, 'Stadio Maradona', 'Giornata 38'),
        _dm(3021, DateTime(2023,5,28), '20:45', 'NS', 'Inter', 'Atalanta', 0, 0, 'San Siro', 'Giornata 38'),


      ];
    }
    return events;
  }

  SoccerMatch _liveDm(int id, DateTime date, String home, String away,
      int hs, int as_, int elapsed, String venue, String round) {
    return SoccerMatch(
      id: id, date: date, time: '20:45', status: '2H', elapsed: elapsed, venue: venue,
      homeTeamId: 0, homeTeamName: home, homeTeamLogo: _teamLogos[home],
      awayTeamId: 0, awayTeamName: away, awayTeamLogo: _teamLogos[away],
      homeScore: hs, awayScore: as_, leagueName: 'Serie A', season: 2023, round: round,
    );
  }

  static const Map<String, String> _teamLogos = {
    'Napoli': 'https://media.api-sports.io/football/teams/492.png',
    'Inter': 'https://media.api-sports.io/football/teams/505.png',
    'Milan': 'https://media.api-sports.io/football/teams/489.png',
    'Juventus': 'https://media.api-sports.io/football/teams/496.png',
    'Roma': 'https://media.api-sports.io/football/teams/497.png',
    'Lazio': 'https://media.api-sports.io/football/teams/487.png',
    'Atalanta': 'https://media.api-sports.io/football/teams/499.png',
    'Fiorentina': 'https://media.api-sports.io/football/teams/502.png',
    'Torino': 'https://media.api-sports.io/football/teams/503.png',
    'Bologna': 'https://media.api-sports.io/football/teams/500.png',
    'Monza': 'https://media.api-sports.io/football/teams/1579.png',
    'Sassuolo': 'https://media.api-sports.io/football/teams/488.png',
    'Lecce': 'https://media.api-sports.io/football/teams/867.png',
    'Udinese': 'https://media.api-sports.io/football/teams/494.png',
    'Sampdoria': 'https://media.api-sports.io/football/teams/498.png',
    'Verona': 'https://media.api-sports.io/football/teams/504.png',
    'Salernitana': 'https://media.api-sports.io/football/teams/514.png',
  };

  SoccerMatch _dm(int id, DateTime date, String time, String status,
      String home, String away, int hs, int as_, String venue, String round) {
    return SoccerMatch(
      id: id, date: date, time: time, status: status, venue: venue,
      homeTeamId: 0, homeTeamName: home, homeTeamLogo: _teamLogos[home],
      awayTeamId: 0, awayTeamName: away, awayTeamLogo: _teamLogos[away],
      homeScore: hs, awayScore: as_, leagueName: 'Serie A', season: 2023, round: round,
    );
  }

  String _getMonthName(int month, {BuildContext? ctx}) {
    final isEn = ctx != null ? Localizations.localeOf(ctx).languageCode == 'en' : false;
    final months = ['', isEn ? 'January' : 'Gennaio', isEn ? 'February' : 'Febbraio', isEn ? 'March' : 'Marzo', isEn ? 'April' : 'Aprile', isEn ? 'May' : 'Maggio',
        isEn ? 'June' : 'Giugno', isEn ? 'July' : 'Luglio', isEn ? 'August' : 'Agosto', isEn ? 'September' : 'Settembre', isEn ? 'October' : 'Ottobre', isEn ? 'November' : 'Novembre', isEn ? 'December' : 'Dicembre'];
    return months[month.clamp(1, 12)];
  }

    List<SoccerMatch> _getMatchesForDay(DateTime? day) {
    if (day == null) return [];
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _matchEvents[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedMatches = _getMatchesForDay(selectedDay);
      });

      _haptic.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final S s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(s, theme, isDark),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: _buildCalendar(theme, isDark, s),
          ),
          // ── Handle (tap/drag per toggle) ──
          GestureDetector(
            onTap: () {
              _haptic.lightImpact();
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy > 50 && _calendarFormat == CalendarFormat.week) {
                setState(() => _calendarFormat = CalendarFormat.month);
              } else if (details.velocity.pixelsPerSecond.dy < -50 && _calendarFormat == CalendarFormat.month) {
                setState(() => _calendarFormat = CalendarFormat.week);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: isDark ? Colors.grey[900] : Colors.white,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[350],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          // ── Lista partite con scroll + gesture listener ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification && 
                            notification.scrollDelta != null) {
                          final delta = notification.scrollDelta!;
                          final pos = notification.metrics.pixels;
                          // Scroll giù → comprimi
                          if (delta > 3 && _calendarFormat == CalendarFormat.month) {
                            setState(() => _calendarFormat = CalendarFormat.week);
                          }
                          // Scroll su vicino alla cima → espandi
                          if (delta < -3 && pos < 50 && _calendarFormat == CalendarFormat.week) {
                            setState(() => _calendarFormat = CalendarFormat.month);
                          }
                        }
                        // Overscroll in cima → espandi
                        if (notification is OverscrollNotification && 
                            notification.overscroll < -1 &&
                            _calendarFormat == CalendarFormat.week) {
                          setState(() => _calendarFormat = CalendarFormat.month);
                        }
                        return false;
                      },
                      child: _buildMatchList(s, theme, isDark),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(S s, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.calendar,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selectedMatches.length} ${s.matches}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  _haptic.lightImpact();
                  // Per demo usiamo il 14 maggio, con API useremo DateTime.now()
                  final today = DateTime(2023, 5, 14); // TODO: DateTime(now.year, now.month, now.day) con API
                  setState(() {
                    _focusedDay = today;
                    _selectedDay = today;
                    _calendarFormat = CalendarFormat.month;
                    _selectedMatches = _getMatchesForDay(_selectedDay);
                  });
                  _loadMatchesForMonth(today);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(tr(context, 'Oggi'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.primaryColor)),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _haptic.lightImpact();
                  setState(() => _calendarFormat = CalendarFormat.month);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.keyboard_arrow_up_rounded, size: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme, bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? Colors.grey[900] : const Color(0xFFFAFAFA),
      child: TableCalendar<SoccerMatch>(
        firstDay: DateTime(2023, 1, 1),
        lastDay: DateTime(2023, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mese',
          CalendarFormat.week: 'Settimana',
        },
        rowHeight: 42,
        daysOfWeekHeight: 20,
        eventLoader: _getMatchesForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          if (format == CalendarFormat.month || format == CalendarFormat.week) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        formatAnimationDuration: const Duration(milliseconds: 200),
        formatAnimationCurve: Curves.easeOutCubic,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          _loadMatchesForMonth(focusedDay);
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 6.0,
          markerDecoration: const BoxDecoration(
            color: Color(0xFF4CAF50),
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.map((event) {
                  final m = event;
                  return Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.isLive ? Colors.red : Colors.green,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        locale: Localizations.localeOf(context).languageCode == 'en' ? 'en_US' : 'it_IT',
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: theme.primaryColor,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchList(S s, ThemeData theme, bool isDark) {
    if (_selectedMatches.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_soccer,
                size: 64,
                color: Colors.grey.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                s.noMatchesOnDate,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDay != null
                      ? '${tr(context, "Partite del")} ${_selectedDay!.day} ${_getMonthName(_selectedDay!.month, ctx: context)} ${_selectedDay!.year}'
                      : s.todayMatches,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedMatches.length,
              itemBuilder: (context, index) {
                final match = _selectedMatches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    children: [
                      MatchCard(
                        match: match,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchDetailScreen(match: match),
                            ),
                          );
                        },
                      ),
                      // Heart favorite button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Builder(builder: (ctx) {
                          final favSvc = ctx.read<FavoritesService>();
                          final isFav = favSvc.isMatchFavorite(match.id);
                          final isLive = match.status == 'LIVE' || match.status == '1H' || match.status == '2H' || match.status == 'HT';
                          return Row(mainAxisSize: MainAxisSize.min, children: [
                            if (isLive) ...[
                              Builder(builder: (bellCtx) {
                                final notifSvc = bellCtx.read<MatchNotificationPreferencesService>();
                                final settings = notifSvc.getSettingsForMatch(match.id);
                                final hasNotif = settings.enabled && (settings.notifyHomeGoals || settings.notifyAwayGoals);
                                return GestureDetector(
                                  onTap: () {
                                    HapticService().lightImpact();
                                    if (!hasNotif) { notifSvc.enableBasicNotifications(match.id); }
                                    else { notifSvc.disableAllNotifications(match.id); }
                                    (bellCtx as Element).markNeedsBuild();
                                  },
                                  child: Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: hasNotif ? const Color(0xFF4CAF50).withOpacity(0.15) : Colors.black.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      hasNotif ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                                      size: 18, color: hasNotif ? const Color(0xFF4CAF50) : Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(width: 4),
                            ],
                            GestureDetector(
                              onTap: () {
                                HapticService().lightImpact();
                                final wasFav = favSvc.isMatchFavorite(match.id);
                                favSvc.toggleMatchFavorite(match.id, status: match.status);
                                if (!wasFav) {
                                  favSvc.storeMatchDisplayData(match.id, {
                                    'homeTeam': match.homeTeamName, 'awayTeam': match.awayTeamName,
                                    'homeLogo': match.homeTeamLogo ?? '', 'awayLogo': match.awayTeamLogo ?? '',
                                    'homeId': match.homeTeamId, 'awayId': match.awayTeamId,
                                    'homeScore': match.homeScore, 'awayScore': match.awayScore,
                                    'status': match.status, 'date': match.time, 'time': match.time,
                                    'league': match.leagueName ?? 'Serie A', 'round': '',
                                  });
                                }
                                (ctx as Element).markNeedsBuild();
                              },
                              child: Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: isFav ? Colors.red.withOpacity(0.12) : Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 18, color: isFav ? Colors.red : Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ]);
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
