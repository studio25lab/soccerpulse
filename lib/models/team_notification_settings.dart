// lib/models/team_notification_settings.dart
/// Impostazioni di notifica per una singola SQUADRA seguita.
/// A differenza di MatchNotificationSettings (goal casa/trasferta), qui i
/// goal sono distinti tra "della squadra seguita" e "degli avversari",
/// perche una squadra gioca sia in casa sia in trasferta.
class TeamNotificationSettings {
  final int teamId;
  // Notifiche goal
  final bool notifyTeamGoals;
  final bool notifyOpponentGoals;
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
  // Abilitazione generale per questa squadra
  final bool enabled;

  TeamNotificationSettings({
    required this.teamId,
    this.notifyTeamGoals = true,
    this.notifyOpponentGoals = true,
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
    this.enabled = true,
  });

  // ----- Preset -----

  /// Preset di default applicato quando si aggiunge la squadra ai preferiti.
  /// Coerente con il comportamento stile SofaScore: notifiche attive.
  static TeamNotificationSettings defaultEnabled(int teamId) {
    return TeamNotificationSettings(
      teamId: teamId,
      notifyTeamGoals: true,
      notifyOpponentGoals: true,
      notifyRedCards: true,
      notifyPenalties: true,
      notifyMatchStart: true,
      notifyMatchEnd: true,
      enabled: true,
    );
  }

  static TeamNotificationSettings complete(int teamId) {
    return TeamNotificationSettings(
      teamId: teamId,
      notifyTeamGoals: true,
      notifyOpponentGoals: true,
      notifyYellowCards: true,
      notifyRedCards: true,
      notifySubstitutions: true,
      notifyShotsOnTarget: true,
      notifyCorners: true,
      notifyPenalties: true,
      notifyFouls: true,
      notifyOffsides: true,
      notifyMatchStart: true,
      notifyHalfTime: true,
      notifySecondHalfStart: true,
      notifyMatchEnd: true,
      notifyVarDecisions: true,
      enabled: true,
    );
  }

  static TeamNotificationSettings goalsOnly(int teamId) {
    return TeamNotificationSettings(
      teamId: teamId,
      notifyTeamGoals: true,
      notifyOpponentGoals: true,
      notifyRedCards: false,
      notifyPenalties: false,
      notifyMatchStart: false,
      notifyMatchEnd: false,
      enabled: true,
    );
  }

  static TeamNotificationSettings disabled(int teamId) {
    return TeamNotificationSettings(
      teamId: teamId,
      notifyTeamGoals: false,
      notifyOpponentGoals: false,
      notifyYellowCards: false,
      notifyRedCards: false,
      notifySubstitutions: false,
      notifyShotsOnTarget: false,
      notifyCorners: false,
      notifyPenalties: false,
      notifyFouls: false,
      notifyOffsides: false,
      notifyMatchStart: false,
      notifyHalfTime: false,
      notifySecondHalfStart: false,
      notifyMatchEnd: false,
      notifyVarDecisions: false,
      enabled: false,
    );
  }

  // ----- copyWith -----
  TeamNotificationSettings copyWith({
    int? teamId,
    bool? notifyTeamGoals,
    bool? notifyOpponentGoals,
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
    bool? enabled,
  }) {
    return TeamNotificationSettings(
      teamId: teamId ?? this.teamId,
      notifyTeamGoals: notifyTeamGoals ?? this.notifyTeamGoals,
      notifyOpponentGoals: notifyOpponentGoals ?? this.notifyOpponentGoals,
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
      enabled: enabled ?? this.enabled,
    );
  }

  // ----- Helpers -----

  /// True se almeno una notifica e attiva (e l-abilitazione generale e on).
  bool get hasActiveNotifications {
    if (!enabled) return false;
    return notifyTeamGoals ||
        notifyOpponentGoals ||
        notifyYellowCards ||
        notifyRedCards ||
        notifySubstitutions ||
        notifyShotsOnTarget ||
        notifyCorners ||
        notifyPenalties ||
        notifyFouls ||
        notifyOffsides ||
        notifyMatchStart ||
        notifyHalfTime ||
        notifySecondHalfStart ||
        notifyMatchEnd ||
        notifyVarDecisions;
  }

  int get activeNotificationsCount {
    if (!enabled) return 0;
    int c = 0;
    if (notifyTeamGoals) c++;
    if (notifyOpponentGoals) c++;
    if (notifyYellowCards) c++;
    if (notifyRedCards) c++;
    if (notifySubstitutions) c++;
    if (notifyShotsOnTarget) c++;
    if (notifyCorners) c++;
    if (notifyPenalties) c++;
    if (notifyFouls) c++;
    if (notifyOffsides) c++;
    if (notifyMatchStart) c++;
    if (notifyHalfTime) c++;
    if (notifySecondHalfStart) c++;
    if (notifyMatchEnd) c++;
    if (notifyVarDecisions) c++;
    return c;
  }

  // ----- JSON -----
  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'notifyTeamGoals': notifyTeamGoals,
      'notifyOpponentGoals': notifyOpponentGoals,
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
      'enabled': enabled,
    };
  }

  factory TeamNotificationSettings.fromJson(Map<String, dynamic> json) {
    return TeamNotificationSettings(
      teamId: json['teamId'] as int,
      notifyTeamGoals: json['notifyTeamGoals'] as bool? ?? true,
      notifyOpponentGoals: json['notifyOpponentGoals'] as bool? ?? true,
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
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
