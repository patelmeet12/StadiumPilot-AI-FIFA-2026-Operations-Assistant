class RoutePlan {
  final String title;
  final int totalDurationMins;
  final int totalDistanceMeters;
  final List<String> steps;
  final bool isWheelchairFriendly;
  final String crowdCongestionLevel; // "Low", "Medium", "High"
  final String reasoning;
  final List<String> accessibilityFeatures;

  const RoutePlan({
    required this.title,
    required this.totalDurationMins,
    required this.totalDistanceMeters,
    required this.steps,
    required this.isWheelchairFriendly,
    required this.crowdCongestionLevel,
    required this.reasoning,
    required this.accessibilityFeatures,
  });
}
