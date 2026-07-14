import '../../entities/ai_recommendation.dart';
import '../../entities/volunteer_task.dart';
import '../../entities/user_role.dart';
import 'context_engine.dart';

/// Volunteer Coordinator managing active task queues for volunteer role.
class VolunteerCoordinator {
  List<AIRecommendation> analyzeVolunteerCoordinations({
    required DecisiveContext context,
    required List<VolunteerTask> tasks,
    dynamic
    deployment, // accepted but not used here — crowd engine handles reallocation
    required int gateBWait,
  }) {
    final List<AIRecommendation> recommendations = [];

    // Only applicable for Volunteers
    if (context.role != UserRole.volunteer) return recommendations;

    // Active Task Assignment Notification
    final openTasks = tasks.where((t) => !t.isCompleted).toList();
    if (openTasks.isNotEmpty) {
      recommendations.add(
        AIRecommendation(
          id: 'rec_vol_task',
          title: 'Active Task Assigned',
          recommendation:
              'Report immediately to ${openTasks.first.location} to complete task "${openTasks.first.title}".',
          reason:
              'Your active task list contains open operations assignments in Section 102.',
          estimatedBenefit:
              'Ensures venue protocols are completed on schedule.',
          priority: 'High',
          confidenceLevel: 0.98,
          category: 'Tasks',
          alternativeOptions: const [
            'Request task re-assignment via dispatcher',
            'Mark task status as In-Progress',
          ],
          estimatedTimeSavedMinutes: 10,
          estimatedWalkingDistanceSavedMeters: 50,
          estimatedCo2ReductionKg: 0.0,
          operationalImpact:
              'Maintains volunteer operational efficiency indexes above 90%.',
        ),
      );
    }

    return recommendations;
  }
}
