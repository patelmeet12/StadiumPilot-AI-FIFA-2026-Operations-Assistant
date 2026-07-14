import '../../entities/ai_recommendation.dart';
import '../../entities/crowd_state.dart';
import '../../entities/incident.dart';
import '../../entities/user_role.dart';
import '../../entities/volunteer_deployment.dart';
import '../../entities/simulation_scenario.dart';
import 'context_engine.dart';

/// Crowd Intelligence Engine assessing wait queues, surge capacities, and role-specific crowd management actions.
class CrowdIntelligenceEngine {
  List<AIRecommendation> analyzeCrowd(
    DecisiveContext context,
    CrowdState crowdState, {
    List<Incident> incidents = const [],
    VolunteerDeployment? deployment,
  }) {
    final List<AIRecommendation> recommendations = [];

    final gateBWait = crowdState.gateWaitTimes['Gate B'] ?? 0;
    final isGateBHot = gateBWait >= 20;
    final food1Wait =
        crowdState.foodCourtWaitTimes['Food Court 1 (North)'] ?? 0;
    final role = context.role;

    // ─── Fan-specific recommendations ───────────────────────────────────────

    if (role == UserRole.fan) {
      // Gate bypass advice
      if (isGateBHot) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_fan_gate',
            title: 'Gate Entry Queue Bypass',
            recommendation:
                'Enter via Gate D instead of Gate B at MetLife Stadium.',
            reason:
                'Gate B entry queue has peaked at $gateBWait mins (limit 20 mins) during ${context.matchPhase}. Re-routing is optimal for a family size of ${context.familySize}.',
            estimatedBenefit:
                'Saves ~${gateBWait - 5} minutes of standing in line.',
            priority: 'High',
            confidenceLevel: 0.94,
            category: 'Crowd',
            alternativeOptions: const [
              'Enter via Gate A (current wait: 8 mins)',
              'Hold inside parking lot zone until queue levels subside',
            ],
            estimatedTimeSavedMinutes: gateBWait - 5,
            estimatedWalkingDistanceSavedMeters: -120,
            estimatedCo2ReductionKg: 0.15,
            operationalImpact:
                'Balances entrance loading and reduces localized bottleneck risks.',
          ),
        );
      }

      // Dining bypass
      if (food1Wait >= 18) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_fan_food',
            title: 'Fast Dining Alternative',
            recommendation:
                'Dine at Food Court 2 (South) or order on mobile at MetLife Stadium.',
            reason:
                'Food Court 1 queue wait times are at $food1Wait mins during ${context.matchPhase}. Suggesting south court dining for family size of ${context.familySize}.',
            estimatedBenefit:
                'Saves ${food1Wait - 5} minutes on food collection.',
            priority: 'Medium',
            confidenceLevel: 0.89,
            category: 'Crowd',
            alternativeOptions: const [
              'Order via mobile app for pickup express checkout',
              'Visit localized Concourse Section 110 drink cart',
            ],
            estimatedTimeSavedMinutes: food1Wait - 5,
            estimatedWalkingDistanceSavedMeters: 60,
            estimatedCo2ReductionKg: 0.05,
            operationalImpact:
                'Reduces queue build-ups and concourse walking friction.',
          ),
        );
      }
    }

    // ─── Volunteer-specific recommendations ─────────────────────────────────

    if (role == UserRole.volunteer) {
      // Incident alert
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
                'An open incident of category "${openInc.category}" (Priority: ${openInc.priority}) is reported at MetLife Stadium during ${context.matchPhase}, requiring active volunteer dispatcher support.',
            estimatedBenefit:
                'Helps clear incident and secures localized fan safety.',
            priority: 'High',
            confidenceLevel: 0.95,
            category: 'Safety',
            alternativeOptions: const [
              'Report to nearest security guard checkpoint for assistance',
              'Check in with volunteer operations command office',
            ],
            estimatedTimeSavedMinutes: 12,
            estimatedWalkingDistanceSavedMeters: 140,
            estimatedCo2ReductionKg: 0.0,
            operationalImpact:
                'Maintains fast response times and keeps emergency pathways completely clear.',
          ),
        );
      }

      // Gate B marshalling assist
      if (isGateBHot) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_vol_gate_assist',
            title: 'Crowd Marshalling Support',
            recommendation:
                'Deploy to Gate B outer plaza and direct fans to Gate D at MetLife Stadium.',
            reason:
                'Gate B is experiencing overload ($gateBWait min wait). Redirecting incoming crowd balances gate operations.',
            estimatedBenefit:
                'Balances crowd load and reduces gate wait time by 15%.',
            priority: 'High',
            confidenceLevel: 0.92,
            category: 'Crowd',
            alternativeOptions: const [
              'Redirect fans to outer concessions plazas',
              'Assist with ticket scanners checks at Gate B',
            ],
            estimatedTimeSavedMinutes: 18,
            estimatedWalkingDistanceSavedMeters: 200,
            estimatedCo2ReductionKg: 0.1,
            operationalImpact:
                'Maintains crowd flow speeds, reducing potential gate crushing hazards.',
          ),
        );
      }
    }

    // ─── Organizer-specific recommendations ─────────────────────────────────

    if (role == UserRole.organizer || role == UserRole.staff) {
      if (isGateBHot) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_org_gate_trigger',
            title: 'Capacity Management Action',
            recommendation:
                'Trigger public display redirect and dispatch 4 volunteers to North Concourse at MetLife Stadium.',
            reason:
                'Gate B entry queue has exceeded the yellow safety threshold ($gateBWait mins). Gate D has spare capacity (5 mins) at current time ${context.currentTime.hour}:${context.currentTime.minute.toString().padLeft(2, '0')}.',
            estimatedBenefit:
                'Reduces peak congestion bottleneck risk at North entry.',
            priority: 'Critical',
            confidenceLevel: 0.97,
            category: 'Safety',
            alternativeOptions: const [
              'Open secondary access wickets at Gate B outer fence',
              'Announce gate bypass delay warning to fan mobile apps',
            ],
            estimatedTimeSavedMinutes: 22,
            estimatedWalkingDistanceSavedMeters: 100,
            estimatedCo2ReductionKg: 0.08,
            operationalImpact:
                'Stabilizes gate throughput rates to below yellow warning limits.',
          ),
        );

        // Staff reallocation when plaza is understaffed
        if (deployment != null && deployment.plazaActive < 10) {
          recommendations.add(
            AIRecommendation(
              id: 'rec_org_reallocate_plaza',
              title: 'Staff Deployment Inefficiency Warning',
              recommendation:
                  'Reallocate 4 volunteers from Concourse Concessions to Plaza Entry Gates.',
              reason:
                  'Plaza active staff count is low (${deployment.plazaActive}) during severe Gate B congestion ($gateBWait min wait) at MetLife Stadium.',
              estimatedBenefit:
                  'Accelerates the adoption rate of Gate D reroutes by 35%.',
              priority: 'High',
              confidenceLevel: 0.93,
              category: 'Crowd',
              alternativeOptions: const [
                'Request emergency standby volunteer deployment reserve',
                'Shift 2 volunteers from Medical desk and 2 from Security check',
              ],
              estimatedTimeSavedMinutes: 15,
              estimatedWalkingDistanceSavedMeters: 80,
              estimatedCo2ReductionKg: 0.0,
              operationalImpact:
                  'Optimizes local personnel distribution efficiency by 30%.',
            ),
          );
        }
      }
    }

    // ─── Scenario-based crowd rules (role-agnostic) ─────────────────────────

    // Extra Time concessions
    if (context.activeScenario == SimulationScenario.extraTime) {
      recommendations.add(
        AIRecommendation(
          id: 'scenario_extra_time',
          title: 'Scenario Mode: Extra Time Logistics',
          recommendation: role == UserRole.fan
              ? 'Note that stadium concessions remain open during extra time. Transit lines are extended.'
              : 'Extend concession stand opening hours by 30 minutes and delay local train egress schedule standby.',
          reason:
              'Match has entered Extra Time phase. Exit surges are delayed by 30-40 minutes.',
          estimatedBenefit:
              'Maintains refreshment supply index and aligns transit loops.',
          priority: 'High',
          confidenceLevel: 0.96,
          category: 'Crowd',
          alternativeOptions: const [
            'Close concessions and restrict fans to bottled water distribution',
            'Request transit platform holding gate delay locks',
          ],
          estimatedTimeSavedMinutes: 30,
          estimatedWalkingDistanceSavedMeters: 0,
          estimatedCo2ReductionKg: 0.8,
          operationalImpact:
              'Prevents mass post-match transit line gridlock at local stations.',
        ),
      );
    }

    // Penalty Shootout exit gate pre-positioning
    if (context.activeScenario == SimulationScenario.penaltyShootout) {
      recommendations.add(
        AIRecommendation(
          id: 'scenario_penalty_shootout',
          title: 'Scenario Mode: Penalty Shootout Security',
          recommendation: role == UserRole.fan
              ? 'Remain seated. Secure egress routes will be opened immediately after shootout completion.'
              : 'Pre-position security personnel at pitch-side boundaries and standby emergency exit gates.',
          reason:
              'Penalty Shootout phase active. High risk of pitch invasion or localized crowd surge exit rushes.',
          estimatedBenefit: 'Prevents field intrusion risks completely.',
          priority: 'High',
          confidenceLevel: 0.97,
          category: 'Safety',
          alternativeOptions: const [
            'Double outer perimeter patrol counts',
            'Trigger PA warning broadcasts against field entry',
          ],
          estimatedTimeSavedMinutes: 10,
          estimatedWalkingDistanceSavedMeters: 40,
          estimatedCo2ReductionKg: 0.0,
          operationalImpact:
              'Maintains strict perimeter boundary protocols, ensuring safety compliance.',
        ),
      );
    }

    // Crowd Surge gate barriers
    if (context.activeScenario == SimulationScenario.crowdSurge) {
      recommendations.add(
        AIRecommendation(
          id: 'scenario_crowd_surge',
          title: 'Scenario Mode: Entrance Surge Marshalling',
          recommendation: role == UserRole.fan
              ? 'Entrance Gate B is overloaded. Please follow guide rails to Gate D.'
              : 'Deploy emergency crowd barriers at Gate B outer check-point, and broadcast Gate D bypass instructions.',
          reason:
              'Crowd Surge scenario active: ticket inflow rates at plaza gate have exceeded 150/minute.',
          estimatedBenefit:
              'Lowers outer gate crush density index to safe limits.',
          priority: 'Critical',
          confidenceLevel: 0.98,
          category: 'Crowd',
          alternativeOptions: const [
            'Temporarily lock outer ticketing wickets for 2 minutes',
            'Deploy gate-marshalling security team',
          ],
          estimatedTimeSavedMinutes: 15,
          estimatedWalkingDistanceSavedMeters: 120,
          estimatedCo2ReductionKg: 0.1,
          operationalImpact:
              'Maintains local gate crowd pressure metrics within safety limits.',
        ),
      );
    }

    return recommendations;
  }
}
