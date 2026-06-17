// lib/pages/league_selection_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';

class LeagueSelectionScreen extends StatefulWidget {
  final bool isInitialSetup;
  final bool allowMultiple;

  const LeagueSelectionScreen({
    Key? key,
    this.isInitialSetup = false,
    this.allowMultiple = false,
  }) : super(key: key);

  @override
  State<LeagueSelectionScreen> createState() => _LeagueSelectionScreenState();
}

class _LeagueSelectionScreenState extends State<LeagueSelectionScreen>
    with TickerProviderStateMixin {
  final HapticService _haptic = HapticService();

  int? _selectedLeagueId;
  Set<int> _selectedLeagueIds = {};

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<Map<String, dynamic>> _leagues = [
    {
      'id': 135,
      'name': 'Serie A',
      'country': 'Italy',
      'flag': '🇮🇹',
      'logo': 'https://media-4.api-sports.io/football/leagues/135.png',
      'season': 2024,
    },
    {
      'id': 39,
      'name': 'Premier League',
      'country': 'England',
      'flag': '🏴󐁧󐁢󐁥󐁮󐁧󐁿',
      'logo': 'https://media-4.api-sports.io/football/leagues/39.png',
      'season': 2024,
    },
    {
      'id': 140,
      'name': 'La Liga',
      'country': 'Spain',
      'flag': '🇪🇸',
      'logo': 'https://media-4.api-sports.io/football/leagues/140.png',
      'season': 2024,
    },
    {
      'id': 78,
      'name': 'Bundesliga',
      'country': 'Germany',
      'flag': '🇩🇪',
      'logo': 'https://media-4.api-sports.io/football/leagues/78.png',
      'season': 2024,
    },
    {
      'id': 61,
      'name': 'Ligue 1',
      'country': 'France',
      'flag': '🇫🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/61.png',
      'season': 2024,
    },
    {
      'id': 94,
      'name': 'Primeira Liga',
      'country': 'Portugal',
      'flag': '🇵🇹',
      'logo': 'https://media-4.api-sports.io/football/leagues/94.png',
      'season': 2024,
    },
    {
      'id': 88,
      'name': 'Eredivisie',
      'country': 'Netherlands',
      'flag': '🇳🇱',
      'logo': 'https://media-4.api-sports.io/football/leagues/88.png',
      'season': 2024,
    },
    {
      'id': 203,
      'name': 'Super Lig',
      'country': 'Turkey',
      'flag': '🇹🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/203.png',
      'season': 2024,
    },
    {
      'id': 71,
      'name': 'Série A',
      'country': 'Brazil',
      'flag': '🇧🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/71.png',
      'season': 2024,
    },
    {
      'id': 128,
      'name': 'Liga Profesional',
      'country': 'Argentina',
      'flag': '🇦🇷',
      'logo': 'https://media-4.api-sports.io/football/leagues/128.png',
      'season': 2024,
    },
    {
      'id': 253,
      'name': 'MLS',
      'country': 'USA',
      'flag': '🇺🇸',
      'logo': 'https://media-4.api-sports.io/football/leagues/253.png',
      'season': 2024,
    },
    {
      'id': 2,
      'name': 'Champions League',
      'country': 'Europe',
      'flag': '🏆',
      'logo': 'https://media-4.api-sports.io/football/leagues/2.png',
      'season': 2024,
    },
    {
      'id': 3,
      'name': 'Europa League',
      'country': 'Europe',
      'flag': '🥈',
      'logo': 'https://media-4.api-sports.io/football/leagues/3.png',
      'season': 2024,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSelectedLeagues();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _loadSelectedLeagues() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.allowMultiple) {
      final leagueIds = prefs.getStringList('selected_league_ids') ?? ['135'];
      setState(() {
        _selectedLeagueIds = leagueIds.map((id) => int.parse(id)).toSet();
      });
    } else {
      final leagueId = prefs.getInt('selected_league_id') ?? 135;
      setState(() {
        _selectedLeagueId = leagueId;
      });
    }
  }

  Future<void> _saveSelection() async {
    _haptic.mediumImpact();

    final prefs = await SharedPreferences.getInstance();

    if (widget.allowMultiple) {
      final leagueIds = _selectedLeagueIds.map((id) => id.toString()).toList();
      await prefs.setStringList('selected_league_ids', leagueIds);
    } else {
      if (_selectedLeagueId != null) {
        await prefs.setInt('selected_league_id', _selectedLeagueId!);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Campionati salvati'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      if (widget.isInitialSetup) {
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        Navigator.pop(context, true);
      }
    }
  }

  void _toggleLeague(int leagueId) {
    _haptic.lightImpact();

    setState(() {
      if (widget.allowMultiple) {
        if (_selectedLeagueIds.contains(leagueId)) {
          _selectedLeagueIds.remove(leagueId);
        } else {
          _selectedLeagueIds.add(leagueId);
        }
      } else {
        _selectedLeagueId = leagueId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Select Leagues' : 'Campionati'),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
        actions: [
          if (widget.allowMultiple || _selectedLeagueId != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveSelection,
            ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [Colors.grey[900]!, Colors.grey[850]!]
                    : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
              ),
            ),
            child: Row(
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Icon(
                    Icons.sports_soccer,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.allowMultiple
                            ? tr(context, 'Seleziona i tuoi campionati')
                            : tr(context, 'Seleziona il campionato'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.allowMultiple
                            ? tr(context, 'Puoi selezionare più campionati')
                            : 'Scegli il tuo campionato preferito',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Leagues Grid
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _leagues.length,
                itemBuilder: (context, index) {
                  final league = _leagues[index];
                  final isSelected = widget.allowMultiple
                      ? _selectedLeagueIds.contains(league['id'])
                      : _selectedLeagueId == league['id'];

                  return GlassmorphicCard(
                    child: InkWell(
                      onTap: () => _toggleLeague(league['id']),
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // League logo
                                if (league['logo'] != null)
                                  CachedNetworkImage(
                                    imageUrl: league['logo'],
                                    width: 60,
                                    height: 60,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => Icon(
                                      Icons.sports_soccer,
                                      size: 60,
                                      color: theme.primaryColor,
                                    ),
                                  )
                                else
                                  Icon(
                                    Icons.sports_soccer,
                                    size: 60,
                                    color: theme.primaryColor,
                                  ),
                                const SizedBox(height: 12),

                                // League name
                                Text(
                                  league['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),

                                // Country
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      league['flag'],
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      league['country'],
                                      style: TextStyle(
                                        fontSize: 11,
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
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
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
                                  ),
                            ),

                          // Border highlight
                          if (isSelected)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 50))
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      );
                },
              ),
            ),
          ),

          // Bottom action button
          if (!widget.isInitialSetup)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed:
                    (_selectedLeagueId != null || _selectedLeagueIds.isNotEmpty)
                        ? _saveSelection
                        : null,
                icon: Icon(Icons.save),
                label: Text(tr(context, 'Salva Selezione')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}
