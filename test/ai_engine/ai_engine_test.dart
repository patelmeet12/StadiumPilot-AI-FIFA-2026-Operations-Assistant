// ============================================================
// AI Decision Engine Tests: All 10 Engine Modules
// Tests context engine, individual engines, and orchestrator
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/entities/incident.dart';
import 'package:stadium_pilot_ai/domain/entities/user_role.dart';
import 'package:stadium_pilot_ai/domain/entities/simulation_scenario.dart';
import 'package:stadium_pilot_ai/domain/entities/volunteer_deployment.dart';
import 'package:stadium_pilot_ai/domain/entities/volunteer_task.dart';
import 'package:stadium_pilot_ai/domain/entities/match_detail.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/context_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/navigation_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/crowd_intelligence_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/accessibility_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/transportation_optimizer.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/sustainability_advisor.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/volunteer_coordinator.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/operational_intelligence_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/risk_prediction_engine.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_ai_recommendations.dart';

// Helper builders
DecisiveContext _ctx({
  UserRole role = UserRole.fan,
  String weather = 'None',
  double temp = 26.0,
  bool accessibility = false,
  int familySize = 2,
  SimulationScenario scenario = SimulationScenario.none,
  String matchPhase = 'Pre-Match',
}) =>
    ContextEngine().buildContext(
      role: role,
      location: 'Sec 120',
      weatherAlert: weather,
      temperature: temp,
      currentTime: DateTime(2026, 7, 14, 18, 0),
      accessibilityRequired: accessibility,
      familySize: familySize,
      matchPhase: matchPhase,
      activeScenario: scenario,
    );

CrowdState _crowdWith({int gateBWait = 5, int food1Wait = 5}) => CrowdState(
      gateWaitTimes: {'Gate B': gateBWait, 'Gate D': 3},
      foodCourtWaitTimes: {'Food Court 1 (North)': food1Wait},
      restroomWaitTimes: {},
      zoneDensities: {},
    );

// ─── ContextEngine ────────────────────────────────────────────────────────────

void main() {

group('ContextEngine', () {
  test('builds context with all 9 fields populated', () {
    final ctx = _ctx();
    expect(ctx.role, equals(UserRole.fan));
    expect(ctx.weatherAlert, equals('None'));
    expect(ctx.temperature, equals(26.0));
    expect(ctx.accessibilityRequired, isFalse);
    expect(ctx.familySize, equals(2));
    expect(ctx.activeScenario, equals(SimulationScenario.none));
  });

  test('preserves accessibility flag correctly', () {
    final ctx = _ctx(accessibility: true);
    expect(ctx.accessibilityRequired, isTrue);
  });

  test('preserves active scenario', () {
    final ctx = _ctx(scenario: SimulationScenario.heavyRain);
    expect(ctx.activeScenario, equals(SimulationScenario.heavyRain));
  });
});

// ─── NavigationEngine ─────────────────────────────────────────────────────────

group('NavigationEngine - Weather', () {
  final engine = NavigationEngine();

  test('generates lightning fan shelter rec', () {
    final ctx = _ctx(role: UserRole.fan, weather: 'Heavy Lightning Warning');
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.any((r) => r.id == 'rec_weather_lightning_fan'), isTrue);
  });

  test('generates lightning volunteer rec', () {
    final ctx = _ctx(role: UserRole.volunteer, weather: 'Heavy Lightning Warning');
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.any((r) => r.id == 'rec_weather_lightning_vol'), isTrue);
  });

  test('generates lightning organizer rec', () {
    final ctx = _ctx(role: UserRole.organizer, weather: 'Heavy Lightning Warning');
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.any((r) => r.id == 'rec_weather_lightning_org'), isTrue);
  });

  test('generates heat fan rec', () {
    final ctx = _ctx(role: UserRole.fan, weather: 'Extreme Heat Alert', temp: 36.0);
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.any((r) => r.id == 'rec_weather_heat_fan'), isTrue);
  });

  test('heat fan rec includes family size', () {
    final ctx = _ctx(role: UserRole.fan, weather: 'Extreme Heat Alert', temp: 36.0, familySize: 4);
    final recs = engine.analyzeNavigation(ctx);
    final rec = recs.firstWhere((r) => r.id == 'rec_weather_heat_fan');
    expect(rec.recommendation, contains('4'));
  });

  test('no weather recs for None alert', () {
    final ctx = _ctx(role: UserRole.fan, weather: 'None');
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.where((r) => r.id.startsWith('rec_weather')), isEmpty);
  });
});

