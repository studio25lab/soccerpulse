// lib/models/match_notification_settings.dart

/// Modello per le impostazioni di notifica di una singola partita
class MatchNotificationSettings {
  final int matchId;

  // Notifiche goal
  final bool notifyHomeGoals;
  final bool notifyAwayGoals;

  // Notifiche cartellini
  final bool notifyYellowCards;
  final bool notifyRedCards;

  // Notifiche sostituzioni
  final bool notifySubstitutions;

  // Notifiche tiri e azioni
  final bool notifyShotsOnTarget;
  final bool notifyCorners;
  final bool notifyPenalties;
  final bool notifyFouls;
  final bool notifyOffsides;

  // Notifiche eventi partita
  final bool notifyMatchStart;
  final bool notifyHalfTime;
  final bool notifySecondHalfStart;
  final bool notifyMatchEnd;

  // Notifiche VAR
  final bool notifyVarDecisions;

  // Notifiche ogni X minuti (0 = disattivato)
  final int minuteUpdateInterval;

  // Abilitazione generale per questo match
  final bool enabled;

  MatchNotificationSettings({
    required this.matchId,
    this.notifyHomeGoals = true,
    this.notifyAwayGoals = true,
    this.notifyYellowCards = false,
    this.notifyRedCards = true,
    this.notifySubstitutions = false,
    this.notifyShotsOnTarget = false,
    this.notifyCorners = false,
    this.notifyPenalties = true,
    this.notifyFouls = false,
    this.notifyOffsides = false,
    this.notifyMatchStart = true,
    this.notifyHalfTime = false,
    this.notifySecondHalfStart = false,
    this.notifyMatchEnd = true,
    this.notifyVarDecisions = true,
    this.minuteUpdateInterval = 0,
    this.enabled = true,
  });

  // Preset configurazioni rapide
  static MatchNotificationSettings minimal(int matchId) {
    return MatchNotificationSettings(
      matchId: matchId,
      notifyHomeGoals: true,
      notifyAwayGoals: true,
      notifyRedCards: true,
      notifyMatchStart: true,
      notifyMatchEnd: true,
      enabled: true,
    );
  }

  static MatchNotificationSettings complete(int matchId) {
    return MatchNotificationSettings(
      matchId: matchId,
      notifyHomeGoals: true,
      notifyAwayGoals: true,
      notifyYellowCards: true,
      notifyRedCards: true,
      notifySubstitutions: true,
      notifyShotsOnTarget: true,
      notifyCorners: true,
      notifyPenalties: true,
      notifyMatchStart: true,
      notifyHalfTime: true,
      notifySecondHalfStart: true,
      notifyMatchEnd: true,
      notifyVarDecisions: true,
      minuteUpdateInterval: 15,
      enabled: true,
    );
  }

  static MatchNotificationSettings goalsOnly(int matchId) {
    return MatchNotificationSettings(
      matchId: matchId,
      notifyHomeGoals: true,
      notifyAwayGoals: true,
      notifyRedCards: false,
      notifyMatchStart: false,
      notifyMatchEnd: false,
      enabled: true,
    );
  }

  static MatchNotificationSettings disabled(int matchId) {
    return MatchNotificationSettings(
      matchId: matchId,
      enabled: false,
    );
  }

  // Copia con modifiche
  MatchNotificationSettings copyWith({
    int? matchId,
    bool? notifyHomeGoals,
    bool? notifyAwayGoals,
    bool? notifyYellowCards,
    bool? notifyRedCards,
    bool? notifySubstitutions,
    bool? notifyShotsOnTarget,
    bool? notifyCorners,
    bool? notifyPenalties,
    bool? notifyFouls,
    bool? notifyOffsides,
    bool? notifyMatchStart,
    bool? notifyHalfTime,
    bool? notifySecondHalfStart,
    bool? notifyMatchEnd,
    bool? notifyVarDecisions,
    int? minuteUpdateInterval,
    bool? enabled,
  }) {
    return MatchNotificationSettings(
      matchId: matchId ?? this.matchId,
      notifyHomeGoals: notifyHomeGoals ?? this.notifyHomeGoals,
      notifyAwayGoals: notifyAwayGoals ?? this.notifyAwayGoals,
      notifyYellowCards: notifyYellowCards ?? this.notifyYellowCards,
      notifyRedCards: notifyRedCards ?? this.notifyRedCards,
      notifySubstitutions: notifySubstitutions ?? this.notifySubstitutions,
      notifyShotsOnTarget: notifyShotsOnTarget ?? this.notifyShotsOnTarget,
      notifyCorners: notifyCorners ?? this.notifyCorners,
      notifyPenalties: notifyPenalties ?? this.notifyPenalties,
      notifyFouls: notifyFouls ?? this.notifyFouls,
      notifyOffsides: notifyOffsides ?? this.notifyOffsides,
      notifyMatchStart: notifyMatchStart ?? this.notifyMatchStart,
      notifyHalfTime: notifyHalfTime ?? this.notifyHalfTime,
      notifySecondHalfStart:
          notifySecondHalfStart ?? this.notifySecondHalfStart,
      notifyMatchEnd: notifyMatchEnd ?? this.notifyMatchEnd,
      notifyVarDecisions: notifyVarDecisions ?? this.notifyVarDecisions,
      minuteUpdateInterval: minuteUpdateInterval ?? this.minuteUpdateInterval,
      enabled: enabled ?? this.enabled,
    );
  }

