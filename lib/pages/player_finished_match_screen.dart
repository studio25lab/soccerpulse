import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import '../models/soccer_match.dart';
import '../services/haptic_service.dart';
import '../api/api_service.dart';
// ⭐ NUOVI IMPORT PER MatchDataService
import '../services/match_data_service.dart';
import '../models/match_data.dart';
import '../widgets/player_performance_widgets.dart';
import 'dart:math' as math;

class PlayerFinishedMatchScreen extends StatefulWidget {
  final String playerName;
  final int playerNumber;
  final String teamName;
  final Color teamColor;
  final SoccerMatch match;
  final int? playerId;

  const PlayerFinishedMatchScreen({
    Key? key,
    required this.playerName,
    required this.playerNumber,
    required this.teamName,
    required this.teamColor,
    required this.match,
    this.playerId,
  }) : super(key: key);

  @override
  State<PlayerFinishedMatchScreen> createState() =>
      _PlayerFinishedMatchScreenState();
}

class _PlayerFinishedMatchScreenState extends State<PlayerFinishedMatchScreen>
    with TickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  late TabController _tabController;
  bool _notificationsEnabled = false;

  bool _heatmapExpanded = false;
  bool _statsMapExpanded = false;
  String _selectedStatsType = 'Shot';
  String _selectedAccuracy = 'Tutti';

  // HEATMAP DATA STATE
  List<Offset> _heatmapPositions = [];
  bool _isLoadingHeatmap = false;
  bool _isUsingRealHeatmapData = false;

  // EVENTS DATA STATE
  List<Map<String, dynamic>> _matchEvents = [];
  bool _isLoadingEvents = false;
  bool _isUsingRealEventsData = false;

  // ⭐ NUOVO: MatchDataService state
  final MatchDataService _matchDataService = MatchDataService();
  PlayerMatchStats? _playerStats;
  bool _isLoadingPlayerStats = false;

  // REPLAY ANIMATION STATE
  late AnimationController _replayController;
  bool _isReplaying = false;
  int _currentReplayIndex = 0;
  double _playbackSpeed = 1.0;

  // EVENTO SELEZIONATO
  dynamic _selectedEvent;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // ⭐ NUOVO: Carica dati da MatchDataService PRIMA
    _loadPlayerData();

    // Poi carica heatmap ed eventi (mantieni i tuoi sistemi esistenti)
    _loadHeatmapData();
    _loadMatchEvents();

    // Init replay animation controller
    _replayController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        if (_isReplaying && _replayController.isCompleted) {
          _advanceReplay();
        }
      });
  }

  // ⭐ NUOVO: Carica dati giocatore da MatchDataService
  Future<void> _loadPlayerData() async {
    setState(() => _isLoadingPlayerStats = true);

    try {
      print(
          '🔄 Loading player stats for ${widget.playerName} from MatchDataService...');

      final matchData = await _matchDataService.loadMatchData(
        widget.match.id,
        forceRefresh: false,
      );

      final playerStats = matchData.getPlayerStats(widget.playerName);

      if (playerStats != null) {
        setState(() {
          _playerStats = playerStats;
          _isLoadingPlayerStats = false;
        });

        print(
            '✅ Player stats loaded: ${playerStats.goals} goals, ${playerStats.assists} assists, ${playerStats.shots.length} shots');
      } else {
        print('⚠️ No stats found for ${widget.playerName} in MatchData');
        setState(() => _isLoadingPlayerStats = false);
      }
    } catch (e) {
      print('⚠️ Error loading player stats from MatchDataService: $e');
      setState(() => _isLoadingPlayerStats = false);
    }
  }

  // Advance to next event in replay
  void _advanceReplay() {
    if (!_isReplaying) return;

    final events = _getStatsData();
    if (events is List && _currentReplayIndex < events.length - 1) {
      setState(() {
        _currentReplayIndex++;
      });
      _replayController.forward(from: 0);
    } else {
      _stopReplay();
    }
  }

  void _startReplay() {
    setState(() {
      _isReplaying = true;
      _currentReplayIndex = 0;
    });
    _replayController.forward(from: 0);
  }

  void _stopReplay() {
    setState(() {
      _isReplaying = false;
      _currentReplayIndex = 0;
    });
    _replayController.stop();
  }

  void _toggleReplay() {
    if (_isReplaying) {
      _stopReplay();
    } else {
      _startReplay();
    }
  }

  void _changePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 0.5) {
        _playbackSpeed = 1.0;
      } else if (_playbackSpeed == 1.0) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 0.5;
      }

      _replayController.duration = Duration(
        milliseconds: (2000 / _playbackSpeed).round(),
      );
    });
  }

  Future<void> _loadHeatmapData() async {
    if (widget.playerId == null) {
      // ⭐ MODIFICATO: Prova prima a usare heatmap da PlayerStats
      if (_playerStats != null && _playerStats!.heatmapPositions.isNotEmpty) {
        setState(() {
          _heatmapPositions = _playerStats!.heatmapPositions;
          _isUsingRealHeatmapData = true;
        });
        print(
            '✅ Using heatmap from PlayerStats: ${_heatmapPositions.length} touches');
        return;
      }

      setState(() {
        _heatmapPositions = _generateRealisticHeatmap();
        _isUsingRealHeatmapData = false;
      });
      return;
    }

    setState(() => _isLoadingHeatmap = true);

    try {
      final apiService = ApiService();
      final positions = await apiService.fetchPlayerHeatmap(
        widget.match.id,
        widget.playerId!,
      );

      if (positions.isNotEmpty) {
        setState(() {
          _heatmapPositions = positions;
          _isUsingRealHeatmapData = true;
          _isLoadingHeatmap = false;
        });
        print('✅ Using REAL heatmap data: ${positions.length} touches');
      } else {
        // ⭐ Fallback a PlayerStats se API fallisce
        if (_playerStats != null && _playerStats!.heatmapPositions.isNotEmpty) {
          setState(() {
            _heatmapPositions = _playerStats!.heatmapPositions;
            _isUsingRealHeatmapData = true;
            _isLoadingHeatmap = false;
          });
        } else {
          setState(() {
            _heatmapPositions = _generateRealisticHeatmap();
            _isUsingRealHeatmapData = false;
            _isLoadingHeatmap = false;
          });
        }
        print('ℹ️ Using MOCK heatmap data');
      }
    } catch (e) {
      // ⭐ Fallback a PlayerStats
      if (_playerStats != null && _playerStats!.heatmapPositions.isNotEmpty) {
        setState(() {
          _heatmapPositions = _playerStats!.heatmapPositions;
          _isUsingRealHeatmapData = true;
          _isLoadingHeatmap = false;
        });
      } else {
        setState(() {
          _heatmapPositions = _generateRealisticHeatmap();
          _isUsingRealHeatmapData = false;
          _isLoadingHeatmap = false;
        });
      }
      print('⚠️ Heatmap API error: $e');
    }
  }

  Future<void> _loadMatchEvents() async {
    setState(() => _isLoadingEvents = true);

    try {
      final apiService = ApiService();
      final events = await apiService.fetchMatchEvents(widget.match.id);

      if (events.isNotEmpty) {
        final playerEvents = events.where((event) {
          final playerName = event['player']?['name'] ?? '';
          final assistName = event['assist']?['name'] ?? '';
          return playerName.toLowerCase() == widget.playerName.toLowerCase() ||
              assistName.toLowerCase() == widget.playerName.toLowerCase();
        }).toList();

        setState(() {
          _matchEvents = playerEvents;
          _isUsingRealEventsData = playerEvents.isNotEmpty;
          _isLoadingEvents = false;
        });
        print(
            '✅ Loaded ${playerEvents.length} real events for ${widget.playerName}');
      } else {
        setState(() {
          _matchEvents = [];
          _isUsingRealEventsData = false;
          _isLoadingEvents = false;
        });
        print('ℹ️ No events data from API');
      }
    } catch (e) {
      setState(() {
        _matchEvents = [];
        _isUsingRealEventsData = false;
        _isLoadingEvents = false;
      });
      print('⚠️ Events API error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _replayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildTabBar(isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMatchStatsTab(isDark),
                _buildSeasonStatsTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.teamColor, widget.teamColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _notificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_none,
                  color: Colors.white,
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  _showNotificationDialog();
                },
              ),
              IconButton(
                icon: const Icon(Icons.star_border, color: Colors.white),
                onPressed: () => _haptic.lightImpact(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playerName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${widget.playerNumber} • ${widget.teamName}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.match.homeTeamName} ${widget.match.homeScore} - ${widget.match.awayScore} ${widget.match.awayTeamName}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      color: isDark ? Colors.grey[850] : Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: widget.teamColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: widget.teamColor,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 18),
                SizedBox(width: 8),
                Text(tr(context, 'Questa Partita'), style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 18),
                SizedBox(width: 8),
                Text(tr(context, 'Stagione'), style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStatsTab(bool isDark) {
    // ⭐ USA DATI VERI se disponibili
    final stats = _playerStats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRatingCard(isDark),
          SizedBox(height: 16),
          _buildMatchInfoCard(isDark),
          SizedBox(height: 16),
          _buildStatsCard(tr(context, 'Statistiche Partita'), isDark, [
            _buildStatRow(
                tr(context, 'Minuti giocati'), '${stats?.minutesPlayed ?? 90}\'', isDark),
            _buildStatRow(tr(context, 'Goal'), '${stats?.goals ?? 1}', isDark),
            _buildStatRow(tr(context, 'Assist'), '${stats?.assists ?? 0}', isDark),
            _buildStatRow('xG (Expected Goals)', '0.82', isDark,
                isHighlight: true),
            _buildStatRow('xA (Expected Assists)', '0.14', isDark,
                isHighlight: true),
            _buildStatRow(tr(context, 'Tiri'), '${stats?.shots.length ?? 4}', isDark),
            _buildStatRow(
                tr(context, 'Tiri in porta'), '${stats?.shotsOnTarget ?? 2}', isDark),
            _buildStatRow(
                tr(context, 'Passaggi'),
                '${stats?.accuratePasses ?? 45}/${stats?.totalPasses ?? 52}',
                isDark),
            _buildStatRow(
                tr(context, 'Precisione passaggi'),
                '${stats != null && stats.totalPasses > 0 ? ((stats.accuratePasses / stats.totalPasses * 100).toStringAsFixed(0)) : "87"}%',
                isDark),
            _buildStatRow(
                tr(context, 'Dribbling'),
                '${stats?.successfulDribbles ?? 3}/${(stats?.successfulDribbles ?? 3) + (stats?.failedDribbles ?? 2)}',
                isDark),
            _buildStatRow(
                tr(context, 'Duelli vinti'),
                '${stats?.duelsWon ?? 7}/${(stats?.duelsWon ?? 7) + (stats?.duelsLost ?? 5)}',
                isDark),
            _buildStatRow(tr(context, 'Contrasti'), '${stats?.tackles ?? 2}', isDark),
            _buildStatRow(tr(context, 'Intercetti'), '${stats?.interceptions ?? 1}', isDark),
            _buildStatRow(tr(context, 'Fuorigioco'), '1', isDark),
            _buildStatRow(
                tr(context, 'Falli fatti'), '${stats?.foulsCommitted ?? 2}', isDark),
            _buildStatRow(tr(context, 'Falli subiti'), '${stats?.foulsDrawn ?? 3}', isDark),
          ]),
          const SizedBox(height: 16),
          _buildHeatmapSection(isDark),
          const SizedBox(height: 16),
          _buildEventsMapSection(isDark),
          const SizedBox(height: 16),
          RadarPerformanceWidget(
            teamColor: widget.teamColor,
            isDark: isDark,
            playerName: widget.playerName,
          ),
          MatchTimelineWidget(
            teamColor: widget.teamColor,
            isDark: isDark,
            playerName: widget.playerName,
          ),
          ColoredStatsBarWidget(
            teamColor: widget.teamColor,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              _haptic.lightImpact();
              setState(() => _heatmapExpanded = !_heatmapExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.teamColor.withOpacity(0.2),
                          widget.teamColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.grid_on, color: widget.teamColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'Heatmap'),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          tr(context, 'Zone di presenza in campo'),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _heatmapExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_heatmapExpanded) ...[
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.teamColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.arrow_back,
                                size: 20, color: widget.teamColor),
                            const SizedBox(width: 8),
                            Text(
                              tr(context, 'Direzione di gioco'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: widget.teamColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isLoadingHeatmap)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isUsingRealHeatmapData
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isUsingRealHeatmapData
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isUsingRealHeatmapData
                                ? Icons.cloud_done
                                : Icons.memory,
                            size: 16,
                            color: _isUsingRealHeatmapData
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isUsingRealHeatmapData
                                ? 'Dati reali API (${_heatmapPositions.length} tocchi)'
                                : tr(context, 'Dati simulati (upgrade Premium per dati reali)'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isUsingRealHeatmapData
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: _isLoadingHeatmap
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: widget.teamColor),
                                SizedBox(height: 12),
                                Text(
                                  tr(context, 'Caricamento dati...'),
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CustomPaint(
                                painter: CompleteFieldHeatmapPainter(
                                  positions: _heatmapPositions,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildHeatmapLegend(isDark),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeatmapLegend(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'Intensità presenza:'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF4CAF50),
                        Color(0xFFCDDC39),
                        Color(0xFFFFEB3B),
                        Color(0xFFFF9800),
                        Color(0xFFFF5722),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tr(context, 'Bassa'),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              Text(tr(context, 'Alta'),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MAPPA EVENTI CON REPLAY ANIMATO E DETTAGLI TAP
  // ============================================================================
  Widget _buildEventsMapSection(bool isDark) {
    final events = _getStatsData();
    final hasEvents = events is List && events.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              _haptic.lightImpact();
              setState(() => _statsMapExpanded = !_statsMapExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.teamColor.withOpacity(0.2),
                          widget.teamColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.show_chart,
                        color: widget.teamColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(context, 'Mappa Eventi'),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getEventsMapSubtitle(),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _statsMapExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          if (_statsMapExpanded) ...[
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Filtri tipo eventi
                  Row(
                    children: [
                      _buildStatsTypeChip('Shot', Icons.sports_soccer, isDark),
                      const SizedBox(width: 8),
                      _buildStatsTypeChip('Pass', Icons.compare_arrows, isDark),
                      const SizedBox(width: 8),
                      _buildStatsTypeChip('Drib', Icons.directions_run, isDark),
                      const SizedBox(width: 8),
                      _buildStatsTypeChip('Def', Icons.shield, isDark),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filtri accuratezza/risultato
                  if (_selectedStatsType == 'Pass' ||
                      _selectedStatsType == 'Shot' ||
                      _selectedStatsType == 'Drib') ...[
                    Row(
                      children: [
                        _buildAccuracyChip('Tutti', isDark),
                        const SizedBox(width: 8),
                        _buildAccuracyChip(
                            _selectedStatsType == 'Shot'
                                ? tr(context, 'Tiri in porta')
                                : _selectedStatsType == 'Drib'
                                    ? 'Riuscito'
                                    : 'Accurato',
                            isDark),
                        const SizedBox(width: 8),
                        _buildAccuracyChip(
                            _selectedStatsType == 'Shot'
                                ? tr(context, 'Tiri fuori')
                                : _selectedStatsType == 'Drib'
                                    ? 'Fallito'
                                    : 'Non accurato',
                            isDark),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 4),

                  // LEGENDA COLORI (per Shot)
                  if (_selectedStatsType == 'Shot' && hasEvents) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLegendItem('🟢', 'Goal', Colors.green, isDark),
                          const SizedBox(width: 16),
                          _buildLegendItem(
                              '🟡', 'Parato', Colors.amber, isDark),
                          const SizedBox(width: 16),
                          _buildLegendItem('🔴', 'Fuori', Colors.red, isDark),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // STATISTICHE RIASSUNTIVE (per Shot)
                  if (_selectedStatsType == 'Shot' && hasEvents) ...[
                    _buildShotStatistics(isDark),
                    const SizedBox(height: 12),
                  ],

                  // Indicatore dati
                  if (!_isLoadingEvents)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (_playerStats != null)
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (_playerStats != null)
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (_playerStats != null)
                                ? Icons.cloud_done
                                : Icons.memory,
                            size: 16,
                            color: (_playerStats != null)
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            (_playerStats != null)
                                ? 'Dati reali MatchDataService'
                                : tr(context, 'Dati simulati (attendi dati partita reale)'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: (_playerStats != null)
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // REPLAY CONTROLS
                  if (hasEvents) _buildReplayControls(isDark),

                  // Campo con eventi
                  AspectRatio(
                    aspectRatio: 1.4,
                    child: _isLoadingEvents
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: widget.teamColor),
                                SizedBox(height: 12),
                                Text(
                                  tr(context, 'Caricamento eventi...'),
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTapUp: (details) =>
                                _handleMapTap(details, events),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CustomPaint(
                                  painter: AnimatedStatsMapPainter(
                                    type: _selectedStatsType,
                                    data: events,
                                    isDark: isDark,
                                    replayIndex:
                                        _isReplaying ? _currentReplayIndex : -1,
                                    animation: _replayController,
                                    selectedEvent: _selectedEvent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // REPLAY CONTROLS
  Widget _buildReplayControls(bool isDark) {
    final events = _getStatsData();
    final eventCount = events is List ? events.length : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.teamColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button
              Material(
                color: widget.teamColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _haptic.lightImpact();
                    _toggleReplay();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      _isReplaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Progress info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.movie_filter,
                            size: 16, color: widget.teamColor),
                        const SizedBox(width: 6),
                        Text(
                          _isReplaying
                              ? tr(context, 'Replay in corso...') + ' (${_currentReplayIndex + 1}/$eventCount)'
                              : tr(context, 'Replay eventi') + ' ($eventCount)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    if (_isReplaying) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: eventCount > 0
                              ? (_currentReplayIndex + 1) / eventCount
                              : 0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(widget.teamColor),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Speed control
              Material(
                color: isDark ? Colors.grey[700] : Colors.white,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    _haptic.lightImpact();
                    _changePlaybackSpeed();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed, size: 16, color: widget.teamColor),
                        const SizedBox(width: 4),
                        Text(
                          '${_playbackSpeed}x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.teamColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFieldZoneName(Offset position) {
    String verticalZone;
    if (position.dx < 0.25) {
      verticalZone = tr(context, 'Area Difensiva');
    } else if (position.dx < 0.45) {
      verticalZone = tr(context, 'Trequarti Difensiva');
    } else if (position.dx < 0.60) {
      verticalZone = tr(context, 'Centrocampo');
    } else if (position.dx < 0.82) {
      verticalZone = tr(context, 'Trequarti Offensiva');
    } else {
      verticalZone = tr(context, 'Area di Rigore Offensiva');
    }

    String horizontalZone;
    if (position.dy < 0.33) {
      horizontalZone = tr(context, 'Fascia Sinistra');
    } else if (position.dy < 0.67) {
      horizontalZone = tr(context, 'Centro');
    } else {
      horizontalZone = tr(context, 'Fascia Destra');
    }

    return '$verticalZone - $horizontalZone';
  }

  void _handleMapTap(TapUpDetails details, dynamic events) {
    if (events is! List || events.isEmpty) return;

    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = details.localPosition;
    final size = box.size;

    final tapX = localPosition.dx / size.width;
    final tapY = localPosition.dy / size.height;
    final tapPos = Offset(tapX, tapY);

    print('🔍 TAP at position: ($tapX, $tapY)');

    double minDistance = double.infinity;
    dynamic closestEvent;
    int closestIndex = -1;

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      double distance;

      if (event is PMShotData) {
        final dx = tapX - event.position.dx;
        final dy = tapY - event.position.dy;
        distance = math.sqrt(dx * dx + dy * dy);
        if (distance < 0.15) {
          print(
              '  Shot #$i: type=${event.isGoal ? "Goal" : (event.onTarget ? "OnTarget" : "OffTarget")}, distance=$distance');
        }
      } else if (event is PMPassData) {
        distance = _distanceToLine(tapPos, event.from, event.to);
        if (distance < 0.1) {
          print(
              '  Pass #$i: isAccurate=${event.isAccurate}, distance=$distance');
        }
      } else if (event is PMDribbleData) {
        distance = _distanceToLine(tapPos, event.from, event.to);
      } else if (event is PMDefenseData) {
        final dx = tapX - event.position.dx;
        final dy = tapY - event.position.dy;
        distance = math.sqrt(dx * dx + dy * dy);
      } else {
        continue;
      }

      if (distance < minDistance) {
        minDistance = distance;
        closestEvent = event;
        closestIndex = i;
      }
    }

    if (closestEvent != null) {
      print('🎯 Closest event: #$closestIndex, distance: $minDistance');
    }

    final threshold =
        (closestEvent is PMPassData || closestEvent is PMDribbleData)
            ? 0.03
            : 0.35;

    if (closestEvent != null && minDistance < threshold) {
      _showEventDetails(closestEvent,
          isDark: Theme.of(context).brightness == Brightness.dark);
    } else {
      print(
          '❌ No event found (min distance: $minDistance, threshold: $threshold)');
    }
  }

  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final dx = lineEnd.dx - lineStart.dx;
    final dy = lineEnd.dy - lineStart.dy;

    if (dx == 0 && dy == 0) {
      final pdx = point.dx - lineStart.dx;
      final pdy = point.dy - lineStart.dy;
      return math.sqrt(pdx * pdx + pdy * pdy);
    }

    final t =
        ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
            (dx * dx + dy * dy);

    final tClamped = t.clamp(0.0, 1.0);

    final closestX = lineStart.dx + tClamped * dx;
    final closestY = lineStart.dy + tClamped * dy;

    final pdx = point.dx - closestX;
    final pdy = point.dy - closestY;
    return math.sqrt(pdx * pdx + pdy * pdy);
  }

  void _showEventDetails(dynamic event, {required bool isDark}) {
    _haptic.lightImpact();

    String title = '';
    List<Widget> details = [];
    Color accentColor = widget.teamColor;

    if (event is PMShotData) {
      print(
          '📋 _showEventDetails: Shot event - isGoal=${event.isGoal}, onTarget=${event.onTarget}');

      final zoneName = _getFieldZoneName(event.position);
      final minute = (15 + (event.position.dx * 60).toInt()).toString();

      if (event.isGoal) {
        print('   → Branch: GOAL (verde)');
        title = '⚽ GOAL!';
        accentColor = Colors.green;

        final hasAssist = math.Random().nextBool();
        final assistName = hasAssist ? 'Rovella' : null;

        details = [
          _buildDetailRow(Icons.person, 'Segnato da', widget.playerName),
          _buildDetailRow(Icons.place, tr(context, 'Zona campo'), zoneName),
          if (assistName != null)
            _buildDetailRow(Icons.sports_soccer, 'Assist', assistName),
          _buildDetailRow(Icons.access_time, 'Minuto', '$minute\''),
        ];
      } else if (event.onTarget) {
        print('   → Branch: IN PORTA (giallo)');
        title = '🧤 Tiro in Porta';
        accentColor = Colors.orange;

        final goalkeeperName = 'Maignan';

        details = [
          _buildDetailRow(Icons.person, 'Tiro di', widget.playerName),
          _buildDetailRow(Icons.back_hand, 'Parato da', goalkeeperName),
          _buildDetailRow(Icons.place, tr(context, 'Zona campo'), zoneName),
          _buildDetailRow(Icons.access_time, 'Minuto', '$minute\''),
        ];
      } else {
        print('   → Branch: FUORI (rosso)');
        title = '❌ Tiro Fuori';
        accentColor = Colors.red;

        details = [
          _buildDetailRow(Icons.person, 'Tiro di', widget.playerName),
          _buildDetailRow(Icons.warning, 'Esito', 'Tiro fuori porta'),
          _buildDetailRow(Icons.place, tr(context, 'Zona campo'), zoneName),
          _buildDetailRow(Icons.access_time, 'Minuto', '$minute\''),
        ];
      }
    } else if (event is PMPassData) {
      title = tr(context, '⚽ Passaggio');
      accentColor = event.isAccurate ? Colors.green : Colors.red;

      final distance = math.sqrt(math.pow(event.to.dx - event.from.dx, 2) +
          math.pow(event.to.dy - event.from.dy, 2));

      final fromZone = _getFieldZoneName(event.from);
      final toZone = _getFieldZoneName(event.to);

      details = [
        _buildDetailRow(Icons.person, tr(context, 'Passaggio di'), widget.playerName),
        _buildDetailRow(Icons.timeline, 'Esito',
            event.isAccurate ? 'Passaggio riuscito' : tr(context, 'Passaggio sbagliato')),
        _buildDetailRow(
            Icons.straighten, 'Distanza', '~${(distance * 50).toInt()} metri'),
        _buildDetailRow(Icons.place, 'Da zona', fromZone),
        _buildDetailRow(Icons.location_on, 'Verso zona', toZone),
      ];
    } else if (event is PMDribbleData) {
      title = tr(context, '🏃 Dribbling');
      accentColor = event.successful ? Colors.purple : Colors.orange;

      final fromZone = _getFieldZoneName(event.from);
      final toZone = _getFieldZoneName(event.to);

      details = [
        _buildDetailRow(Icons.person, tr(context, 'Dribbling di'), widget.playerName),
        _buildDetailRow(Icons.check_circle, 'Esito',
            event.successful ? 'Riuscito' : 'Fallito'),
        _buildDetailRow(Icons.place, tr(context, 'Zona inizio'), fromZone),
        _buildDetailRow(Icons.location_on, tr(context, 'Zona fine'), toZone),
      ];
    } else if (event is PMDefenseData) {
      title = '🛡️ Azione Difensiva';
      accentColor = event.successful ? Colors.blue : Colors.grey;

      String typeLabel = '';
      switch (event.type) {
        case PMDefenseType.tackle:
          typeLabel = 'Contrasto';
          break;
        case PMDefenseType.interception:
          typeLabel = 'Intercetto';
          break;
        case PMDefenseType.clearance:
          typeLabel = 'Rinvio';
          break;
      }

      final zoneName = _getFieldZoneName(event.position);

      details = [
        _buildDetailRow(Icons.person, 'Azione di', widget.playerName),
        _buildDetailRow(Icons.shield, 'Tipo azione', typeLabel),
        _buildDetailRow(Icons.check_circle, 'Esito',
            event.successful ? 'Riuscito' : 'Fallito'),
        _buildDetailRow(Icons.place, 'Zona campo', zoneName),
      ];
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.info_outline, color: accentColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...details,
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tr(context, 'Chiudi'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: widget.teamColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getEventsMapSubtitle() {
    switch (_selectedStatsType) {
      case 'Shot':
        return tr(context, 'Tiri e conclusioni in tempo reale');
      case 'Pass':
        return tr(context, 'Passaggi e assist della partita');
      case 'Drib':
        return tr(context, 'Dribbling e conduzioni effettuate');
      case 'Def':
        return 'Azioni difensive registrate';
      default:
        return 'Visualizzazione eventi partita';
    }
  }

  Widget _buildStatsTypeChip(String label, IconData icon, bool isDark) {
    final isSelected = _selectedStatsType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _haptic.lightImpact();
          setState(() {
            _selectedStatsType = label;
            _selectedAccuracy = 'Tutti';
            _stopReplay();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      widget.teamColor,
                      widget.teamColor.withOpacity(0.8),
                    ],
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.teamColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracyChip(String label, bool isDark) {
    final isSelected = _selectedAccuracy == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _haptic.lightImpact();
          setState(() {
            _selectedAccuracy = label;
            _stopReplay();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.teamColor
                : (isDark ? Colors.grey[800] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tr(context, label),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      String emoji, String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildShotStatistics(bool isDark) {
    final shots = _generateMockShots();
    final totalShots = shots.length;
    final goals = shots.where((s) => s.isGoal).length;
    final onTarget = shots.where((s) => s.onTarget && !s.isGoal).length;
    final offTarget = shots.where((s) => !s.onTarget).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStatItem('📊', '$totalShots', 'Totali', isDark),
          Container(width: 1, height: 20, color: Colors.grey[400]),
          _buildCompactStatItem('🟢', '$goals', 'Goal', isDark),
          Container(width: 1, height: 20, color: Colors.grey[400]),
          _buildCompactStatItem('🟡', '$onTarget', 'Parati', isDark),
          Container(width: 1, height: 20, color: Colors.grey[400]),
          _buildCompactStatItem('🔴', '$offTarget', 'Fuori', isDark),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(
      String emoji, String value, String label, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  // ⭐ MODIFICATO: Usa dati da PlayerMatchStats quando disponibili
  dynamic _getStatsData() {
    if (_playerStats != null) {
      // ✅ USA DATI VERI da PlayerMatchStats!
      if (_selectedStatsType == 'Shot') {
        final shots = _playerStats!.shots
            .map((shot) => PMShotData(
                  position: shot.position,
                  onTarget: shot.onTarget,
                  isGoal: shot.isGoal,
                ))
            .toList();

        if (_selectedAccuracy == tr(context, 'Tiri in porta') ||
            _selectedAccuracy == 'Accurato') {
          return shots.where((s) => s.onTarget).toList();
        } else if (_selectedAccuracy == tr(context, 'Tiri fuori') ||
            _selectedAccuracy == 'Non accurato') {
          return shots.where((s) => !s.onTarget).toList();
        }
        return shots;
      } else if (_selectedStatsType == 'Pass') {
        final passes = _playerStats!.passes
            .map((pass) => PMPassData(
                  from: pass.from,
                  to: pass.to,
                  isAccurate: pass.isAccurate,
                ))
            .toList();

        if (_selectedAccuracy == 'Accurato') {
          return passes.where((p) => p.isAccurate).toList();
        } else if (_selectedAccuracy == 'Non accurato') {
          return passes.where((p) => !p.isAccurate).toList();
        }
        return passes;
      } else if (_selectedStatsType == 'Drib') {
        final dribbles = _playerStats!.dribbles
            .map((dribble) => PMDribbleData(
                  from: dribble.from,
                  to: dribble.to,
                  successful: dribble.successful,
                ))
            .toList();

        if (_selectedAccuracy == 'Riuscito') {
          return dribbles.where((d) => d.successful).toList();
        } else if (_selectedAccuracy == 'Fallito') {
          return dribbles.where((d) => !d.successful).toList();
        }
        return dribbles;
      }
    }

    // Fallback a mock se PlayerStats non disponibili
    if (_isUsingRealEventsData && _matchEvents.isNotEmpty) {
      return _parseRealEventsForType(_selectedStatsType);
    }

    if (_selectedStatsType == 'Pass') {
      final passes = _generateMockPasses();
      if (_selectedAccuracy == 'Accurato') {
        return passes.where((p) => p.isAccurate).toList();
      } else if (_selectedAccuracy == 'Non accurato') {
        return passes.where((p) => !p.isAccurate).toList();
      }
      return passes;
    } else if (_selectedStatsType == 'Shot') {
      final shots = _generateMockShots();
      if (_selectedAccuracy == tr(context, 'Tiri in porta') ||
          _selectedAccuracy == 'Accurato') {
        return shots.where((s) => s.onTarget).toList();
      } else if (_selectedAccuracy == tr(context, 'Tiri fuori') ||
          _selectedAccuracy == 'Non accurato') {
        return shots.where((s) => !s.onTarget).toList();
      }
      return shots;
    } else if (_selectedStatsType == 'Drib') {
      final dribbles = _generateMockDribbles();
      if (_selectedAccuracy == 'Riuscito') {
        return dribbles.where((d) => d.successful).toList();
      } else if (_selectedAccuracy == 'Fallito') {
        return dribbles.where((d) => !d.successful).toList();
      }
      return dribbles;
    } else if (_selectedStatsType == 'Def') {
      return _generateMockDefenseActions();
    }
    return [];
  }

  dynamic _parseRealEventsForType(String type) {
    return [];
  }

  List<PMPassData> _generateMockPasses() {
    final random = math.Random(42);
    return List.generate(35, (index) {
      final fromX = 0.2 + random.nextDouble() * 0.6;
      final fromY = 0.2 + random.nextDouble() * 0.6;
      final toX = (fromX + (random.nextDouble() - 0.5) * 0.4).clamp(0.1, 0.9);
      final toY = (fromY + (random.nextDouble() - 0.5) * 0.4).clamp(0.1, 0.9);
      final isAccurate = random.nextDouble() > 0.15;
      return PMPassData(
        from: Offset(fromX, fromY),
        to: Offset(toX, toY),
        isAccurate: isAccurate,
      );
    });
  }

  // ⭐ MODIFICATO: Usa dati veri se disponibili, altrimenti mock
  List<PMShotData> _generateMockShots() {
    if (_playerStats != null && _playerStats!.shots.isNotEmpty) {
      print(
          '🎯 Using REAL shots from PlayerStats: ${_playerStats!.shots.length} shots');
      return _playerStats!.shots
          .map((shot) => PMShotData(
                position: shot.position,
                onTarget: shot.onTarget,
                isGoal: shot.isGoal,
              ))
          .toList();
    }

    // Fallback a mock
    print('⚠️ Using MOCK shots');
    return [
      PMShotData(
        position: const Offset(0.55, 0.52),
        onTarget: true,
        isGoal: true,
      ),
      PMShotData(
        position: const Offset(0.71, 0.48),
        onTarget: true,
        isGoal: false,
      ),
      PMShotData(
        position: const Offset(0.88, 0.20),
        onTarget: false,
        isGoal: false,
      ),
      PMShotData(
        position: const Offset(0.88, 0.78),
        onTarget: false,
        isGoal: false,
      ),
    ];
  }

  List<PMDribbleData> _generateMockDribbles() {
    final random = math.Random(42);
    return List.generate(5, (index) {
      final fromX = 0.3 + random.nextDouble() * 0.4;
      final fromY = 0.2 + random.nextDouble() * 0.6;
      final toX = (fromX + 0.05 + random.nextDouble() * 0.1).clamp(0.1, 0.9);
      final toY = (fromY + (random.nextDouble() - 0.5) * 0.15).clamp(0.1, 0.9);
      final successful = index < 3;
      return PMDribbleData(
        from: Offset(fromX, fromY),
        to: Offset(toX, toY),
        successful: successful,
      );
    });
  }

  List<PMDefenseData> _generateMockDefenseActions() {
    final random = math.Random(42);
    return List.generate(6, (index) {
      final x = 0.2 + random.nextDouble() * 0.5;
      final y = 0.2 + random.nextDouble() * 0.6;
      final types = [
        PMDefenseType.tackle,
        PMDefenseType.interception,
        PMDefenseType.clearance
      ];
      return PMDefenseData(
        position: Offset(x, y),
        type: types[index % types.length],
        successful: random.nextDouble() > 0.3,
      );
    });
  }

  List<Offset> _generateRealisticHeatmap() {
    final random = math.Random(42);
    final positions = <Offset>[];

    for (int i = 0; i < 45; i++) {
      positions.add(Offset(
        0.58 + random.nextDouble() * 0.20,
        0.10 + random.nextDouble() * 0.22,
      ));
    }

    for (int i = 0; i < 38; i++) {
      positions.add(Offset(
        0.68 + random.nextDouble() * 0.16,
        0.16 + random.nextDouble() * 0.24,
      ));
    }

    for (int i = 0; i < 32; i++) {
      positions.add(Offset(
        0.76 + random.nextDouble() * 0.14,
        0.22 + random.nextDouble() * 0.22,
      ));
    }

    for (int i = 0; i < 28; i++) {
      positions.add(Offset(
        0.48 + random.nextDouble() * 0.18,
        0.14 + random.nextDouble() * 0.24,
      ));
    }

    for (int i = 0; i < 25; i++) {
      positions.add(Offset(
        0.60 + random.nextDouble() * 0.18,
        0.30 + random.nextDouble() * 0.20,
      ));
    }

    for (int i = 0; i < 18; i++) {
      positions.add(Offset(
        0.84 + random.nextDouble() * 0.10,
        0.18 + random.nextDouble() * 0.20,
      ));
    }

    for (int i = 0; i < 16; i++) {
      positions.add(Offset(
        0.38 + random.nextDouble() * 0.16,
        0.16 + random.nextDouble() * 0.24,
      ));
    }

    for (int i = 0; i < 14; i++) {
      positions.add(Offset(
        0.50 + random.nextDouble() * 0.14,
        0.08 + random.nextDouble() * 0.18,
      ));
    }

    for (int i = 0; i < 12; i++) {
      positions.add(Offset(
        0.72 + random.nextDouble() * 0.14,
        0.36 + random.nextDouble() * 0.18,
      ));
    }

    for (int i = 0; i < 10; i++) {
      positions.add(Offset(
        0.32 + random.nextDouble() * 0.14,
        0.20 + random.nextDouble() * 0.20,
      ));
    }

    return positions;
  }

  Widget _buildSeasonStatsTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatsCard(tr(context, 'Statistiche Stagionali'), isDark, [
            _buildStatRow(tr(context, 'Presenze'), '25', isDark),
            _buildStatRow(tr(context, 'Goal'), '8', isDark),
            _buildStatRow(tr(context, 'Assist'), '5', isDark),
            _buildStatRow(tr(context, 'Minuti giocati'), '2.100', isDark),
            _buildStatRow(tr(context, 'Media voto'), '7.5', isDark),
            _buildStatRow(tr(context, 'Cartellini gialli'), '2', isDark),
            _buildStatRow(tr(context, 'Cartellini rossi'), '0', isDark),
          ]),
          const SizedBox(height: 16),
          _buildStatsCard(tr(context, 'Ultimi 5 Match'), isDark, [
            _buildFormRow(['7.5', '8.0', '6.8', '7.9', '7.2'], isDark),
          ]),
        ],
      ),
    );
  }

  Widget _buildRatingCard(bool isDark) {
    // ⭐ USA RATING VERO
    final rating = _playerStats?.rating ?? 7.8;
    final minutes = _playerStats?.minutesPlayed ?? 90;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.teamColor, widget.teamColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.teamColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(tr(context, 'Valutazione'),
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.teamColor,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 2,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
          Column(
            children: [
              Text(tr(context, 'Minuti'),
                  style: TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 8),
              Text('$minutes\'',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: widget.teamColor, size: 20),
              SizedBox(width: 8),
              Text(tr(context, 'Informazioni Partita'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow(tr(context, 'Competizione'), 'Serie A', isDark),
          const SizedBox(height: 8),
          _buildInfoRow(tr(context, 'Data'), '21 Gennaio 2026', isDark),
          const SizedBox(height: 8),
          _buildInfoRow(tr(context, 'Stadio'), 'Stadio Olimpico', isDark),
        ],
      ),
    );
  }

  Widget _buildStatsCard(String title, bool isDark, List<Widget> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...stats,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: isHighlight
                      ? (isDark ? Colors.purple[300] : Colors.purple[700])
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isHighlight) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('NEW',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple)),
                ),
              ],
            ],
          ),
          Container(
            padding: isHighlight
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                : EdgeInsets.zero,
            decoration: isHighlight
                ? BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.purple.withOpacity(0.3), width: 1),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.purple : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFormRow(List<String> ratings, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: ratings.map((rating) {
        final ratingValue = double.parse(rating);
        Color color;
        if (ratingValue >= 7.5) {
          color = Colors.green;
        } else if (ratingValue >= 6.5) {
          color = Colors.orange;
        } else {
          color = Colors.red;
        }
        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              rating,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showNotificationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.notifications, color: widget.teamColor),
            SizedBox(width: 12),
            Text(tr(context, 'Notifiche Giocatore')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationOption(tr(context, 'Goal segnati'), true, isDark),
              _buildNotificationOption(tr(context, 'Assist forniti'), true, isDark),
              _buildNotificationOption(tr(context, 'Cartellino giallo'), false, isDark),
              _buildNotificationOption(tr(context, 'Cartellino rosso'), false, isDark),
              _buildNotificationOption(tr(context, 'Tiri totali'), true, isDark),
              _buildNotificationOption(tr(context, 'Tiri in porta'), true, isDark),
              _buildNotificationOption(tr(context, 'Falli fatti'), false, isDark),
              _buildNotificationOption(tr(context, 'Falli subiti'), false, isDark),
              _buildNotificationOption(tr(context, 'Fuorigioco'), false, isDark),
              _buildNotificationOption(
                  tr(context, 'Voto fine primo tempo (Fantacalcio)'), true, isDark),
              _buildNotificationOption(
                  tr(context, 'Voto finale partita (Fantacalcio)'), true, isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Annulla')),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _notificationsEnabled = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${tr(context, 'Notifiche attivate per')} ${widget.playerName}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.teamColor,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'Salva')),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(String label, bool enabled, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 14, color: isDark ? Colors.white : Colors.black87),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {},
            activeColor: widget.teamColor,
          ),
        ],
      ),
    );
  }
}

// DATA MODELS (mantieni invariati)
class PMPassData {
  final Offset from;
  final Offset to;
  final bool isAccurate;
  PMPassData({required this.from, required this.to, required this.isAccurate});
}

class PMShotData {
  final Offset position;
  final bool onTarget;
  final bool isGoal;
  PMShotData(
      {required this.position, required this.onTarget, required this.isGoal});
}

class PMDribbleData {
  final Offset from;
  final Offset to;
  final bool successful;
  PMDribbleData(
      {required this.from, required this.to, required this.successful});
}

enum PMDefenseType { tackle, interception, clearance }

class PMDefenseData {
  final Offset position;
  final PMDefenseType type;
  final bool successful;
  PMDefenseData(
      {required this.position, required this.type, required this.successful});
}

// HEATMAP PAINTER (mantieni invariato - TUTTO IL TUO CODICE)
class CompleteFieldHeatmapPainter extends CustomPainter {
  final List<Offset> positions;
  final bool isDark;

  CompleteFieldHeatmapPainter({required this.positions, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    _drawField(canvas, size);
    _drawHeatmap(canvas, size);
  }

  void _drawField(Canvas canvas, Size size) {
    final fieldPaint = Paint()..color = const Color(0xFFB8E6B8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final margin = 8.0;

    canvas.drawRect(
      Rect.fromLTWH(
          margin, margin, size.width - margin * 2, size.height - margin * 2),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width / 2, margin),
      Offset(size.width / 2, size.height - margin),
      linePaint,
    );

    final centerCircleRadius = size.width * 0.0915;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      centerCircleRadius,
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    final penaltyWidth = size.width * 0.165;
    final penaltyHeight = size.height * 0.42;
    final penaltyY = (size.height - penaltyHeight) / 2;

    canvas.drawRect(
      Rect.fromLTWH(margin, penaltyY, penaltyWidth, penaltyHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - margin - penaltyWidth, penaltyY, penaltyWidth,
          penaltyHeight),
      linePaint,
    );

    final penaltySpotDist = size.width * 0.11;
    final leftPenaltyX = margin + penaltySpotDist;
    final rightPenaltyX = size.width - margin - penaltySpotDist;
    final penaltySpotY = size.height / 2;
    final arcRadius = size.width * 0.0915;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(leftPenaltyX, penaltySpotY),
        radius: arcRadius,
      ),
      -0.9273,
      1.8546,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(rightPenaltyX, penaltySpotY),
        radius: arcRadius,
      ),
      math.pi - 0.9273,
      1.8546,
      false,
      linePaint,
    );

    canvas.drawCircle(
      Offset(leftPenaltyX, penaltySpotY),
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(rightPenaltyX, penaltySpotY),
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    final sixYardWidth = size.width * 0.055;
    final sixYardHeight = size.height * 0.19;
    final sixYardY = (size.height - sixYardHeight) / 2;

    canvas.drawRect(
      Rect.fromLTWH(margin, sixYardY, sixYardWidth, sixYardHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - margin - sixYardWidth, sixYardY, sixYardWidth,
          sixYardHeight),
      linePaint,
    );

    final goalPaint = Paint()..color = const Color(0xFF2E7D32);
    final goalWidth = 5.0;
    final goalHeight = size.height * 0.13;
    final goalY = (size.height - goalHeight) / 2;

    canvas.drawRect(
      Rect.fromLTWH(0, goalY, goalWidth, goalHeight),
      goalPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - goalWidth, goalY, goalWidth, goalHeight),
      goalPaint,
    );

    final cornerRadius = size.width * 0.010;

    canvas.drawArc(
      Rect.fromLTWH(
        margin - cornerRadius,
        margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      0,
      math.pi / 2,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        size.width - margin - cornerRadius,
        margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        margin - cornerRadius,
        size.height - margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        size.width - margin - cornerRadius,
        size.height - margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      math.pi,
      math.pi / 2,
      false,
      linePaint,
    );
  }

  void _drawHeatmap(Canvas canvas, Size size) {
    const resolution = 90;
    final densityMap = List.generate(
      resolution,
      (_) => List.filled(resolution, 0.0),
    );

    for (int py = 0; py < resolution; py++) {
      for (int px = 0; px < resolution; px++) {
        final x = px / resolution;
        final y = py / resolution;
        double density = 0.0;

        for (final pos in positions) {
          final dx = x - pos.dx;
          final dy = y - pos.dy;
          final distSq = dx * dx + dy * dy;

          final sigma = 0.028;
          density += math.exp(-distSq / (2 * sigma * sigma));
        }

        densityMap[py][px] = density;
      }
    }

    double maxDensity = 0;
    for (final row in densityMap) {
      for (final d in row) {
        if (d > maxDensity) maxDensity = d;
      }
    }

    for (int py = 0; py < resolution; py++) {
      for (int px = 0; px < resolution; px++) {
        final density = densityMap[py][px] / maxDensity;

        if (density < 0.70) continue;

        final centerX = (px + 0.5) / resolution * size.width;
        final centerY = (py + 0.5) / resolution * size.height;
        final center = Offset(centerX, centerY);

        final pixelSize = size.width / resolution * 1.1;

        Color color;
        double opacity;

        if (density >= 0.95) {
          color = const Color(0xFFE53935);
          opacity = 0.96;
        } else if (density >= 0.88) {
          final t = (density - 0.88) / 0.07;
          color = Color.lerp(
            const Color(0xFFFF5722),
            const Color(0xFFE53935),
            t,
          )!;
          opacity = 0.78 + t * 0.18;
        } else if (density >= 0.80) {
          final t = (density - 0.80) / 0.08;
          color = Color.lerp(
            const Color(0xFFFF9800),
            const Color(0xFFFF5722),
            t,
          )!;
          opacity = 0.65 + t * 0.13;
        } else {
          final t = (density - 0.70) / 0.10;
          color = Color.lerp(
            const Color(0xFFFFEB3B),
            const Color(0xFFFF9800),
            t,
          )!;
          opacity = 0.52 + t * 0.13;
        }

        final paint = Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(center, pixelSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ANIMATED STATS MAP PAINTER (mantieni invariato - TUTTO IL TUO CODICE CON REPLAY)
class AnimatedStatsMapPainter extends CustomPainter {
  final String type;
  final dynamic data;
  final bool isDark;
  final int replayIndex;
  final Animation<double> animation;
  final dynamic selectedEvent;

  AnimatedStatsMapPainter({
    required this.type,
    required this.data,
    required this.isDark,
    required this.replayIndex,
    required this.animation,
    this.selectedEvent,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    _drawField(canvas, size);

    if (data is List && data.isNotEmpty) {
      final events = data as List;

      switch (type) {
        case 'Shot':
          _drawShots(canvas, size, events.cast<PMShotData>());
          break;
        case 'Pass':
          _drawPasses(canvas, size, events.cast<PMPassData>());
          break;
        case 'Drib':
          _drawDribbles(canvas, size, events.cast<PMDribbleData>());
          break;
        case 'Def':
          _drawDefensiveActions(canvas, size, events.cast<PMDefenseData>());
          break;
      }
    }
  }

  void _drawField(Canvas canvas, Size size) {
    final fieldGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2E7D32),
        const Color(0xFF388E3C),
        const Color(0xFF2E7D32)
      ],
    );
    final fieldPaint = Paint()
      ..shader = fieldGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), linePaint);
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), linePaint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.1, linePaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2,
        Paint()..color = Colors.white);

    final penaltyWidth = size.width * 0.16;
    final penaltyHeight = size.height * 0.4;
    canvas.drawRect(
        Rect.fromLTWH(
            4, (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - penaltyWidth - 4,
            (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
        linePaint);

    final sixYardWidth = size.width * 0.06;
    final sixYardHeight = size.height * 0.18;
    canvas.drawRect(
        Rect.fromLTWH(
            4, (size.height - sixYardHeight) / 2, sixYardWidth, sixYardHeight),
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - sixYardWidth - 4,
            (size.height - sixYardHeight) / 2, sixYardWidth, sixYardHeight),
        linePaint);

    final goalPaint = Paint()..color = const Color(0xFF1B5E20);
    final goalWidth = 4.0;
    final goalHeight = size.height * 0.12;
    canvas.drawRect(
        Rect.fromLTWH(0, (size.height - goalHeight) / 2, goalWidth, goalHeight),
        goalPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - goalWidth, (size.height - goalHeight) / 2,
            goalWidth, goalHeight),
        goalPaint);
  }

  void _drawShots(Canvas canvas, Size size, List<PMShotData> shots) {
    print('🎨 PAINTER: Drawing ${shots.length} shots');
    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final color =
          shot.isGoal ? 'VERDE' : (shot.onTarget ? 'GIALLO' : 'ROSSO');
      print(
          '   Shot #$i: isGoal=${shot.isGoal}, onTarget=${shot.onTarget} → Color: $color');
    }

    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final pos =
          Offset(shot.position.dx * size.width, shot.position.dy * size.height);

      late Offset targetPoint;

      if (shot.onTarget || shot.isGoal) {
        final goalY = size.height / 2;
        targetPoint = Offset(size.width - 10, goalY);
      } else {
        final goalCenterY = size.height / 2;
        final goalHeight = size.height * 0.12;
        final goalTop = goalCenterY - goalHeight / 2;
        final goalBottom = goalCenterY + goalHeight / 2;

        final isHighShot = pos.dy < goalCenterY;
        final isWideShot = (pos.dy - goalCenterY).abs() > goalHeight;

        if (isWideShot) {
          if (pos.dy < goalCenterY) {
            targetPoint = Offset(size.width - 5, goalTop - 20);
          } else {
            targetPoint = Offset(size.width - 5, goalBottom + 20);
          }
        } else if (isHighShot) {
          targetPoint = Offset(size.width - 8, goalTop - 15);
        } else {
          targetPoint = Offset(size.width - 8, goalBottom + 15);
        }
      }

      final linePaint = Paint()
        ..color = (shot.isGoal
                ? const Color(0xFF4CAF50)
                : (shot.onTarget
                    ? const Color(0xFFFFEB3B)
                    : const Color(0xFFE53935)))
            .withOpacity(0.7 * opacity)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pos, targetPoint, linePaint);

      final shotPaint = Paint()
        ..color = (shot.isGoal
                ? const Color(0xFF4CAF50)
                : (shot.onTarget
                    ? const Color(0xFFFFEB3B)
                    : const Color(0xFFE53935)))
            .withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, shot.isGoal ? 10 : 8, shotPaint);
      canvas.drawCircle(
          pos,
          shot.isGoal ? 10 : 8,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      if (shot.isGoal) {
        final textStyle = TextStyle(
            color: Colors.white.withOpacity(opacity),
            fontSize: 16,
            fontWeight: FontWeight.bold);
        final textSpan = TextSpan(text: '⚽', style: textStyle);
        final textPainter =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(pos.dx - 8, pos.dy - 8));
      }
    }
  }

  void _drawPasses(Canvas canvas, Size size, List<PMPassData> passes) {
    for (int i = 0; i < passes.length; i++) {
      final pass = passes[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final from =
          Offset(pass.from.dx * size.width, pass.from.dy * size.height);
      final to = Offset(pass.to.dx * size.width, pass.to.dy * size.height);
      final passPaint = Paint()
        ..color = (pass.isAccurate
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE53935))
            .withOpacity(0.7 * opacity)
        ..strokeWidth = pass.isAccurate ? 2.5 : 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, passPaint);

      final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
      final arrowSize = 8.0;
      final path = Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(to.dx - arrowSize * math.cos(angle - math.pi / 6),
            to.dy - arrowSize * math.sin(angle - math.pi / 6))
        ..moveTo(to.dx, to.dy)
        ..lineTo(to.dx - arrowSize * math.cos(angle + math.pi / 6),
            to.dy - arrowSize * math.sin(angle + math.pi / 6));
      canvas.drawPath(path, passPaint);

      canvas.drawCircle(
          to,
          4,
          Paint()
            ..color = (pass.isAccurate
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE53935))
                .withOpacity(opacity));
    }
  }

  void _drawDribbles(Canvas canvas, Size size, List<PMDribbleData> dribbles) {
    for (int i = 0; i < dribbles.length; i++) {
      final dribble = dribbles[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final from =
          Offset(dribble.from.dx * size.width, dribble.from.dy * size.height);
      final to =
          Offset(dribble.to.dx * size.width, dribble.to.dy * size.height);
      final dribblePaint = Paint()
        ..color = (dribble.successful
                ? const Color(0xFF9C27B0)
                : const Color(0xFFFF9800))
            .withOpacity(0.7 * opacity)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(from.dx, from.dy);
      final steps = 8;
      for (int j = 0; j <= steps; j++) {
        final t = j / steps;
        final x = from.dx + (to.dx - from.dx) * t;
        final y =
            from.dy + (to.dy - from.dy) * t + math.sin(t * math.pi * 3) * 10;
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, dribblePaint);

      canvas.drawCircle(from, 6,
          Paint()..color = const Color(0xFF9C27B0).withOpacity(opacity));
      canvas.drawCircle(
          from,
          6,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawCircle(
          to,
          6,
          Paint()
            ..color = (dribble.successful
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF5722))
                .withOpacity(opacity));
      canvas.drawCircle(
          to,
          6,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  void _drawDefensiveActions(
      Canvas canvas, Size size, List<PMDefenseData> actions) {
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final pos = Offset(
          action.position.dx * size.width, action.position.dy * size.height);
      Color color;
      String label;
      switch (action.type) {
        case PMDefenseType.tackle:
          color = const Color(0xFF2196F3);
          label = 'T';
          break;
        case PMDefenseType.interception:
          color = const Color(0xFF4CAF50);
          label = 'I';
          break;
        case PMDefenseType.clearance:
          color = const Color(0xFFFF9800);
          label = 'C';
          break;
      }

      canvas.drawCircle(
          pos,
          16,
          Paint()
            ..color =
                color.withOpacity((action.successful ? 0.3 : 0.15) * opacity)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          pos,
          12,
          Paint()
            ..color = color.withOpacity(opacity)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          pos,
          12,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = action.successful ? 3 : 2);

      final textStyle = TextStyle(
          color: Colors.white.withOpacity(opacity),
          fontSize: 10,
          fontWeight: FontWeight.bold);
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedStatsMapPainter oldDelegate) {
    return oldDelegate.replayIndex != replayIndex ||
        oldDelegate.animation != animation ||
        oldDelegate.selectedEvent != selectedEvent;
  }
}
