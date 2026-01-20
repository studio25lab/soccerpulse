// lib/models/team.dart

class Team {
  final int id;
  final String name;
  final String? code;
  final String? country;
  final String? logo;
  final int? founded;
  final bool? national;
  final VenueInfo? venue;

  Team({
    required this.id,
    required this.name,
    this.code,
    this.country,
    this.logo,
    this.founded,
    this.national,
    this.venue,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    final team = json['team'] ?? json;
    final venue = json['venue'];

    return Team(
      id: team['id'] ?? 0,
      name: team['name'] ?? '',
      code: team['code'],
      country: team['country'],
      logo: team['logo'],
      founded: team['founded'],
      national: team['national'],
      venue: venue != null ? VenueInfo.fromJson(venue) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'country': country,
      'logo': logo,
      'founded': founded,
      'national': national,
      'venue': venue?.toJson(),
    };
  }
}

class VenueInfo {
  final int? id;
  final String? name;
  final String? address;
  final String? city;
  final int? capacity;
  final String? surface;
  final String? image;

  VenueInfo({
    this.id,
    this.name,
    this.address,
    this.city,
    this.capacity,
    this.surface,
    this.image,
  });

  factory VenueInfo.fromJson(Map<String, dynamic> json) {
    return VenueInfo(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      city: json['city'],
      capacity: json['capacity'],
      surface: json['surface'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'capacity': capacity,
      'surface': surface,
      'image': image,
    };
  }
}
