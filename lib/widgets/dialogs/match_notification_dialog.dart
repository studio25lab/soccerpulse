// lib/widgets/dialogs/match_notification_dialog.dart
//
// Dialog per gestire le preferenze di notifica per una specifica partita.
// Estratto da match_detail_screen.dart per ridurre il monolite.
//
// Pattern: funzione top-level che riceve callback per accedere e modificare
// lo state del widget chiamante. Cosi il dialog e' riusabile e testabile.
//
// // [FAV-extract-match-notif-dialog]

import 'package:flutter/material.dart';
import '../../models/soccer_match.dart';
import '../../models/match_notification_settings.dart';
import '../../services/haptic_service.dart';
import '../../services/match_notification_preferences_service.dart';
import '../../utils/l10n_helper.dart';
import '../notification_settings_widgets.dart';

/// Mostra il bottom sheet di gestione notifiche per una partita.
///
/// I callback gestiscono lettura/scrittura dello state del widget chiamante:
/// - [getSettings] / [setSettings]: accesso bidirezionale alle settings.
/// - [onUpdateFromKey]: aggiorna una singola chiave (es. "goals", "fouls").
/// - [onSetAll]: attiva/disattiva tutte le notifiche.
Future<void> showMatchNotificationDialogV2(
  BuildContext context, {
  required SoccerMatch match,
  required MatchNotificationSettings Function() getSettings,
  required void Function(MatchNotificationSettings) setSettings,
  required MatchNotificationPreferencesService service,
  required HapticService haptic,
  required void Function(String key, bool value) onUpdateFromKey,
  required void Function(bool value) onSetAll,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final s = getSettings();
          final en = s.enabled;

          final allOn = s.notifyHomeGoals &&
              s.notifyAwayGoals &&
              s.notifyPenalties &&
              s.notifyVarDecisions &&
              s.notifyMatchStart &&
              s.notifyHalfTime &&
              s.notifyMatchEnd &&
              s.notifyYellowCards &&
              s.notifyRedCards &&
              s.notifySubstitutions &&
              s.notifyCorners &&
              s.notifyOffsides &&
              s.notifyShotsOnTarget &&
              s.notifyFouls;

          final activeCount = s.activeNotificationsCount;

          void refresh() {
            setSheetState(() {});
          }

          void toggle(String key, bool value) {
            haptic.lightImpact();
            onUpdateFromKey(key, value);
            refresh();
          }

          void toggleAll() {
            haptic.lightImpact();
            onSetAll(!allOn);
            refresh();
          }

          void applyPreset(String name) {
            haptic.mediumImpact();
            MatchNotificationSettings next;
            switch (name) {
              case 'goals':
                next = MatchNotificationSettings.goalsOnly(match.id);
                break;
              case 'minimal':
                next = MatchNotificationSettings.minimal(match.id);
                break;
              case 'complete':
                next = MatchNotificationSettings.complete(match.id);
                break;
              case 'disabled':
                next = MatchNotificationSettings.disabled(match.id);
                break;
              default:
                return;
            }
            setSettings(next);
            service.saveSettingsForMatch(next);
            refresh();
          }

          void setMaster(bool value) {
            haptic.lightImpact();
            final next = s.copyWith(enabled: value);
            setSettings(next);
            service.saveSettingsForMatch(next);
            refresh();
          }

          return NotifSheetContainer(
            children: [
              NotifSheetHeader(
                title: tr(context, 'Notifiche Partita'),
                subtitle:
                    '${match.homeTeamName} vs ${match.awayTeamName}',
                allOn: allOn,
                onToggleAll: toggleAll,
                onClose: () {
                  haptic.lightImpact();
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      NotifPresetChips(
                        presets: [
                          NotifPresetChipData(
                            label: tr(context, 'Solo Goal'),
                            icon: Icons.sports_soccer,
                            onTap: () => applyPreset('goals'),
                          ),
                          NotifPresetChipData(
                            label: tr(context, 'Predefinito'),
                            icon: Icons.notifications_none,
                            onTap: () => applyPreset('minimal'),
                          ),
                          NotifPresetChipData(
                            label: tr(context, 'Completo'),
                            icon: Icons.notifications_active,
                            onTap: () => applyPreset('complete'),
                          ),
                          NotifPresetChipData(
                            label: tr(context, 'Disattiva tutto'),
                            icon: Icons.notifications_off,
                            onTap: () => applyPreset('disabled'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      NotifMasterSwitch(
                        title: tr(context, 'Notifiche Partita'),
                        subtitle: en
                            ? '$activeCount ${tr(context, 'eventi attivi')}'
                            : tr(context, 'Disattivate'),
                        value: en,
                        onChanged: setMaster,
                      ),
                      const SizedBox(height: 4),
                      NotifSectionHeader(
                        title: tr(context, 'Risultato'),
                        icon: Icons.flag_rounded,
                      ),
                      NotifSwitchRow(
                        icon: Icons.sports_soccer,
                        color: const Color(0xFF4CAF50),
                        title: tr(context, 'Goal'),
                        subtitle:
                            tr(context, 'Notifica con marcatore e minuto'),
                        value: s.notifyHomeGoals,
                        enabled: en,
                        onChanged: (v) => toggle('goals', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.gps_fixed_rounded,
                        color: const Color(0xFFE91E63),
                        title: tr(context, 'Rigori'),
                        subtitle: tr(context,
                            'Rigori assegnati, segnati e sbagliati'),
                        value: s.notifyPenalties,
                        enabled: en,
                        onChanged: (v) => toggle('penalties', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.videocam_rounded,
                        color: const Color(0xFF2196F3),
                        title: tr(context, 'Decisioni VAR'),
                        subtitle: tr(context,
                            'Revisioni e decisioni arbitrali al VAR'),
                        value: s.notifyVarDecisions,
                        enabled: en,
                        onChanged: (v) => toggle('var', v),
                      ),
                      NotifSectionHeader(
                        title: tr(context, 'Tempi di gioco'),
                        icon: Icons.timer_rounded,
                      ),
                      NotifSwitchRow(
                        icon: Icons.play_circle_outline_rounded,
                        color: const Color(0xFF66BB6A),
                        title: tr(context, 'Inizio tempo'),
                        subtitle:
                            tr(context, 'Calcio d\'inizio 1° e 2° tempo'),
                        value: s.notifyMatchStart,
                        enabled: en,
                        onChanged: (v) => toggle('kickoff', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.pause_circle_outline_rounded,
                        color: const Color(0xFFFFA726),
                        title: tr(context, 'Fine primo tempo'),
                        subtitle: tr(context,
                            'Risultato parziale all\'intervallo'),
                        value: s.notifyHalfTime,
                        enabled: en,
                        onChanged: (v) => toggle('halftime', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.stop_circle_outlined,
                        color: const Color(0xFFEF5350),
                        title: tr(context, 'Fischio finale'),
                        subtitle:
                            tr(context, 'Risultato finale della partita'),
                        value: s.notifyMatchEnd,
                        enabled: en,
                        onChanged: (v) => toggle('fulltime', v),
                      ),
                      NotifSectionHeader(
                        title: tr(context, 'Disciplina'),
                        icon: Icons.shield_rounded,
                      ),
                      NotifSwitchRow(
                        icon: Icons.square_rounded,
                        color: const Color(0xFFFFCA28),
                        title: tr(context, 'Cartellini gialli'),
                        subtitle: tr(context, 'Ammonizioni e doppi gialli'),
                        value: s.notifyYellowCards,
                        enabled: en,
                        onChanged: (v) => toggle('yellowCards', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.square_rounded,
                        color: const Color(0xFFE53935),
                        title: tr(context, 'Cartellini rossi'),
                        subtitle: tr(context,
                            'Espulsioni dirette e per doppio giallo'),
                        value: s.notifyRedCards,
                        enabled: en,
                        onChanged: (v) => toggle('redCards', v),
                      ),
                      NotifSectionHeader(
                        title: tr(context, 'Eventi di gioco'),
                        icon: Icons.sports_rounded,
                      ),
                      NotifSwitchRow(
                        icon: Icons.swap_horiz_rounded,
                        color: const Color(0xFF42A5F5),
                        title: tr(context, 'Sostituzioni'),
                        subtitle: tr(context,
                            'Cambi effettuati da entrambe le squadre'),
                        value: s.notifySubstitutions,
                        enabled: en,
                        onChanged: (v) => toggle('substitutions', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.flag_outlined,
                        color: const Color(0xFF26A69A),
                        title: tr(context, 'Calci d\'angolo'),
                        subtitle: tr(context,
                            'Corner battuti da entrambe le squadre'),
                        value: s.notifyCorners,
                        enabled: en,
                        onChanged: (v) => toggle('corners', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.front_hand_rounded,
                        color: const Color(0xFF7E57C2),
                        title: tr(context, 'Fuorigioco'),
                        subtitle:
                            tr(context, 'Posizioni di offside segnalate'),
                        value: s.notifyOffsides,
                        enabled: en,
                        onChanged: (v) => toggle('offsides', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.gps_fixed,
                        color: const Color(0xFFFF7043),
                        title: tr(context, 'Tiri in porta'),
                        subtitle: tr(context,
                            'Tiri nello specchio della porta'),
                        value: s.notifyShotsOnTarget,
                        enabled: en,
                        onChanged: (v) => toggle('shotsOnTarget', v),
                      ),
                      NotifSwitchRow(
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFF8D6E63),
                        title: tr(context, 'Falli'),
                        subtitle: tr(context, 'Falli commessi in campo'),
                        value: s.notifyFouls,
                        enabled: en,
                        onChanged: (v) => toggle('fouls', v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
