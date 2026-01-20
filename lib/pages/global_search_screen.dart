// lib/pages/global_search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../models/player.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../generated/l10n.dart';
import '../widgets/glassmorphic_card.dart';
import 'match_detail_screen.dart';
import 'team_detail_screen.dart';
import 'player_detail_screen.dart';
import '../utils/player_converter.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({Key? key}) : super(key: key);

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Search state
  String _searchQuery = '';
  bool _isSearching = false;

  // Results
  List<SoccerMatch> _matchResults = [];
  List<TeamStanding> _teamResults = [];
  List<Player> _playerResults = [];

  // Recent searches
  List<String> _recentSearches = [
    'Inter',
    'Milan',
    'Juventus',
    'Napoli',
    'Roma',
  ];

  // Popular searches
  final List<Map<String, dynamic>> _popularSearches = [
    {'icon': Icons.sports_soccer, 'label': 'Serie A', 'query': 'Serie A'},
    {
      'icon': Icons.emoji_events,
      'label': 'Champions',
      'query': 'Champions League'
    },
    {'icon': Icons.star, 'label': 'Osimhen', 'query': 'Osimhen'},
    {'icon': Icons.stadium, 'label': 'San Siro', 'query': 'San Siro'},
    {
      'icon': Icons.trending_up,
      'label': 'Top Scorer',
      'query': 'Capocannoniere'
    },
    {'icon': Icons.calendar_today, 'label': 'Oggi', 'query': 'Partite oggi'},
  ];

  // Filters
  String _selectedFilter = 'all';
  final Map<String, String> _filters = {
    'all': 'Tutto',
    'matches': 'Partite',
    'teams': 'Squadre',
    'players': 'Giocatori',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _focusNode.requestFocus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    // Aggiungi alle ricerche recenti
    if (!_recentSearches.contains(query)) {
      _recentSearches.insert(0, query);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
    }

    // Simula ricerca (in produzione chiamerebbe l'API)
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      // Mock results
      _matchResults = _generateMockMatches(query);
      _teamResults = _generateMockTeams(query);
      _playerResults = _generateMockPlayers(query);
      _isSearching = false;
    });
  }

  List<SoccerMatch> _generateMockMatches(String query) {
    // In produzione filtrerebbe dalle partite reali
    return [];
  }

  List<TeamStanding> _generateMockTeams(String query) {
    final allTeams = [
      TeamStanding(
        teamId: 505,
        teamName: 'Inter',
        teamLogo: 'https://media.api-sports.io/football/teams/505.png',
        position: 3,
        leagueId: 135,
        points: 72,
        played: 38,
        wins: 23,
        draws: 3,
        losses: 12,
        goalsFor: 71,
        goalsAgainst: 43,
        goalsDiff: 28,
        home: TeamStats(
            played: 19,
            win: 14,
            draw: 1,
            lose: 4,
            goalsFor: 40,
            goalsAgainst: 18),
        away: TeamStats(
            played: 19,
            win: 9,
            draw: 2,
            lose: 8,
            goalsFor: 31,
            goalsAgainst: 25),
        form: 'WWLWW',
        description: 'Serie A',
      ),
      TeamStanding(
        teamId: 489,
        teamName: 'AC Milan',
        teamLogo: 'https://media.api-sports.io/football/teams/489.png',
        position: 4,
        leagueId: 135,
        points: 70,
        played: 38,
        wins: 20,
        draws: 10,
        losses: 8,
        goalsFor: 65,
        goalsAgainst: 43,
        goalsDiff: 22,
        home: TeamStats(
            played: 19,
            win: 12,
            draw: 4,
            lose: 3,
            goalsFor: 35,
            goalsAgainst: 18),
        away: TeamStats(
            played: 19,
            win: 8,
            draw: 6,
            lose: 5,
            goalsFor: 30,
            goalsAgainst: 25),
        form: 'DWWLW',
        description: 'Serie A',
      ),
    ];

    return allTeams
        .where(
            (team) => team.teamName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<Player> _generateMockPlayers(String query) {
    final allPlayers = [
      Player(
        id: 278,
        name: 'Victor Osimhen',
        photo: 'https://media.api-sports.io/football/players/278.png',
        nationality: 'Nigeria',
        age: 24,
        position: 'Attacker',
        teamId: 492,
        teamName: 'Napoli',
        teamLogo: 'https://media.api-sports.io/football/teams/492.png',
        goals: 26,
        assists: 4,
        appearances: 32,
        lineups: 32,
        yellowCards: 2,
        redCards: 0,
        rating: 7.8,
      ),
    ];

    return allPlayers
        .where(
            (player) => player.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: true,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Cerca squadre, giocatori, partite...',
              hintStyle: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _haptic.lightImpact();
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _matchResults.clear();
                          _teamResults.clear();
                          _playerResults.clear();
                        });
                      },
                    )
                  : null,
            ),
            onSubmitted: _performSearch,
            onChanged: (value) {
              setState(() {});
              if (value.length >= 3) {
                _performSearch(value);
              }
            },
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              _haptic.lightImpact();
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => _filters.entries.map((entry) {
              return PopupMenuItem<String>(
                value: entry.key,
                child: Row(
                  children: [
                    if (_selectedFilter == entry.key)
                      Icon(Icons.check, color: theme.primaryColor, size: 20),
                    if (_selectedFilter != entry.key) const SizedBox(width: 20),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(theme, isDark, s),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark, S s) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primaryColor),
            const SizedBox(height: 16),
            const Text('Ricerca in corso...'),
          ],
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return _buildInitialState(theme, isDark, s);
    }

    if (_matchResults.isEmpty &&
        _teamResults.isEmpty &&
        _playerResults.isEmpty) {
      return _buildNoResults(theme, isDark, s);
    }

    return _buildSearchResults(theme, isDark, s);
  }

  Widget _buildInitialState(ThemeData theme, bool isDark, S s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ricerche recenti
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ricerche recenti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _haptic.lightImpact();
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: const Text('Cancella'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  avatar: const Icon(Icons.history, size: 18),
                  onPressed: () {
                    _haptic.lightImpact();
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Ricerche popolari
          Text(
            'Ricerche popolari',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _popularSearches.length,
            itemBuilder: (context, index) {
              final item = _popularSearches[index];
              return GlassmorphicCard(
                borderRadius: 12,
                child: InkWell(
                  onTap: () {
                    _haptic.lightImpact();
                    _searchController.text = item['query'];
                    _performSearch(item['query']);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'],
                          size: 24,
                          color: theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item['label'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(
                    delay: Duration(milliseconds: index * 50),
                    duration: const Duration(milliseconds: 300),
                  )
                  .fadeIn();
            },
          ),

          const SizedBox(height: 24),

          // Suggerimenti
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.1),
                  theme.primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Suggerimenti di ricerca',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Cerca per nome squadra (es: "Inter")\n'
                  '• Cerca per giocatore (es: "Osimhen")\n'
                  '• Cerca per stadio (es: "San Siro")\n'
                  '• Usa filtri per risultati più precisi',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme, bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun risultato per "$_searchQuery"',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prova con un\'altra ricerca',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.clear),
            label: const Text('Nuova ricerca'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _haptic.lightImpact();
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
              _focusNode.requestFocus();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, bool isDark, S s) {
    final hasTeams = _teamResults.isNotEmpty &&
        (_selectedFilter == 'all' || _selectedFilter == 'teams');
    final hasPlayers = _playerResults.isNotEmpty &&
        (_selectedFilter == 'all' || _selectedFilter == 'players');
    final hasMatches = _matchResults.isNotEmpty &&
        (_selectedFilter == 'all' || _selectedFilter == 'matches');

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          if (_selectedFilter == 'all')
            Container(
              color: isDark ? Colors.grey[850] : Colors.white,
              child: TabBar(
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: theme.primaryColor,
                tabs: [
                  Tab(text: 'Squadre (${_teamResults.length})'),
                  Tab(text: 'Giocatori (${_playerResults.length})'),
                  Tab(text: 'Partite (${_matchResults.length})'),
                ],
              ),
            ),
          Expanded(
            child: _selectedFilter == 'all'
                ? TabBarView(
                    children: [
                      _buildTeamResults(theme, isDark),
                      _buildPlayerResults(theme, isDark),
                      _buildMatchResults(theme, isDark),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        if (hasTeams) _buildTeamResults(theme, isDark),
                        if (hasPlayers) _buildPlayerResults(theme, isDark),
                        if (hasMatches) _buildMatchResults(theme, isDark),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamResults(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teamResults.length,
      itemBuilder: (context, index) {
        final team = _teamResults[index];
        return GlassmorphicCard(
          borderRadius: 12,
          child: ListTile(
            leading: team.teamLogo != null
                ? CachedNetworkImage(
                    imageUrl: team.teamLogo!,
                    width: 40,
                    height: 40,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.sports_soccer, size: 40),
                  )
                : const Icon(Icons.sports_soccer, size: 40),
            title: Text(
              team.teamName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle:
                Text('Posizione: ${team.position}° • Punti: ${team.points}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _haptic.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamDetailScreen(teamStanding: team),
                ),
              );
            },
          ),
        )
            .animate()
            .slideX(
              begin: 0.2,
              end: 0,
              delay: Duration(milliseconds: index * 50),
            )
            .fadeIn();
      },
    );
  }

  Widget _buildPlayerResults(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _playerResults.length,
      itemBuilder: (context, index) {
        final player = _playerResults[index];
        return GlassmorphicCard(
          borderRadius: 12,
          child: ListTile(
            leading: player.photo != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: player.photo!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person, size: 40),
                    ),
                  )
                : const Icon(Icons.person, size: 40),
            title: Text(
              player.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${player.teamName} • ${player.position}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${player.goals}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const Text(
                  'Gol',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            onTap: () {
              _haptic.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailScreen(
                    player: PlayerConverter.toPlayerDetail(
                      player,
                      teamName: player.teamName,
                      teamColor: const Color(0xFF2196F3),
                    ),
                  ),
                ),
              );
            },
          ),
        )
            .animate()
            .slideX(
              begin: 0.2,
              end: 0,
              delay: Duration(milliseconds: index * 50),
            )
            .fadeIn();
      },
    );
  }

  Widget _buildMatchResults(ThemeData theme, bool isDark) {
    if (_matchResults.isEmpty) {
      return const Center(
        child: Text('Nessuna partita trovata'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matchResults.length,
      itemBuilder: (context, index) {
        final match = _matchResults[index];
        return Container(); // MatchCard here
      },
    );
  }
}
