import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/player.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final int rank;
  final VoidCallback? onTap;
  final bool showTeam;

  const PlayerCard({
    super.key,
    required this.player,
    required this.rank,
    this.onTap,
    this.showTeam = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final goals = player.goals ?? 0;
    final assists = player.assists ?? 0;
    final appearances = player.appearances ?? 0;

    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.grey[400]!;
    if (rank == 3) rankColor = Colors.orange[300]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: rank <= 3
                ? rankColor.withOpacity(0.5)
                : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]!),
            width: rank <= 3 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: rank <= 3
                  ? rankColor.withOpacity(0.2)
                  : (isDarkMode ? Colors.black26 : Colors.black12),
              blurRadius: rank <= 3 ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? rankColor.withOpacity(0.2)
                    : (isDarkMode ? Colors.white10 : Colors.grey[100]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3
                        ? rankColor
                        : (isDarkMode ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Player Photo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white10 : Colors.grey[100],
                shape: BoxShape.circle,
                border: Border.all(
                  color: rank <= 3
                      ? rankColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: player.photo != null
                    ? Image.network(
                        player.photo!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.grey[400]),
                      )
                    : Icon(Icons.person, size: 30, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 16),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (showTeam && player.teamName.isNotEmpty) ...[
                    Row(
                      children: [
                        if (player.teamLogo != null) ...[
                          Image.network(
                            player.teamLogo!,
                            width: 16,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.sports_soccer,
                                size: 16,
                                color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            player.teamName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (player.nationality != null)
                    Text(
                      player.nationality!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),

            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.2),
                        Theme.of(context).primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'in $appearances partite',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (assists > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$assists assist',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }
}
