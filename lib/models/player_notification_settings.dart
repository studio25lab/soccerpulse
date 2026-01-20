// lib/models/player_notification_settings.dart

/// Modello per le impostazioni di notifica di un singolo giocatore
class PlayerNotificationSettings {
  final int playerId;
  final String playerName;
  final int?
      matchId; // Opzionale: se vogliamo notifiche solo per un match specifico

  // Notifiche azioni offensive
  final bool notifyGoals;
  final bool notifyAssists;
  final bool notifyShotsOnTarget;
  final bool notifyShotsOffTarget;

  // Notifiche cartellini
  final bool notifyYellowCard;
  final bool notifyRedCard;

  // Notifiche falli
  final bool notifyFoulCommitted;
  final bool notifyFoulSuffered;

  // Notifiche sostituzioni
  final bool notifySubstitutionOn;
  final bool notifySubstitutionOff;

  // Notifiche azioni difensive
  final bool notifyInterceptions;
  final bool notifyTackles;
  final bool notifyClearances;

  // Notifiche salvataggi (per portieri)
  final bool notifySaves;
  final bool notifyPenaltySaved;

  // Notifiche altre azioni
  final bool notifyKeyPasses;
  final bool notifyDribblesSuccessful;
  final bool notifyOffsides;

  // Abilitazione generale
  final bool enabled;

  PlayerNotificationSettings({
    required this.playerId,
    required this.playerName,
    this.matchId,
    this.notifyGoals = true,
    this.notifyAssists = true,
    this.notifyShotsOnTarget = false,
    this.notifyShotsOffTarget = false,
    this.notifyYellowCard = true,
    this.notifyRedCard = true,
    this.notifyFoulCommitted = false,
    this.notifyFoulSuffered = false,
    this.notifySubstitutionOn = true,
    this.notifySubstitutionOff = true,
    this.notifyInterceptions = false,
    this.notifyTackles = false,
    this.notifyClearances = false,
    this.notifySaves = false,
    this.notifyPenaltySaved = true,
    this.notifyKeyPasses = false,
    this.notifyDribblesSuccessful = false,
    this.notifyOffsides = false,
    this.enabled = true,
  });

  // Preset configurazioni rapide
  static PlayerNotificationSettings attackerPreset(
      int playerId, String playerName,
      {int? matchId}) {
    return PlayerNotificationSettings(
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      notifyGoals: true,
      notifyAssists: true,
      notifyShotsOnTarget: true,
      notifyKeyPasses: true,
      notifyDribblesSuccessful: true,
      notifyYellowCard: true,
      notifyRedCard: true,
      enabled: true,
    );
  }

  static PlayerNotificationSettings midfielderPreset(
      int playerId, String playerName,
      {int? matchId}) {
    return PlayerNotificationSettings(
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      notifyGoals: true,
      notifyAssists: true,
      notifyKeyPasses: true,
      notifyTackles: true,
      notifyInterceptions: true,
      notifyYellowCard: true,
      notifyRedCard: true,
      enabled: true,
    );
  }

  static PlayerNotificationSettings defenderPreset(
      int playerId, String playerName,
      {int? matchId}) {
    return PlayerNotificationSettings(
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      notifyGoals: true,
      notifyYellowCard: true,
      notifyRedCard: true,
      notifyTackles: true,
      notifyInterceptions: true,
      notifyClearances: true,
      notifyFoulCommitted: true,
      enabled: true,
    );
  }

  static PlayerNotificationSettings goalkeeperPreset(
      int playerId, String playerName,
      {int? matchId}) {
    return PlayerNotificationSettings(
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      notifyYellowCard: true,
      notifyRedCard: true,
      notifySaves: true,
      notifyPenaltySaved: true,
      enabled: true,
    );
  }

  static PlayerNotificationSettings essentialOnly(
      int playerId, String playerName,
      {int? matchId}) {
    return PlayerNotificationSettings(
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      notifyGoals: true,
      notifyAssists: true,
      notifyYellowCard: true,
      notifyRedCard: true,
      enabled: true,
    );
  }

  static PlayerNotificationSettings disabled(int playerId, String playerName,
      {int? matchId}) {
    return PlayerNotificationSettings(
      playerId: playerId,
      playerName: playerName,
      matchId: matchId,
      enabled: false,
    );
  }

