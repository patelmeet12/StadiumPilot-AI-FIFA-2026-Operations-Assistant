class TransportPlan {
  final String modeName; // e.g. "Metro Line 2", "Express shuttle", "Taxi/Ride Share"
  final String iconType; // "train", "bus", "car", "walk"
  final int durationMins;
  final double estimatedCost; // 0.0 for free public transit / walk
  final String crowdLevel; // "Low", "Medium", "High"
  final double co2EmissionsKg; // carbon footprint
  final double co2SavedKg; // Carbon savings vs standard ride
  final int ecoScore; // 1-100 rating
  final bool isRecommended;
  final String recommendationReason;
  final String sustainabilityTip;

  const TransportPlan({
    required this.modeName,
    required this.iconType,
    required this.durationMins,
    required this.estimatedCost,
    required this.crowdLevel,
    required this.co2EmissionsKg,
    required this.co2SavedKg,
    required this.ecoScore,
    required this.isRecommended,
    required this.recommendationReason,
    required this.sustainabilityTip,
  });
}
