import '../../entities/ai_recommendation.dart';
import '../../entities/incident.dart';
import '../../entities/user_role.dart';
import 'context_engine.dart';

/// Operational Intelligence Engine managing critical incident alerts and translations.
class OperationalIntelligenceEngine {
  List<AIRecommendation> analyzeOperations({
    required DecisiveContext context,
    required List<Incident> incidents,
  }) {
    final List<AIRecommendation> recommendations = [];

    if (context.role == UserRole.fan) return recommendations;

    // 1. Critical Incident dispatch escalation
    final openCriticalIncidents = incidents
        .where((i) => i.priority == 'Critical' && i.status == 'Open')
        .toList();
    if (openCriticalIncidents.isNotEmpty) {
      recommendations.add(
        AIRecommendation(
          id: 'rec_org_incident_resolve',
          title: 'Critical Incident Escalation',
          recommendation:
              'Dispatch medical/security team to ${openCriticalIncidents.first.location}.',
          reason:
              'Critical incident reported: "${openCriticalIncidents.first.title}" remains unassigned during ${context.matchPhase}.',
          estimatedBenefit:
              'Resolves emergency situation and ensures venue compliance.',
          priority: 'Critical',
          confidenceLevel: 0.99,
          category: 'Safety',
          alternativeOptions: const [
            'Call local municipal safety responders dispatch',
            'Trigger generalized localized PA safety announcements',
          ],
          estimatedTimeSavedMinutes: 10,
          estimatedWalkingDistanceSavedMeters: 120,
          estimatedCo2ReductionKg: 0.0,
          operationalImpact:
              'Resolves critical security/medical risks, maintaining venue compliance indexes.',
        ),
      );
    }

    // 2. Multilingual Incident Translation Pipeline Simulator
    for (final inc in incidents) {
      if (inc.status == 'Open') {
        String? translation;
        final titleLower = inc.title.toLowerCase();
        final descLower = inc.description.toLowerCase();

        if (titleLower.contains('rampa') ||
            descLower.contains('rampa') ||
            descLower.contains('obstrucción')) {
          translation =
              'Wheelchair accessibility ramp obstruction near Gate B lobby.';
        } else if (titleLower.contains('panne') ||
            descLower.contains('électricité') ||
            descLower.contains('grill')) {
          translation =
              'Power breaker outage at Food Court 1 (North) concession grills.';
        } else if (titleLower.contains('caída') ||
            descLower.contains('herido') ||
            descLower.contains('resbaló')) {
          translation =
              'Fan slip-and-fall injury near Section 104 concourse corridor.';
        }

        if (translation != null) {
          recommendations.add(
            AIRecommendation(
              id: 'rec_translate_${inc.id}',
              title: 'AI Translator Service',
              recommendation: 'English translation: "$translation"',
              reason:
                  'Reported description was submitted in non-English format: "${inc.description}" at MetLife Stadium during ${context.matchPhase}.',
              estimatedBenefit:
                  'Bypasses language barrier to speed up responder allocation.',
              priority: 'High',
              confidenceLevel: 0.96,
              category: 'Safety',
              alternativeOptions: const [
                'Request local human interpreter support',
                'Consult manual translation lookups dictionary',
              ],
              estimatedTimeSavedMinutes: 8,
              estimatedWalkingDistanceSavedMeters: 0,
              estimatedCo2ReductionKg: 0.0,
              operationalImpact:
                  'Speeds up dispatcher tasking timelines, achieving a translation delay reduction of 95%.',
            ),
          );
        }
      }
    }

    return recommendations;
  }
}