  // Copia con modifiche
  PlayerNotificationSettings copyWith({
    int? playerId,
    String? playerName,
    int? matchId,
    bool? notifyGoals,
    bool? notifyAssists,
    bool? notifyShotsOnTarget,
    bool? notifyShotsOffTarget,
    bool? notifyYellowCard,
    bool? notifyRedCard,
    bool? notifyFoulCommitted,
    bool? notifyFoulSuffered,
    bool? notifySubstitutionOn,
    bool? notifySubstitutionOff,
    bool? notifyInterceptions,
    bool? notifyTackles,
    bool? notifyClearances,
    bool? notifySaves,
    bool? notifyPenaltySaved,
    bool? notifyKeyPasses,
    bool? notifyDribblesSuccessful,
    bool? notifyOffsides,
    bool? enabled,
  }) {
    return PlayerNotificationSettings(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      matchId: matchId ?? this.matchId,
      notifyGoals: notifyGoals ?? this.notifyGoals,
      notifyAssists: notifyAssists ?? this.notifyAssists,
      notifyShotsOnTarget: notifyShotsOnTarget ?? this.notifyShotsOnTarget,
      notifyShotsOffTarget: notifyShotsOffTarget ?? this.notifyShotsOffTarget,
      notifyYellowCard: notifyYellowCard ?? this.notifyYellowCard,
      notifyRedCard: notifyRedCard ?? this.notifyRedCard,
      notifyFoulCommitted: notifyFoulCommitted ?? this.notifyFoulCommitted,
      notifyFoulSuffered: notifyFoulSuffered ?? this.notifyFoulSuffered,
      notifySubstitutionOn: notifySubstitutionOn ?? this.notifySubstitutionOn,
      notifySubstitutionOff:
          notifySubstitutionOff ?? this.notifySubstitutionOff,
      notifyInterceptions: notifyInterceptions ?? this.notifyInterceptions,
      notifyTackles: notifyTackles ?? this.notifyTackles,
      notifyClearances: notifyClearances ?? this.notifyClearances,
      notifySaves: notifySaves ?? this.notifySaves,
      notifyPenaltySaved: notifyPenaltySaved ?? this.notifyPenaltySaved,
      notifyKeyPasses: notifyKeyPasses ?? this.notifyKeyPasses,
      notifyDribblesSuccessful:
          notifyDribblesSuccessful ?? this.notifyDribblesSuccessful,
      notifyOffsides: notifyOffsides ?? this.notifyOffsides,
      enabled: enabled ?? this.enabled,
    );
  }

  // Serializzazione JSON
  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'matchId': matchId,
      'notifyGoals': notifyGoals,
      'notifyAssists': notifyAssists,
      'notifyShotsOnTarget': notifyShotsOnTarget,
      'notifyShotsOffTarget': notifyShotsOffTarget,
      'notifyYellowCard': notifyYellowCard,
      'notifyRedCard': notifyRedCard,
      'notifyFoulCommitted': notifyFoulCommitted,
      'notifyFoulSuffered': notifyFoulSuffered,
      'notifySubstitutionOn': notifySubstitutionOn,
      'notifySubstitutionOff': notifySubstitutionOff,
      'notifyInterceptions': notifyInterceptions,
      'notifyTackles': notifyTackles,
      'notifyClearances': notifyClearances,
      'notifySaves': notifySaves,
      'notifyPenaltySaved': notifyPenaltySaved,
      'notifyKeyPasses': notifyKeyPasses,
      'notifyDribblesSuccessful': notifyDribblesSuccessful,
      'notifyOffsides': notifyOffsides,
      'enabled': enabled,
    };
  }

  factory PlayerNotificationSettings.fromJson(Map<String, dynamic> json) {
    return PlayerNotificationSettings(
      playerId: json['playerId'] as int,
      playerName: json['playerName'] as String,
      matchId: json['matchId'] as int?,
      notifyGoals: json['notifyGoals'] as bool? ?? true,
      notifyAssists: json['notifyAssists'] as bool? ?? true,
      notifyShotsOnTarget: json['notifyShotsOnTarget'] as bool? ?? false,
      notifyShotsOffTarget: json['notifyShotsOffTarget'] as bool? ?? false,
      notifyYellowCard: json['notifyYellowCard'] as bool? ?? true,
      notifyRedCard: json['notifyRedCard'] as bool? ?? true,
      notifyFoulCommitted: json['notifyFoulCommitted'] as bool? ?? false,
      notifyFoulSuffered: json['notifyFoulSuffered'] as bool? ?? false,
      notifySubstitutionOn: json['notifySubstitutionOn'] as bool? ?? true,
      notifySubstitutionOff: json['notifySubstitutionOff'] as bool? ?? true,
      notifyInterceptions: json['notifyInterceptions'] as bool? ?? false,
      notifyTackles: json['notifyTackles'] as bool? ?? false,
      notifyClearances: json['notifyClearances'] as bool? ?? false,
      notifySaves: json['notifySaves'] as bool? ?? false,
      notifyPenaltySaved: json['notifyPenaltySaved'] as bool? ?? true,
      notifyKeyPasses: json['notifyKeyPasses'] as bool? ?? false,
      notifyDribblesSuccessful:
          json['notifyDribblesSuccessful'] as bool? ?? false,
      notifyOffsides: json['notifyOffsides'] as bool? ?? false,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  // Helper per contare notifiche attive
  int get activeNotificationsCount {
    int count = 0;
    if (notifyGoals) count++;
    if (notifyAssists) count++;
    if (notifyShotsOnTarget) count++;
    if (notifyShotsOffTarget) count++;
    if (notifyYellowCard) count++;
    if (notifyRedCard) count++;
    if (notifyFoulCommitted) count++;
    if (notifyFoulSuffered) count++;
    if (notifySubstitutionOn) count++;
    if (notifySubstitutionOff) count++;
    if (notifyInterceptions) count++;
    if (notifyTackles) count++;
    if (notifyClearances) count++;
    if (notifySaves) count++;
    if (notifyPenaltySaved) count++;
    if (notifyKeyPasses) count++;
    if (notifyDribblesSuccessful) count++;
    if (notifyOffsides) count++;
    return count;
  }

  bool get hasActiveNotifications {
    return enabled && activeNotificationsCount > 0;
  }

  // Chiave univoca per il giocatore
  String get key {
    if (matchId != null) {
      return '${playerId}_$matchId';
    }
    return playerId.toString();
  }

  @override
  String toString() {
    return 'PlayerNotificationSettings(playerId: $playerId, playerName: $playerName, enabled: $enabled, active: $activeNotificationsCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerNotificationSettings &&
        other.playerId == playerId &&
        other.matchId == matchId;
  }

  @override
  int get hashCode => Object.hash(playerId, matchId);
}
