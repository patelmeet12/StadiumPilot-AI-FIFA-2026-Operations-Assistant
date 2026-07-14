// ============================================================
// Navigation Logic Tests: CalculateRoute use case
// Tests routing decisions: wheelchair, crowd bypass, direct
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/usecases/calculate_route.dart';

void main() {
  late CrowdState congestedState;
  late CrowdState calmState;
  late CalculateRoute usecase;

  setUp(() {
    usecase = CalculateRoute();
    congestedState = CrowdState.initial(); // Gate B = 25 mins
    calmState = const CrowdState(
      gateWaitTimes: {'Gate B': 5, 'Gate A': 3, 'Gate C': 4, 'Gate D': 2},
      foodCourtWaitTimes: {'Food Court 1 (North)': 5},
      restroomWaitTimes: {},
      zoneDensities: {},
    );
  });

  // ─── Direct Route ──────────────────────────────────────────────────────────

  group('Direct Route (no flags)', () {
    test('returns Fastest Direct Route title', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.title, equals('Fastest Direct Route'));
      expect(route.isWheelchairFriendly, isFalse);
    });

    test('direct route at Gate B during congestion shows High congestion', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: congestedState,
      );
      expect(route.crowdCongestionLevel, equals('High'));
      expect(route.totalDurationMins, greaterThanOrEqualTo(22));
    });

    test('direct route from Gate A at calm state shows shorter duration', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.totalDurationMins, lessThan(22));
    });

    test('steps contain destination location name', () async {
      final route = await usecase.call(
        start: 'Gate C',
        destination: 'Section 104',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.steps.last, contains('Section 104'));
    });
  });

  // ─── Wheelchair Route ──────────────────────────────────────────────────────

  group('Wheelchair-Friendly Route', () {
    test('returns Accessible Route title', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.title, equals('Accessible Route'));
      expect(route.isWheelchairFriendly, isTrue);
    });

    test('accessible route includes elevator step', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.steps.any((s) => s.toLowerCase().contains('elevator')), isTrue);
    });

    test('accessibility features list is populated', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Section 104',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.accessibilityFeatures, isNotEmpty);
      expect(route.accessibilityFeatures, contains('Elevator West Access'));
    });

    test('wheelchair + avoidCrowds + Gate B congestion redirects to Gate D', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: true,
        crowdState: congestedState,
      );
      expect(route.steps.any((s) => s.contains('Gate D')), isTrue);
      expect(route.crowdCongestionLevel, equals('Low'));
    });

    test('wheelchair route reasoning mentions step-free pathway', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Section 120',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.reasoning.toLowerCase(), contains('step-free'));
    });
  });

  // ─── Crowd Avoid Route ─────────────────────────────────────────────────────

  group('Least Crowded Route (avoidCrowds=true)', () {
    test('returns Least Crowded Route title', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: true,
        crowdState: calmState,
      );
      expect(route.title, equals('Least Crowded Route'));
    });

    test('avoids Gate B and reroutes to Gate D when Gate B is congested', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: true,
        crowdState: congestedState,
      );
      expect(route.steps.any((s) => s.contains('Gate D')), isTrue);
      expect(route.crowdCongestionLevel, equals('Low'));
    });

    test('reroutes away from congested Food Court 1', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Food Court 1',
        wheelchairFriendly: false,
        avoidCrowds: true,
        crowdState: congestedState,
      );
      expect(route.steps.any((s) => s.contains('Food Court 2')), isTrue);
    });

    test('crowd redirect adds distance but reduces duration vs congested direct', () async {
      final crowdRoute = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: true,
        crowdState: congestedState,
      );
      final directRoute = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: congestedState,
      );
      expect(crowdRoute.totalDurationMins, lessThan(directRoute.totalDurationMins));
    });

    test('no reroute if Gate B is not congested', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: true,
        crowdState: calmState,
      );
      // Should not redirect since Gate B wait is only 5 mins
      expect(route.steps.any((s) => s.contains('Gate D')), isFalse);
    });
  });

  // ─── Edge Cases ────────────────────────────────────────────────────────────

  group('Navigation Edge Cases', () {
    test('steps list is never empty', () async {
      final route = await usecase.call(
        start: 'Gate A',
        destination: 'Section 120',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.steps, isNotEmpty);
    });

    test('total distance is always positive', () async {
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: congestedState,
      );
      expect(route.totalDistanceMeters, greaterThan(0));
    });

    test('handles whitespace in start/destination gracefully', () async {
      final route = await usecase.call(
        start: '  Gate B  ',
        destination: '  Section 128  ',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: calmState,
      );
      expect(route.steps, isNotEmpty);
    });
  });
}