group('NavigationEngine - Scenarios', () {
  final engine = NavigationEngine();

  test('generates heavy rain rec for volunteer', () {
    final ctx = _ctx(role: UserRole.volunteer, scenario: SimulationScenario.heavyRain);
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.any((r) => r.id == 'scenario_heavy_rain'), isTrue);
  });

  test('heavy rain rec for fan contains ponchos', () {
    final ctx = _ctx(role: UserRole.fan, scenario: SimulationScenario.heavyRain);
    final recs = engine.analyzeNavigation(ctx);
    final rec = recs.firstWhere((r) => r.id == 'scenario_heavy_rain');
    expect(rec.recommendation, contains('poncho'));
  });

  test('generates power failure rec', () {
    final ctx = _ctx(role: UserRole.fan, scenario: SimulationScenario.powerFailure);
    final recs = engine.analyzeNavigation(ctx);
    final rec = recs.firstWhere((r) => r.id == 'scenario_power_failure');
    expect(rec.priority, equals('Critical'));
    expect(rec.recommendation, contains('Elevators are offline'));
  });

  test('generates medical emergency rec', () {
    final ctx = _ctx(role: UserRole.organizer, scenario: SimulationScenario.medicalEmergency);
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.any((r) => r.id == 'scenario_medical_emergency'), isTrue);
  });

  test('generates VIP arrival rec', () {
    final ctx = _ctx(role: UserRole.fan, scenario: SimulationScenario.vipArrival);
    final recs = engine.analyzeNavigation(ctx);
    expect(recs.any((r) => r.id == 'scenario_vip_arrival'), isTrue);
  });
});

// ─── CrowdIntelligenceEngine ──────────────────────────────────────────────────

group('CrowdIntelligenceEngine - Fan', () {
  final engine = CrowdIntelligenceEngine();

  test('generates gate bypass for fan when Gate B >= 20', () {
    final ctx = _ctx(role: UserRole.fan);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 25));
    expect(recs.any((r) => r.id == 'rec_fan_gate'), isTrue);
  });

  test('no gate bypass for fan when Gate B < 20', () {
    final ctx = _ctx(role: UserRole.fan);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 15));
    expect(recs.any((r) => r.id == 'rec_fan_gate'), isFalse);
  });

  test('generates food court bypass when Food Court 1 >= 18', () {
    final ctx = _ctx(role: UserRole.fan);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(food1Wait: 20));
    expect(recs.any((r) => r.id == 'rec_fan_food'), isTrue);
  });

  test('gate bypass saves time proportional to wait time', () {
    final ctx = _ctx(role: UserRole.fan);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 25));
    final rec = recs.firstWhere((r) => r.id == 'rec_fan_gate');
    expect(rec.estimatedTimeSavedMinutes, equals(20)); // 25 - 5
  });
});

