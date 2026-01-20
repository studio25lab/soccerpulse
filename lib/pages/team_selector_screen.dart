import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../api/api_service.dart';
import '../models/team.dart';
import '../models/league.dart';
import '../services/user_preferences_service.dart';
import '../services/haptic_service.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_state_widget.dart';
import '../generated/l10n.dart';

class TeamSelectorScreen extends StatefulWidget {
  final bool isManagingFavorites;

  const TeamSelectorScreen({
    super.key,
    this.isManagingFavorites = false,
  });

  @override
  State<TeamSelectorScreen> createState() => _TeamSelectorScreenState();
}

class _TeamSelectorScreenState extends State<TeamSelectorScreen> {
  final ApiService _apiService = ApiService();
  final UserPreferencesService _prefs = UserPreferencesService.getInstance();
  final HapticService _haptic = HapticService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedLeagueId = 135;
  late Future<List<Team>> _teamsFuture;
  List<int> _favoriteTeamIds = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadTeams();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _prefs.getFavoriteTeams();
    setState(() {
      _favoriteTeamIds = favorites;
    });
  }

  void _loadTeams({bool forceRefresh = false}) {
    setState(() {});
  }

  Future<void> _toggleFavorite(int teamId) async {
    _haptic.medium();
    if (_favoriteTeamIds.contains(teamId)) {
      await _prefs.removeFavoriteTeam(teamId);
    } else {
      await _prefs.addFavoriteTeam(teamId);
    }
    _loadFavorites();
  }

  List<Team> _filterTeams(List<Team> teams) {
    if (_searchQuery.isEmpty) return teams;
    return teams
        .where((team) =>
            team.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final selectedLeague = League.popularLeagues.firstWhere(
      (l) => l.id == _selectedLeagueId,
      orElse: () => League.popularLeagues.first,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(selectedLeague, s),
          _buildSearchBar(s),
          _buildContent(s),
        ],
      ),
      floatingActionButton:
          widget.isManagingFavorites && _favoriteTeamIds.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () {
                    _haptic.success();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: Text(s.save),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack)
              : null,
    );
  }

  Widget _buildAppBar(League league, S s) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(league.logo ?? '⚽', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.isManagingFavorites ? s.manageFavorites : s.selectTeams,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: -30,
              child: Icon(
                Icons.group_add,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isManagingFavorites ? s.manageFavorites : s.addTeams,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(),
                  const SizedBox(height: 4),
                  if (_favoriteTeamIds.isNotEmpty)
                    Text(
                      '${_favoriteTeamIds.length} ${s.followedTeams}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideX(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<int>(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                league.logo ?? '⚽',
                style: const TextStyle(fontSize: 20),
              ),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
          onSelected: (leagueId) {
            _haptic.light();
            setState(() {
              _selectedLeagueId = leagueId;
            });
            _loadTeams(forceRefresh: true);
          },
          itemBuilder: (context) => League.popularLeagues.map((league) {
            return PopupMenuItem<int>(
              value: league.id,
              child: Row(
                children: [
                  Text(league.logo ?? '⚽',
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          league.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          league.country,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (league.id == _selectedLeagueId)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).primaryColor,
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchBar(S s) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
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
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: s.searchTeam,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _haptic.light();
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
    );
  }

  Widget _buildContent(S s) {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<Team>>(
        future: _teamsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 400,
              child: LoadingStateWidget(
                message: 'Caricamento squadre...',
                style: LoadingStyle.soccer,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString(), s);
          }

          final teams = _filterTeams(snapshot.data ?? []);

          if (teams.isEmpty) {
            return SizedBox(
              height: 400,
              child: EmptyStateWidget(
                icon: Icons.search_off,
                title: s.noTeamsFound,
                message: _searchQuery.isNotEmpty
                    ? 'Prova a cercare con un altro nome'
                    : 'Nessuna squadra disponibile',
                color: Theme.of(context).primaryColor,
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  '${teams.length} ${teams.length == 1 ? s.team : s.teams}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AnimationLimiter(
                child: Column(
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: teams.map((team) {
                      final isFavorite = _favoriteTeamIds.contains(team.id);
                      return _buildTeamCard(team, isFavorite, s);
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeamCard(Team team, bool isFavorite, S s) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFavorite
              ? Colors.amber
              : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]!),
          width: isFavorite ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isFavorite
                ? Colors.amber.withOpacity(0.2)
                : (isDarkMode ? Colors.black26 : Colors.black12),
            blurRadius: isFavorite ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _haptic.medium();
          _toggleFavorite(team.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: team.logo != null && team.logo!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          team.logo!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.sports_soccer, size: 30),
                        ),
                      )
                    : const Icon(Icons.sports_soccer, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.country ?? 'Italia',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFavorite
                      ? Colors.amber.withOpacity(0.2)
                      : (isDarkMode ? Colors.white10 : Colors.grey[100]),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite
                      ? Colors.amber
                      : (isDarkMode ? Colors.white60 : Colors.grey[400]),
                  size: 24,
                ),
              )
                  .animate(
                    target: isFavorite ? 1 : 0,
                  )
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 200.ms,
                  ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildError(String error, S s) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red)
              .animate()
              .shake(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            s.errorLoading,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _haptic.medium();
              _loadTeams(forceRefresh: true);
            },
            icon: const Icon(Icons.refresh),
            label: Text(s.retry),
          ),
        ],
      ),
    );
  }
}
