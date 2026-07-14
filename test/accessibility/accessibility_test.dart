// ============================================================
// Accessibility Tests
// Tests accessibility routing, engine outputs, WCAG compliance
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/entities/simulation_scenario.dart';
import 'package:stadium_pilot_ai/domain/entities/user_role.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/accessibility_engine.dart';
import 'package:stadium_pilot_ai/domain/services/ai_decision_engine/context_engine.dart';
import 'package:stadium_pilot_ai/domain/usecases/calculate_route.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_ai_recommendations.dart';

DecisiveContext _ctx({
  UserRole role = UserRole.fan,
  bool accessibility = false,
  int familySize = 1,
}) =>
    ContextEngine().buildContext(
      role: role,
      location: 'Gate B',
      weatherAlert: 'None',
      temperature: 26.0,
      currentTime: DateTime(2026, 7, 14, 18, 0),
      accessibilityRequired: accessibility,
      familySize: familySize,
      matchPhase: 'Pre-Match',
      activeScenario: SimulationScenario.none,
    );

void main() {
  // ─── AccessibilityEngine ──────────────────────────────────────────────────

  group('AccessibilityEngine - Elevator Routing', () {
    final engine = AccessibilityEngine();

    test('elevator tip is generated for all roles', () {
      for (final role in UserRole.values) {
        final ctx = _ctx(role: role, accessibility: false);
        final recs = engine.analyzeAccessibility(ctx);
        expect(recs.any((r) => r.id == 'rec_access_elevator'), isTrue,
            reason: 'Expected elevator rec for role: $role');
      }
    });

    test('elevator rec has non-empty reason', () {
      final recs = AccessibilityEngine().analyzeAccessibility(_ctx());
      final rec = recs.firstWhere((r) => r.id == 'rec_access_elevator');
      expect(rec.reason, isNotEmpty);
    });

    test('elevator rec confidence level >= 0.8', () {
      final recs = AccessibilityEngine().analyzeAccessibility(_ctx());
      final rec = recs.firstWhere((r) => r.id == 'rec_access_elevator');
      expect(rec.confidenceLevel, greaterThanOrEqualTo(0.8));
    });

    test('elevator rec has alternative options', () {
      final recs = AccessibilityEngine().analyzeAccessibility(_ctx());
      final rec = recs.firstWhere((r) => r.id == 'rec_access_elevator');
      expect(rec.alternativeOptions, isNotEmpty);
    });
  });

  group('AccessibilityEngine - Wheelchair Routing', () {
    final engine = AccessibilityEngine();

    test('wheelchair routing rec generated when accessibility = true', () {
      final ctx = _ctx(accessibility: true);
      final recs = engine.analyzeAccessibility(ctx);
      expect(recs.any((r) => r.id == 'rec_access_routing'), isTrue);
    });

    test('wheelchair routing rec NOT generated when accessibility = false', () {
      final ctx = _ctx(accessibility: false);
      final recs = engine.analyzeAccessibility(ctx);
      expect(recs.any((r) => r.id == 'rec_access_routing'), isFalse);
    });

    test('wheelchair rec mentions ramp or wheelchair', () {
      final ctx = _ctx(accessibility: true);
      final recs = engine.analyzeAccessibility(ctx);
      final rec = recs.firstWhere((r) => r.id == 'rec_access_routing');
      final text = rec.recommendation.toLowerCase();
      expect(text.contains('wheelchair') || text.contains('ramp') || text.contains('gate a'), isTrue);
    });

    test('wheelchair routing has priority High or above', () {
      final ctx = _ctx(accessibility: true);
      final recs = engine.analyzeAccessibility(ctx);
      final rec = recs.firstWhere((r) => r.id == 'rec_access_routing');
      final validPriorities = ['High', 'Critical'];
      expect(validPriorities, contains(rec.priority));
    });
  });

  // ─── CalculateRoute - Wheelchair Logic ───────────────────────────────────

  group('CalculateRoute - Wheelchair Mode', () {
    late CalculateRoute usecase;
    late CrowdState calmState;
    late CrowdState congestedState;

    setUp(() {
      usecase = CalculateRoute();
      calmState = const CrowdState(
        gateWaitTimes: {'Gate B': 5, 'Gate D': 2},
        foodCourtWaitTimes: {},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
      congestedState = const CrowdState(
        gateWaitTimes: {'Gate B': 25, 'Gate D': 3},
        foodCourtWaitTimes: {},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
    });

    test('wheelchair route is marked isWheelchairFriendly', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.isWheelchairFriendly, isTrue);
    });

    test('wheelchair route has accessibility features', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.accessibilityFeatures, isNotEmpty);
      expect(route.accessibilityFeatures, contains('Elevator West Access'));
      expect(route.accessibilityFeatures, contains('Ramped Accessways'));
    });

    test('wheelchair route includes elevator in steps', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: calmState,
      );
      final hasElevator = route.steps.any((s) => s.toLowerCase().contains('elevator'));
      expect(hasElevator, isTrue);
    });

    test('wheelchair + avoidCrowds + congested Gate B uses Gate D route', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: true,
        crowdState: congestedState,
      );
      final usesGateD = route.steps.any((s) => s.contains('Gate D'));
      expect(usesGateD, isTrue);
      expect(route.crowdCongestionLevel, equals('Low'));
    });

    test('non-wheelchair route does NOT include elevator west access', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.accessibilityFeatures, isEmpty);
    });
  });

  // ─── GetAIRecommendations - Accessibility Flags ───────────────────────────

  group('GetAIRecommendations - Accessibility Integration', () {
    late GetAIRecommendations usecase;

    setUp(() {
      usecase = GetAIRecommendations();
    });

    test('accessibility required produces wheelchair rec in output', () async {
      final recs = await usecase.call(
        role: UserRole.fan,
        location: 'Gate B',
        crowdState: CrowdState.initial(),
        incidents: [],
        tasks: [],
        accessibilityRequired: true,
      );
      expect(recs.any((r) => r.id == 'rec_access_routing'), isTrue);
    });

    test('accessibility NOT required = no wheelchair rec', () async {
      final recs = await usecase.call(
        role: UserRole.fan,
        location: 'Gate B',
        crowdState: const CrowdState(
          gateWaitTimes: {'Gate B': 5},
          foodCourtWaitTimes: {},
          restroomWaitTimes: {},
          zoneDensities: {},
        ),
        incidents: [],
        tasks: [],
        accessibilityRequired: false,
      );
      expect(recs.any((r) => r.id == 'rec_access_routing'), isFalse);
    });

    test('elevator rec always present regardless of accessibility flag', () async {
      for (final flag in [true, false]) {
        final recs = await usecase.call(
          role: UserRole.fan,
          location: 'Gate B',
          crowdState: const CrowdState(
            gateWaitTimes: {},
            foodCourtWaitTimes: {},
            restroomWaitTimes: {},
            zoneDensities: {},
          ),
          incidents: [],
          tasks: [],
          accessibilityRequired: flag,
        );
        expect(recs.any((r) => r.id == 'rec_access_elevator'), isTrue,
            reason: 'Expected elevator rec with accessibilityRequired=$flag');
      }
    });

    test('wheelchair rec has walking distance saved > 0', () async {
      final recs = await usecase.call(
        role: UserRole.fan,
        location: 'Gate B',
        crowdState: CrowdState.initial(),
        incidents: [],
        tasks: [],
        accessibilityRequired: true,
      );
      final rec = recs.firstWhere((r) => r.id == 'rec_access_routing');
      // Saves walking distance by using direct accessible lane
      expect(rec.estimatedWalkingDistanceSavedMeters, isNot(equals(0)));
    });
  });
}
