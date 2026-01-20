// lib/pages/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../generated/l10n.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';

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
  }

  Future<void> _loadMatchesForMonth(DateTime month) async {
    setState(() => _isLoading = true);

    try {
      if (month.year == 2023 && month.month == 5) {
        final matches =
            await _apiService.fetchMatchesByDate(DateTime(2023, 5, 14));

        setState(() {
          _matchEvents = {
            DateTime(2023, 5, 14): matches,
          };
          _selectedMatches = _getMatchesForDay(_selectedDay);
          _isLoading = false;
        });
      } else {
        setState(() {
          _matchEvents = {};
          _selectedMatches = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _matchEvents = {};
        _selectedMatches = [];
      });
      print('Errore caricamento: \$e');
    }
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
          Container(
            height: 380,
            child: _buildCalendar(theme, isDark, s),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMatchList(s, theme, isDark),
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
                '\${_selectedMatches.length} \${s.matches}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: () {
                  _haptic.lightImpact();
                  setState(() {
                    _focusedDay = DateTime(2023, 5, 14);
                    _selectedDay = _focusedDay;
                    _selectedMatches = _getMatchesForDay(_selectedDay);
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  _calendarFormat == CalendarFormat.month
                      ? Icons.calendar_view_month
                      : _calendarFormat == CalendarFormat.twoWeeks
                          ? Icons.calendar_view_week
                          : Icons.calendar_today,
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  setState(() {
                    if (_calendarFormat == CalendarFormat.month) {
                      _calendarFormat = CalendarFormat.twoWeeks;
                    } else if (_calendarFormat == CalendarFormat.twoWeeks) {
                      _calendarFormat = CalendarFormat.week;
                    } else {
                      _calendarFormat = CalendarFormat.month;
                    }
                  });
                },
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
      color: isDark ? Colors.grey[900] : Colors.white,
      child: TableCalendar<SoccerMatch>(
        firstDay: DateTime(2023, 1, 1),
        lastDay: DateTime(2023, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        eventLoader: _getMatchesForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
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
          markerDecoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.todayMatches,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\${_selectedDay?.day}/\${_selectedDay?.month}/\${_selectedDay?.year}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _selectedMatches.length,
              itemBuilder: (context, index) {
                final match = _selectedMatches[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MatchCard(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
