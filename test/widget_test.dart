import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadium_pilot_ai/domain/entities/user_role.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/entities/incident.dart';
import 'package:stadium_pilot_ai/domain/usecases/calculate_route.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_transport_options.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_ai_recommendations.dart';
import 'package:stadium_pilot_ai/presentation/pages/role_selection_page.dart';
import 'package:stadium_pilot_ai/presentation/providers/app_state_providers.dart';

void main() {
  group('StadiumPilot AI - Navigation Engine Tests', () {
    final crowdState = CrowdState.initial();

    test('Should return standard fastest route when no options are toggled', () async {
      final usecase = CalculateRoute();
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: false,
        crowdState: crowdState,
      );

      expect(route.title, contains('Fastest Direct Route'));
      expect(route.isWheelchairFriendly, isFalse);
      expect(route.steps, anyElement(contains('escalator')));
      expect(route.steps, anyElement(contains('Gate B')));
    });

    test('Should return step-free route when wheelchairFriendly is active', () async {
      final usecase = CalculateRoute();
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: true,
        avoidCrowds: false,
        crowdState: crowdState,
      );

      expect(route.isWheelchairFriendly, isTrue);
      expect(route.accessibilityFeatures, contains('Elevator West Access'));
      expect(route.steps, anyElement(contains('elevator')));
    });

    test('Should reroute to Gate D when Gate B is congested and avoidCrowds is active', () async {
      final congestedState = CrowdState(
        gateWaitTimes: {'Gate A': 5, 'Gate B': 25, 'Gate C': 10, 'Gate D': 5},
        foodCourtWaitTimes: {},
        restroomWaitTimes: {},
        zoneDensities: {},
      );
      final usecase = CalculateRoute();
      final route = await usecase.call(
        start: 'Gate B',
        destination: 'Section 128',
        wheelchairFriendly: false,
        avoidCrowds: true,
        crowdState: congestedState,
      );

      expect(route.steps, anyElement(contains('Gate D')));
      expect(route.steps, anyElement(contains('CROWD REDIRECT')));
      expect(route.reasoning, contains('Gate B is experiencing heavy congestion'));
    });
  });

  group('StadiumPilot AI - Transportation & Sustainability Tests', () {
    test('Should compute multiple transit modes and recommend Metro by default', () async {
      final usecase = GetTransportOptions();
      final options = await usecase.call(
        origin: 'Downtown Penn Station',
        destination: 'MetLife Stadium Plaza',
        preferredMode: 'metro',
      );

      expect(options.length, equals(4));
      
      final metro = options.firstWhere((o) => o.modeName.contains('Metro'));
      expect(metro.isRecommended, isTrue);
      expect(metro.ecoScore, greaterThanOrEqualTo(90));
      expect(metro.co2SavedKg, greaterThan(3.0));
    });

    test('Should compute high cost and emissions for ride-share taxis', () async {
      final usecase = GetTransportOptions();
      final options = await usecase.call(
        origin: 'Downtown Penn Station',
        destination: 'MetLife Stadium Plaza',
        preferredMode: 'taxi',
      );

      final taxi = options.firstWhere((o) => o.modeName.contains('Taxi'));
      expect(taxi.isRecommended, isTrue); // since preferred mode is taxi
      expect(taxi.ecoScore, lessThan(30));
      expect(taxi.estimatedCost, greaterThan(25.0));
    });
  });

  group('StadiumPilot AI - Decision Engine Tests', () {
    final crowdStateCongested = CrowdState(
      gateWaitTimes: {'Gate A': 5, 'Gate B': 25, 'Gate C': 10, 'Gate D': 5},
      foodCourtWaitTimes: {'Food Court 1 (North)': 20, 'Food Court 2 (South)': 6},
      restroomWaitTimes: {},
      zoneDensities: {},
    );

    final openIncident = Incident(
      id: 'inc_test_1',
      title: 'Water leak',
      category: 'Facility',
      location: 'Section 120 Lobby',
      priority: 'High',
      status: 'Open',
      description: 'Water leaking from pipe',
      reportedTime: DateTime.now(),
    );

    test('Should generate gate bypass and dining options for FAN role during congestion', () async {
      final engine = GetAIRecommendations();
      final recs = await engine.call(
        role: UserRole.fan,
        location: 'Section 128',
        crowdState: crowdStateCongested,
        incidents: [],
        tasks: [],
      );

      final gateBypass = recs.any((r) => r.id == 'rec_fan_gate');
      final diningAssist = recs.any((r) => r.id == 'rec_fan_food');
      
      expect(gateBypass, isTrue);
      expect(diningAssist, isTrue);
    });

    test('Should alert volunteer about active open incidents', () async {
      final engine = GetAIRecommendations();
      final recs = await engine.call(
        role: UserRole.volunteer,
        location: 'Volunteer Lounge',
        crowdState: crowdStateCongested,
        incidents: [openIncident],
        tasks: [],
      );

      final incidentAssist = recs.firstWhere((r) => r.id == 'rec_vol_incident');
      expect(incidentAssist.priority, equals('High'));
      expect(incidentAssist.recommendation, contains('Section 120 Lobby'));
    });

    test('Should alert organizers with capacity management action triggers', () async {
      final engine = GetAIRecommendations();
      final recs = await engine.call(
        role: UserRole.organizer,
        location: 'Control Room',
        crowdState: crowdStateCongested,
        incidents: [],
        tasks: [],
      );

      final capacityTrigger = recs.firstWhere((r) => r.id == 'rec_org_gate_trigger');
      expect(capacityTrigger.priority, equals('Critical'));
      expect(capacityTrigger.recommendation, contains('Trigger public display redirect'));
    });
  });

  group('StadiumPilot AI - Widget Tests', () {
    testWidgets('Should render RoleSelectionPage and show role choices', (WidgetTester tester) async {
      // Set responsive window constraints to prevent layout overflow in headless test
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MaterialApp(
            home: RoleSelectionPage(),
          ),
        ),
      );

      // Verify that title and elements are displayed
      expect(find.text('StadiumPilot AI'), findsOneWidget);
      expect(find.text('Select Your Role'), findsOneWidget);
      expect(find.text('Fan / Ticket Holder'), findsOneWidget);
      expect(find.text('Volunteer Staff'), findsOneWidget);
    });
  });
}
