import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../api/api_service.dart';
import '../models/league.dart';
import '../generated/l10n.dart';

class TopScorersScreen extends StatefulWidget {
  const TopScorersScreen({super.key});

  @override
  State<TopScorersScreen> createState() => _TopScorersScreenState();
}

class _TopScorersScreenState extends State<TopScorersScreen> {
  final ApiService _apiService = ApiService();
  int _selectedLeagueId = 135; // Serie A di default
  late Future<List<Map<String, dynamic>>> _scorersFuture;

  @override
  void initState() {
    super.initState();
    _loadScorers();
  }

  void _loadScorers() {
    setState(() {
      _scorersFuture = _apiService.fetchTopScorers(_selectedLeagueId);
    });
  }

  Future<void> _selectLeague() async {
    final s = S.of(context)!;

    final selected = await showDialog<League>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.selectLeague),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: League.popularLeagues.length,
            itemBuilder: (context, index) {
              final league = League.popularLeagues[index];
              return ListTile(
                leading: Text(league.logo ?? '⚽',
                    style: const TextStyle(fontSize: 24)),
                title: Text(league.name),
                selected: league.id == _selectedLeagueId,
                onTap: () => Navigator.pop(context, league),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null && selected.id != _selectedLeagueId) {
      setState(() {
        _selectedLeagueId = selected.id;
      });
      _loadScorers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    final selectedLeague = League.popularLeagues.firstWhere(
      (l) => l.id == _selectedLeagueId,
      orElse: () => League.popularLeagues.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${s.topScorers} - ${selectedLeague.name}'),
        elevation: 0,
        flexibleSpace: Container(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_soccer),
            onPressed: _selectLeague,
            tooltip: s.changeLeague,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _scorersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    s.errorLoading,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadScorers,
                    icon: const Icon(Icons.refresh),
                    label: Text(s.retry),
                  ),
                ],
              ),
            );
          }

          final scorers = snapshot.data ?? [];
          if (scorers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  Text(
                    s.noDataAvailable,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.tryAnotherLeague,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _selectLeague,
                    icon: const Icon(Icons.sports_soccer),
                    label: Text(s.changeLeague),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scorers.length,
            itemBuilder: (context, index) {
              final scorer = scorers[index];
              final player = scorer['player'];
              final statistics = scorer['statistics']?[0];
              final goals = statistics?['goals']?['total'] ?? 0;
              final assists = statistics?['goals']?['assists'] ?? 0;
              final team = statistics?['team'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: player?['photo'] != null
                            ? NetworkImage(player['photo'])
                            : null,
                        child: player?['photo'] == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                      if (index < 3)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.amber
                                  : index == 1
                                      ? Colors.grey[400]
                                      : Colors.brown[300],
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    player?['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        team?['name'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatChip('⚽ $goals', Colors.green),
                          const SizedBox(width: 8),
                          if (assists > 0)
                            _buildStatChip('🎯 $assists', Colors.blue),
                        ],
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: Duration(milliseconds: index * 50))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: 0.2, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8), // ✅ CORRETTO
        ),
      ),
    );
  }
}
