// lib/widgets/match_notification_settings_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/match_notification_settings.dart';
import '../models/soccer_match.dart';
import '../services/match_notification_preferences_service.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';

class MatchNotificationSettingsBottomSheet extends StatefulWidget {
  final SoccerMatch match;

  const MatchNotificationSettingsBottomSheet({
    Key? key,
    required this.match,
  }) : super(key: key);

  static Future<void> show(BuildContext context, SoccerMatch match) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MatchNotificationSettingsBottomSheet(match: match),
    );
  }

  @override
  State<MatchNotificationSettingsBottomSheet> createState() =>
      _MatchNotificationSettingsBottomSheetState();
}

class _MatchNotificationSettingsBottomSheetState
    extends State<MatchNotificationSettingsBottomSheet> {
  final HapticService _haptic = HapticService();
  late MatchNotificationSettings _settings;
  late MatchNotificationPreferencesService _prefsService;

  @override
  void initState() {
    super.initState();
    _prefsService = context.read<MatchNotificationPreferencesService>();
    _settings = _prefsService.getSettingsForMatch(widget.match.id);
  }

  void _updateSettings(MatchNotificationSettings newSettings) {
    setState(() {
      _settings = newSettings;
    });
    _prefsService.saveSettingsForMatch(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preset veloci
                  _buildPresetsSection(theme, isDark),
                  const SizedBox(height: 24),

                  // Master switch
                  _buildMasterSwitch(theme, isDark),
                  const SizedBox(height: 24),

                  // Notifiche Goal
                  _buildGoalNotificationsSection(theme, isDark),
                  const SizedBox(height: 24),

                  // Notifiche Cartellini
                  _buildCardNotificationsSection(theme, isDark),
                  const SizedBox(height: 24),

                  // Notifiche Azioni di Gioco
                  _buildGameActionsSection(theme, isDark),
                  const SizedBox(height: 24),

                  // Notifiche Eventi Partita
                  _buildMatchEventsSection(theme, isDark),
                  const SizedBox(height: 24),

                  // Aggiornamenti Periodici
                  _buildPeriodicUpdatesSection(theme, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Footer con azioni
          _buildFooter(theme, isDark),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.notifications_active,
              color: theme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'Notifiche Partita'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.match.homeTeamName} vs ${widget.match.awayTeamName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
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

  Widget _buildPresetsSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'Configurazioni Rapide'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPresetButton(
                tr(context, 'Solo Goal'),
                Icons.sports_soccer,
                () => _applyPreset('goals'),
                theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPresetButton(
                tr(context, 'Minimo'),
                Icons.notifications_none,
                () => _applyPreset('minimal'),
                theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPresetButton(
                tr(context, 'Completo'),
                Icons.notifications_active,
                () => _applyPreset('complete'),
                theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPresetButton(
                tr(context, 'Disattiva tutto'),
                Icons.notifications_off,
                () => _applyPreset('disabled'),
                theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () {
        _haptic.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.primaryColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterSwitch(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _settings.enabled
                    ? theme.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _settings.enabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _settings.enabled ? theme.primaryColor : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, 'Notifiche Partita'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    _settings.enabled
                        ? '${_settings.activeNotificationsCount} ${tr(context, 'eventi attivi')}'
                        : tr(context, 'Disattivate'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _settings.enabled,
              onChanged: (value) {
                _haptic.lightImpact();
                _updateSettings(_settings.copyWith(enabled: value));
              },
              activeColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalNotificationsSection(ThemeData theme, bool isDark) {
    return _buildSection(
      tr(context, 'Goal'),
      Icons.sports_soccer,
      theme,
      isDark,
      [
        _buildSwitchTile(
          tr(context, 'Goal Squadra Casa'),
          '${widget.match.homeTeamName}',
          _settings.notifyHomeGoals,
          (value) => _updateSettings(
            _settings.copyWith(notifyHomeGoals: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Goal Squadra Trasferta'),
          '${widget.match.awayTeamName}',
          _settings.notifyAwayGoals,
          (value) => _updateSettings(
            _settings.copyWith(notifyAwayGoals: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
      ],
    );
  }

  Widget _buildCardNotificationsSection(ThemeData theme, bool isDark) {
    return _buildSection(
      tr(context, 'Cartellini'),
      Icons.style,
      theme,
      isDark,
      [
        _buildSwitchTile(
          tr(context, 'Cartellini Gialli'),
          tr(context, 'Ammonizioni durante la partita'),
          _settings.notifyYellowCards,
          (value) => _updateSettings(
            _settings.copyWith(notifyYellowCards: value),
          ),
          theme,
          isDark,
          icon: Icons.square,
          iconColor: Colors.yellow[700]!,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Cartellini Rossi'),
          tr(context, 'Espulsioni durante la partita'),
          _settings.notifyRedCards,
          (value) => _updateSettings(
            _settings.copyWith(notifyRedCards: value),
          ),
          theme,
          isDark,
          icon: Icons.square,
          iconColor: Colors.red,
          enabled: _settings.enabled,
        ),
      ],
    );
  }

  Widget _buildGameActionsSection(ThemeData theme, bool isDark) {
    return _buildSection(
      tr(context, 'Azioni di Gioco'),
      Icons.sports,
      theme,
      isDark,
      [
        _buildSwitchTile(
          tr(context, 'Sostituzioni'),
          tr(context, 'Cambi giocatori'),
          _settings.notifySubstitutions,
          (value) => _updateSettings(
            _settings.copyWith(notifySubstitutions: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Tiri in Porta'),
          tr(context, 'Tiri nello specchio della porta'),
          _settings.notifyShotsOnTarget,
          (value) => _updateSettings(
            _settings.copyWith(notifyShotsOnTarget: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Calci d\'Angolo'),
          tr(context, 'Corner assegnati'),
          _settings.notifyCorners,
          (value) => _updateSettings(
            _settings.copyWith(notifyCorners: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Rigori'),
          tr(context, 'Calci di rigore assegnati'),
          _settings.notifyPenalties,
          (value) => _updateSettings(
            _settings.copyWith(notifyPenalties: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Falli'),
          tr(context, 'Falli commessi durante la partita'),
          _settings.notifyFouls,
          (value) => _updateSettings(
            _settings.copyWith(notifyFouls: value),
          ),
          theme,
          isDark,
          icon: Icons.warning,
          iconColor: Colors.orange,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Fuorigioco'),
          tr(context, 'Posizioni di fuorigioco'),
          _settings.notifyOffsides,
          (value) => _updateSettings(
            _settings.copyWith(notifyOffsides: value),
          ),
          theme,
          isDark,
          icon: Icons.flag,
          iconColor: Colors.blue,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Decisioni VAR'),
          tr(context, 'Review e decisioni arbitrali'),
          _settings.notifyVarDecisions,
          (value) => _updateSettings(
            _settings.copyWith(notifyVarDecisions: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
      ],
    );
  }

  Widget _buildMatchEventsSection(ThemeData theme, bool isDark) {
    return _buildSection(
      tr(context, 'Eventi Partita'),
      Icons.event,
      theme,
      isDark,
      [
        _buildSwitchTile(
          tr(context, 'Inizio Partita'),
          tr(context, 'Fischio d\'inizio'),
          _settings.notifyMatchStart,
          (value) => _updateSettings(
            _settings.copyWith(notifyMatchStart: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Fine Primo Tempo'),
          tr(context, 'Intervallo'),
          _settings.notifyHalfTime,
          (value) => _updateSettings(
            _settings.copyWith(notifyHalfTime: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Inizio Secondo Tempo'),
          tr(context, 'Ripresa del gioco'),
          _settings.notifySecondHalfStart,
          (value) => _updateSettings(
            _settings.copyWith(notifySecondHalfStart: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
        _buildSwitchTile(
          tr(context, 'Fine Partita'),
          tr(context, 'Fischio finale'),
          _settings.notifyMatchEnd,
          (value) => _updateSettings(
            _settings.copyWith(notifyMatchEnd: value),
          ),
          theme,
          isDark,
          enabled: _settings.enabled,
        ),
      ],
    );
  }

  Widget _buildPeriodicUpdatesSection(ThemeData theme, bool isDark) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: theme.primaryColor, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    tr(context, 'Aggiornamenti Periodici'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              tr(context, 'Ricevi aggiornamenti ogni X minuti'),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [0, 5, 10, 15, 30].map((minutes) {
                final isSelected = _settings.minuteUpdateInterval == minutes;
                return ChoiceChip(
                  label: Text(minutes == 0 ? 'Off' : '$minutes min'),
                  selected: isSelected,
                  onSelected: _settings.enabled
                      ? (selected) {
                          if (selected) {
                            _haptic.lightImpact();
                            _updateSettings(
                              _settings.copyWith(minuteUpdateInterval: minutes),
                            );
                          }
                        }
                      : null,
                  selectedColor: theme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? theme.primaryColor : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    ThemeData theme,
    bool isDark,
    List<Widget> children,
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
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    ThemeData theme,
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
            Icon(icon, size: 16, color: iconColor ?? theme.primaryColor),
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
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _settings.enabled
                      ? '${_settings.activeNotificationsCount} ${tr(context, 'eventi attivi')}'
                      : tr(context, 'Notifiche disattivate'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                Text(
                  tr(context, 'Le impostazioni sono salvate automaticamente'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _haptic.lightImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(tr(context, 'Fatto')),
          ),
        ],
      ),
    );
  }

  void _applyPreset(String presetName) {
    _prefsService.applyPreset(widget.match.id, presetName);
    setState(() {
      _settings = _prefsService.getSettingsForMatch(widget.match.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${tr(context, 'Preset')} "$presetName" ${tr(context, 'applicato')}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
