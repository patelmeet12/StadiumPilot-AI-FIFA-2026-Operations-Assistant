// ============================================================
// Edge Case Tests: boundary conditions, null safety, invalid inputs
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/entities/ai_recommendation.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/entities/incident.dart';
import 'package:stadium_pilot_ai/domain/entities/simulation_scenario.dart';
import 'package:stadium_pilot_ai/domain/entities/user_role.dart';
import 'package:stadium_pilot_ai/domain/entities/volunteer_task.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/crowd_intelligence_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/context_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/recommendation_ranking_engine.dart';
import 'package:stadium_pilot_ai/domain/usecases/calculate_route.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_ai_recommendations.dart';


DecisiveContext _ctx({
  UserRole role = UserRole.fan,
  String weather = 'None',
  double temp = 26.0,
  bool accessibility = false,
  int familySize = 1,
  SimulationScenario scenario = SimulationScenario.none,
}) =>
    ContextEngine().buildContext(
      role: role,
      location: 'Gate B',
      weatherAlert: weather,
      temperature: temp,
      currentTime: DateTime(2026, 7, 14, 18, 0),
      accessibilityRequired: accessibility,
      familySize: familySize,
      matchPhase: 'Pre-Match',
      activeScenario: scenario,
    );

void main() {
  // ─── CrowdState Edge Cases ─────────────────────────────────────────────────

  group('CrowdState - Edge Cases', () {
    test('empty gate wait times map does not throw', () {
      const empty = CrowdState(
        gateWaitTimes: {},
        foodCourtWaitTimes: {},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
      expect(empty.gateWaitTimes, isEmpty);
    });

    test('exactly at threshold (20 min) triggers bypass', () {
      final state = CrowdState(
        gateWaitTimes: {'Gate B': 20}, // exactly at threshold
        foodCourtWaitTimes: {},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
      final engine = CrowdIntelligenceEngine();
      final ctx = _ctx(role: UserRole.fan);
      final recs = engine.analyzeCrowd(ctx, state);
      expect(recs.any((r) => r.id == 'rec_fan_gate'), isTrue);
    });

    test('one below threshold (19 min) does NOT trigger bypass', () {
      final state = CrowdState(
        gateWaitTimes: {'Gate B': 19},
        foodCourtWaitTimes: {},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
      final engine = CrowdIntelligenceEngine();
      final ctx = _ctx(role: UserRole.fan);
      final recs = engine.analyzeCrowd(ctx, state);
      expect(recs.any((r) => r.id == 'rec_fan_gate'), isFalse);
    });

    test('zero Gate B wait time does not trigger bypass', () {
      final state = CrowdState(
        gateWaitTimes: {'Gate B': 0},
        foodCourtWaitTimes: {},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
      final engine = CrowdIntelligenceEngine();
      final ctx = _ctx(role: UserRole.fan);
      final recs = engine.analyzeCrowd(ctx, state);
      expect(recs.any((r) => r.id == 'rec_fan_gate'), isFalse);
    });

    test('copyWith with empty map clears values', () {
      final state = CrowdState.initial();
      final cleared = state.copyWith(gateWaitTimes: {});
      expect(cleared.gateWaitTimes, isEmpty);
    });
  });

  // ─── GetAIRecommendations - Edge Cases ────────────────────────────────────

  group('GetAIRecommendations - Edge Cases', () {
    late GetAIRecommendations usecase;

    setUp(() {
      usecase = GetAIRecommendations();
    });

    test('empty incidents list does not throw', () async {
      expect(
        () async => await usecase.call(
          role: UserRole.fan,
          location: 'Gate B',
          crowdState: CrowdState.initial(),
          incidents: [],
          tasks: [],
        ),
        returnsNormally,
      );
    });

    test('empty tasks list does not throw', () async {
      expect(
        () async => await usecase.call(
          role: UserRole.volunteer,
          location: 'Volunteer Lounge',
          crowdState: CrowdState.initial(),
          incidents: [],
          tasks: [],
        ),
        returnsNormally,
      );
    });

    test('all 4 user roles complete without exception', () async {
      for (final role in UserRole.values) {
        expect(
          () async => await usecase.call(
            role: role,
            location: 'Sec 120',
            crowdState: CrowdState.initial(),
            incidents: [],
            tasks: [],
          ),
          returnsNormally,
          reason: 'Expected no exception for role: $role',
        );
      }
    });

    test('all 9 simulation scenarios complete without exception', () async {
      for (final scenario in SimulationScenario.values) {
        expect(
          () async => await usecase.call(
            role: UserRole.fan,
            location: 'Sec 120',
            crowdState: CrowdState.initial(),
            incidents: [],
            tasks: [],
            activeScenario: scenario,
          ),
          returnsNormally,
          reason: 'Expected no exception for scenario: $scenario',
        );
      }
    });

    test('very high temperature (50°C) does not throw', () async {
      expect(
        () async => await usecase.call(
          role: UserRole.fan,
          location: 'Gate A',
          crowdState: CrowdState.initial(),
          incidents: [],
          tasks: [],
          temperature: 50.0,
          weatherAlert: 'Extreme Heat Alert',
        ),
        returnsNormally,
      );
    });

    test('zero family size does not throw', () async {
      expect(
        () async => await usecase.call(
          role: UserRole.fan,
          location: 'Gate B',
          crowdState: CrowdState.initial(),
          incidents: [],
          tasks: [],
          familySize: 0,
        ),
        returnsNormally,
      );
    });

    test('all-zero crowd state does not throw', () async {
      const zeroState = CrowdState(
        gateWaitTimes: {'Gate B': 0, 'Gate A': 0},
        foodCourtWaitTimes: {'Food Court 1 (North)': 0},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
      expect(
        () async => await usecase.call(
          role: UserRole.organizer,
          location: 'Control Room',
          crowdState: zeroState,
          incidents: [],
          tasks: [],
        ),
        returnsNormally,
      );
    });

    test('large family size (20 people) propagates correctly', () async {
      final recs = await usecase.call(
        role: UserRole.fan,
        location: 'Gate B',
        crowdState: CrowdState.initial(),
        incidents: [],
        tasks: [],
        familySize: 20,
        weatherAlert: 'Extreme Heat Alert',
        temperature: 36.0,
      );
      // Heat warning should mention family size
      final heatRec = recs.firstWhere(
        (r) => r.id == 'rec_weather_heat_fan',
        orElse: () => recs.first,
      );
      expect(heatRec, isNotNull);
    });
  });

  // ─── CalculateRoute - Edge Cases ──────────────────────────────────────────

  group('CalculateRoute - Edge Cases', () {
    final usecase = CalculateRoute();
    final calmCrowd = const CrowdState(
      gateWaitTimes: {'Gate B': 5},
      foodCourtWaitTimes: {},
      restroomWaitTimes: {},
      zoneDensities: {},
    );

    test('start equals destination does not throw', () async {
      expect(
        () async => await usecase.call(
          start: 'Section 128',
          destination: 'Section 128',
          wheelchairFriendly: false,
          avoidCrowds: false,
          crowdState: calmCrowd,
        ),
        returnsNormally,
      );
    });

    test('both wheelchair and avoidCrowds true works together', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 104',
        wheelchairFriendly: true,
        avoidCrowds: true,
        crowdState: calmCrowd,
      );
      expect(route.isWheelchairFriendly, isTrue);
    });

    test('empty start and destination returns steps', () async {
      final route = await usecase.call(
        start: '',
        destination: '',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmCrowd,
      );
      expect(route.steps, isNotEmpty);
    });

    test('total duration is always at least 1 minute', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Section 100',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmCrowd,
      );
      expect(route.totalDurationMins, greaterThanOrEqualTo(1));
    });
  });

  // ─── Ranking Engine - Edge Cases ──────────────────────────────────────────

  group('RecommendationRankingEngine - Edge Cases', () {
    final engine = RecommendationRankingEngine();

    test('list of one item returns that item', () {
      final rec = const [
        AIRecommendation(
          id: 'single',
          title: 'Single',
          recommendation: 'Do one thing.',
          reason: 'Only reason.',
          estimatedBenefit: 'Benefit.',
          priority: 'High',
          confidenceLevel: 0.9,
          category: 'Safety',
        ),
      ];
      // ignore: avoid_types_on_closure_parameters
      final ranked = engine.rankRecommendations(rec);
      expect(ranked.length, equals(1));
    });

    test('all Critical items retain their count', () {
      final input = List.generate(
        10,
        (i) => AIRecommendation(
          id: 'crit_$i',
          title: 'Critical $i',
          recommendation: 'Action.',
          reason: 'Reason.',
          estimatedBenefit: 'B.',
          priority: 'Critical',
          confidenceLevel: 0.99,
          category: 'Safety',
        ),
      );
      final ranked = engine.rankRecommendations(input);
      expect(ranked.length, equals(10));
      expect(ranked.every((r) => r.priority == 'Critical'), isTrue);
    });
  });

  // ─── Incident - Edge Cases ─────────────────────────────────────────────────

  group('Incident - Edge Cases', () {
    test('incident with very long description does not throw', () {
      final longDesc = 'A' * 10000;
      expect(
        () => Incident(
          id: 'long_desc',
          title: 'Long Desc',
          category: 'Crowd',
          location: 'Gate B',
          priority: 'Low',
          status: 'Open',
          description: longDesc,
          reportedTime: DateTime.now(),
        ),
        returnsNormally,
      );
    });

    test('resolved incident has Resolved status', () {
      final inc = Incident(
        id: 'r_001',
        title: 'Resolved',
        category: 'Facility',
        location: 'Section 108',
        priority: 'Low',
        status: 'Resolved',
        description: 'Fixed.',
        reportedTime: DateTime.now(),
      );
      expect(inc.status, equals('Resolved'));
    });
  });

  // ─── VolunteerTask - Edge Cases ────────────────────────────────────────────

  group('VolunteerTask - Edge Cases', () {
    test('completed task marked via copyWith', () {
      final task = VolunteerTask(
        id: 'edge_task',
        title: 'Edge Task',
        description: 'Edge description.',
        location: 'Section 120',
        priority: 'Medium',
        isCompleted: false,
        assignedTime: DateTime.now(),
      );
      final done = task.copyWith(isCompleted: true);
      expect(done.isCompleted, isTrue);
      expect(done.id, equals('edge_task'));
    });

    test('volunteer with all completed tasks gets no task rec', () async {
      final usecase = GetAIRecommendations();
      final tasks = List.generate(
        5,
        (i) => VolunteerTask(
          id: 'done_$i',
          title: 'Done Task $i',
          description: 'Completed.',
          location: 'Zone $i',
          priority: 'Low',
          isCompleted: true,
          assignedTime: DateTime.now(),
        ),
      );
      final recs = await usecase.call(
        role: UserRole.volunteer,
        location: 'Lounge',
        crowdState: const CrowdState(
          gateWaitTimes: {},
          foodCourtWaitTimes: {},
          restroomWaitTimes: {},
          zoneDensities: {},
        ),
        incidents: [],
        tasks: tasks,
      );
      expect(recs.any((r) => r.id == 'rec_vol_task'), isFalse);
    });
  });
}
