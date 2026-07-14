import '../entities/ai_recommendation.dart';
import '../entities/user_role.dart';
import '../entities/crowd_state.dart';
import '../entities/incident.dart';
import '../entities/volunteer_task.dart';
import '../entities/volunteer_deployment.dart';

/// Usecase containing rule-based logic to simulate advanced, host-city AI decision support recommendations.
class GetAIRecommendations {
  Future<List<AIRecommendation>> call({
    required UserRole role,
    required String location,
    required CrowdState crowdState,
    required List<Incident> incidents,
    required List<VolunteerTask> tasks,
    String weatherAlert = 'None',
    double temperature = 26.0,
    VolunteerDeployment? deployment,
  }) async {
    final List<AIRecommendation> recommendations = [];

    // 1. Weather Hazard Warning Trigger Rules
    if (weatherAlert == 'Heavy Lightning Warning') {
      if (role == UserRole.fan) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_weather_lightning_fan',
            title: 'Severe Weather: Seek Concourse Shelter',
            recommendation:
                'Exposed seating decks present high hazard. Move inside covered concourses immediately.',
            reason:
                'Active lightning storm warning is in effect within 5 miles of MetLife Stadium.',
            estimatedBenefit:
                'Guarantees fan safety and avoids exposure to strikes.',
            priority: 'Critical',
            confidenceLevel: 0.99,
            category: 'Safety',
          ),
        );
      } else if (role == UserRole.volunteer) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_weather_lightning_vol',
            title: 'Severe Weather: Direct Public Inside',
            recommendation:
                'Retreat from open parking structures and direct fans to covered entry hubs.',
            reason:
                'Match operations are suspended due to active local lightning warning.',
            estimatedBenefit:
                'Achieves swift and organized public safety sheltering.',
            priority: 'Critical',
            confidenceLevel: 0.99,
            category: 'Safety',
          ),
        );
      } else if (role == UserRole.organizer || role == UserRole.staff) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_weather_lightning_org',
            title: 'Severe Weather: Suspend Shuttle Carts',
            recommendation:
                'De-energize open-air golf carts, broadcast warning alerts, and dispatch safety marshals.',
            reason:
                'Severe lightning threat level is Critical. Outdoor personnel must seek immediate shelter.',
            estimatedBenefit:
                'Eliminates open-air strike risk across VIP/Media walkways.',
            priority: 'Critical',
            confidenceLevel: 0.99,
            category: 'Safety',
          ),
        );
      }
    } else if (weatherAlert == 'Extreme Heat Alert') {
      if (role == UserRole.fan) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_weather_heat_fan',
            title: 'Severe Weather: Hydration Warning',
            recommendation:
                'Visit cooling hydration zones at Sec 112 Concourse. Claim a free water voucher.',
            reason:
                'Ambient temperatures have peaked at ${temperature.toInt()}°C. High risk of thermal fatigue.',
            estimatedBenefit: 'Prevents thermal exhaustion and dehydration.',
            priority: 'High',
            confidenceLevel: 0.96,
            category: 'Safety',
          ),
        );
      } else if (role == UserRole.volunteer) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_weather_heat_vol',
            title: 'Severe Weather: Distribute Fluids',
            recommendation:
                'Distribute chilled water at Gate check loops. Monitor fans for heat sickness.',
            reason:
                'Extreme Heat Warning is in effect across all outer security entry plazas.',
            estimatedBenefit:
                'Reduces medical intervention incident rates by ~22%.',
            priority: 'High',
            confidenceLevel: 0.94,
            category: 'Safety',
          ),
        );
      } else if (role == UserRole.organizer || role == UserRole.staff) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_weather_heat_org',
            title: 'Severe Weather: Activate Cooling Mists',
            recommendation:
                'Activate outdoor misting stations, dispatch emergency water boxes, and flash heat guidance.',
            reason:
                'Telemetry shows heat stress indices exceed safety thresholds at West entry plaza.',
            estimatedBenefit: 'Supports crowd health safety guidelines.',
            priority: 'High',
            confidenceLevel: 0.97,
            category: 'Safety',
          ),
        );
      }
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
                  'Reported description is in non-English format: "${inc.description}"',
              estimatedBenefit:
                  'Bypasses language barrier to speed up responder allocation.',
              priority: 'High',
              confidenceLevel: 0.96,
              category: 'Safety',
            ),
          );
        }
      }
    }

    // 3. Accessibility Tip (For all roles)
    recommendations.add(
      const AIRecommendation(
        id: 'rec_access_elevator',
        title: 'Step-Free Routing',
        recommendation:
            'Use Elevator West for level transitions near Sec 120-130.',
        reason:
            'Elevator West is operating smoothly with 0 min wait. Restroom and seating access is fully flat via this path.',
        estimatedBenefit: 'Bypasses 3 sets of steep concourse stairs.',
        priority: 'Medium',
        confidenceLevel: 0.98,
        category: 'Accessibility',
      ),
    );

    // 4. Crowd / Gate Congestion (Role specific)
    final isGateBHot = (crowdState.gateWaitTimes['Gate B'] ?? 0) >= 20;

    if (role == UserRole.fan) {
      if (isGateBHot) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_fan_gate',
            title: 'Congestion Bypass: Gate D',
            recommendation: 'Enter via Gate D instead of Gate B.',
            reason:
                'Gate B is highly congested with a 25-minute queue. Gate D has a 5-minute queue.',
            estimatedBenefit: 'Saves ~20 minutes of standing in line.',
            priority: 'High',
            confidenceLevel: 0.94,
            category: 'Crowd',
          ),
        );
      }

      final isFood1Hot =
          (crowdState.foodCourtWaitTimes['Food Court 1 (North)'] ?? 0) >= 18;
      if (isFood1Hot) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_fan_food',
            title: 'Fast Dining Alternative',
            recommendation: 'Dine at Food Court 2 (South) or order on mobile.',
            reason:
                'Food Court 1 (North) queue is 20 mins. Food Court 2 (South) is only 6 mins.',
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
          reason:
              'A surge of 40,000 fans is expected at downtown rail gates after the final whistle.',
          estimatedBenefit: 'Saves 35 minutes of exit crowd containment delay.',
          priority: 'Medium',
          confidenceLevel: 0.85,
          category: 'Transit',
        ),
      );
    } else if (role == UserRole.volunteer) {
      // Direct volunteer to Incidents or Congested gates
      final hasOpenIncident = incidents.any((i) => i.status == 'Open');
      if (hasOpenIncident) {
        final openInc = incidents.firstWhere((i) => i.status == 'Open');
        recommendations.add(
          AIRecommendation(
            id: 'rec_vol_incident',
            title: 'Unassigned Incident Assistance',
            recommendation:
                'Report to ${openInc.location} to support operations.',
            reason:
                'An open incident of category "${openInc.category}" (Priority: ${openInc.priority}) is reported and requires volunteer assistance.',
            estimatedBenefit:
                'Helps clear incident and secures localized fan safety.',
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
            recommendation:
                'Deploy to Gate B outer plaza and direct fans to Gate D.',
            reason:
                'Gate B is experiencing overload (25 min wait). Redirecting incoming fans to Gate D will balance gate operations.',
            estimatedBenefit:
                'Balances crowd load and reduces gate wait time by 15%.',
            priority: 'High',
            confidenceLevel: 0.92,
            category: 'Crowd',
          ),
        );
      }
    } else if (role == UserRole.organizer || role == UserRole.staff) {
      // 5. Technical Decision Support rules for organizers/staff
      if (isGateBHot) {
        recommendations.add(
          const AIRecommendation(
            id: 'rec_org_gate_trigger',
            title: 'Capacity Management Action',
            recommendation:
                'Trigger public display redirect and dispatch 4 volunteers to North Concourse.',
            reason:
                'Gate B entry queue has exceeded the yellow safety threshold (25 mins). Gate D has spare capacity (5 mins).',
            estimatedBenefit:
                'Reduces peak congestion bottleneck risk at North entry.',
            priority: 'Critical',
            confidenceLevel: 0.97,
            category: 'Safety',
          ),
        );

        // Active volunteer redeployment recommendation advice
        if (deployment != null && deployment.plazaActive < 10) {
          recommendations.add(
            AIRecommendation(
              id: 'rec_org_reallocate_plaza',
              title: 'Staff Deployment Inefficiency Warning',
              recommendation:
                  'Reallocate 4 volunteers from Concourse Concessions to Plaza Entry Gates.',
              reason:
                  'Plaza active staff is low (${deployment.plazaActive}) during severe Gate B congestion.',
              estimatedBenefit:
                  'Accelerates the adoption rate of Gate D reroutes by 35%.',
              priority: 'High',
              confidenceLevel: 0.93,
              category: 'Crowd',
            ),
          );
        }
      }

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
                'Critical incident reported: "${openCriticalIncidents.first.title}" remains unassigned.',
            estimatedBenefit:
                'Resolves emergency situation and ensures venue compliance.',
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
