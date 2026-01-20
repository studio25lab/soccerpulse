import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopStatWidget extends StatelessWidget {
  final String title;
  final List<TopStatItem> items;
  final IconData icon;
  final Color color;

  const TopStatWidget({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: items.length > 5 ? 5 : items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildStatItem(
                context,
                index + 1,
                item,
                color,
                isDarkMode,
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatItem(
    BuildContext context,
    int rank,
    TopStatItem item,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank <= 3
            ? color.withOpacity(0.05)
            : (isDarkMode ? Colors.white.withOpacity(0.03) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? color.withOpacity(0.2)
                  : (isDarkMode ? Colors.white10 : Colors.grey[200]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? color : Colors.grey[600],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (item.logo != null) ...[
            Image.network(
              item.logo!,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.sports_soccer, size: 24),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              item.teamName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0);
  }
}

class TopStatItem {
  final String teamName;
  final String? logo;
  final String value;

  TopStatItem({
    required this.teamName,
    this.logo,
    required this.value,
  });
}
