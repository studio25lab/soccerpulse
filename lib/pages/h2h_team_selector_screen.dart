// lib/pages/h2h_team_selector_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../models/team_standing.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';

class H2HTeamSelectorScreen extends StatefulWidget {
  final TeamStanding? excludeTeam;

  const H2HTeamSelectorScreen({
    Key? key,
    this.excludeTeam,
  }) : super(key: key);

  @override
  State<H2HTeamSelectorScreen> createState() => _H2HTeamSelectorScreenState();
}

class _H2HTeamSelectorScreenState extends State<H2HTeamSelectorScreen> {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  final TextEditingController _searchController = TextEditingController();

  // State
  int _selectedLeagueId = 135; // Serie A default
  List<TeamStanding> _teams = [];
  List<TeamStanding> _filteredTeams = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final standings = await _apiService.fetchStandings(_selectedLeagueId);

      if (mounted) {
        setState(() {
          _teams = standings;

          // Escludi la squadra se specificata
          if (widget.excludeTeam != null) {
            _teams = _teams
                .where((team) => team.teamId != widget.excludeTeam!.teamId)
                .toList();
          }

          _filteredTeams = _teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore nel caricamento delle squadre';
          _isLoading = false;
        });
      }
    }
  }

  void _filterTeams(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTeams = _teams;
      } else {
        _filteredTeams = _teams
            .where((team) =>
                team.teamName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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
        title: const Text('Seleziona Squadra'),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(theme, isDark, s),
          _buildSearchBar(isDark),
          Expanded(
            child: _buildTeamsList(isDark, s),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : theme.primaryColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          Text(
            'Campionato',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.grey[400]
                  : theme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLeagueChip(135, 'Serie A', '🇮🇹', isDark),
                _buildLeagueChip(39, 'Premier', '🏴󐁧󐁢󐁥󐁮󐁧󐁿', isDark),
                _buildLeagueChip(140, 'La Liga', '🇪🇸', isDark),
                _buildLeagueChip(78, 'Bundesliga', '🇩🇪', isDark),
                _buildLeagueChip(61, 'Ligue 1', '🇫🇷', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueChip(int leagueId, String name, String flag, bool isDark) {
    final isSelected = _selectedLeagueId == leagueId;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag),
            const SizedBox(width: 4),
            Text(name),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _haptic.lightImpact();
            setState(() => _selectedLeagueId = leagueId);
            _loadTeams();
          }
        },
        selectedColor: Theme.of(context).primaryColor,
        backgroundColor: isDark ? Colors.grey[800] : Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ).animate().scale(duration: 200.ms);
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterTeams,
        decoration: InputDecoration(
          hintText: 'Cerca squadra...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterTeams('');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? Colors.grey[850] : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTeamsList(bool isDark, S s) {
    if (_isLoading) {
      return const Center(
        child: LoadingStateWidget(
          message: 'Caricamento squadre...',
          style: LoadingStyle.pulse,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Errore sconosciuto',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _haptic.lightImpact();
                _loadTeams();
              },
              icon: const Icon(Icons.refresh),
              label: Text(s.retry),
            ),
          ],
        ),
      );
    }

    if (_filteredTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Nessuna squadra trovata per "${_searchController.text}"'
                  : 'Nessuna squadra disponibile',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTeams.length,
      itemBuilder: (context, index) {
        final team = _filteredTeams[index];
        return _buildTeamCard(team, index, isDark)
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildTeamCard(TeamStanding team, int index, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        child: InkWell(
          onTap: () {
            _haptic.lightImpact();
            Navigator.pop(context, team);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Position
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getPositionColor(team.position).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      team.position.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getPositionColor(team.position),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Team logo
                if (team.teamLogo != null)
                  CachedNetworkImage(
                    imageUrl: team.teamLogo!,
                    width: 40,
                    height: 40,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.sports_soccer, size: 40),
                  )
                else
                  const Icon(Icons.sports_soccer, size: 40),
                const SizedBox(width: 12),

                // Team name and stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.teamName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildMiniStat(
                              'P', team.points.toString(), Colors.blue),
                          const SizedBox(width: 12),
                          _buildMiniStat(
                              'V', team.wins.toString(), Colors.green),
                          const SizedBox(width: 12),
                          _buildMiniStat(
                              'N', team.draws.toString(), Colors.orange),
                          const SizedBox(width: 12),
                          _buildMiniStat(
                              'S', team.losses.toString(), Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
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
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getPositionColor(int position) {
    if (position <= 4) return Colors.green;
    if (position <= 6) return Colors.blue;
    if (position >= 18) return Colors.red;
    return Colors.grey;
  }
}
