import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadium_pilot_ai/domain/entities/user_role.dart';
import 'package:stadium_pilot_ai/domain/entities/crowd_state.dart';
import 'package:stadium_pilot_ai/domain/entities/incident.dart';
import 'package:stadium_pilot_ai/domain/entities/volunteer_deployment.dart';
import 'package:stadium_pilot_ai/domain/entities/simulation_scenario.dart';
import 'package:stadium_pilot_ai/domain/usecases/calculate_route.dart';
import 'package:stadium_pilot_ai/presentation/providers/stadium_simulation_providers.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_transport_options.dart';
import 'package:stadium_pilot_ai/domain/usecases/get_ai_recommendations.dart';
import 'package:stadium_pilot_ai/presentation/pages/role_selection_page.dart';
import 'package:stadium_pilot_ai/presentation/pages/dashboard_page.dart';
import 'package:stadium_pilot_ai/presentation/pages/navigation_page.dart';
import 'package:stadium_pilot_ai/presentation/pages/transport_page.dart';
import 'package:stadium_pilot_ai/presentation/pages/accessibility_page.dart';
import 'package:stadium_pilot_ai/presentation/pages/volunteer_dashboard_page.dart';
import 'package:stadium_pilot_ai/presentation/pages/organizer_dashboard_page.dart';
import 'package:stadium_pilot_ai/presentation/providers/app_state_providers.dart';
import 'package:stadium_pilot_ai/core/services/secure_storage_service.dart';
import 'package:stadium_pilot_ai/data/repositories/stadium_repository_impl.dart';

class MockActiveScenarioNotifier extends ActiveScenarioNotifier {
  final SimulationScenario mockScenario;
  MockActiveScenarioNotifier(this.mockScenario);

  @override
  SimulationScenario build() => mockScenario;
}

class MockUserRoleNotifier extends UserRoleNotifier {
  final UserRole mockRole;
  MockUserRoleNotifier(this.mockRole);

  @override
  UserRole build() => mockRole;
}

class MockIncidentListNotifier extends IncidentListNotifier {
  final List<Incident> mockIncidents;
  MockIncidentListNotifier(this.mockIncidents);

  @override
  List<Incident> build() => mockIncidents;
}

class MockCrowdStateNotifier extends CrowdStateNotifier {
  final CrowdState mockState;
  MockCrowdStateNotifier(this.mockState);

  @override
  CrowdState build() => mockState;
}

class MockSelectedMatchNotifier extends SelectedMatchNotifier {
  final String mockMatchId;
  MockSelectedMatchNotifier(this.mockMatchId);

  @override
  String build() => mockMatchId;
}

