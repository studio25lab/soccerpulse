// lib/widgets/team_notification_settings_bottom_sheet.dart
// [FAV-D2a] team sheet unificato

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/team_notification_settings.dart';
import '../models/team_standing.dart';
import '../services/team_notification_preferences_service.dart';
import '../services/haptic_service.dart';
import 'notification_settings_widgets.dart';

/// Bottom sheet dettagliato per configurare le notifiche di una SQUADRA.
/// Stile unificato con il bottom sheet dei match (widget condivisi).
class TeamNotificationSettingsBottomSheet extends StatefulWidget {
  final int teamId;
  final String teamName;

  const TeamNotificationSettingsBottomSheet({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  static Future<void> show(
    BuildContext context, {
    required int teamId,
    required String teamName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TeamNotificationSettingsBottomSheet(
        teamId: teamId,
        teamName: teamName,
      ),
    );
  }

  static Future<void> showForTeam(BuildContext context, TeamStanding team) {
    return show(context, teamId: team.teamId, teamName: team.teamName);
  }

  @override
  State<TeamNotificationSettingsBottomSheet> createState() =>
      _TeamNotificationSettingsBottomSheetState();
}

class _TeamNotificationSettingsBottomSheetState
    extends State<TeamNotificationSettingsBottomSheet> {
  final HapticService _haptic = HapticService();
  late TeamNotificationSettings _settings;
  late TeamNotificationPreferencesService _prefsService;

  @override
  void initState() {
    super.initState();
    _prefsService = context.read<TeamNotificationPreferencesService>();
    _settings = _prefsService.getSettingsForTeam(widget.teamId);
  }

  void _update(TeamNotificationSettings s) {
    setState(() => _settings = s);
    _prefsService.saveSettingsForTeam(s);
  }

  /// Tutte le notifiche di dettaglio sono attive?
  bool get _allOn =>
      _settings.notifyTeamGoals &&
      _settings.notifyOpponentGoals &&
      _settings.notifyYellowCards &&
      _settings.notifyRedCards &&
      _settings.notifySubstitutions &&
      _settings.notifyShotsOnTarget &&
      _settings.notifyCorners &&
      _settings.notifyPenalties &&
      _settings.notifyFouls &&
      _settings.notifyOffsides &&
      _settings.notifyMatchStart &&
      _settings.notifyHalfTime &&
      _settings.notifySecondHalfStart &&
      _settings.notifyMatchEnd &&
      _settings.notifyVarDecisions;

  void _toggleAll() {
    _haptic.lightImpact();
    _update(_allOn
        ? TeamNotificationSettings.disabled(widget.teamId)
        : TeamNotificationSettings.complete(widget.teamId));
  }

  void _applyPreset(String name) {
    _haptic.mediumImpact();
    TeamNotificationSettings p;
    switch (name) {
      case 'goals':
        p = TeamNotificationSettings.goalsOnly(widget.teamId);
        break;
      case 'complete':
        p = TeamNotificationSettings.complete(widget.teamId);
        break;
      case 'disabled':
        p = TeamNotificationSettings.disabled(widget.teamId);
        break;
      case 'default':
      default:
        p = TeamNotificationSettings.defaultEnabled(widget.teamId);
    }
    _update(p);
  }

  @override
  Widget build(BuildContext context) {
    final en = _settings.enabled;
    final count = _settings.activeNotificationsCount;

    return NotifSheetContainer(
      children: [
        NotifSheetHeader(
          title: tr(context, 'Notifiche Squadra'),
          subtitle: widget.teamName,
          allOn: _allOn,
          onToggleAll: _toggleAll,
          onClose: () {
            _haptic.lightImpact();
            Navigator.pop(context);
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NotifPresetChips(
                  presets: [
                    NotifPresetChipData(
                      label: tr(context, 'Solo Goal'),
                      icon: Icons.sports_soccer,
                      onTap: () => _applyPreset('goals'),
                    ),
                    NotifPresetChipData(
                      label: tr(context, 'Predefinito'),
                      icon: Icons.notifications_none,
                      onTap: () => _applyPreset('default'),
                    ),
                    NotifPresetChipData(
                      label: tr(context, 'Completo'),
                      icon: Icons.notifications_active,
                      onTap: () => _applyPreset('complete'),
                    ),
                    NotifPresetChipData(
                      label: tr(context, 'Disattiva tutto'),
                      icon: Icons.notifications_off,
                      onTap: () => _applyPreset('disabled'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                NotifMasterSwitch(
                  title: tr(context, 'Notifiche Squadra'),
                  subtitle: en
                      ? '$count ${tr(context, 'eventi attivi')}'
                      : tr(context, 'Disattivate'),
                  value: en,
                  onChanged: (v) {
                    _haptic.lightImpact();
                    _update(_settings.copyWith(enabled: v));
                  },
                ),
                const SizedBox(height: 4),

                NotifSectionHeader(
                  title: tr(context, 'Goal'),
                  icon: Icons.flag_rounded,
                ),
                NotifSwitchRow(
                  icon: Icons.sports_soccer,
                  color: const Color(0xFF4CAF50),
                  title: tr(context, 'Goal della Squadra'),
                  subtitle: tr(context, 'Quando segna la squadra seguita'),
                  value: _settings.notifyTeamGoals,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyTeamGoals: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.sports_soccer_outlined,
                  color: const Color(0xFF66BB6A),
                  title: tr(context, 'Goal degli Avversari'),
                  subtitle:
                      tr(context, 'Quando segna la squadra avversaria'),
                  value: _settings.notifyOpponentGoals,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyOpponentGoals: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.gps_fixed_rounded,
                  color: const Color(0xFFE91E63),
                  title: tr(context, 'Rigori'),
                  subtitle: tr(context, 'Calci di rigore assegnati'),
                  value: _settings.notifyPenalties,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyPenalties: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.videocam_rounded,
                  color: const Color(0xFF2196F3),
                  title: tr(context, 'Decisioni VAR'),
                  subtitle: tr(context, 'Review e decisioni arbitrali'),
                  value: _settings.notifyVarDecisions,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyVarDecisions: v)),
                ),

                NotifSectionHeader(
                  title: tr(context, 'Tempi di gioco'),
                  icon: Icons.timer_rounded,
                ),
                NotifSwitchRow(
                  icon: Icons.play_circle_outline_rounded,
                  color: const Color(0xFF66BB6A),
                  title: tr(context, 'Inizio Partita'),
                  subtitle: tr(context, 'Fischio d\'inizio'),
                  value: _settings.notifyMatchStart,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyMatchStart: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.pause_circle_outline_rounded,
                  color: const Color(0xFFFFA726),
                  title: tr(context, 'Fine Primo Tempo'),
                  subtitle: tr(context, 'Intervallo'),
                  value: _settings.notifyHalfTime,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyHalfTime: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.replay_circle_filled_rounded,
                  color: const Color(0xFF26A69A),
                  title: tr(context, 'Inizio Secondo Tempo'),
                  subtitle: tr(context, 'Ripresa del gioco'),
                  value: _settings.notifySecondHalfStart,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifySecondHalfStart: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.stop_circle_outlined,
                  color: const Color(0xFFEF5350),
                  title: tr(context, 'Fine Partita'),
                  subtitle: tr(context, 'Fischio finale'),
                  value: _settings.notifyMatchEnd,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyMatchEnd: v)),
                ),

                NotifSectionHeader(
                  title: tr(context, 'Disciplina'),
                  icon: Icons.shield_rounded,
                ),
                NotifSwitchRow(
                  icon: Icons.square_rounded,
                  color: const Color(0xFFFFCA28),
                  title: tr(context, 'Cartellini Gialli'),
                  subtitle:
                      tr(context, 'Ammonizioni durante la partita'),
                  value: _settings.notifyYellowCards,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyYellowCards: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.square_rounded,
                  color: const Color(0xFFE53935),
                  title: tr(context, 'Cartellini Rossi'),
                  subtitle:
                      tr(context, 'Espulsioni durante la partita'),
                  value: _settings.notifyRedCards,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyRedCards: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.swap_horiz_rounded,
                  color: const Color(0xFF42A5F5),
                  title: tr(context, 'Sostituzioni'),
                  subtitle: tr(context, 'Cambi giocatori'),
                  value: _settings.notifySubstitutions,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifySubstitutions: v)),
                ),

                NotifSectionHeader(
                  title: tr(context, 'Gioco'),
                  icon: Icons.sports_rounded,
                ),
                NotifSwitchRow(
                  icon: Icons.flag_outlined,
                  color: const Color(0xFF26A69A),
                  title: tr(context, 'Calci d\'Angolo'),
                  subtitle: tr(context, 'Corner assegnati'),
                  value: _settings.notifyCorners,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyCorners: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.front_hand_rounded,
                  color: const Color(0xFF8D6E63),
                  title: tr(context, 'Fuorigioco'),
                  subtitle: tr(context, 'Posizioni di fuorigioco'),
                  value: _settings.notifyOffsides,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyOffsides: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.gps_fixed,
                  color: const Color(0xFF5C6BC0),
                  title: tr(context, 'Tiri in Porta'),
                  subtitle:
                      tr(context, 'Tiri nello specchio della porta'),
                  value: _settings.notifyShotsOnTarget,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyShotsOnTarget: v)),
                ),
                NotifSwitchRow(
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFF78909C),
                  title: tr(context, 'Falli'),
                  subtitle:
                      tr(context, 'Falli commessi durante la partita'),
                  value: _settings.notifyFouls,
                  enabled: en,
                  onChanged: (v) =>
                      _update(_settings.copyWith(notifyFouls: v)),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().slideY(
          begin: 1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}
