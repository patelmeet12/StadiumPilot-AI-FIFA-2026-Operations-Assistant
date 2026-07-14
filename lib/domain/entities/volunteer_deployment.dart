/// Represents the volunteer staff allocation across different stadium operational zones.
class VolunteerDeployment {
  final int plazaActive;
  final int plazaBreak;
  final int concourseActive;
  final int concourseBreak;
  final int medicalActive;
  final int medicalBreak;
  final int securityActive;
  final int securityBreak;

  const VolunteerDeployment({
    required this.plazaActive,
    required this.plazaBreak,
    required this.concourseActive,
    required this.concourseBreak,
    required this.medicalActive,
    required this.medicalBreak,
    required this.securityActive,
    required this.securityBreak,
  });

  /// The default initial deployment preset.
  factory VolunteerDeployment.initial() {
    return const VolunteerDeployment(
      plazaActive: 14,
      plazaBreak: 2,
      concourseActive: 10,
      concourseBreak: 0,
      medicalActive: 8,
      medicalBreak: 1,
      securityActive: 6,
      securityBreak: 0,
    );
  }

  int get totalActive =>
      plazaActive + concourseActive + medicalActive + securityActive;
  int get totalBreak =>
      plazaBreak + concourseBreak + medicalBreak + securityBreak;
  int get totalVolunteers => totalActive + totalBreak;

  VolunteerDeployment copyWith({
    int? plazaActive,
    int? plazaBreak,
    int? concourseActive,
    int? concourseBreak,
    int? medicalActive,
    int? medicalBreak,
    int? securityActive,
    int? securityBreak,
  }) {
    return VolunteerDeployment(
      plazaActive: plazaActive ?? this.plazaActive,
      plazaBreak: plazaBreak ?? this.plazaBreak,
      concourseActive: concourseActive ?? this.concourseActive,
      concourseBreak: concourseBreak ?? this.concourseBreak,
      medicalActive: medicalActive ?? this.medicalActive,
      medicalBreak: medicalBreak ?? this.medicalBreak,
      securityActive: securityActive ?? this.securityActive,
      securityBreak: securityBreak ?? this.securityBreak,
    );
  }
}