void main() {
  group('StadiumPilot AI - Navigation Engine Tests', () {
    final crowdState = CrowdState.initial();

    test(
      'Should return standard fastest route when no options are toggled',
      () async {
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
      },
    );

    test(
      'Should return step-free route when wheelchairFriendly is active',
      () async {
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
      },
    );

    test(
      'Should reroute to Gate D when Gate B is congested and avoidCrowds is active',
      () async {
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
        expect(
          route.reasoning,
          contains('Gate B is experiencing heavy congestion'),
        );
      },
    );
  });

  group('StadiumPilot AI - Transportation & Sustainability Tests', () {
    test(
      'Should compute multiple transit modes and recommend Metro by default',
      () async {
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
      },
    );

    test(
      'Should compute high cost and emissions for ride-share taxis',
      () async {
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
      },
    );
  });

  group('StadiumPilot AI - Decision Engine Tests', () {
    final crowdStateCongested = CrowdState(
      gateWaitTimes: {'Gate A': 5, 'Gate B': 25, 'Gate C': 10, 'Gate D': 5},
      foodCourtWaitTimes: {
        'Food Court 1 (North)': 20,
        'Food Court 2 (South)': 6,
      },
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

    test(
      'Should generate gate bypass and dining options for FAN role during congestion',
      () async {
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
      },
    );

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

    test(
      'Should alert organizers with capacity management action triggers',
      () async {
        final engine = GetAIRecommendations();
        final recs = await engine.call(
          role: UserRole.organizer,
          location: 'Control Room',
          crowdState: crowdStateCongested,
          incidents: [],
          tasks: [],
        );

        final capacityTrigger = recs.firstWhere(
          (r) => r.id == 'rec_org_gate_trigger',
        );
        expect(capacityTrigger.priority, equals('Critical'));
        expect(
          capacityTrigger.recommendation,
          contains('Trigger public display redirect'),
        );
      },
    );
  });

  group('StadiumPilot AI - Widget Tests', () {
    testWidgets('Should render RoleSelectionPage and show role choices', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: RoleSelectionPage()),
        ),
      );

      // Verify that title and elements are displayed
      expect(find.text('StadiumPilot AI'), findsOneWidget);
      expect(find.text('Select Your Role'), findsOneWidget);
      expect(find.text('Fan / Ticket Holder'), findsOneWidget);
      expect(find.text('Volunteer Staff'), findsOneWidget);
    });
  });

  group('StadiumPilot AI - Secure Storage & Repository Tests', () {
    test(
      'SecureStorageService should encrypt, decrypt, and delete values',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final secureStorage = SecureStorageService(prefs);

        // Write value
        await secureStorage.write('test_key', 'my_secret_data');

        // Verify it is encrypted in raw prefs
        final rawVal = prefs.getString('sec_test_key');
        expect(rawVal, isNotNull);
        expect(rawVal, isNot(equals('my_secret_data')));

        // Read value and verify decryption
        final readVal = secureStorage.read('test_key');
        expect(readVal, equals('my_secret_data'));

        // Delete value
        await secureStorage.delete('test_key');
        expect(secureStorage.read('test_key'), isNull);
      },
    );

    test(
      'StadiumRepositoryImpl should fetch, update, and reset telemetry simulation',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repository = StadiumRepositoryImpl(prefs);

        // Verify initial loading of static stadium match details
        final match = await repository.getMatchDetails();
        expect(match.stadiumName, contains('MetLife'));
        expect(match.homeTeam, equals('Argentina'));

        // Verify custom incidents operations
        final incidents = await repository.getIncidents();
        expect(incidents, isNotEmpty);
        final initialLength = incidents.length;

        // Add a reported incident
        final testIncident = Incident(
          id: 'test_inc_123',
          title: 'Water leak',
          category: 'Facility',
          location: 'Section 102 Lobby',
          priority: 'Medium',
          status: 'Open',
          description: 'Water leak near restroom entrance',
          reportedTime: DateTime.now(),
        );
        await repository.reportIncident(testIncident);

        final updatedIncidents = await repository.getIncidents();
        expect(updatedIncidents.length, equals(initialLength + 1));
        expect(updatedIncidents.any((i) => i.id == 'test_inc_123'), isTrue);

        // Update incident status
        final updatedInc = testIncident.copyWith(status: 'Resolved');
        await repository.updateIncident(updatedInc);
        final resolvedIncidents = await repository.getIncidents();
        final matchingInc = resolvedIncidents.firstWhere(
          (i) => i.id == 'test_inc_123',
        );
        expect(matchingInc.status, equals('Resolved'));

        // Reset simulator and verify it reverts to default
        await repository.resetSimulator();
        final resetIncidents = await repository.getIncidents();
        expect(resetIncidents.length, equals(initialLength));
        expect(resetIncidents.any((i) => i.id == 'test_inc_123'), isFalse);
      },
    );
  });

  group('StadiumPilot AI - Page Rendering Widget Tests', () {
    testWidgets('Should render DashboardPage and check panels', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: DashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Operations Desk'), findsWidgets);
      expect(find.text('Local Travel Status'), findsOneWidget);
      expect(find.text('Accessibility Operations'), findsOneWidget);
    });

    testWidgets('Should render NavigationPage and check components', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: NavigationPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('AI Navigation Assistant'), findsOneWidget);
    });

    testWidgets('Should render TransportPage and check transit modes', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: TransportPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(
        find.text('Transportation & Sustainability Advisor'),
        findsOneWidget,
      );
    });

    testWidgets('Should render AccessibilityPage and check options', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: AccessibilityPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Accessibility Companion'), findsOneWidget);
    });

    testWidgets('Should render VolunteerDashboardPage and check checklists', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Volunteer Operations Desk'), findsOneWidget);
      expect(find.text('My Assigned Task Checklist'), findsOneWidget);
    });

    testWidgets('Should render OrganizerDashboardPage and check panels', (
      WidgetTester tester,
    ) async {
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
          child: const MaterialApp(home: OrganizerDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Tournament Organizer Console'), findsOneWidget);
      expect(find.text('Stadium Flow Heatmap'), findsOneWidget);
      expect(find.text('Volunteer Deployment & Availability'), findsOneWidget);
      expect(find.text('Stadium Transit & Commute Overview'), findsOneWidget);
      expect(find.text('FIFA 2026 Fixture Command Panel'), findsOneWidget);
      expect(
        find.text('AI Operational KPIs & Impact Analytics'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Should render VolunteerDashboardPage check-in simulator and badge',
      (WidgetTester tester) async {
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
            child: const MaterialApp(home: VolunteerDashboardPage()),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('ACTIVE VOLUNTEER ASSIGNMENT ZONE'), findsOneWidget);
        expect(find.text('Shift Duty: CHECK-IN REQUIRED'), findsOneWidget);
        expect(find.text('Scan Check-In QR Code'), findsOneWidget);
      },
    );
  });

  group('StadiumPilot AI - Enhanced Safety & Weather Telemetry Tests', () {
    final crowdState = CrowdState.initial();

    test(
      'Should generate severe weather warnings for lightning conditions',
      () async {
        final engine = GetAIRecommendations();
        final fanRecs = await engine.call(
          role: UserRole.fan,
          location: 'Sec 120',
          crowdState: crowdState,
          incidents: [],
          tasks: [],
          weatherAlert: 'Heavy Lightning Warning',
        );

        final weatherAlert = fanRecs.firstWhere(
          (r) => r.id == 'rec_weather_lightning_fan',
        );
        expect(weatherAlert.priority, equals('Critical'));
        expect(weatherAlert.category, equals('Safety'));
        expect(weatherAlert.recommendation, contains('covered concourses'));

        final volRecs = await engine.call(
          role: UserRole.volunteer,
          location: 'Gate plaza',
          crowdState: crowdState,
          incidents: [],
          tasks: [],
          weatherAlert: 'Heavy Lightning Warning',
        );
        final volAlert = volRecs.firstWhere(
          (r) => r.id == 'rec_weather_lightning_vol',
        );
        expect(
          volAlert.recommendation,
          contains('direct fans to covered entry hubs'),
        );
      },
    );

    test(
      'Should translate non-English Spanish/French incident reports in decision engine',
      () async {
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

        final engine = GetAIRecommendations();
        final recs = await engine.call(
          role: UserRole.organizer,
          location: 'Control room',
          crowdState: crowdState,
          incidents: [spanishIncident],
          tasks: [],
        );

        final translation = recs.firstWhere(
          (r) => r.id == 'rec_translate_inc_sp_1',
        );
        expect(
          translation.recommendation,
          contains('Wheelchair accessibility ramp obstruction'),
        );
        expect(
          translation.reason,
          contains('Reported description was submitted in non-English format'),
        );
      },
    );

    test(
      'Should generate staff reallocation recommendations when plaza staff is low during gate congestion',
      () async {
        final congestedState = CrowdState(
          gateWaitTimes: {'Gate A': 5, 'Gate B': 25, 'Gate C': 5, 'Gate D': 5},
          foodCourtWaitTimes: {},
          restroomWaitTimes: {},
          zoneDensities: {},
        );

        final lowPlazaDeployment = VolunteerDeployment(
          plazaActive: 6,
          plazaBreak: 2,
          concourseActive: 10,
          concourseBreak: 0,
          medicalActive: 8,
          medicalBreak: 1,
          securityActive: 6,
          securityBreak: 0,
        );

        final engine = GetAIRecommendations();
        final recs = await engine.call(
          role: UserRole.organizer,
          location: 'Control Room',
          crowdState: congestedState,
          incidents: [],
          tasks: [],
          deployment: lowPlazaDeployment,
        );

        final reallocateRec = recs.firstWhere(
          (r) => r.id == 'rec_org_reallocate_plaza',
        );
        expect(reallocateRec.priority, equals('High'));
        expect(
          reallocateRec.recommendation,
          contains('Reallocate 4 volunteers from Concourse Concessions'),
        );
      },
    );
  });

  group('StadiumPilot AI - Predictive Risk Engine Tests', () {
    test(
      'Should generate predictive risks matching gate and weather presets',
      () async {
        final container = ProviderContainer(
          overrides: [
            crowdStateProvider.overrideWith(
              () => MockCrowdStateNotifier(
                const CrowdState(
                  zoneDensities: {'Gate B': 0.8},
                  gateWaitTimes: {'Gate B': 25},
                  foodCourtWaitTimes: {'Food Court 1 (North)': 10},
                  restroomWaitTimes: {},
                ),
              ),
            ),
            selectedMatchProvider.overrideWith(
              () => MockSelectedMatchNotifier('match_usa_england'),
            ), // Has lightning
          ],
        );

        final risks = await container.read(riskPredictionsProvider.future);

        // Verify gate congestion risk
        final gateRisk = risks.firstWhere((r) => r.id == 'risk_gate_b');
        expect(gateRisk.probability, equals(0.88));
        expect(
          gateRisk.preventiveAction,
          contains('reroute incoming fans to Gate D'),
        );

        // Verify weather lightning risk
        final weatherRisk = risks.firstWhere(
          (r) => r.id == 'risk_weather_lightning',
        );
        expect(weatherRisk.probability, equals(0.95));
        expect(weatherRisk.riskCategory, equals('Weather'));
      },
    );
  });

  group('StadiumPilot AI - Active Scenario Simulation Tests', () {
    test(
      'Should generate scenario-specific recommendations for Heavy Rain and Power Failure',
      () async {
        final engine = GetAIRecommendations();

        final rainRecs = await engine.call(
          role: UserRole.volunteer,
          location: 'Concourse Lobby',
          crowdState: CrowdState.initial(),
          incidents: [],
          tasks: [],
          activeScenario: SimulationScenario.heavyRain,
        );

        final rainRec = rainRecs.firstWhere(
          (r) => r.id == 'scenario_heavy_rain',
        );
        expect(rainRec.title, contains('Heavy Rain'));
        expect(rainRec.recommendation, contains('ponchos'));

        final powerRecs = await engine.call(
          role: UserRole.fan,
          location: 'Section 104',
          crowdState: CrowdState.initial(),
          incidents: [],
          tasks: [],
          activeScenario: SimulationScenario.powerFailure,
        );

        final powerRec = powerRecs.firstWhere(
          (r) => r.id == 'scenario_power_failure',
        );
        expect(powerRec.priority, equals('Critical'));
        expect(powerRec.recommendation, contains('Elevators are offline'));
      },
    );
  });

  group('StadiumPilot AI - Proactive Alerts Engine Tests', () {
    test(
      'Should generate proactive notifications when delay and surge occur',
      () async {
        final container = ProviderContainer(
          overrides: [
            userRoleProvider.overrideWith(
              () => MockUserRoleNotifier(UserRole.fan),
            ),
            selectedMatchProvider.overrideWith(
              () => MockSelectedMatchNotifier('match_usa_england'),
            ),
            incidentListProvider.overrideWith(
              () => MockIncidentListNotifier([]),
            ),
            crowdStateProvider.overrideWith(
              () => MockCrowdStateNotifier(
                const CrowdState(
                  zoneDensities: {'Gate B': 0.8},
                  gateWaitTimes: {'Gate B': 25},
                  foodCourtWaitTimes: {'Food Court 1 (North)': 20},
                  restroomWaitTimes: {'Restrooms Level 1 East': 15},
                ),
              ),
            ),
            activeScenarioProvider.overrideWith(
              () =>
                  MockActiveScenarioNotifier(SimulationScenario.transportDelay),
            ),
          ],
        );

        final alerts = await container.read(proactiveAlertsProvider.future);

        // Verify Metro delay alert is proactive
        final metroAlert = alerts.firstWhere((a) => a.id == 'metro_delayed');
        expect(metroAlert.title, contains('Transit Delay Alert'));
        expect(metroAlert.color, equals(Colors.orange));

        // Verify Restroom alert is proactive
        final restroomAlert = alerts.firstWhere(
          (a) => a.id == 'restroom_queue',
        );
        expect(
          restroomAlert.description,
          contains('Level 1 East restroom queue has increased'),
        );
      },
    );
  });
}
