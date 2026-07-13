import '../entities/route_plan.dart';
import '../entities/crowd_state.dart';

class CalculateRoute {
  Future<RoutePlan> call({
    required String start,
    required String destination,
    required bool wheelchairFriendly,
    required bool avoidCrowds,
    required CrowdState crowdState,
  }) async {
    // Standardize locations
    final startLoc = start.trim();
    final destLoc = destination.trim();

    // Congestion values check
    final isGateBCongested = (crowdState.gateWaitTimes['Gate B'] ?? 0) >= 20;
    final isFoodCourt1Congested =
        (crowdState.foodCourtWaitTimes['Food Court 1 (North)'] ?? 0) >= 15;

    List<String> steps = [];
    List<String> accessibilityFeatures = [];
    int duration = 6;
    int distance = 250;
    String congestion = "Low";
    String reasoning = "";

    // Generate path logic
    if (wheelchairFriendly) {
      accessibilityFeatures.addAll([
        'Elevator West Access',
        'Ramped Accessways',
        'Wide Doorways',
      ]);
      steps.add(
        'Start at $startLoc. Follow yellow tactile paving towards elevator bank West.',
      );

      if (startLoc.contains('Gate B') && avoidCrowds && isGateBCongested) {
        steps.add(
          'REROUTE CROWD BYPASS: Proceed to Gate D accessible lane instead of Gate B.',
        );
        steps.add('Enter through Gate D automated wider ticket scanner.');
        duration += 4;
        distance += 120;
        congestion = "Low";
        reasoning =
            "Redirected to Gate D to bypass a 25-minute queue at Gate B. Utilized the automated wide gate scanner and West elevator for wheelchair support.";
      } else {
        steps.add('Enter via accessible Gate A lanes.');
        reasoning =
            "Utilized step-free pathways and elevators to avoid Level 1 staircases. Recommended for strollers and wheelchair users.";
      }

      steps.add('Take elevator West to Level 2.');
      steps.add(
        'Follow the wheelchair-friendly signage to the concourse corridor.',
      );
      steps.add('Arrive at $destLoc via flat threshold seating entrance.');
      duration += 3;
    } else {
      // Normal route
      steps.add('Start at $startLoc. Proceed towards main concourse stairs.');

      if (avoidCrowds) {
        if (startLoc.contains('Gate B') && isGateBCongested) {
          steps.add(
            'CROWD REDIRECT: Redirect via outer ring walking path to Gate D.',
          );
          steps.add('Enter through Gate D express line.');
          duration += 3;
          distance += 150;
          congestion = "Low";
          reasoning =
              "Rerouted via Gate D because Gate B is experiencing heavy congestion (25 min wait). Gate D reduces your wait time to 5 mins.";
        } else if (destLoc.contains('Food Court 1') && isFoodCourt1Congested) {
          steps.add(
            'CROWD REDIRECT: Walk towards Food Court 2 (South) instead of Food Court 1.',
          );
          steps.add('Order food via Mobile Express Lane.');
          duration = 5;
          distance -= 50;
          congestion = "Low";
          reasoning =
              "Food Court 1 is heavily congested. Food Court 2 (South) will save you approximately 14 minutes of wait time.";
        } else {
          steps.add('Enter through Gate C ticket turnstiles.');
          reasoning = "Normal route via low congestion corridors.";
        }
      } else {
        // Direct route, ignore congestion
        if (startLoc.contains('Gate B')) {
          steps.add('Enter through Gate B main turnstiles.');
          congestion = isGateBCongested ? "High" : "Medium";
          duration = isGateBCongested ? 22 : 8;
          reasoning =
              "Direct route selected. Note: Gate B has high queue wait times.";
        } else {
          steps.add('Enter through Gate C turnstiles.');
          reasoning = "Standard direct pathway via closest gate access point.";
        }
      }

      steps.add('Take the central escalator to Level 2 concourse.');
      steps.add('Turn left and walk 80 meters along the concourse wall.');
      steps.add('Arrive at $destLoc.');
    }

    return RoutePlan(
      title: wheelchairFriendly
          ? 'Accessible Route'
          : (avoidCrowds ? 'Least Crowded Route' : 'Fastest Direct Route'),
      totalDurationMins: duration,
      totalDistanceMeters: distance,
      steps: steps,
      isWheelchairFriendly: wheelchairFriendly,
      crowdCongestionLevel: congestion,
      reasoning: reasoning,
      accessibilityFeatures: accessibilityFeatures,
    );
  }
}
