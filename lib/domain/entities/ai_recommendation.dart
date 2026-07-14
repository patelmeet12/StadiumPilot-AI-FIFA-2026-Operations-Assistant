class AIRecommendation {
  final String id;
  final String title;
  final String recommendation;
  final String reason;
  final String estimatedBenefit;
  final String priority; // "Low", "Medium", "High", "Critical"
  final double confidenceLevel; // 0.0 - 1.0 (expressed as percentage in UI)
  final String
  category; // "Navigation", "Crowd", "Transit", "Accessibility", "Safety"

  // Contextual reasoning attributes
  final List<String> alternativeOptions;
  final int estimatedTimeSavedMinutes;
  final int estimatedWalkingDistanceSavedMeters;
  final double estimatedCo2ReductionKg;
  final String operationalImpact;

  const AIRecommendation({
    required this.id,
    required this.title,
    required this.recommendation,
    required this.reason,
    required this.estimatedBenefit,
    required this.priority,
    required this.confidenceLevel,
    required this.category,
    this.alternativeOptions = const [],
    this.estimatedTimeSavedMinutes = 0,
    this.estimatedWalkingDistanceSavedMeters = 0,
    this.estimatedCo2ReductionKg = 0.0,
    this.operationalImpact = 'No system-level friction.',
  });
}