group('CrowdIntelligenceEngine - Volunteer', () {
  final engine = CrowdIntelligenceEngine();

  final openIncident = Incident(
    id: 'inc_001',
    title: 'Crowd Issue',
    category: 'Crowd',
    location: 'Gate B',
    priority: 'High',
    status: 'Open',
    description: 'Large crowd forming.',
    reportedTime: DateTime.now(),
  );

  test('generates incident alert for volunteer', () {
    final ctx = _ctx(role: UserRole.volunteer);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(), incidents: [openIncident]);
    expect(recs.any((r) => r.id == 'rec_vol_incident'), isTrue);
  });

  test('no incident alert if no open incidents', () {
    final ctx = _ctx(role: UserRole.volunteer);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(), incidents: []);
    expect(recs.any((r) => r.id == 'rec_vol_incident'), isFalse);
  });

  test('generates gate marshalling rec when Gate B is hot', () {
    final ctx = _ctx(role: UserRole.volunteer);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 25));
    expect(recs.any((r) => r.id == 'rec_vol_gate_assist'), isTrue);
  });
});

group('CrowdIntelligenceEngine - Organizer', () {
  final engine = CrowdIntelligenceEngine();

  test('generates gate trigger rec for organizer when Gate B >= 20', () {
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 22));
    expect(recs.any((r) => r.id == 'rec_org_gate_trigger'), isTrue);
  });

  test('gate trigger is Critical priority', () {
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 22));
    final rec = recs.firstWhere((r) => r.id == 'rec_org_gate_trigger');
    expect(rec.priority, equals('Critical'));
  });

  test('generates plaza reallocation when plaza staff < 10', () {
    final ctx = _ctx(role: UserRole.organizer);
    final lowDep = const VolunteerDeployment(
      plazaActive: 6, plazaBreak: 0, concourseActive: 10,
      concourseBreak: 0, medicalActive: 8, medicalBreak: 0,
      securityActive: 6, securityBreak: 0,
    );
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 25), deployment: lowDep);
    expect(recs.any((r) => r.id == 'rec_org_reallocate_plaza'), isTrue);
  });

  test('no reallocation when plaza staff >= 10', () {
    final ctx = _ctx(role: UserRole.organizer);
    final dep = VolunteerDeployment.initial(); // plazaActive = 14
    final recs = engine.analyzeCrowd(ctx, _crowdWith(gateBWait: 25), deployment: dep);
    expect(recs.any((r) => r.id == 'rec_org_reallocate_plaza'), isFalse);
  });
});

group('CrowdIntelligenceEngine - Scenarios', () {
  final engine = CrowdIntelligenceEngine();

  test('generates extra time rec', () {
    final ctx = _ctx(scenario: SimulationScenario.extraTime);
    final recs = engine.analyzeCrowd(ctx, _crowdWith());
    expect(recs.any((r) => r.id == 'scenario_extra_time'), isTrue);
  });

  test('generates crowd surge rec', () {
    final ctx = _ctx(scenario: SimulationScenario.crowdSurge);
    final recs = engine.analyzeCrowd(ctx, _crowdWith());
    expect(recs.any((r) => r.id == 'scenario_crowd_surge'), isTrue);
  });

  test('crowd surge rec is Critical', () {
    final ctx = _ctx(scenario: SimulationScenario.crowdSurge);
    final recs = engine.analyzeCrowd(ctx, _crowdWith());
    final rec = recs.firstWhere((r) => r.id == 'scenario_crowd_surge');
    expect(rec.priority, equals('Critical'));
  });
});

// ─── AccessibilityEngine ──────────────────────────────────────────────────────

group('AccessibilityEngine', () {
  final engine = AccessibilityEngine();

  test('always generates elevator routing tip', () {
    final ctx = _ctx(role: UserRole.fan, accessibility: false);
    final recs = engine.analyzeAccessibility(ctx);
    expect(recs.any((r) => r.id == 'rec_access_elevator'), isTrue);
  });

  test('generates wheelchair routing when accessibility required', () {
    final ctx = _ctx(role: UserRole.fan, accessibility: true);
    final recs = engine.analyzeAccessibility(ctx);
    expect(recs.any((r) => r.id == 'rec_access_routing'), isTrue);
  });

  test('no wheelchair routing when accessibility not required', () {
    final ctx = _ctx(role: UserRole.fan, accessibility: false);
    final recs = engine.analyzeAccessibility(ctx);
    expect(recs.any((r) => r.id == 'rec_access_routing'), isFalse);
  });

  test('elevator tip includes accessibility flag info', () {
    final ctx = _ctx(role: UserRole.fan, accessibility: true);
    final recs = engine.analyzeAccessibility(ctx);
    final rec = recs.firstWhere((r) => r.id == 'rec_access_elevator');
    expect(rec.reason, contains('true'));
  });
});

