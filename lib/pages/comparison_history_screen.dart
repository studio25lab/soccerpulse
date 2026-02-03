import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../services/comparison_service.dart';
import 'player_comparison_screen.dart';

class ComparisonHistoryScreen extends StatefulWidget {
  final List<Player> allPlayers;

  const ComparisonHistoryScreen({
    Key? key,
    required this.allPlayers,
  }) : super(key: key);

  @override
  State<ComparisonHistoryScreen> createState() =>
      _ComparisonHistoryScreenState();
}

class _ComparisonHistoryScreenState extends State<ComparisonHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ComparisonService _comparisonService = ComparisonService();

  late TabController _tabController;
  List<PlayerComparison> _recentComparisons = [];
  List<PlayerComparison> _favoriteComparisons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadComparisons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComparisons() async {
    setState(() => _isLoading = true);

    _recentComparisons = await _comparisonService.getRecentComparisons();
    _favoriteComparisons = await _comparisonService.getFavoriteComparisons();

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Storico Confronti'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Text('Recenti (${_recentComparisons.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 18),
                  const SizedBox(width: 8),
                  Text('Preferiti (${_favoriteComparisons.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecentList(isDark),
                _buildFavoritesList(isDark),
              ],
            ),
    );
  }

  Widget _buildRecentList(bool isDark) {
    if (_recentComparisons.isEmpty) {
      return _buildEmptyState('Nessun confronto recente', isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _recentComparisons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comparison = _recentComparisons[index];
        return _buildComparisonCard(comparison, isDark);
      },
    );
  }

  Widget _buildFavoritesList(bool isDark) {
    if (_favoriteComparisons.isEmpty) {
      return _buildEmptyState('Nessun confronto preferito', isDark);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteComparisons.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final comparison = _favoriteComparisons[index];
        return _buildComparisonCard(comparison, isDark);
      },
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'I tuoi confronti salvati appariranno qui',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(PlayerComparison comparison, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'it');
    final comparisonPlayers = _getPlayersFromComparison(comparison);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openComparison(comparison),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isDark ? Colors.grey[850]! : Colors.white,
                isDark ? Colors.grey[800]! : Colors.grey[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comparison.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      comparison.isFavorite ? Icons.star : Icons.star_border,
                      color: comparison.isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () async {
                      await _comparisonService.toggleFavorite(comparison.id);
                      await _loadComparisons();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteDialog(comparison),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (comparisonPlayers.isNotEmpty)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: comparisonPlayers.length,
                    itemBuilder: (context, index) {
                      final player = comparisonPlayers[index];
                      final colors = [
                        const Color(0xFF00C853),
                        const Color(0xFF2196F3),
                        const Color(0xFFFF9800),
                      ];

                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors[index % colors.length],
                                    colors[index % colors.length]
                                        .withOpacity(0.7),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  player.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              player.name.split(' ').last,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(comparison.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${comparison.playerIds.length} giocatori',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Player> _getPlayersFromComparison(PlayerComparison comparison) {
    return widget.allPlayers
        .where((p) => comparison.playerIds.contains(p.id))
        .toList();
  }

  void _openComparison(PlayerComparison comparison) {
    final players = _getPlayersFromComparison(comparison);

    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giocatori non più disponibili'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerComparisonScreen(
          initialPlayers: players,
          allPlayers: widget.allPlayers,
        ),
      ),
    );
  }

  void _showDeleteDialog(PlayerComparison comparison) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Confronto'),
        content: Text('Vuoi eliminare "${comparison.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _comparisonService.deleteComparison(comparison.id);
              await _loadComparisons();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Confronto eliminato'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
