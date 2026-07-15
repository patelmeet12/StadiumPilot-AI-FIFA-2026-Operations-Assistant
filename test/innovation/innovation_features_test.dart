import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stadium_pilot_ai/presentation/pages/command_center_page.dart';
import 'package:stadium_pilot_ai/presentation/providers/app_state_providers.dart';

void main() {
  group('StadiumPilot AI - Innovation Console Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Should render CommandCenterPage components', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sharedPreferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MaterialApp(
            home: CommandCenterPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify page titles render
      expect(find.text('FIFA AI COMMAND CENTER & DIGITAL TWIN'), findsOneWidget);
      expect(find.text('Active Digital Twin Layout Map'), findsOneWidget);
      expect(find.text('AI Event Replay Engine Scrubber'), findsOneWidget);
      expect(find.text('Energy Consumption & Weather Impacts'), findsOneWidget);
      expect(find.text('AI Incident Triage Console'), findsOneWidget);
      expect(find.text('AI Lost Child Assistant matching'), findsOneWidget);
    });

    testWidgets('Should trigger lost child search locator', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sharedPreferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MaterialApp(
            home: CommandCenterPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type child description
      final txtField = find.byType(TextField);
      expect(txtField, findsOneWidget);
      await tester.enterText(txtField, 'Red shirt, 8yo');

      // Click Search button
      final searchBtn = find.text('Initiate Smart Search');
      expect(searchBtn, findsOneWidget);
      await tester.tap(searchBtn);

      // Settle search delay
      await tester.pump(const Duration(milliseconds: 700));

      // Match found text should appear
      expect(find.textContaining('MATCH FOUND'), findsOneWidget);
    });

    testWidgets('Should update selected Digital Twin zone on tap', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sharedPreferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          ],
          child: const MaterialApp(
            home: CommandCenterPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on a zone tile
      final zoneTile = find.text('PLAZA EAST');
      expect(zoneTile, findsOneWidget);
      await tester.tap(zoneTile);
      await tester.pump();

      // Verify display updates
      expect(find.text('SELECTED NODE: PLAZA EAST'), findsOneWidget);
    });
  });
}
