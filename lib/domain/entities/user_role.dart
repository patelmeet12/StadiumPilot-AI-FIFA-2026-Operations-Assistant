enum UserRole {
  fan,
  volunteer,
  organizer,
  staff;

  String get displayName {
    switch (this) {
      case UserRole.fan:
        return 'Fan';
      case UserRole.volunteer:
        return 'Volunteer';
      case UserRole.organizer:
        return 'Organizer';
      case UserRole.staff:
        return 'Venue Staff';
    }
  }
}
