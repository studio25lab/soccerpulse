// lib/widgets/player_detail_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/player.dart';
import '../models/soccer_match.dart';
import '../models/player_notification_settings.dart';
import '../services/haptic_service.dart';
import '../services/player_notification_preferences_service.dart';
import '../widgets/glassmorphic_card.dart';

class PlayerDetailBottomSheet extends StatefulWidget {
  final Player player;
  final SoccerMatch match;

  const PlayerDetailBottomSheet({
    Key? key,
    required this.player,
    required this.match,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required Player player,
    required SoccerMatch match,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerDetailBottomSheet(
        player: player,
        match: match,
      ),
    );
  }

  @override
  State<PlayerDetailBottomSheet> createState() =>
      _PlayerDetailBottomSheetState();
}

class _PlayerDetailBottomSheetState extends State<PlayerDetailBottomSheet>
    with SingleTickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          _buildHeader(theme, isDark),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(text: 'Statistiche'),
              Tab(text: 'Notifiche'),
            ],
          ),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(theme, isDark),
                _buildNotificationsTab(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn();
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          // Player photo
          Hero(
            tag: 'player_${widget.player.id}',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.primaryColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: widget.player.photo != null
                    ? CachedNetworkImage(
                        imageUrl: widget.player.photo!,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.person, size: 40),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRatingColor(widget.player.rating)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.player.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getRatingColor(widget.player.rating),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.player.position} • ${widget.player.teamName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _haptic.lightImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heat Map
          _buildHeatMapSection(theme, isDark),
          const SizedBox(height: 24),

          // Match Summary
          _buildMatchSummary(theme, isDark),
          const SizedBox(height: 24),

          // Detailed Stats
          _buildDetailedStats(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeatMapSection(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Heat Map Posizioni',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4A7C59), Color(0xFF3D6B4C)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: PlayerHeatMapPainter(
                    player: widget.player,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSummary(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Partita',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill(
                  'Goal',
                  (widget.player.goals ?? 0).toString(),
                  Icons.sports_soccer,
                  Colors.green,
                ),
                _buildStatPill(
                  'Assist',
                  (widget.player.assists ?? 0).toString(),
                  Icons.assistant,
                  Colors.blue,
                ),
                _buildStatPill(
                  'Tiri',
                  (widget.player.shots ?? 0).toString(),
                  Icons.gps_fixed,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiche Dettagliate',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Tiri
        _buildStatSection(
          'Tiri',
          Icons.sports_soccer,
          theme,
          [
            _buildStatRow('Tiri totali', widget.player.shots ?? 0),
            _buildStatRow('Tiri in porta', widget.player.shotsOnTarget ?? 0),
          ],
        ),
        const SizedBox(height: 16),

        // Passaggi
        _buildStatSection(
          'Passaggi',
          Icons.swap_calls,
          theme,
          [
            _buildStatRow('Passaggi totali', widget.player.passes ?? 0),
            _buildStatRow(
                'Passaggi riusciti', widget.player.passesCompleted ?? 0),
            if (widget.player.passes != null &&
                widget.player.passes! > 0 &&
                widget.player.passesCompleted != null)
              _buildStatRow(
                'Precisione',
                widget.player.passesCompleted ?? 0,
                maxValue: widget.player.passes,
                isPercentage: true,
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Difesa
        _buildStatSection(
          'Difesa',
          Icons.shield,
          theme,
          [
            _buildStatRow('Tackle', widget.player.tackles ?? 0),
            _buildStatRow('Intercetti', widget.player.interceptions ?? 0),
          ],
        ),
        const SizedBox(height: 16),

        // Falli e Cartellini
        _buildStatSection(
          'Disciplina',
          Icons.warning,
          theme,
          [
            _buildStatRow('Falli commessi', widget.player.foulsCommitted ?? 0),
            _buildStatRow('Falli subiti', widget.player.foulsSuffered ?? 0),
            _buildStatRow('Cartellini gialli', widget.player.yellowCards ?? 0,
                color: Colors.yellow[700]),
            _buildStatRow('Cartellini rossi', widget.player.redCards ?? 0,
                color: Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildStatSection(
    String title,
    IconData icon,
    ThemeData theme,
    List<Widget> stats,
  ) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    int value, {
    int? maxValue,
    bool isPercentage = false,
    Color? color,
  }) {
    double percentage = 1.0;
    String displayValue = value.toString();

    if (maxValue != null && maxValue > 0) {
      percentage = value / maxValue;
      if (isPercentage) {
        displayValue = '${(percentage * 100).toInt()}%';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (maxValue != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? Theme.of(context).primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationsTab(ThemeData theme, bool isDark) {
    return Consumer<PlayerNotificationPreferencesService>(
      builder: (context, notifPrefs, child) {
        final settings = notifPrefs.getSettingsForPlayer(
          widget.player.id,
          widget.player.name,
          matchId: widget.match.id,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Master switch
              _buildMasterSwitch(settings, notifPrefs, theme, isDark),
              const SizedBox(height: 24),

              // Preset veloci
              _buildPresetsSection(settings, notifPrefs, theme, isDark),
              const SizedBox(height: 24),

              // Notifiche offensive
              _buildOffensiveNotifications(settings, notifPrefs, theme, isDark),
              const SizedBox(height: 16),

              // Notifiche difensive
              _buildDefensiveNotifications(settings, notifPrefs, theme, isDark),
              const SizedBox(height: 16),

              // Notifiche disciplina
              _buildDisciplineNotifications(
                  settings, notifPrefs, theme, isDark),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMasterSwitch(
    PlayerNotificationSettings settings,
    PlayerNotificationPreferencesService notifPrefs,
    ThemeData theme,
    bool isDark,
  ) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: settings.enabled
                    ? theme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                settings.enabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: settings.enabled ? theme.primaryColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifiche Giocatore',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    settings.enabled
                        ? '${settings.activeNotificationsCount} eventi attivi'
                        : 'Disattivate',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.enabled,
              onChanged: (value) {
                _haptic.lightImpact();
                notifPrefs.togglePlayerNotifications(
                  widget.player.id,
                  widget.player.name,
                  value,
                  matchId: widget.match.id,
                );
              },
              activeColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection(
    PlayerNotificationSettings settings,
    PlayerNotificationPreferencesService notifPrefs,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurazioni Rapide',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPresetChip('Essenziale', 'essential', notifPrefs, theme),
            _buildPresetChip('Attaccante', 'attacker', notifPrefs, theme),
            _buildPresetChip('Centrocampista', 'midfielder', notifPrefs, theme),
            _buildPresetChip('Difensore', 'defender', notifPrefs, theme),
            _buildPresetChip('Portiere', 'goalkeeper', notifPrefs, theme),
            _buildPresetChip('Disattiva', 'disabled', notifPrefs, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip(
    String label,
    String presetName,
    PlayerNotificationPreferencesService notifPrefs,
    ThemeData theme,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _haptic.lightImpact();
        notifPrefs.applyPreset(
          widget.player.id,
          widget.player.name,
          presetName,
          matchId: widget.match.id,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preset "$label" applicato'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      backgroundColor: theme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: theme.primaryColor),
    );
  }

  Widget _buildOffensiveNotifications(
    PlayerNotificationSettings settings,
    PlayerNotificationPreferencesService notifPrefs,
    ThemeData theme,
    bool isDark,
  ) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_soccer, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Azioni Offensive',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationSwitch(
              'Goal',
              'Quando segna',
              settings.notifyGoals,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyGoals: value),
              ),
              isDark,
              enabled: settings.enabled,
            ),
            _buildNotificationSwitch(
              'Assist',
              'Quando fa un assist',
              settings.notifyAssists,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyAssists: value),
              ),
              isDark,
              enabled: settings.enabled,
            ),
            _buildNotificationSwitch(
              'Tiri in porta',
              'Quando tira in porta',
              settings.notifyShotsOnTarget,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyShotsOnTarget: value),
              ),
              isDark,
              enabled: settings.enabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefensiveNotifications(
    PlayerNotificationSettings settings,
    PlayerNotificationPreferencesService notifPrefs,
    ThemeData theme,
    bool isDark,
  ) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Azioni Difensive',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationSwitch(
              'Tackle',
              'Quando fa un tackle',
              settings.notifyTackles,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyTackles: value),
              ),
              isDark,
              enabled: settings.enabled,
            ),
            _buildNotificationSwitch(
              'Intercetti',
              'Quando intercetta il pallone',
              settings.notifyInterceptions,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyInterceptions: value),
              ),
              isDark,
              enabled: settings.enabled,
            ),
            if (widget.player.position.toLowerCase().contains('portiere') ||
                widget.player.position.toLowerCase().contains('goalkeeper'))
              _buildNotificationSwitch(
                'Salvataggi',
                'Quando effettua una parata',
                settings.notifySaves,
                (value) => _updateSetting(
                  notifPrefs,
                  settings.copyWith(notifySaves: value),
                ),
                isDark,
                enabled: settings.enabled,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplineNotifications(
    PlayerNotificationSettings settings,
    PlayerNotificationPreferencesService notifPrefs,
    ThemeData theme,
    bool isDark,
  ) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Disciplina',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNotificationSwitch(
              'Cartellino Giallo',
              'Quando riceve ammonizione',
              settings.notifyYellowCard,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyYellowCard: value),
              ),
              isDark,
              icon: Icons.square,
              iconColor: Colors.yellow[700],
              enabled: settings.enabled,
            ),
            _buildNotificationSwitch(
              'Cartellino Rosso',
              'Quando viene espulso',
              settings.notifyRedCard,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyRedCard: value),
              ),
              isDark,
              icon: Icons.square,
              iconColor: Colors.red,
              enabled: settings.enabled,
            ),
            _buildNotificationSwitch(
              'Fallo Commesso',
              'Quando commette un fallo',
              settings.notifyFoulCommitted,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyFoulCommitted: value),
              ),
              isDark,
              enabled: settings.enabled,
            ),
            _buildNotificationSwitch(
              'Fallo Subito',
              'Quando subisce un fallo',
              settings.notifyFoulSuffered,
              (value) => _updateSetting(
                notifPrefs,
                settings.copyWith(notifyFoulSuffered: value),
              ),
              isDark,
              enabled: settings.enabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSwitch(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark, {
    IconData? icon,
    Color? iconColor,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: enabled
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.grey,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled
                ? (newValue) {
                    _haptic.lightImpact();
                    onChanged(newValue);
                  }
                : null,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  void _updateSetting(
    PlayerNotificationPreferencesService notifPrefs,
    PlayerNotificationSettings newSettings,
  ) {
    notifPrefs.saveSettingsForPlayer(newSettings);
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return const Color(0xFF00C853);
    if (rating >= 7.0) return const Color(0xFF64DD17);
    if (rating >= 6.0) return const Color(0xFFFFAB00);
    if (rating >= 5.0) return const Color(0xFFFF6D00);
    return const Color(0xFFD50000);
  }
}

// Painter per Heat Map giocatore
class PlayerHeatMapPainter extends CustomPainter {
  final Player player;

  PlayerHeatMapPainter({required this.player});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(player.id);

    // Disegna campo
    final fieldPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      fieldPaint,
    );

    // Linea metà campo
    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      fieldPaint,
    );

    // Genera punti heat map basati su posizione giocatore
    final position = player.position.toLowerCase();
    List<Offset> heatPoints = [];

    if (position.contains('portiere') || position.contains('goalkeeper')) {
      heatPoints = _generateGoalkeeperHeatMap(size, random);
    } else if (position.contains('difensore') ||
        position.contains('defender')) {
      heatPoints = _generateDefenderHeatMap(size, random);
    } else if (position.contains('centrocampista') ||
        position.contains('midfielder')) {
      heatPoints = _generateMidfielderHeatMap(size, random);
    } else {
      heatPoints = _generateAttackerHeatMap(size, random);
    }

    // Disegna heat map
    for (final point in heatPoints) {
      final gradient = RadialGradient(
        colors: [
          Colors.red.withOpacity(0.6),
          Colors.orange.withOpacity(0.3),
          Colors.yellow.withOpacity(0.1),
          Colors.transparent,
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: point, radius: 40),
        );

      canvas.drawCircle(point, 40, paint);
    }
  }

  List<Offset> _generateGoalkeeperHeatMap(Size size, math.Random random) {
    return List.generate(15, (i) {
      return Offset(
        size.width * 0.5 + (random.nextDouble() - 0.5) * size.width * 0.3,
        size.height * 0.9 + (random.nextDouble() - 0.5) * size.height * 0.1,
      );
    });
  }

  List<Offset> _generateDefenderHeatMap(Size size, math.Random random) {
    return List.generate(20, (i) {
      return Offset(
        size.width * 0.5 + (random.nextDouble() - 0.5) * size.width * 0.8,
        size.height * 0.75 + (random.nextDouble() - 0.5) * size.height * 0.2,
      );
    });
  }

  List<Offset> _generateMidfielderHeatMap(Size size, math.Random random) {
    return List.generate(25, (i) {
      return Offset(
        size.width * 0.5 + (random.nextDouble() - 0.5) * size.width * 0.9,
        size.height * 0.5 + (random.nextDouble() - 0.5) * size.height * 0.4,
      );
    });
  }

  List<Offset> _generateAttackerHeatMap(Size size, math.Random random) {
    return List.generate(20, (i) {
      return Offset(
        size.width * 0.5 + (random.nextDouble() - 0.5) * size.width * 0.7,
        size.height * 0.25 + (random.nextDouble() - 0.5) * size.height * 0.3,
      );
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
