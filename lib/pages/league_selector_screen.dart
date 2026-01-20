// lib/pages/league_selector_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';

class LeagueSelectorScreen extends StatefulWidget {
  final int? initialLeagueId;
  final Function(int leagueId, String leagueName)? onLeagueSelected;

  const LeagueSelectorScreen({
    Key? key,
    this.initialLeagueId,
    this.onLeagueSelected,
  }) : super(key: key);

  @override
  State<LeagueSelectorScreen> createState() => _LeagueSelectorScreenState();
}

class _LeagueSelectorScreenState extends State<LeagueSelectorScreen>
    with SingleTickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  final TextEditingController _searchController = TextEditingController();

  int? _selectedLeagueId;
  List<Map<String, dynamic>> _filteredLeagues = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _allLeagues = [
    // Top European Leagues
    {
      'id': 135,
      'name': 'Serie A',
      'country': 'Italy',
      'flag': '🇮🇹',
      'logo': 'https://media-4.api-sports.io/football/leagues/135.png',
      'priority': 1,
    },
    {
      'id': 39,
      'name': 'Premier League',
      'country': 'England',
      'flag': '🏴󐁧󐁢󐁥󐁮󐁧󐁿',
      'logo': 'https://media-4.api-sports.io/football/leagues/39.png',
      'priority': 1,
    },
    {
      'id': 140,
      'name': 'La Liga',
      'country': 'Spain',
      'flag': '🇪🇸',
      'logo': 'https://media-4.api-sports.io/football/leagues/140.png',
      'priority': 1,
    },
    {
      'id': 78,
      'name': 'Bundesliga',
      'country': 'Germany',
      'flag': '🇩🇪',
      'logo': 'https://media-4.api-sports.io/football/leagues/78.png',
      'priority': 1,
    },
    {
      'id': 61,
      'name': 'Ligue 1',
      'country': 'France',
      'flag': '🇫🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/61.png',
      'priority': 1,
    },

    // Other European Leagues
    {
      'id': 94,
      'name': 'Primeira Liga',
      'country': 'Portugal',
      'flag': '🇵🇹',
      'logo': 'https://media-4.api-sports.io/football/leagues/94.png',
      'priority': 2,
    },
    {
      'id': 88,
      'name': 'Eredivisie',
      'country': 'Netherlands',
      'flag': '🇳🇱',
      'logo': 'https://media-4.api-sports.io/football/leagues/88.png',
      'priority': 2,
    },
    {
      'id': 144,
      'name': 'Jupiler Pro League',
      'country': 'Belgium',
      'flag': '🇧🇪',
      'logo': 'https://media-4.api-sports.io/football/leagues/144.png',
      'priority': 2,
    },
    {
      'id': 179,
      'name': 'Scottish Premiership',
      'country': 'Scotland',
      'flag': '🏴󐁧󐁢󐁳󐁣󐁴󐁿',
      'logo': 'https://media-4.api-sports.io/football/leagues/179.png',
      'priority': 2,
    },
    {
      'id': 203,
      'name': 'Super Lig',
      'country': 'Turkey',
      'flag': '🇹🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/203.png',
      'priority': 2,
    },

    // South American Leagues
    {
      'id': 71,
      'name': 'Série A',
      'country': 'Brazil',
      'flag': '🇧🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/71.png',
      'priority': 2,
    },
    {
      'id': 128,
      'name': 'Liga Profesional',
      'country': 'Argentina',
      'flag': '🇦🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/128.png',
      'priority': 2,
    },

    // North American
    {
      'id': 253,
      'name': 'MLS',
      'country': 'USA',
      'flag': '🇺🇸',
      'logo': 'https://media-4.api-sports.io/football/leagues/253.png',
      'priority': 3,
    },
    {
      'id': 262,
      'name': 'Liga MX',
      'country': 'Mexico',
      'flag': '🇲🇽',
      'logo': 'https://media-4.api-sports.io/football/leagues/262.png',
      'priority': 3,
    },

    // International Competitions
    {
      'id': 2,
      'name': 'Champions League',
      'country': 'Europe',
      'flag': '🏆',
      'logo': 'https://media-4.api-sports.io/football/leagues/2.png',
      'priority': 0,
    },
    {
      'id': 3,
      'name': 'Europa League',
      'country': 'Europe',
      'flag': '🥈',
      'logo': 'https://media-4.api-sports.io/football/leagues/3.png',
      'priority': 0,
    },
    {
      'id': 848,
      'name': 'Conference League',
      'country': 'Europe',
      'flag': '🥉',
      'logo': 'https://media-4.api-sports.io/football/leagues/848.png',
      'priority': 0,
    },
    {
      'id': 4,
      'name': 'Euro Championship',
      'country': 'Europe',
      'flag': '⚽',
      'logo': 'https://media-4.api-sports.io/football/leagues/4.png',
      'priority': 0,
    },
    {
      'id': 1,
      'name': 'World Cup',
      'country': 'World',
      'flag': '🌍',
      'logo': 'https://media-4.api-sports.io/football/leagues/1.png',
      'priority': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedLeagueId = widget.initialLeagueId;
    _filteredLeagues = List.from(_allLeagues)
      ..sort((a, b) => a['priority'].compareTo(b['priority']));
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  void _filterLeagues(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLeagues = List.from(_allLeagues)
          ..sort((a, b) => a['priority'].compareTo(b['priority']));
      } else {
        _filteredLeagues = _allLeagues
            .where((league) =>
                league['name']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                league['country']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList()
          ..sort((a, b) => a['priority'].compareTo(b['priority']));
      }
    });
  }

  void _selectLeague(Map<String, dynamic> league) {
    _haptic.lightImpact();

    setState(() {
      _selectedLeagueId = league['id'];
    });

    // Return selected league
    if (widget.onLeagueSelected != null) {
      widget.onLeagueSelected!(league['id'], league['name']);
    }

    Navigator.pop(context, {
      'id': league['id'],
      'name': league['name'],
      'country': league['country'],
      'logo': league['logo'],
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Seleziona Campionato'),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
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
            child: TextField(
              controller: _searchController,
              onChanged: _filterLeagues,
              decoration: InputDecoration(
                hintText: 'Cerca campionato o nazione...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterLeagues('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Quick filters
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickFilter('Top 5', () {
                  setState(() {
                    _filteredLeagues =
                        _allLeagues.where((l) => l['priority'] == 1).toList();
                  });
                }, isDark),
                _buildQuickFilter('Europa', () {
                  setState(() {
                    _filteredLeagues = _allLeagues
                        .where((l) =>
                            l['country'] != 'Brazil' &&
                            l['country'] != 'Argentina' &&
                            l['country'] != 'USA' &&
                            l['country'] != 'Mexico' &&
                            l['country'] != 'World')
                        .toList();
                  });
                }, isDark),
                _buildQuickFilter('Coppe', () {
                  setState(() {
                    _filteredLeagues =
                        _allLeagues.where((l) => l['priority'] == 0).toList();
                  });
                }, isDark),
                _buildQuickFilter('Tutti', () {
                  setState(() {
                    _filteredLeagues = List.from(_allLeagues)
                      ..sort((a, b) => a['priority'].compareTo(b['priority']));
                  });
                }, isDark),
              ],
            ),
          ),

          // Leagues list
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _filteredLeagues.length,
                itemBuilder: (context, index) {
                  final league = _filteredLeagues[index];
                  final isSelected = _selectedLeagueId == league['id'];

                  // Group separator
                  Widget? separator;
                  if (index == 0 ||
                      _filteredLeagues[index - 1]['priority'] !=
                          league['priority']) {
                    String title = '';
                    switch (league['priority']) {
                      case 0:
                        title = 'Competizioni Internazionali';
                        break;
                      case 1:
                        title = 'Top 5 Campionati';
                        break;
                      case 2:
                        title = 'Altri Campionati';
                        break;
                      case 3:
                        title = 'America';
                        break;
                    }

                    separator = Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (separator != null) separator,
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: GlassmorphicCard(
                          child: InkWell(
                            onTap: () => _selectLeague(league),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // League logo
                                  Container(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.primaryColor.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: league['logo'] != null
                                        ? CachedNetworkImage(
                                            imageUrl: league['logo'],
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                            errorWidget:
                                                (context, url, error) => Icon(
                                              Icons.sports_soccer,
                                              color: theme.primaryColor,
                                            ),
                                          )
                                        : Icon(
                                            Icons.sports_soccer,
                                            color: theme.primaryColor,
                                          ),
                                  ),
                                  const SizedBox(width: 12),

                                  // League info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          league['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? theme.primaryColor
                                                : (isDark
                                                    ? Colors.white
                                                    : Colors.black87),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              league['flag'],
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              league['country'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Selection indicator
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ).animate().scale(
                                          duration: 300.ms,
                                          curve: Curves.elasticOut,
                                        )
                                  else
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey[400],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: index * 30))
                          .slideX(begin: 0.1, end: 0),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilter(String label, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () {
          _haptic.lightImpact();
          onTap();
        },
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
