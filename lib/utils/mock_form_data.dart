// lib/utils/mock_form_data.dart
//
// Helper centralizzato per generare partite mock procedurali per una squadra.
//
// PROVVISORIO: usato per consentire il funzionamento dei filtri 5/10/20/Tutte
// in MatchFormTab (pre-match) e TeamDetailScreen (squadra) anche prima
// dell'integrazione API.
//
// QUANDO ARRIVERA L'API:
// - Rimuovere questo file
// - Sostituire _getTeamForm con chiamata API che ritorna List<Map>
// - Sostituire _generateExtraDemoMatches con chiamata API che ritorna
//   List<SoccerMatch>
//
// // [FAV-mock-form-data]

import '../models/soccer_match.dart';

/// Genera [count] partite procedurali mock per [teamName].
///
/// Le partite sono deterministiche (hash del nome squadra) e quindi stabili
/// fra reload. I risultati simulano team con ~50% vittorie, ~20% pareggi,
/// ~30% sconfitte (sbilanciato verso vittorie per realismo Serie A top team).
///
/// Le date partono da [startMonth]/[startYear] e vanno indietro nel tempo.
///
/// Output: lista di Map con chiavi 'opponent', 'score', 'result',
/// 'venue', 'comp', 'date'.
List<Map<String, dynamic>> generateMockFormMaps(
  String teamName, {
  int count = 20,
  int startMonth = 4,
  int startYear = 2023,
  int seedOffset = 0,
}) {
  const opponentsPool = [
    'Sassuolo', 'Empoli', 'Cagliari', 'Frosinone', 'Salernitana',
    'Monza', 'Lecce', 'Verona', 'Udinese', 'Genoa',
    'Torino', 'Bologna', 'Fiorentina', 'Atalanta', 'Inter',
    'Milan', 'Juventus', 'Napoli', 'Roma', 'Lazio',
  ];

  final hash = teamName.hashCode.abs() + seedOffset;
  final result = <Map<String, dynamic>>[];

  // Genera date scaglionate ogni ~2 settimane andando indietro
  int year = startYear;
  int month = startMonth;
  int day = 28;

  for (int i = 0; i < count; i++) {
    // Avversario: rotazione deterministica, evita self-match
    var opp = opponentsPool[(hash + i) % opponentsPool.length];
    if (opp == teamName) {
      opp = opponentsPool[(hash + i + 1) % opponentsPool.length];
    }

    final isHome = (hash + i) % 2 == 0;

    // Risultato pseudo-random deterministico
    final rnd = (hash + i * 7) % 10;
    int teamScore, oppScore;
    String resultLetter;
    if (rnd < 5) {
      // Vittoria
      teamScore = 1 + (rnd % 3);
      oppScore = (rnd % 2);
      resultLetter = 'W';
    } else if (rnd < 7) {
      // Pareggio
      teamScore = rnd % 3;
      oppScore = teamScore;
      resultLetter = 'D';
    } else {
      // Sconfitta
      teamScore = (rnd % 2);
      oppScore = 1 + (rnd % 2);
      resultLetter = 'L';
    }

    // Score formato "home-away" rispetto alla squadra di riferimento
    final hs = isHome ? teamScore : oppScore;
    final as_ = isHome ? oppScore : teamScore;

    final dateStr =
        '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';

    result.add({
      'opponent': opp,
      'score': '$hs-$as_',
      'result': resultLetter,
      'venue': isHome ? 'Casa' : 'Trasferta',
      'comp': 'Serie A',
      'date': dateStr,
    });

    // Decrementa data di ~14 giorni
    day -= 14;
    if (day < 1) {
      day += 28;
      month -= 1;
      if (month < 1) {
        month = 12;
        year -= 1;
      }
    }
  }

  return result;
}

/// Variante che ritorna SoccerMatch invece di Map.
/// Usata da TeamDetailScreen che lavora con SoccerMatch.
///
/// [teamName] e [teamId] identificano la squadra di riferimento.
/// [teamLogos] e' una mappa nome -> URL logo (passata dal chiamante).
List<SoccerMatch> generateMockFormMatches(
  String teamName,
  int teamId, {
  required Map<String, String> teamLogos,
  int count = 20,
  int startMonth = 4,
  int startYear = 2023,
  int seedOffset = 0,
  int idBase = 7000,
}) {
  final maps = generateMockFormMaps(
    teamName,
    count: count,
    startMonth: startMonth,
    startYear: startYear,
    seedOffset: seedOffset,
  );

  final matches = <SoccerMatch>[];
  for (int i = 0; i < maps.length; i++) {
    final m = maps[i];
    final opp = m['opponent'] as String;
    final isHome = m['venue'] == 'Casa';
    final scoreParts = (m['score'] as String).split('-');
    final hs = int.tryParse(scoreParts[0]) ?? 0;
    final as_ = int.tryParse(scoreParts[1]) ?? 0;
    final dateParts = (m['date'] as String).split('/');
    final day = int.tryParse(dateParts[0]) ?? 1;
    final month = int.tryParse(dateParts[1]) ?? 1;
    final year = month >= 9 ? startYear - 1 : startYear;

    matches.add(SoccerMatch(
      id: idBase + teamId * 100 + i,
      date: DateTime(year, month, day),
      time: '20:45',
      status: 'FT',
      venue: isHome ? 'Casa' : 'Trasferta',
      homeTeamId: isHome ? teamId : 0,
      homeTeamName: isHome ? teamName : opp,
      homeTeamLogo: teamLogos[isHome ? teamName : opp],
      awayTeamId: isHome ? 0 : teamId,
      awayTeamName: isHome ? opp : teamName,
      awayTeamLogo: teamLogos[isHome ? opp : teamName],
      homeScore: hs,
      awayScore: as_,
      leagueName: 'Serie A',
      season: 2023,
      round: 'Giornata ${count - i}',
    ));
  }
  return matches;
}
