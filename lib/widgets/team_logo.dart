import 'package:flutter/material.dart';

class TeamLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final String? teamName;

  const TeamLogo({
    super.key,
    this.logoUrl,
    this.size = 32,
    this.teamName,
  });

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.sports_soccer,
        size: size * 0.6,
        color: Colors.grey[600],
      ),
    );
  }
}
