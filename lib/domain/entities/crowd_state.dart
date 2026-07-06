class CrowdState {
  final Map<String, int> gateWaitTimes; // Gate Name -> Wait time in mins
  final Map<String, int> foodCourtWaitTimes; // Food Court Name -> Wait time in mins
  final Map<String, int> restroomWaitTimes; // Restroom Location -> Wait time in mins
  final Map<String, double> zoneDensities; // Zone Name -> Density (0.0 - 1.0)

  const CrowdState({
    required this.gateWaitTimes,
    required this.foodCourtWaitTimes,
    required this.restroomWaitTimes,
    required this.zoneDensities,
  });

  factory CrowdState.initial() {
    return const CrowdState(
      gateWaitTimes: {
        'Gate A': 8,
        'Gate B': 25, // Congested
        'Gate C': 15,
        'Gate D': 5,  // Fast alternative
        'Gate E': 18,
      },
      foodCourtWaitTimes: {
        'Food Court 1 (North)': 20, // Congested
        'Food Court 2 (South)': 6,  // Fast alternative
        'Food Court 3 (East)': 14,
        'Food Court 4 (West)': 8,
      },
      restroomWaitTimes: {
        'Restrooms Level 1 East': 15,
        'Restrooms Level 1 West': 4,
        'Restrooms Level 2 North': 12,
        'Restrooms Level 2 South': 3,
      },
      zoneDensities: {
        'North Entry Plaza': 0.85,
        'South Entry Plaza': 0.40,
        'East Concourse': 0.65,
        'West Concourse': 0.50,
      },
    );
  }

  CrowdState copyWith({
    Map<String, int>? gateWaitTimes,
    Map<String, int>? foodCourtWaitTimes,
    Map<String, int>? restroomWaitTimes,
    Map<String, double>? zoneDensities,
  }) {
    return CrowdState(
      gateWaitTimes: gateWaitTimes ?? this.gateWaitTimes,
      foodCourtWaitTimes: foodCourtWaitTimes ?? this.foodCourtWaitTimes,
      restroomWaitTimes: restroomWaitTimes ?? this.restroomWaitTimes,
      zoneDensities: zoneDensities ?? this.zoneDensities,
    );
  }
}
