import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:soccerpulse/utils/l10n_helper.dart';

class TeamFormWidget extends StatelessWidget {
  final String teamName;
  final String? teamLogo;
  final List<String> form; // W, D, L
  final int points;
  final int rank;
  final VoidCallback? onTap;

  const TeamFormWidget({
    super.key,
    required this.teamName,
    this.teamLogo,
    required this.form,
    required this.points,
    required this.rank,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formScore = _calculateFormScore();
    final formColor = _getFormColor(formScore);
    final formText = _getFormText(formScore, context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Team info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (teamLogo != null) ...[
                        Image.network(
                          teamLogo!,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.sports_soccer, size: 24),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          teamName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: formColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: formColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$points pts',
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

            // Form indicators
            Row(
              children: form.reversed.take(5).map((result) {
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _getResultColor(result).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getResultColor(result),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      result,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getResultColor(result),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }

  int _calculateFormScore() {
    int score = 0;
    for (var result in form.take(5)) {
      if (result == 'W') score += 3;
      if (result == 'D') score += 1;
    }
    return score;
  }

  Color _getFormColor(int score) {
    if (score >= 12) return Colors.green;
    if (score >= 8) return Colors.lightGreen;
    if (score >= 5) return Colors.orange;
    return Colors.red;
  }

  String _getFormText(int score, BuildContext context) {
    if (score >= 12) return 'Eccellente';
    if (score >= 8) return 'Buona';
    if (score >= 5) return tr(context, 'Nella Media');
    return 'Scarsa';
  }

  Color _getResultColor(String result) {
    switch (result) {
      case 'W':
        return Colors.green;
      case 'D':
        return Colors.orange;
      case 'L':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
