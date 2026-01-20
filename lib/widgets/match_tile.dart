import 'package:flutter/material.dart';
import 'package:soccer_pulse/models/match.dart';

class MatchTile extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const MatchTile({super.key, required this.match, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dynamic m = match;

    // Prova a ricavare nomi squadre e data in modo resiliente
    final home = (m?.homeTeam is String)
        ? m.homeTeam as String
        : (m?.homeTeamName is String)
            ? m.homeTeamName as String
            : 'Home';
    final away = (m?.awayTeam is String)
        ? m.awayTeam as String
        : (m?.awayTeamName is String)
            ? m.awayTeamName as String
            : 'Away';

    // punteggio se disponibile
    String? score;
    if (m?.score is String) {
      score = m.score as String;
    } else if (m?.homeScore is int && m?.awayScore is int) {
      score = '${m.homeScore}-${m.awayScore}';
    }

    // data/ora: supporta DateTime o String
    String when = '';
    final v = m?.date;
    if (v is DateTime) {
      when = '${v.day}/${v.month}/${v.year}';
    } else if (v is String) {
      when = v;
    }

    return ListTile(
      title: Text('$home vs $away'),
      subtitle: Text(when),
      trailing: score == null ? null : Text(score),
      onTap: onTap,
    );
  }
}
