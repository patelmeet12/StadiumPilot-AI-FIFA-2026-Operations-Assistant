import '../../entities/ai_recommendation.dart';
import '../../entities/user_role.dart';
import 'context_engine.dart';

/// Accessibility Engine generating step-free pathways and elevator warnings.
class AccessibilityEngine {
  List<AIRecommendation> analyzeAccessibility(DecisiveContext context) {
    final List<AIRecommendation> recommendations = [];

    // Always append elevator check tip
    recommendations.add(
      AIRecommendation(
        id: 'rec_access_elevator',
        title: 'Step-Free Routing',
        recommendation:
            'Use Elevator West for level transitions near Sec 120-130 at MetLife Stadium.',
        reason:
            'Elevator West is operating smoothly with 0 min wait. Accessibility profiles (Required: ${context.accessibilityRequired}, Family Size: ${context.familySize}) indicate steep concourse stairs represent high strain.',
        estimatedBenefit: 'Bypasses 3 sets of steep concourse stairs.',
        priority: 'Medium',
        confidenceLevel: 0.98,
        category: 'Accessibility',
        alternativeOptions: const [
          'Use primary stairwells near Concourse West',
          'Request manual transport volunteer help escorts',
        ],
        estimatedTimeSavedMinutes: 4,
        estimatedWalkingDistanceSavedMeters: 20,
        estimatedCo2ReductionKg: 0.0,
        operationalImpact:
            'Balances concourse stair friction indices for group movements.',
      ),
    );

    // If accessibility Required is true, append specific wheelchair routing
    if (context.accessibilityRequired) {
      recommendations.add(
        AIRecommendation(
          id: 'rec_access_routing',
          title: 'Wheelchair & Step-Free Routing',
          recommendation: context.role == UserRole.fan
              ? 'Navigate via Ramp West to Concourse Level 2. Elevators near Gate B are running at peak load.'
              : 'Deploy a volunteer with a wheelchair to Ramp West check-point to assist step-free ticket holders.',
          reason:
              'Accessibility profile is active. Elevator near Gate B reports high utilization. Suggested step-free ramp pathway.',
          estimatedBenefit: 'Avoids 8-minute elevator queue delay.',
          priority: 'High',
          confidenceLevel: 0.95,
          category: 'Accessibility',
          alternativeOptions: const [
            'Wait for Gate B elevator escort assistance service',
            'Request golf cart plaza transit coordinate dispatch',
          ],
          estimatedTimeSavedMinutes: 8,
          estimatedWalkingDistanceSavedMeters: -50,
          estimatedCo2ReductionKg: 0.0,
          operationalImpact:
              'Maintains ADA/FIFA accessibility response indexes, keeping elevator waiting areas safe.',
        ),
      );
    }

    return recommendations;
  }
}
