// ============================================================
// Unit Tests: Domain Entities
// Tests data model construction, copyWith, computed properties
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/domain/entities/ai_recommendation.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/entities/incident.dart';
import 'package:stadium_pilot_ai/domain/entities/match_detail.dart';
import 'package:stadium_pilot_ai/domain/entities/operational_risk.dart';
import 'package:stadium_pilot_ai/domain/entities/route_plan.dart';
import 'package:stadium_pilot_ai/domain/entities/simulation_scenario.dart';
import 'package:stadium_pilot_ai/domain/entities/transport_plan.dart';
import 'package:stadium_pilot_ai/domain/entities/user_role.dart';
import 'package:stadium_pilot_ai/domain/entities/volunteer_deployment.dart';
import 'package:stadium_pilot_ai/domain/entities/volunteer_task.dart';

void main() {
  // ─── CrowdState ────────────────────────────────────────────────────────────

  group('CrowdState entity', () {
    test('initial() returns expected gate wait times', () {
      final state = CrowdState.initial();
      expect(state.gateWaitTimes['Gate B'], equals(25));
      expect(state.gateWaitTimes['Gate D'], equals(5));
      expect(state.foodCourtWaitTimes['Food Court 1 (North)'], equals(20));
      expect(state.foodCourtWaitTimes['Food Court 2 (South)'], equals(6));
    });

    test('copyWith overrides only specified fields', () {
      final original = CrowdState.initial();
      final copy = original.copyWith(
        gateWaitTimes: {'Gate B': 10},
      );
      expect(copy.gateWaitTimes['Gate B'], equals(10));
      // Other fields remain from original
      expect(
        copy.foodCourtWaitTimes['Food Court 1 (North)'],
        equals(original.foodCourtWaitTimes['Food Court 1 (North)']),
      );
    });

    test('zone densities are between 0.0 and 1.0', () {
      final state = CrowdState.initial();
      for (final density in state.zoneDensities.values) {
        expect(density, greaterThanOrEqualTo(0.0));
        expect(density, lessThanOrEqualTo(1.0));
      }
    });

    test('returns low-congestion state correctly', () {
      final calm = CrowdState(
        gateWaitTimes: {'Gate A': 2, 'Gate B': 3},
        foodCourtWaitTimes: {'Food Court 1 (North)': 2},
        restroomWaitTimes: {'Restrooms Level 1 East': 1},
        zoneDensities: {'North Entry Plaza': 0.1},
      );
      expect(calm.gateWaitTimes['Gate B'], equals(3));
    });
  });

  // ─── AIRecommendation ──────────────────────────────────────────────────────

  group('AIRecommendation entity', () {
    const rec = AIRecommendation(
      id: 'test_rec_001',
      title: 'Test Title',
      recommendation: 'Go left.',
      reason: 'Because left is faster.',
      estimatedBenefit: 'Saves time.',
      priority: 'High',
      confidenceLevel: 0.95,
      category: 'Navigation',
      alternativeOptions: ['Go right', 'Wait'],
      estimatedTimeSavedMinutes: 10,
      estimatedWalkingDistanceSavedMeters: 100,
      estimatedCo2ReductionKg: 0.5,
      operationalImpact: 'Reduces queue.',
    );

    test('all fields are set correctly', () {
      expect(rec.id, equals('test_rec_001'));
      expect(rec.confidenceLevel, equals(0.95));
      expect(rec.priority, equals('High'));
      expect(rec.estimatedTimeSavedMinutes, equals(10));
      expect(rec.estimatedCo2ReductionKg, equals(0.5));
      expect(rec.alternativeOptions.length, equals(2));
    });

    test('defaults for optional fields are set', () {
      const minimal = AIRecommendation(
        id: 'min',
        title: 'Min',
        recommendation: 'Do this.',
        reason: 'Reason.',
        estimatedBenefit: 'Benefit.',
        priority: 'Low',
        confidenceLevel: 0.5,
        category: 'Safety',
      );
      expect(minimal.estimatedTimeSavedMinutes, equals(0));
      expect(minimal.estimatedCo2ReductionKg, equals(0.0));
      expect(minimal.alternativeOptions, isEmpty);
      expect(minimal.operationalImpact, equals('No system-level friction.'));
    });
  });

  // ─── Incident ──────────────────────────────────────────────────────────────

  group('Incident entity', () {
    final incident = Incident(
      id: 'inc_001',
      title: 'Spill on Level 2',
      category: 'Facility',
      location: 'Section 110',
      priority: 'Medium',
      status: 'Open',
      description: 'Water spill near concession stand.',
      reportedTime: DateTime(2026, 7, 14, 18, 30),
    );

    test('fields are correctly assigned', () {
      expect(incident.id, equals('inc_001'));
      expect(incident.status, equals('Open'));
      expect(incident.priority, equals('Medium'));
    });

    test('copyWith updates status correctly', () {
      final resolved = incident.copyWith(status: 'Resolved');
      expect(resolved.status, equals('Resolved'));
      expect(resolved.id, equals(incident.id));
    });

    test('copyWith without args returns equivalent object', () {
      final copy = incident.copyWith();
      expect(copy.title, equals(incident.title));
      expect(copy.location, equals(incident.location));
    });
  });

  // ─── MatchDetail & MatchPreset ─────────────────────────────────────────────

  group('MatchDetail entity', () {
    final match = MatchDetail(
      homeTeam: 'Argentina',
      awayTeam: 'France',
      matchTime: DateTime(2026, 7, 14, 19, 0),
      stadiumName: 'MetLife Stadium',
      ticketClass: 'Category 1',
      section: '120',
      row: 'G',
      seat: '14',
      gate: 'Gate B',
      recommendedArrivalTime: DateTime(2026, 7, 14, 17, 0),
    );

    test('computed matchLabel returns correct string', () {
      expect(match.matchLabel, equals('Argentina vs France'));
    });

    test('computed seatLabel formats correctly', () {
      expect(match.seatLabel, equals('Sec 120, Row G, Seat 14'));
    });

    test('defaults for optional telemetry fields', () {
      expect(match.weatherAlert, equals('None'));
      expect(match.temperature, equals(26.0));
      expect(match.attendanceProjection, equals(82500));
    });
  });

  group('MatchPreset static presets', () {
    test('contains exactly 4 presets', () {
      expect(MatchPreset.presets.length, equals(4));
    });

    test('USA vs England preset has lightning warning', () {
      final usaEngland = MatchPreset.presets.firstWhere(
        (p) => p.matchId == 'match_usa_england',
      );
      expect(usaEngland.weatherAlert, equals('Heavy Lightning Warning'));
      expect(usaEngland.temperature, equals(18.0));
    });

    test('Mexico vs Canada preset has heat alert', () {
      final mexicoCanada = MatchPreset.presets.firstWhere(
        (p) => p.matchId == 'match_mexico_canada',
      );
      expect(mexicoCanada.weatherAlert, equals('Extreme Heat Alert'));
      expect(mexicoCanada.temperature, equals(36.0));
    });

    test('all presets have non-empty matchId', () {
      for (final preset in MatchPreset.presets) {
        expect(preset.matchId, isNotEmpty);
      }
    });

    test('railUsageRate is between 0.0 and 1.0 for all presets', () {
      for (final preset in MatchPreset.presets) {
        expect(preset.railUsageRate, greaterThan(0.0));
        expect(preset.railUsageRate, lessThanOrEqualTo(1.0));
      }
    });
  });

  // ─── OperationalRisk ───────────────────────────────────────────────────────

  group('OperationalRisk entity', () {
    const risk = OperationalRisk(
      id: 'risk_001',
      title: 'Gate B Overload',
      riskCategory: 'Gate',
      probability: 0.88,
      timeline: 'Next 15 Mins',
      description: 'Gate B projected to hit critical queue threshold.',
      preventiveAction: 'Redirect to Gate D.',
      expectedImpact: 'Reduces wait time by 7 mins.',
    );

    test('all fields correctly set', () {
      expect(risk.id, equals('risk_001'));
      expect(risk.probability, equals(0.88));
      expect(risk.riskCategory, equals('Gate'));
    });

    test('probability is in valid range', () {
      expect(risk.probability, greaterThanOrEqualTo(0.0));
      expect(risk.probability, lessThanOrEqualTo(1.0));
    });
  });

  // ─── VolunteerDeployment ───────────────────────────────────────────────────

  group('VolunteerDeployment entity', () {
    test('initial() returns correct default counts', () {
      final dep = VolunteerDeployment.initial();
      expect(dep.plazaActive, equals(14));
      expect(dep.medicalActive, equals(8));
    });

    test('totalActive sums all active zones', () {
      final dep = VolunteerDeployment.initial();
      expect(
        dep.totalActive,
        equals(dep.plazaActive + dep.concourseActive + dep.medicalActive + dep.securityActive),
      );
    });

    test('totalVolunteers equals active plus break', () {
      final dep = VolunteerDeployment.initial();
      expect(dep.totalVolunteers, equals(dep.totalActive + dep.totalBreak));
    });

    test('copyWith updates single field correctly', () {
      final dep = VolunteerDeployment.initial();
      final updated = dep.copyWith(plazaActive: 20);
      expect(updated.plazaActive, equals(20));
      expect(updated.medicalActive, equals(dep.medicalActive));
    });
  });

  // ─── VolunteerTask ─────────────────────────────────────────────────────────

  group('VolunteerTask entity', () {
    final task = VolunteerTask(
      id: 'task_001',
      title: 'Gate B Queue Management',
      description: 'Assist fans at Gate B queue.',
      location: 'Gate B outer plaza',
      priority: 'High',
      isCompleted: false,
      assignedTime: DateTime(2026, 7, 14, 16, 0),
    );

    test('fields are correctly set', () {
      expect(task.id, equals('task_001'));
      expect(task.isCompleted, isFalse);
      expect(task.priority, equals('High'));
    });

    test('copyWith marks task as completed', () {
      final done = task.copyWith(isCompleted: true);
      expect(done.isCompleted, isTrue);
      expect(done.id, equals(task.id));
    });
  });

  // ─── TransportPlan ─────────────────────────────────────────────────────────

  group('TransportPlan entity', () {
    const plan = TransportPlan(
      modeName: 'FIFA Metro Line 2',
      iconType: 'train',
      durationMins: 22,
      estimatedCost: 2.50,
      crowdLevel: 'Medium',
      co2EmissionsKg: 0.15,
      co2SavedKg: 3.20,
      ecoScore: 95,
      isRecommended: true,
      recommendationReason: 'Fastest eco choice.',
      sustainabilityTip: 'Reduces emissions by 95%.',
    );

    test('eco score is within valid range', () {
      expect(plan.ecoScore, greaterThanOrEqualTo(0));
      expect(plan.ecoScore, lessThanOrEqualTo(100));
    });

    test('co2SavedKg is greater than co2EmissionsKg for eco options', () {
      expect(plan.co2SavedKg, greaterThan(plan.co2EmissionsKg));
    });

    test('isRecommended is true', () {
      expect(plan.isRecommended, isTrue);
    });
  });

  // ─── SimulationScenario ────────────────────────────────────────────────────

  group('SimulationScenario enum', () {
    test('all 9 scenario values exist', () {
      expect(SimulationScenario.values.length, equals(9));
    });

    test('none scenario exists', () {
      expect(SimulationScenario.values, contains(SimulationScenario.none));
    });

    test('heavyRain scenario exists', () {
      expect(SimulationScenario.values, contains(SimulationScenario.heavyRain));
    });

    test('powerFailure scenario exists', () {
      expect(SimulationScenario.values, contains(SimulationScenario.powerFailure));
    });
  });

  // ─── UserRole ──────────────────────────────────────────────────────────────

  group('UserRole enum', () {
    test('4 roles exist', () {
      expect(UserRole.values.length, equals(4));
    });

    test('all expected roles present', () {
      expect(UserRole.values, containsAll([
        UserRole.fan,
        UserRole.volunteer,
        UserRole.organizer,
        UserRole.staff,
      ]));
    });
  });

  // ─── RoutePlan ─────────────────────────────────────────────────────────────

  group('RoutePlan entity', () {
    const route = RoutePlan(
      title: 'Accessible Route',
      totalDurationMins: 9,
      totalDistanceMeters: 280,
      steps: ['Step 1', 'Step 2'],
      isWheelchairFriendly: true,
      crowdCongestionLevel: 'Low',
      reasoning: 'Elevator route selected.',
      accessibilityFeatures: ['Elevator West', 'Ramps'],
    );

    test('fields are correctly set', () {
      expect(route.title, equals('Accessible Route'));
      expect(route.isWheelchairFriendly, isTrue);
      expect(route.steps.length, equals(2));
      expect(route.accessibilityFeatures.length, equals(2));
    });

    test('duration and distance are positive', () {
      expect(route.totalDurationMins, greaterThan(0));
      expect(route.totalDistanceMeters, greaterThan(0));
    });
  });
}
