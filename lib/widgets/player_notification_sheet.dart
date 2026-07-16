// lib/widgets/player_notification_sheet.dart
// Pannello notifiche giocatore CONDIVISO, richiamabile da qualsiasi
// schermata (favorites, ricerca, top scorer, ...).
//
// Estratto dalla logica di favorites_screen per evitare duplicazioni.
// Apre un bottom sheet con gli interruttori delle notifiche giocatore
// (gol, assist, cartellini, ecc.), salvati per nome giocatore.
//
// Uso:
//   showPlayerNotificationSheet(
//     context,
//     playerName: 'Lautaro Martinez',
//     playerId: someId,
//     photo: 'https://...',   // opzionale
//   );
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/player_notification_preferences_service.dart';
import '../services/haptic_service.dart';
import '../generated/l10n.dart';
import '../utils/l10n_helper.dart';

final HapticService _haptic = HapticService();

/// Apre il pannello notifiche per un giocatore. Ritorna quando chiuso.
Future<void> showPlayerNotificationSheet(
  BuildContext context, {
  required String playerName,
  required int playerId,
  String? photo,
}) async {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final notifService = context.read<PlayerNotificationPreferencesService>();

  // Cerca settings per nome (qualsiasi ID)
  final allSettings = notifService.getPlayersWithActiveNotifications();
  final existing = allSettings.where((s) => s.playerName == playerName);
  var settings = existing.isNotEmpty
      ? existing.first
      : notifService.getSettingsForPlayer(playerId, playerName);

  final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
  final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
  final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final toggles = <String, bool>{
            'goals': settings.notifyGoals,
            'assists': settings.notifyAssists,
            'shotsOnTarget': settings.notifyShotsOnTarget,
            'dribblesSuccessful': settings.notifyDribblesSuccessful,
            'yellowCard': settings.notifyYellowCard,
            'redCard': settings.notifyRedCard,
            'foulCommitted': settings.notifyFoulCommitted,
            'foulSuffered': settings.notifyFoulSuffered,
            'substitutionOn': settings.notifySubstitutionOn,
            'keyPasses': settings.notifyKeyPasses,
            'offsides': settings.notifyOffsides,
          };
          final activeCount = toggles.values.where((v) => v).length;
          final allOn = toggles.values.every((v) => v);

          void update(String key, bool val) {
            setSheetState(() {
              settings = settings.copyWith(
                notifyGoals: key == 'goals' ? val : null,
                notifyAssists: key == 'assists' ? val : null,
                notifyShotsOnTarget: key == 'shotsOnTarget' ? val : null,
                notifyDribblesSuccessful:
                    key == 'dribblesSuccessful' ? val : null,
                notifyYellowCard: key == 'yellowCard' ? val : null,
                notifyRedCard: key == 'redCard' ? val : null,
                notifyFoulCommitted: key == 'foulCommitted' ? val : null,
                notifyFoulSuffered: key == 'foulSuffered' ? val : null,
                notifySubstitutionOn: key == 'substitutionOn' ? val : null,
                notifyKeyPasses: key == 'keyPasses' ? val : null,
                notifyOffsides: key == 'offsides' ? val : null,
                enabled: true,
              );
              notifService.saveSettingsForPlayer(settings);
              notifService.updateAllSettingsForPlayerByName(
                  playerName, settings);
            });
          }

          void setAll(bool val) {
            setSheetState(() {
              if (val) {
                settings = settings.copyWith(
                    notifyGoals: true,
                    notifyAssists: true,
                    notifyShotsOnTarget: true,
                    notifyDribblesSuccessful: true,
                    notifyYellowCard: true,
                    notifyRedCard: true,
                    notifyFoulCommitted: true,
                    notifyFoulSuffered: true,
                    notifySubstitutionOn: true,
                    notifyKeyPasses: true,
                    notifyOffsides: true,
                    enabled: true);
              } else {
                settings = settings.copyWith(
                    notifyGoals: false,
                    notifyAssists: false,
                    notifyShotsOnTarget: false,
                    notifyDribblesSuccessful: false,
                    notifyYellowCard: false,
                    notifyRedCard: false,
                    notifyFoulCommitted: false,
                    notifyFoulSuffered: false,
                    notifySubstitutionOn: false,
                    notifyKeyPasses: false,
                    notifyOffsides: false,
                    enabled: false);
              }
              notifService.saveSettingsForPlayer(settings);
              notifService.updateAllSettingsForPlayerByName(
                  playerName, settings);
            });
          }

          Widget tile(String key, IconData icon, String title, String sub,
              Color color) {
            final isOn = toggles[key] ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    _haptic.lightImpact();
                    update(key, !isOn);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                        color: isOn
                            ? color.withValues(alpha: isDark ? 0.12 : 0.06)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isOn
                                ? color.withValues(alpha: isDark ? 0.3 : 0.2)
                                : isDark
                                    ? Colors.white10
                                    : Colors.grey[200]!,
                            width: isOn ? 1.5 : 1)),
                    child: Row(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              color:
                                  color.withValues(alpha: isOn ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon,
                              size: 20,
                              color: isOn
                                  ? color
                                  : isDark
                                      ? Colors.white30
                                      : Colors.grey[400])),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(title,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isOn
                                        ? (isDark
                                            ? Colors.white
                                            : Colors.black87)
                                        : (isDark
                                            ? Colors.white54
                                            : Colors.grey[500]))),
                            const SizedBox(height: 2),
                            Text(sub,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.grey[400])),
                          ])),
                      AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 26,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              color: isOn
                                  ? color
                                  : isDark
                                      ? Colors.white12
                                      : Colors.grey[300]),
                          child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: isOn
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                  margin: const EdgeInsets.all(3),
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4)
                                      ])))),
                    ]),
                  ),
                ),
              ),
            );
          }

          Widget header(String t, IconData ic) => Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(children: [
                  Icon(ic,
                      size: 16,
                      color: isDark ? Colors.white38 : Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(t,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white38 : Colors.grey[500])),
                ]),
              );

          return Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
                color: bg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, -5))
                ]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(children: [
                    ClipOval(
                        child: CachedNetworkImage(
                            imageUrl: photo ?? '',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.primaryColor
                                        .withValues(alpha: 0.1)),
                                child: Icon(Icons.person,
                                    color: theme.primaryColor, size: 24)))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(playerName,
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: tx)),
                          const SizedBox(height: 2),
                          Text(
                              activeCount > 0
                                  ? '$activeCount/${toggles.length} ${tr(context, 'notifiche attive')}'
                                  : tr(context, 'Nessuna notifica attiva'),
                              style: TextStyle(fontSize: 13, color: lb)),
                        ])),
                    GestureDetector(
                        onTap: () {
                          _haptic.lightImpact();
                          setAll(!allOn);
                        },
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: allOn
                                    ? theme.primaryColor
                                    : isDark
                                        ? Colors.white10
                                        : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: allOn
                                        ? theme.primaryColor
                                        : isDark
                                            ? Colors.white24
                                            : Colors.grey[300]!)),
                            child: Text(
                                allOn
                                    ? S.of(context)!.deactivate
                                    : S.of(context)!.activateAll,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: allOn
                                        ? Colors.white
                                        : isDark
                                            ? Colors.white70
                                            : Colors.grey[700])))),
                  ])),
              Divider(
                  color: isDark ? Colors.white12 : Colors.grey[200], height: 1),
              Flexible(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header(S.of(context)!.offensive, Icons.sports_soccer),
                      tile('goals', Icons.sports_soccer,
                          S.of(context)!.goalNotif, S.of(context)!.goalDesc,
                          const Color(0xFF4CAF50)),
                      tile('assists', Icons.assistant_rounded,
                          S.of(context)!.assistNotif, S.of(context)!.assistDesc,
                          const Color(0xFF2196F3)),
                      tile('shotsOnTarget', Icons.gps_not_fixed,
                          S.of(context)!.shotsOnTargetNotif,
                          S.of(context)!.shotsOnTargetDesc,
                          const Color(0xFFFF7043)),
                      tile('keyPasses', Icons.trending_up,
                          S.of(context)!.keyPassesNotif,
                          S.of(context)!.keyPassesDesc,
                          const Color(0xFF26A69A)),
                      tile('dribblesSuccessful', Icons.directions_run,
                          S.of(context)!.dribblesNotif,
                          S.of(context)!.dribblesDesc,
                          const Color(0xFF66BB6A)),
                      tile('offsides', Icons.front_hand,
                          S.of(context)!.offsidesNotif,
                          S.of(context)!.offsidesDesc,
                          const Color(0xFF7E57C2)),
                      const SizedBox(height: 16),
                      header(S.of(context)!.discipline, Icons.style),
                      tile('yellowCard', Icons.square_rounded,
                          S.of(context)!.yellowCardNotif,
                          S.of(context)!.yellowCardDesc,
                          const Color(0xFFFFCA28)),
                      tile('redCard', Icons.square_rounded,
                          S.of(context)!.redCardNotif,
                          S.of(context)!.redCardDesc,
                          const Color(0xFFE53935)),
                      tile('foulCommitted', Icons.warning_amber,
                          S.of(context)!.foulsCommittedNotif,
                          S.of(context)!.foulsCommittedDesc,
                          const Color(0xFF8D6E63)),
                      tile('foulSuffered', Icons.personal_injury,
                          S.of(context)!.foulsSufferedNotif,
                          S.of(context)!.foulsSufferedDesc,
                          const Color(0xFF5C6BC0)),
                      const SizedBox(height: 16),
                      header(S.of(context)!.other, Icons.swap_horiz),
                      tile('substitutionOn', Icons.swap_horiz,
                          S.of(context)!.substitutionNotif,
                          S.of(context)!.substitutionDesc,
                          const Color(0xFF42A5F5)),
                    ]),
              )),
            ]),
          );
        },
      );
    },
  );
}
