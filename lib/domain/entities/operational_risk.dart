/// Represents an upcoming operational risk predicted by the AI engine.
class OperationalRisk {
  final String id;
  final String title;
  final String
  riskCategory; // "Gate", "Medical", "Transit", "Crowd", "Weather", "Exit"
  final double probability; // 0.0 - 1.0
  final String timeline; // e.g. "Immediate", "In 15 mins", "Post-Match"
  final String description;
  final String preventiveAction;
  final String expectedImpact;

  const OperationalRisk({
    required this.id,
    required this.title,
    required this.riskCategory,
    required this.probability,
    required this.timeline,
    required this.description,
    required this.preventiveAction,
    required this.expectedImpact,
  });
}
