import '../../entities/ai_recommendation.dart';
import '../../entities/user_role.dart';
import '../../entities/simulation_scenario.dart';
import 'context_engine.dart';

/// Navigation Engine compiling route pathing and egress shortcuts.
class NavigationEngine {
  List<AIRecommendation> analyzeNavigation(DecisiveContext context) {
    final List<AIRecommendation> recommendations = [];
    final weatherAlert = context.weatherAlert;
    final role = context.role;
    final temperature = context.temperature;
    final matchPhase = context.matchPhase;
    final timeContext = context.currentTime;
    final activeScenario = context.activeScenario;

    // VIP corridor alert
    if (activeScenario == SimulationScenario.vipArrival) {
      recommendations.add(
        AIRecommendation(
          id: 'scenario_vip_arrival',
          title: 'Scenario Mode: VIP Escort & Pathway Security',
          recommendation: role == UserRole.fan
              ? 'VIP motorcade is passing. Gate C entry lobby is temporarily restricted (3 mins).'
              : 'Activate secure VIP corridor section 110 and deploy 2 escort coordinators to Gate C check-in.',
          reason:
              'VIP Motorcade arrival scheduled in 5 minutes at MetLife Stadium (Match Phase: $matchPhase).',
          estimatedBenefit:
              'Secures VIP transit timeline and protocol compliance.',
          priority: 'Medium',
          confidenceLevel: 0.91,
          category: 'Navigation',
          alternativeOptions: const [
            'Hold general public ticket checks at Gate C section 2 for 3 minutes',
            'Redirect VIP corridor escort via South loading elevator',
          ],
          estimatedTimeSavedMinutes: 8,
          estimatedWalkingDistanceSavedMeters: 80,
          estimatedCo2ReductionKg: 0.0,
          operationalImpact:
              'Secures VIP timeline protocol compliance with zero friction index.',
        ),
      );
    }

    // Heavy Rain poncho logistics
    if (activeScenario == SimulationScenario.heavyRain) {
      recommendations.add(
        AIRecommendation(
          id: 'scenario_heavy_rain',
          title: 'Scenario Mode: Heavy Rain Logistics',
          recommendation: role == UserRole.fan
              ? 'Check out free rain poncho distribution hubs at Gate check areas of MetLife Stadium.'
              : 'Distribute rain ponchos at Gate entries and activate concourse floor dryers to prevent slips.',
          reason:
              'Active Heavy Rain scenario simulated. Concourse moisture sensors report high slippage risk.',
          estimatedBenefit: 'Prevents slip incidents and keeps fans dry.',
          priority: 'Medium',
          confidenceLevel: 0.94,
          category: 'Safety',
          alternativeOptions: const [
            'Advise fans to purchase umbrellas at concourse shops',
            'Delay outer gate open times by 10 minutes',
          ],
          estimatedTimeSavedMinutes: 5,
          estimatedWalkingDistanceSavedMeters: 20,
          estimatedCo2ReductionKg: 0.0,
          operationalImpact:
              'Reduces concourse slip hazards by 80% and increases comfort indexes.',
        ),
      );
    }

    // Medical Emergency responder route clearances
    if (activeScenario == SimulationScenario.medicalEmergency) {
      recommendations.add(
        AIRecommendation(
          id: 'scenario_medical_emergency',
          title: 'Scenario Mode: Medical Response Route Clearance',
          recommendation: role == UserRole.fan
              ? 'Keep evacuation lane West clear for emergency responder movements.'
              : 'Clear emergency vehicle ingress lane A and dispatch standby medical volunteer squad 2 to Section 104.',
          reason:
              'Medical Emergency scenario simulated: report of fan medical distress at MetLife Stadium concourse lobby.',
          estimatedBenefit:
              'Speeds up medic response and protects guest safety.',
          priority: 'Critical',
          confidenceLevel: 0.99,
          category: 'Safety',
          alternativeOptions: const [
            'Escort patient to nearest first-aid kiosk via wheelchair',
            'Alert municipal EMS responders standby',
          ],
          estimatedTimeSavedMinutes: 4,
          estimatedWalkingDistanceSavedMeters: 150,
          estimatedCo2ReductionKg: 0.0,
          operationalImpact:
              'Saves 4 minutes in medical response transit time, ensuring golden-hour target is met.',
        ),
      );
    }

    // Power Failure scenario
    if (activeScenario == SimulationScenario.powerFailure) {
      recommendations.add(
        AIRecommendation(
          id: 'scenario_power_failure',
          title: 'Scenario Mode: Power Grid Restoration Operations',
          recommendation: role == UserRole.fan
              ? 'Secondary concourse lighting is active. Elevators are offline; please use main exit stairs.'
              : 'De-energize secondary elevator loops, activate concourse battery backup lights, and deploy volunteers with flashlights.',
          reason:
              'Power Failure scenario active: grid drop detected at Concourse sector 2 of MetLife Stadium.',
          estimatedBenefit:
              'Maintains concourse visibility and avoids guest exit panic.',
          priority: 'Critical',
          confidenceLevel: 0.99,
          category: 'Safety',
          alternativeOptions: const [
            'Redirect concourse traffic to South Gate outer exits',
            'Instruct concession vendors to halt electronic payments',
          ],
          estimatedTimeSavedMinutes: 12,
          estimatedWalkingDistanceSavedMeters: 180,
          estimatedCo2ReductionKg: 0.5,
          operationalImpact:
              'Prevents stampede warnings and guides crowd to secure open-air plazas.',
        ),
      );
    }

    // Weather warning rules matching original implementation
    if (weatherAlert == 'Heavy Lightning Warning') {
      if (role == UserRole.fan) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_weather_lightning_fan',
            title: 'Severe Weather: Seek Concourse Shelter',
            recommendation:
                'Exposed seating decks at MetLife Stadium present high hazard under $weatherAlert ($temperature°C). Move inside covered concourses immediately.',
            reason:
                'Active lightning storm warning is in effect within 5 miles of MetLife Stadium during the $matchPhase phase (Time: ${timeContext.hour}:${timeContext.minute.toString().padLeft(2, '0')}).',
            estimatedBenefit:
                'Guarantees fan safety and avoids exposure to strikes.',
            priority: 'Critical',
            confidenceLevel: 0.99,
            category: 'Safety',
            alternativeOptions: const [
              'Seek shelter under Gate B entry corridors',
              'Relocate to lower level concession tunnels',
            ],
            estimatedTimeSavedMinutes: 15,
            estimatedWalkingDistanceSavedMeters: 250,
            estimatedCo2ReductionKg: 0.0,
            operationalImpact:
                'Evacuates high-risk seating areas, reducing localized lightning strike exposure index by 98%.',
          ),
        );
      } else if (role == UserRole.volunteer) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_weather_lightning_vol',
            title: 'Severe Weather: Direct Public Inside',
            recommendation:
                'Retreat from open parking structures and direct fans to covered entry hubs at MetLife Stadium.',
            reason:
                'Match operations are suspended due to active local lightning warning during $matchPhase. Safe assignment is priority for volunteer team.',
            estimatedBenefit:
                'Achieves swift and organized public safety sheltering.',
            priority: 'Critical',
            confidenceLevel: 0.99,
            category: 'Safety',
            alternativeOptions: const [
              'Standby inside the main Plaza gate check-point tunnels',
              'Report to Section 102 volunteer operations hub',
            ],
            estimatedTimeSavedMinutes: 10,
            estimatedWalkingDistanceSavedMeters: 180,
            estimatedCo2ReductionKg: 0.0,
            operationalImpact:
                'Coordinates the mass movement of fans, stabilizing stadium entry safety margins.',
          ),
        );
      } else if (role == UserRole.organizer || role == UserRole.staff) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_weather_lightning_org',
            title: 'Severe Weather: Suspend Shuttle Carts',
            recommendation:
                'De-energize open-air golf carts at MetLife Stadium, broadcast warning alerts, and dispatch safety marshals.',
            reason:
                'Severe lightning threat level is Critical at ${timeContext.hour}:${timeContext.minute}. Outdoor personnel must seek immediate shelter during this $matchPhase storm.',
            estimatedBenefit:
                'Eliminates open-air strike risk across VIP/Media walkways.',
            priority: 'Critical',
            confidenceLevel: 0.99,
            category: 'Safety',
            alternativeOptions: const [
              'Deploy covered logistics shuttle buses',
              'Delay next media arrivals scheduled for this shift',
            ],
            estimatedTimeSavedMinutes: 20,
            estimatedWalkingDistanceSavedMeters: 300,
            estimatedCo2ReductionKg: 0.45,
            operationalImpact:
                'Secures high-exposure transit pathways, achieving complete tournament compliance.',
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
                'Visit cooling hydration zones at Sec 112 Concourse. Claim a free water voucher for your family size of ${context.familySize}.',
            reason:
                'Ambient temperatures have peaked at ${temperature.toInt()}°C. High risk of thermal fatigue for neurodivergent or senior fans.',
            estimatedBenefit: 'Prevents thermal exhaustion and dehydration.',
            priority: 'High',
            confidenceLevel: 0.96,
            category: 'Safety',
            alternativeOptions: const [
              'Visit medical station Section 104 lobby',
              'Purchase drinks at nearest Concourse Section 120 concession',
            ],
            estimatedTimeSavedMinutes: 12,
            estimatedWalkingDistanceSavedMeters: 90,
            estimatedCo2ReductionKg: 0.0,
            operationalImpact:
                'Maintains public health wellness metrics and prevents heat exhaustion events.',
          ),
        );
      } else if (role == UserRole.volunteer) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_weather_heat_vol',
            title: 'Severe Weather: Distribute Fluids',
            recommendation:
                'Distribute chilled water at Gate check loops of MetLife Stadium. Monitor fans for heat sickness.',
            reason:
                'Extreme Heat Warning is in effect across all outer security entry plazas during $matchPhase ($temperature°C).',
            estimatedBenefit:
                'Reduces medical intervention incident rates by ~22%.',
            priority: 'High',
            confidenceLevel: 0.94,
            category: 'Safety',
            alternativeOptions: const [
              'Distribute electrolyte packs inside gate corridors',
              'Set up misting devices near plaza security checks',
            ],
            estimatedTimeSavedMinutes: 15,
            estimatedWalkingDistanceSavedMeters: 140,
            estimatedCo2ReductionKg: 0.05,
            operationalImpact:
                'Lowers localized dehydration incident frequencies during gate processing peaks.',
          ),
        );
      } else if (role == UserRole.organizer || role == UserRole.staff) {
        recommendations.add(
          AIRecommendation(
            id: 'rec_weather_heat_org',
            title: 'Severe Weather: Activate Cooling Mists',
            recommendation:
                'Activate outdoor misting stations at MetLife Stadium, dispatch emergency water boxes, and flash heat guidance.',
            reason:
                'Telemetry shows heat stress indices exceed safety thresholds at West entry plaza during $matchPhase ($temperature°C). Current time is ${timeContext.hour}:${timeContext.minute}.',
            estimatedBenefit: 'Supports crowd health safety guidelines.',
            priority: 'High',
            confidenceLevel: 0.97,
            category: 'Safety',
            alternativeOptions: const [
              'Open air-conditioned Section 101/102 lobbies to the public',
              'Increase Concourse concessions cold drink shipments',
            ],
            estimatedTimeSavedMinutes: 18,
            estimatedWalkingDistanceSavedMeters: 160,
            estimatedCo2ReductionKg: 0.2,
            operationalImpact:
                'Decreases emergency medical dispatches by up to 25% across outer plazas.',
          ),
        );
      }
    }

    return recommendations;
  }
}