// ─── TransportationOptimizer ──────────────────────────────────────────────────

group('TransportationOptimizer', () {
  final engine = TransportationOptimizer();

  test('generates transport delay rec when scenario active', () {
    final ctx = _ctx(scenario: SimulationScenario.transportDelay);
    final recs = engine.analyzeTransportation(ctx);
    expect(recs.any((r) => r.id == 'scenario_transport_delay'), isTrue);
  });

  test('no transport delay rec for none scenario', () {
    final ctx = _ctx(scenario: SimulationScenario.none);
    final recs = engine.analyzeTransportation(ctx);
    expect(recs.any((r) => r.id == 'scenario_transport_delay'), isFalse);
  });
});

// ─── SustainabilityAdvisor ────────────────────────────────────────────────────

group('SustainabilityAdvisor', () {
  final engine = SustainabilityAdvisor();

  test('generates fan transit rec for fan role', () {
    final ctx = _ctx(role: UserRole.fan);
    final recs = engine.analyzeSustainability(ctx);
    expect(recs.any((r) => r.id == 'rec_fan_transit'), isTrue);
  });

  test('fan transit rec has positive CO2 reduction', () {
    final ctx = _ctx(role: UserRole.fan);
    final recs = engine.analyzeSustainability(ctx);
    final rec = recs.firstWhere((r) => r.id == 'rec_fan_transit');
    expect(rec.estimatedCo2ReductionKg, greaterThan(0));
  });

  test('no fan transit rec for volunteer', () {
    final ctx = _ctx(role: UserRole.volunteer);
    final recs = engine.analyzeSustainability(ctx);
    expect(recs.any((r) => r.id == 'rec_fan_transit'), isFalse);
  });
});

// ─── VolunteerCoordinator ─────────────────────────────────────────────────────

group('VolunteerCoordinator', () {
  final engine = VolunteerCoordinator();

  final openTask = VolunteerTask(
    id: 'task_001',
    title: 'Gate B Queue Management',
    description: 'Assist at Gate B.',
    location: 'Gate B outer plaza',
    priority: 'High',
    isCompleted: false,
    assignedTime: DateTime.now(),
  );

  final doneTask = openTask.copyWith(isCompleted: true);

  test('generates task assignment rec for volunteer with open task', () {
    final ctx = _ctx(role: UserRole.volunteer);
    final recs = engine.analyzeVolunteerCoordinations(
      context: ctx,
      tasks: [openTask],
      gateBWait: 0,
    );
    expect(recs.any((r) => r.id == 'rec_vol_task'), isTrue);
  });

  test('no task rec when all tasks are completed', () {
    final ctx = _ctx(role: UserRole.volunteer);
    final recs = engine.analyzeVolunteerCoordinations(
      context: ctx,
      tasks: [doneTask],
      gateBWait: 0,
    );
    expect(recs.any((r) => r.id == 'rec_vol_task'), isFalse);
  });

  test('task rec references task location', () {
    final ctx = _ctx(role: UserRole.volunteer);
    final recs = engine.analyzeVolunteerCoordinations(
      context: ctx,
      tasks: [openTask],
      gateBWait: 0,
    );
    final rec = recs.firstWhere((r) => r.id == 'rec_vol_task');
    expect(rec.recommendation, contains('Gate B outer plaza'));
  });

  test('no recs for organizer (only volunteer)', () {
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeVolunteerCoordinations(
      context: ctx,
      tasks: [openTask],
      gateBWait: 0,
    );
    expect(recs, isEmpty);
  });
});

