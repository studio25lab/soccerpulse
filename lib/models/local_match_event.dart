// lib/models/local_match_event.dart
// Modello evento partita (goal, cartellino, sostituzione, ecc.)

class LocalMatchEvent {
  final String type; // goal, yellowCard, redCard, substitution, offside, var, corner, penalty, penaltyMiss
  final int minute;
  final String playerName;
  final String? detail;     // es. nome giocatore entrante per sostituzioni
  final String? subDetail;  // es. "Assist: Zaccagni"
  final String? playerPhoto;
  final bool isHomeTeam;

  const LocalMatchEvent({
    required this.type,
    required this.minute,
    required this.playerName,
    this.detail,
    this.subDetail,
    required this.isHomeTeam,
    this.playerPhoto,
  });

  /// Factory per creare da API-Football events endpoint
  factory LocalMatchEvent.fromApiJson(Map<String, dynamic> json, {
    required String homeTeamName,
  }) {
    final type = _mapApiEventType(
      json['type'] ?? '',
      json['detail'] ?? '',
    );
    final team = json['team'] ?? {};
    final player = json['player'] ?? {};
    final assist = json['assist'] ?? {};

    return LocalMatchEvent(
      type: type,
      minute: json['time']?['elapsed'] ?? 0,
      playerName: player['name'] ?? '',
      detail: assist['name'],
      subDetail: json['comments'],
      isHomeTeam: team['name'] == homeTeamName,
      playerPhoto: player['photo'],
    );
  }

  static String _mapApiEventType(String apiType, String apiDetail) {
    switch (apiType.toLowerCase()) {
      case 'goal':
        if (apiDetail.toLowerCase().contains('penalty')) return 'penalty';
        if (apiDetail.toLowerCase().contains('own')) return 'goal'; // own goal handled via detail
        return 'goal';
      case 'card':
        if (apiDetail.toLowerCase().contains('red')) return 'redCard';
        return 'yellowCard';
      case 'subst':
        return 'substitution';
      case 'var':
        return 'var';
      default:
        return apiType.toLowerCase();
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'minute': minute,
    'playerName': playerName,
    'detail': detail,
    'subDetail': subDetail,
    'isHomeTeam': isHomeTeam,
    'playerPhoto': playerPhoto,
  };
}
