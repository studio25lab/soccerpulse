// lib/models/match_event.dart

/// Evento di una partita (goal, cartellino, sostituzione, ecc.)
class MatchEvent {
  final String
      type; // 'goal', 'yellowCard', 'redCard', 'substitution', 'shot', etc.
  final int minute; // Minuto dell'evento
  final String playerName; // Nome del giocatore coinvolto
  final String team; // Nome della squadra
  final String? detail; // Dettaglio breve (es. "Assist: Zaccagni")
  final String?
      extraInfo; // Info aggiuntiva (es. "Tiro di destro dall'area...")
  final String? playerPhoto; // URL foto giocatore (opzionale)
  final int? playerId; // ID giocatore (opzionale)
  final String? assistPlayerName; // Nome giocatore assist (per goal)
  final String? substituteInName; // Nome giocatore che entra (per sostituzioni)
  final String? substituteOutName; // Nome giocatore che esce (per sostituzioni)

  MatchEvent({
    required this.type,
    required this.minute,
    required this.playerName,
    required this.team,
    this.detail,
    this.extraInfo,
    this.playerPhoto,
    this.playerId,
    this.assistPlayerName,
    this.substituteInName,
    this.substituteOutName,
  });

  /// È un goal?
  bool get isGoal => type == 'goal';

  /// È un cartellino (giallo o rosso)?
  bool get isCard => type == 'yellowCard' || type == 'redCard';

  /// È un cartellino giallo?
  bool get isYellowCard => type == 'yellowCard';

  /// È un cartellino rosso?
  bool get isRedCard => type == 'redCard';

  /// È una sostituzione?
  bool get isSubstitution => type == 'substitution';

  /// È un tiro?
  bool get isShot => type == 'shot';

  /// È un rigore?
  bool get isPenalty => type == 'penalty';

  /// È un corner?
  bool get isCorner => type == 'corner';

  /// È un fuorigioco?
  bool get isOffside => type == 'offside';

  /// Crea MatchEvent da JSON generico
  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      type: json['type'] as String,
      minute: json['minute'] as int,
      playerName: json['playerName'] as String,
      team: json['team'] as String,
      detail: json['detail'] as String?,
      extraInfo: json['extraInfo'] as String?,
      playerPhoto: json['playerPhoto'] as String?,
      playerId: json['playerId'] as int?,
      assistPlayerName: json['assistPlayerName'] as String?,
      substituteInName: json['substituteInName'] as String?,
      substituteOutName: json['substituteOutName'] as String?,
    );
  }

  /// Crea MatchEvent da JSON API-Sports
  /// Formato API-Sports: { "time": {"elapsed": 12}, "type": "Goal", "player": {"name": "..."}, "team": {"name": "..."}, ... }
  factory MatchEvent.fromApiSportsJson(Map<String, dynamic> json) {
    // Estrai tempo
    final timeData = json['time'] as Map<String, dynamic>?;
    final elapsed = timeData?['elapsed'] as int? ?? 0;

    // Estrai tipo evento
    String eventType = 'unknown';
    final type = json['type'] as String?;
    final detail = json['detail'] as String?;

    if (type == 'Goal') {
      eventType = 'goal';
    } else if (type == 'Card') {
      if (detail == 'Yellow Card') {
        eventType = 'yellowCard';
      } else if (detail == 'Red Card') {
        eventType = 'redCard';
      }
    } else if (type == 'subst') {
      eventType = 'substitution';
    } else if (type == 'Var') {
      eventType = 'var';
    }

    // Estrai giocatore
    final playerData = json['player'] as Map<String, dynamic>?;
    final playerName = playerData?['name'] as String? ?? 'Unknown';

    // Estrai squadra
    final teamData = json['team'] as Map<String, dynamic>?;
    final teamName = teamData?['name'] as String? ?? 'Unknown';

    // Estrai assist (per goal)
    final assistData = json['assist'] as Map<String, dynamic>?;
    final assistPlayerName = assistData?['name'] as String?;

    // Estrai giocatore sostituito (per sostituzioni)
    final substituteData = json['assist'] as Map<String,
        dynamic>?; // API-Sports usa 'assist' per il giocatore che entra
    final substituteInName = substituteData?['name'] as String?;

    return MatchEvent(
      type: eventType,
      minute: elapsed,
      playerName: playerName,
      team: teamName,
      detail: detail,
      extraInfo: json['comments'] as String?,
      playerPhoto: null,
      playerId: playerData?['id'] as int?,
      assistPlayerName: assistPlayerName,
      substituteInName: substituteInName,
      substituteOutName: eventType == 'substitution' ? playerName : null,
    );
  }

  /// Converte in JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'minute': minute,
      'playerName': playerName,
      'team': team,
      'detail': detail,
      'extraInfo': extraInfo,
      'playerPhoto': playerPhoto,
      'playerId': playerId,
      'assistPlayerName': assistPlayerName,
      'substituteInName': substituteInName,
      'substituteOutName': substituteOutName,
    };
  }

  /// Copia con modifiche
  MatchEvent copyWith({
    String? type,
    int? minute,
    String? playerName,
    String? team,
    String? detail,
    String? extraInfo,
    String? playerPhoto,
    int? playerId,
    String? assistPlayerName,
    String? substituteInName,
    String? substituteOutName,
  }) {
    return MatchEvent(
      type: type ?? this.type,
      minute: minute ?? this.minute,
      playerName: playerName ?? this.playerName,
      team: team ?? this.team,
      detail: detail ?? this.detail,
      extraInfo: extraInfo ?? this.extraInfo,
      playerPhoto: playerPhoto ?? this.playerPhoto,
      playerId: playerId ?? this.playerId,
      assistPlayerName: assistPlayerName ?? this.assistPlayerName,
      substituteInName: substituteInName ?? this.substituteInName,
      substituteOutName: substituteOutName ?? this.substituteOutName,
    );
  }

  @override
  String toString() {
    return 'MatchEvent(type: $type, minute: $minute, player: $playerName, team: $team)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MatchEvent &&
        other.type == type &&
        other.minute == minute &&
        other.playerName == playerName &&
        other.team == team;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        minute.hashCode ^
        playerName.hashCode ^
        team.hashCode;
  }
}
