class Incident {
  final String id;
  final String title;
  final String category; // "Medical", "Crowd", "Spill", "Facility", "Security"
  final String location; // e.g. "Gate B", "Section 128"
  final String priority; // "Low", "Medium", "High", "Critical"
  final String status; // "Open", "Assigned", "Resolved"
  final String description;
  final DateTime reportedTime;

  const Incident({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.priority,
    required this.status,
    required this.description,
    required this.reportedTime,
  });

  Incident copyWith({
    String? id,
    String? title,
    String? category,
    String? location,
    String? priority,
    String? status,
    String? description,
    DateTime? reportedTime,
  }) {
    return Incident(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      description: description ?? this.description,
      reportedTime: reportedTime ?? this.reportedTime,
    );
  }
}
