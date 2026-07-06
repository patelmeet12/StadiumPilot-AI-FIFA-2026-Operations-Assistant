class VolunteerTask {
  final String id;
  final String title;
  final String description;
  final String location;
  final String priority; // "Low", "Medium", "High"
  final bool isCompleted;
  final DateTime assignedTime;

  const VolunteerTask({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.priority,
    required this.isCompleted,
    required this.assignedTime,
  });

  VolunteerTask copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? priority,
    bool? isCompleted,
    DateTime? assignedTime,
  }) {
    return VolunteerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      assignedTime: assignedTime ?? this.assignedTime,
    );
  }
}
