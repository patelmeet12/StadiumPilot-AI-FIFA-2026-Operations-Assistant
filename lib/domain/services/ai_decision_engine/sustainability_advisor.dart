import '../../entities/ai_recommendation.dart';
import '../../entities/user_role.dart';
import 'context_engine.dart';

/// Sustainability Advisor detailing eco-friendly pathways and carbon footprint reductions.
class SustainabilityAdvisor {
  List<AIRecommendation> analyzeSustainability(DecisiveContext context) {
    final List<AIRecommendation> recommendations = [];

    if (context.role == UserRole.fan) {
      recommendations.add(
        const AIRecommendation(
          id: 'rec_fan_transit',
          title: 'Post-Match Congestion Warning',
          recommendation:
              'Use the official FIFA Metro Line 2 (Platform B) for transit egress. Avoid ride-share taxis.',
          reason:
              'Post-match taxi demand is projected to create a 45-minute congestion loop at rideshare zone A. Metro departures run every 3 minutes.',
          estimatedBenefit:
              'Saves 35 minutes wait time and reduces commuter carbon footprint.',
          priority: 'High',
          confidenceLevel: 0.92,
          category: 'Transit',
          alternativeOptions: [
            'Walk via designated green pedestrian pathways to regional parking Hub C',
            'Wait in concourse plaza concessions area for egress congestion to clear',
          ],
          estimatedTimeSavedMinutes: 35,
          estimatedWalkingDistanceSavedMeters: 180,
          estimatedCo2ReductionKg: 2.4,
          operationalImpact:
              'Lowers localized vehicle carbon emissions and prevents regional arterial road gridlock.',
        ),
      );
    }

    return recommendations;
  }
}
