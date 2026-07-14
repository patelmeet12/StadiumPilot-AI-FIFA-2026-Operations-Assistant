import '../../entities/operational_risk.dart';
import '../../entities/crowd_state.dart';
import '../../entities/match_detail.dart';

/// Risk Prediction Engine forecasting gate queues, exits, and weather risks.
class RiskPredictionEngine {
  List<OperationalRisk> predictUpcomingRisks({
    required CrowdState crowdState,
    required MatchPreset preset,
  }) {
    final List<OperationalRisk> risks = [];

    // 1. Gate congestion risk
    final gateBWait = crowdState.gateWaitTimes['Gate B'] ?? 0;
    if (gateBWait >= 18) {
      risks.add(
        OperationalRisk(
          id: 'risk_gate_b',
          title: 'Gate Congestion Warning: Gate B queue overload',
          riskCategory: 'Gate',
          probability: 0.88,
          timeline: 'Next 15 Mins',
          description:
              'Ticketing queues at Gate B have reached $gateBWait minutes and are projected to surge during egress checkins.',
          preventiveAction:
              'Deploy auxiliary volunteers and reroute incoming fans to Gate D.',
          expectedImpact:
              'Lowers ticket processing bottlenecks and reduces wait time by 7 mins.',
        ),
      );
    }

    // 2. Weather safety risk
    if (preset.weatherAlert == 'Heavy Lightning Warning') {
      risks.add(
        const OperationalRisk(
          id: 'risk_weather_lightning',
          title: 'Electrical Lightning Strike Threat',
          riskCategory: 'Weather',
          probability: 0.95,
          timeline: 'Immediate',
          description:
              'Active lightning strikes recorded within 5 miles. 82% probability of lightning strike within MetLife stadium envelope.',
          preventiveAction:
              'Initiate immediate seating deck evacuation broadcast and move all open-area fans inside concourses.',
          expectedImpact:
              'Protects personal safety, minimizing severe weather hazard index.',
        ),
      );
    }

    // 3. Exit bottlenecks
    risks.add(
      const OperationalRisk(
        id: 'risk_exit_bottleneck',
        title: 'Gate Clearance Bottleneck: Gate A egress routes',
        riskCategory: 'Exit',
        probability: 0.65,
        timeline: 'Post-Match',
        description:
            'Egress modeling predicts exit bottlenecks at Gate A due to narrow outer fence construction design.',
        preventiveAction:
            'Open secondary escape gates A3 and A4, and flash exit bypass directions on standard big screens.',
        expectedImpact:
            'Reduces post-match stadium exit clearance time by 18 mins.',
      ),
    );

    return risks;
  }
}
