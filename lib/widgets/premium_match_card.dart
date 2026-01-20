import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/match.dart';
import '../services/haptic_service.dart';
import '../pages/match_detail_screen.dart';
import 'animated_page_transition.dart';

class PremiumMatchCard extends StatefulWidget {
  final Match match;
  final bool showLeague;

  const PremiumMatchCard({
    super.key,
    required this.match,
    this.showLeague = true,
  });

  @override
  State<PremiumMatchCard> createState() => _PremiumMatchCardState();
}

class _PremiumMatchCardState extends State<PremiumMatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final HapticService _haptic = HapticService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        _haptic.medium();
        context.pushWithTransition(
          MatchDetailScreen(match: widget.match),
          type: TransitionType.fadeScale,
        );
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.95).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [
                      const Color(0xFF1E1E1E),
                      const Color(0xFF2C2C2C),
                    ]
                  : [
                      Colors.white,
                      Colors.grey[50]!,
                    ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.match.isLive
                  ? Colors.red.withOpacity(0.5)
                  : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey[200]!),
              width: widget.match.isLive ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.match.isLive
                    ? Colors.red.withOpacity(0.2)
                    : (isDarkMode ? Colors.black38 : Colors.black12),
                blurRadius: widget.match.isLive ? 16 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                    ),
                  ),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildHeader(context, isDarkMode),
                      const SizedBox(height: 20),
                      _buildMatchContent(context, isDarkMode),
                      const SizedBox(height: 16),
                      _buildFooter(context, isDarkMode),
                    ],
                  ),
                ),

                // Live Badge
                if (widget.match.isLive)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(
                                  onPlay: (controller) => controller.repeat())
                              .fadeIn(duration: 500.ms)
                              .then()
                              .fadeOut(duration: 500.ms),
                          const SizedBox(width: 6),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildHeader(BuildContext context, bool isDarkMode) {
    if (!widget.showLeague || widget.match.leagueName == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (widget.match.leagueLogo != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              widget.match.leagueLogo!,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.sports_soccer,
                size: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.match.leagueName ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${widget.match.date.day}/${widget.match.date.month} • ${widget.match.time}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchContent(BuildContext context, bool isDarkMode) {
    return Row(
      children: [
        // Home Team
        Expanded(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: widget.match.homeTeamLogo != null
                    ? Image.network(
                        widget.match.homeTeamLogo!,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.sports_soccer, size: 40),
                      )
                    : const Icon(Icons.sports_soccer, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                widget.match.homeTeamName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Score or Time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getStatusColor(context).withOpacity(0.2),
                  _getStatusColor(context).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(context).withOpacity(0.3),
              ),
            ),
            child: Text(
              _getDisplayText(),
              style: TextStyle(
                fontSize: widget.match.isScheduled ? 18 : 32,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(context),
              ),
            ),
          ),
        ),

        // Away Team
        Expanded(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: widget.match.awayTeamLogo != null
                    ? Image.network(
                        widget.match.awayTeamLogo!,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.sports_soccer, size: 40),
                      )
                    : const Icon(Icons.sports_soccer, size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                widget.match.awayTeamName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.match.venue != null) ...[
            Icon(
              Icons.stadium,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                widget.match.venue!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    if (widget.match.isLive) return Colors.red;
    if (widget.match.isFinished) return Colors.green;
    return Theme.of(context).primaryColor;
  }

  String _getDisplayText() {
    if (widget.match.isScheduled) {
      return widget.match.time;
    }
    return '${widget.match.homeScore} - ${widget.match.awayScore}';
  }
}
