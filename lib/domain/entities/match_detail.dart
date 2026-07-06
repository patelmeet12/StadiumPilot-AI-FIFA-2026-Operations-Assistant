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
  });

  String get matchLabel => '$homeTeam vs $awayTeam';
  String get seatLabel => 'Sec $section, Row $row, Seat $seat';
}
