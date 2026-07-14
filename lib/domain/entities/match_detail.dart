class MatchDetail {
  final String homeTeam;
  final String awayTeam;
  final DateTime matchTime;
  final String stadiumName;
  final String ticketClass;
  final String section;
  final String row;
  final String seat;
  final String gate;
  final DateTime recommendedArrivalTime;

  // New FIFA 2026-specific real-time telemetry attributes
  final String matchId;
  final String weatherAlert;
  final double temperature;
  final int attendanceProjection;
  final String vipMediaPriority;

  const MatchDetail({
    required this.homeTeam,
    required this.awayTeam,
    required this.matchTime,
    required this.stadiumName,
    required this.ticketClass,
    required this.section,
    required this.row,
    required this.seat,
    required this.gate,
    required this.recommendedArrivalTime,
    this.matchId = 'match_argentina_france',
    this.weatherAlert = 'None',
    this.temperature = 26.0,
    this.attendanceProjection = 82500,
    this.vipMediaPriority = 'High',
  });

  String get matchLabel => '$homeTeam vs $awayTeam';
  String get seatLabel => 'Sec $section, Row $row, Seat $seat';

  MatchDetail copyWith({
    String? homeTeam,
    String? awayTeam,
    DateTime? matchTime,
    String? stadiumName,
    String? ticketClass,
    String? section,
    String? row,
    String? seat,
    String? gate,
    DateTime? recommendedArrivalTime,
    String? matchId,
    String? weatherAlert,
    double? temperature,
    int? attendanceProjection,
    String? vipMediaPriority,
  }) {
    return MatchDetail(
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      matchTime: matchTime ?? this.matchTime,
      stadiumName: stadiumName ?? this.stadiumName,
      ticketClass: ticketClass ?? this.ticketClass,
      section: section ?? this.section,
      row: row ?? this.row,
      seat: seat ?? this.seat,
      gate: gate ?? this.gate,
      recommendedArrivalTime:
          recommendedArrivalTime ?? this.recommendedArrivalTime,
      matchId: matchId ?? this.matchId,
      weatherAlert: weatherAlert ?? this.weatherAlert,
      temperature: temperature ?? this.temperature,
      attendanceProjection: attendanceProjection ?? this.attendanceProjection,
      vipMediaPriority: vipMediaPriority ?? this.vipMediaPriority,
    );
  }
}

/// Predefined FIFA World Cup 2026 match presets representing different host operational scenarios.
class MatchPreset {
  final String matchId;
  final String homeTeam;
  final String awayTeam;
  final String weatherAlert;
  final double temperature;
  final int attendanceProjection;
  final String vipMediaPriority;
  final double crowdMultiplier;
  final double railUsageRate;

  const MatchPreset({
    required this.matchId,
    required this.homeTeam,
    required this.awayTeam,
    required this.weatherAlert,
    required this.temperature,
    required this.attendanceProjection,
    required this.vipMediaPriority,
    required this.crowdMultiplier,
    required this.railUsageRate,
  });

  static const List<MatchPreset> presets = [
    MatchPreset(
      matchId: 'match_argentina_france',
      homeTeam: 'Argentina',
      awayTeam: 'France',
      weatherAlert: 'None',
      temperature: 26.0,
      attendanceProjection: 82500,
      vipMediaPriority: 'High',
      crowdMultiplier: 1.1,
      railUsageRate: 0.72,
    ),
    MatchPreset(
      matchId: 'match_usa_england',
      homeTeam: 'USA',
      awayTeam: 'England',
      weatherAlert: 'Heavy Lightning Warning',
      temperature: 18.0,
      attendanceProjection: 84100,
      vipMediaPriority: 'Critical',
      crowdMultiplier: 1.35,
      railUsageRate: 0.88,
    ),
    MatchPreset(
      matchId: 'match_mexico_canada',
      homeTeam: 'Mexico',
      awayTeam: 'Canada',
      weatherAlert: 'Extreme Heat Alert',
      temperature: 36.0,
      attendanceProjection: 79200,
      vipMediaPriority: 'Medium',
      crowdMultiplier: 1.0,
      railUsageRate: 0.60,
    ),
    MatchPreset(
      matchId: 'match_brazil_portugal',
      homeTeam: 'Brazil',
      awayTeam: 'Portugal',
      weatherAlert: 'None',
      temperature: 22.0,
      attendanceProjection: 83000,
      vipMediaPriority: 'Critical',
      crowdMultiplier: 1.25,
      railUsageRate: 0.85,
    ),
  ];
}
