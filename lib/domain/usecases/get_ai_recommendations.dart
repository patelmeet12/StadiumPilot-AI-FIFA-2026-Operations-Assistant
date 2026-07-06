import '../entities/ai_recommendation.dart';
import '../entities/user_role.dart';
import '../entities/crowd_state.dart';
import '../entities/incident.dart';
import '../entities/volunteer_task.dart';

class GetAIRecommendations {
  Future<List<AIRecommendation>> call({
    required UserRole role,
    required String location,
    required CrowdState crowdState,
    required List<Incident> incidents,
    required List<VolunteerTask> tasks,
  }) async {
    final List<AIRecommendation> recommendations = [];

    // 1. Accessibility Tip (For all roles)
    recommendations.add(
      const AIRecommendation(
        id: 'rec_access_elevator',
        title: 'Step-Free Routing',
        recommendation: 'Use Elevator West for level transitions near Sec 120-130.',
        reason: 'Elevator West is operating smoothly with 0 min wait. Restroom and seating access is fully flat via this path.',
        estimatedBenefit: 'Bypasses 3 sets of steep concourse stairs.',
        priority: 'Medium',
        confidenceLevel: 0.98,
        category: 'Accessibility',
      ),
    );

    // 2. Crowd / Gate Congestion (Role specific)
    final isGateBHot = (crowdState.gateWaitTimes['Gate B'] ?? 0) >= 20;
    
    if (role == UserRole.fan) {
      if (isGateBHot) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_fan_gate',
            title: 'Congestion Bypass: Gate D',
            recommendation: 'Enter via Gate D instead of Gate B.',
            reason: 'Gate B is highly congested with a 25-minute queue. Gate D has a 5-minute queue.',
            estimatedBenefit: 'Saves ~20 minutes of standing in line.',
            priority: 'High',
            confidenceLevel: 0.94,
            category: 'Crowd',
          ),
        );
      }

      final isFood1Hot = (crowdState.foodCourtWaitTimes['Food Court 1 (North)'] ?? 0) >= 18;
      if (isFood1Hot) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_fan_food',
            title: 'Fast Dining Alternative',
            recommendation: 'Dine at Food Court 2 (South) or order on mobile.',
            reason: 'Food Court 1 (North) queue is 20 mins. Food Court 2 (South) is only 6 mins.',
            estimatedBenefit: 'Saves 14 minutes on food collection.',
            priority: 'Medium',
            confidenceLevel: 0.89,
            category: 'Crowd',
          ),
        );
      }

      recommendations.add(
        const AIRecommendation(
          id: 'rec_fan_transit',
          title: 'Post-Match Congestion Warning',
          recommendation: 'Pre-book Metro Line 2 or take Walking Eco-Path.',
          reason: 'A surge of 40,000 fans is expected at downtown rail gates after the final whistle.',
          estimatedBenefit: 'Saves 35 minutes of exit crowd containment delay.',
          priority: 'Medium',
          confidenceLevel: 0.85,
          category: 'Transit',
        ),
      );
    } 
    
    else if (role == UserRole.volunteer) {
      // Direct volunteer to Incidents or Congested gates
      final hasOpenIncident = incidents.any((i) => i.status == 'Open');
      if (hasOpenIncident) {
        final openInc = incidents.firstWhere((i) => i.status == 'Open');
        recommendations.add(
          AIRecommendation(
            id: 'rec_vol_incident',
            title: 'Unassigned Incident Assistance',
            recommendation: 'Report to ${openInc.location} to support operations.',
            reason: 'An open incident of category "${openInc.category}" (Priority: ${openInc.priority}) is reported and requires volunteer assistance.',
            estimatedBenefit: 'Helps clear incident and secures localized fan safety.',
            priority: 'High',
            confidenceLevel: 0.95,
            category: 'Safety',
          ),
        );
      }

      if (isGateBHot) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_vol_gate_assist',
            title: 'Crowd Marshalling Support',
            recommendation: 'Deploy to Gate B outer plaza and direct fans to Gate D.',
            reason: 'Gate B is experiencing overload (25 min wait). Redirecting incoming fans to Gate D will balance gate operations.',
            estimatedBenefit: 'Balances crowd load and reduces gate wait time by 15%.',
            priority: 'High',
            confidenceLevel: 0.92,
            category: 'Crowd',
          ),
        );
      }
    } 
    
    else if (role == UserRole.organizer || role == UserRole.staff) {
      // Technical decisions for organizers/staff
      if (isGateBHot) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_org_gate_trigger',
            title: 'Capacity Management Action',
            recommendation: 'Trigger public display redirect and dispatch 4 volunteers to North Concourse.',
            reason: 'Gate B entry queue has exceeded the yellow safety threshold (25 mins). Gate D has spare capacity (5 mins).',
            estimatedBenefit: 'Reduces peak congestion bottleneck risk at North entry.',
            priority: 'Critical',
            confidenceLevel: 0.97,
            category: 'Safety',
          ),
        );
      }

      final openCriticalIncidents = incidents.where((i) => i.priority == 'Critical' && i.status == 'Open').toList();
      if (openCriticalIncidents.isNotEmpty) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_org_incident_resolve',
            title: 'Critical Incident Escalation',
            recommendation: 'Dispatch medical/security team to ${openCriticalIncidents.first.location}.',
            reason: 'Critical incident reported: "${openCriticalIncidents.first.title}" remains unassigned.',
            estimatedBenefit: 'Resolves emergency situation and ensures venue compliance.',
            priority: 'Critical',
            confidenceLevel: 0.99,
            category: 'Safety',
          ),
        );
      }
    }

    return recommendations;
  }
}
