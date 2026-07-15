import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stadium_pilot_ai/presentation/widgets/accessible_focus_builder.dart';

void main() {
  group('AccessibleFocusBuilder - Basic Behavior', () {
    testWidgets('renders child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusBuilder(
              child: const Text('Test Child Text'),
            ),
          ),
        ),
      );

      expect(find.text('Test Child Text'), findsOneWidget);
    });

    testWidgets('applies semantic properties correctly', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusBuilder(
              semanticLabel: 'Semantic Button Label',
              semanticValue: 'Activated state',
              child: const Text('Semantic Text'),
            ),
          ),
        ),
      );

      // Check if semantics exists matching the label and value
      expect(
        tester.getSemantics(find.byType(AccessibleFocusBuilder)),
        matchesSemantics(
          label: 'Semantic Button Label',
          value: 'Activated state',
          isFocusable: true,
          textDirection: TextDirection.ltr,
        ),
      );

      handle.dispose();
    });

    testWidgets('triggers onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusBuilder(
              onTap: () {
                tapped = true;
              },
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onTap callback when Enter key is pressed', (WidgetTester tester) async {
      bool tapped = false;
      final FocusNode focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusBuilder(
              focusNode: focusNode,
              onTap: () {
                tapped = true;
              },
              child: const Text('Focus Me'),
            ),
          ),
        ),
      );

      // Request focus
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Trigger Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      focusNode.dispose();
    });

    testWidgets('triggers onTap callback when Space key is pressed', (WidgetTester tester) async {
      bool tapped = false;
      final FocusNode focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusBuilder(
              focusNode: focusNode,
              onTap: () {
                tapped = true;
              },
              child: const Text('Focus Me 2'),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      // Trigger Space key
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      focusNode.dispose();
    });
  });

  group('AccessibleFocusBuilder - Focus Outline UI', () {
    testWidgets('draws border when focused', (WidgetTester tester) async {
      final FocusNode focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleFocusBuilder(
              focusNode: focusNode,
              child: const SizedBox(width: 50, height: 50, child: Text('Focus Box')),
            ),
          ),
        ),
      );

      // Verify no border initially
      Container container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AccessibleFocusBuilder),
          matching: find.byType(Container),
        ),
      );
      BoxDecoration? decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNull);

      // Focus the widget
      focusNode.requestFocus();
      await tester.pump();

      // Verify border is drawn now
      container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AccessibleFocusBuilder),
          matching: find.byType(Container),
        ),
      );
      decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isNotNull);

      focusNode.dispose();
    });
  });
}