// ─── OperationalIntelligenceEngine ────────────────────────────────────────────

group('OperationalIntelligenceEngine', () {
  final engine = OperationalIntelligenceEngine();

  final criticalIncident = Incident(
    id: 'inc_crit',
    title: 'Medical Emergency',
    category: 'Medical',
    location: 'Section 104',
    priority: 'Critical',
    status: 'Open',
    description: 'Fan collapsed.',
    reportedTime: DateTime.now(),
  );

  final spanishIncident = Incident(
    id: 'inc_sp_1',
    title: 'Obstrucción de rampa',
    category: 'Accessibility',
    location: 'Gate B access',
    priority: 'High',
    status: 'Open',
    description: 'Una rampa de silla de ruedas tiene una obstrucción',
    reportedTime: DateTime.now(),
  );

  test('generates critical incident escalation rec', () {
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeOperations(context: ctx, incidents: [criticalIncident]);
    expect(recs.any((r) => r.id == 'rec_org_incident_resolve'), isTrue);
  });

  test('incident escalation has Critical priority', () {
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeOperations(context: ctx, incidents: [criticalIncident]);
    final rec = recs.firstWhere((r) => r.id == 'rec_org_incident_resolve');
    expect(rec.priority, equals('Critical'));
  });

  test('translates Spanish incident', () {
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeOperations(context: ctx, incidents: [spanishIncident]);
    final translation = recs.firstWhere((r) => r.id == 'rec_translate_inc_sp_1');
    expect(translation.recommendation, contains('Wheelchair accessibility ramp obstruction'));
  });

  test('translation rec reason mentions non-English format', () {
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeOperations(context: ctx, incidents: [spanishIncident]);
    final rec = recs.firstWhere((r) => r.id == 'rec_translate_inc_sp_1');
    expect(rec.reason, contains('non-English format'));
  });

  test('no recs for fan role (operational engine is staff only)', () {
    final ctx = _ctx(role: UserRole.fan);
    final recs = engine.analyzeOperations(context: ctx, incidents: [criticalIncident]);
    expect(recs, isEmpty);
  });

  test('resolved incidents do not trigger translation', () {
    final resolved = criticalIncident.copyWith(status: 'Resolved');
    final ctx = _ctx(role: UserRole.organizer);
    final recs = engine.analyzeOperations(context: ctx, incidents: [resolved]);
    expect(recs.any((r) => r.id.startsWith('rec_translate')), isFalse);
  });
});

// ─── RiskPredictionEngine ─────────────────────────────────────────────────────