  // Serializzazione JSON per persistenza
  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'notifyHomeGoals': notifyHomeGoals,
      'notifyAwayGoals': notifyAwayGoals,
      'notifyYellowCards': notifyYellowCards,
      'notifyRedCards': notifyRedCards,
      'notifySubstitutions': notifySubstitutions,
      'notifyShotsOnTarget': notifyShotsOnTarget,
      'notifyCorners': notifyCorners,
      'notifyPenalties': notifyPenalties,
      'notifyFouls': notifyFouls,
      'notifyOffsides': notifyOffsides,
      'notifyMatchStart': notifyMatchStart,
      'notifyHalfTime': notifyHalfTime,
      'notifySecondHalfStart': notifySecondHalfStart,
      'notifyMatchEnd': notifyMatchEnd,
      'notifyVarDecisions': notifyVarDecisions,
      'minuteUpdateInterval': minuteUpdateInterval,
      'enabled': enabled,
    };
  }

  factory MatchNotificationSettings.fromJson(Map<String, dynamic> json) {
    return MatchNotificationSettings(
      matchId: json['matchId'] as int,
      notifyHomeGoals: json['notifyHomeGoals'] as bool? ?? true,
      notifyAwayGoals: json['notifyAwayGoals'] as bool? ?? true,
      notifyYellowCards: json['notifyYellowCards'] as bool? ?? false,
      notifyRedCards: json['notifyRedCards'] as bool? ?? true,
      notifySubstitutions: json['notifySubstitutions'] as bool? ?? false,
      notifyShotsOnTarget: json['notifyShotsOnTarget'] as bool? ?? false,
      notifyCorners: json['notifyCorners'] as bool? ?? false,
      notifyPenalties: json['notifyPenalties'] as bool? ?? true,
      notifyFouls: json['notifyFouls'] as bool? ?? false,
      notifyOffsides: json['notifyOffsides'] as bool? ?? false,
      notifyMatchStart: json['notifyMatchStart'] as bool? ?? true,
      notifyHalfTime: json['notifyHalfTime'] as bool? ?? false,
      notifySecondHalfStart: json['notifySecondHalfStart'] as bool? ?? false,
      notifyMatchEnd: json['notifyMatchEnd'] as bool? ?? true,
      notifyVarDecisions: json['notifyVarDecisions'] as bool? ?? true,
      minuteUpdateInterval: json['minuteUpdateInterval'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  // Helper per contare notifiche attive
  int get activeNotificationsCount {
    int count = 0;
    if (notifyHomeGoals) count++;
    if (notifyAwayGoals) count++;
    if (notifyYellowCards) count++;
    if (notifyRedCards) count++;
    if (notifySubstitutions) count++;
    if (notifyShotsOnTarget) count++;
    if (notifyCorners) count++;
    if (notifyPenalties) count++;
    if (notifyFouls) count++;
    if (notifyOffsides) count++;
    if (notifyMatchStart) count++;
    if (notifyHalfTime) count++;
    if (notifySecondHalfStart) count++;
    if (notifyMatchEnd) count++;
    if (notifyVarDecisions) count++;
    return count;
  }

  // Check se ha notifiche attive
  bool get hasActiveNotifications {
    return enabled && activeNotificationsCount > 0;
  }

  @override
  String toString() {
    return 'MatchNotificationSettings(matchId: $matchId, enabled: $enabled, active: $activeNotificationsCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchNotificationSettings && other.matchId == matchId;
  }

  @override
  int get hashCode => matchId.hashCode;
}
