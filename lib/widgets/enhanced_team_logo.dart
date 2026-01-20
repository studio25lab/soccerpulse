import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EnhancedTeamLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  final String? teamName;
  final int? teamId;
  final bool enableHero;
  final bool showShadow;

  const EnhancedTeamLogo({
    super.key,
    this.logoUrl,
    this.size = 32,
    this.teamName,
    this.teamId,
    this.enableHero = false,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = _buildLogo();

    if (enableHero && teamId != null) {
      logo = Hero(
        tag: 'team_logo_$teamId',
        child: logo,
      );
    }

    if (showShadow) {
      logo = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: logo,
      );
    }

    return logo;
  }

  Widget _buildLogo() {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 8),
      child: CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size * 0.5,
          height: size * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.grey[400]!,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[400]!,
          ],
        ),
        borderRadius: BorderRadius.circular(size / 8),
      ),
      child: Icon(
        Icons.sports_soccer,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}