group('RiskPredictionEngine', () {
  final engine = RiskPredictionEngine();

  final lightningPreset = MatchPreset(
    matchId: 'match_usa_england',
    homeTeam: 'USA',
    awayTeam: 'England',
    weatherAlert: 'Heavy Lightning Warning',
    temperature: 18.0,
    attendanceProjection: 84100,
    vipMediaPriority: 'Critical',
    crowdMultiplier: 1.35,
    railUsageRate: 0.88,
  );

  final normalPreset = MatchPreset(
    matchId: 'match_arg_france',
    homeTeam: 'Argentina',
    awayTeam: 'France',
    weatherAlert: 'None',
    temperature: 26.0,
    attendanceProjection: 82500,
    vipMediaPriority: 'High',
    crowdMultiplier: 1.1,
    railUsageRate: 0.72,
  );

  test('generates gate congestion risk when Gate B >= 18', () {
    final risks = engine.predictUpcomingRisks(
      crowdState: _crowdWith(gateBWait: 20),
      preset: normalPreset,
    );
    expect(risks.any((r) => r.id == 'risk_gate_b'), isTrue);
  });

  test('no gate congestion risk when Gate B < 18', () {
    final risks = engine.predictUpcomingRisks(
      crowdState: _crowdWith(gateBWait: 10),
      preset: normalPreset,
    );
    expect(risks.any((r) => r.id == 'risk_gate_b'), isFalse);
  });

  test('generates lightning risk for lightning weather alert', () {
    final risks = engine.predictUpcomingRisks(
      crowdState: _crowdWith(),
      preset: lightningPreset,
    );
    expect(risks.any((r) => r.id == 'risk_weather_lightning'), isTrue);
  });

  test('lightning risk has Critical probability >= 0.9', () {
    final risks = engine.predictUpcomingRisks(
      crowdState: _crowdWith(),
      preset: lightningPreset,
    );
    final risk = risks.firstWhere((r) => r.id == 'risk_weather_lightning');
    expect(risk.probability, greaterThanOrEqualTo(0.9));
  });

  test('always generates exit bottleneck risk', () {
    final risks = engine.predictUpcomingRisks(
      crowdState: _crowdWith(),
      preset: normalPreset,
    );
    expect(risks.any((r) => r.id == 'risk_exit_bottleneck'), isTrue);
  });

  test('all risk probabilities are between 0.0 and 1.0', () {
    final risks = engine.predictUpcomingRisks(
      crowdState: _crowdWith(gateBWait: 20),
      preset: lightningPreset,
    );
    for (final risk in risks) {
      expect(risk.probability, greaterThanOrEqualTo(0.0));
      expect(risk.probability, lessThanOrEqualTo(1.0));
    }
  });
});

// ─── GetAIRecommendations Orchestrator ────────────────────────────────────────

group('GetAIRecommendations Orchestrator', () {
  late GetAIRecommendations usecase;

  setUp(() {
    usecase = GetAIRecommendations();
  });

  test('returns non-empty list for fan with congested state', () async {
    final recs = await usecase.call(
      role: UserRole.fan,
      location: 'Sec 120',
      crowdState: _crowdWith(gateBWait: 25, food1Wait: 20),
      incidents: [],
      tasks: [],
    );
    expect(recs, isNotEmpty);
  });

  test('all returned recommendations have non-empty IDs', () async {
    final recs = await usecase.call(
      role: UserRole.fan,
      location: 'Sec 120',
      crowdState: CrowdState.initial(),
      incidents: [],
      tasks: [],
    );
    for (final rec in recs) {
      expect(rec.id, isNotEmpty);
    }
  });

  test('returns Critical recs before High recs (sorted)', () async {
    final recs = await usecase.call(
      role: UserRole.fan,
      location: 'Sec 120',
      crowdState: CrowdState.initial(),
      incidents: [],
      tasks: [],
      weatherAlert: 'Heavy Lightning Warning',
    );
    final criticalIndex = recs.indexWhere((r) => r.priority == 'Critical');
    final highIndex = recs.indexWhere((r) => r.priority == 'High');
    if (criticalIndex != -1 && highIndex != -1) {
      expect(criticalIndex, lessThan(highIndex));
    }
  });

  test('no duplicate IDs in returned list', () async {
    final recs = await usecase.call(
      role: UserRole.organizer,
      location: 'Control Room',
      crowdState: CrowdState.initial(),
      incidents: [],
      tasks: [],
      activeScenario: SimulationScenario.heavyRain,
    );
    final ids = recs.map((r) => r.id).toList();
    final uniqueIds = ids.toSet();
    expect(ids.length, equals(uniqueIds.length));
  });

  test('all confidence levels are between 0.0 and 1.0', () async {
    final recs = await usecase.call(
      role: UserRole.fan,
      location: 'Sec 104',
      crowdState: CrowdState.initial(),
      incidents: [],
      tasks: [],
    );
    for (final rec in recs) {
      expect(rec.confidenceLevel, greaterThanOrEqualTo(0.0));
      expect(rec.confidenceLevel, lessThanOrEqualTo(1.0));
    }
  });
});
} // end main
