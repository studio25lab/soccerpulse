class League {
  final int id;
  final String name;
  final String country;
  final String? logo;
  final String? flag;

  League({
    required this.id,
    required this.name,
    required this.country,
    this.logo,
    this.flag,
  });

  // Campionati principali supportati
  static List<League> get popularLeagues => [
        League(
          id: 135,
          name: 'Serie A',
          country: 'Italy',
          logo: '🇮🇹',
          flag: '🇮🇹',
        ),
        League(
          id: 39,
          name: 'Premier League',
          country: 'England',
          logo: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
          flag: '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
        ),
        League(
          id: 140,
          name: 'La Liga',
          country: 'Spain',
          logo: '🇪🇸',
          flag: '🇪🇸',
        ),
        League(
          id: 78,
          name: 'Bundesliga',
          country: 'Germany',
          logo: '🇩🇪',
          flag: '🇩🇪',
        ),
        League(
          id: 61,
          name: 'Ligue 1',
          country: 'France',
          logo: '🇫🇷',
          flag: '🇫🇷',
        ),
        League(
          id: 2,
          name: 'UEFA Champions League',
          country: 'World',
          logo: '🏆',
          flag: '🌍',
        ),
      ];

  @override
  String toString() => '$name ($country)';
}
