import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tubilearn_project/theme/app_theme.dart';
import 'package:tubilearn_project/view/profile_setup_screen.dart';

void main() {
  const List<Size> viewports = <Size>[
    Size(360, 640),
    Size(320, 568),
  ];

  const List<double> textScales = <double>[1.0, 1.25];

  Widget buildApp({
    required double textScale,
    required VoidCallback onDone,
    required Future<(int, int)> Function() skillCountsLoader,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
        ),
        child: ProfileSetupScreen(
          onDone: onDone,
          skillCountsLoader: skillCountsLoader,
        ),
      ),
    );
  }

  Future<(int, int)> zeroCountsLoader() async => (0, 0);

  Future<(int, int)> oneEachCountsLoader() async => (1, 1);

  for (final Size viewport in viewports) {
    for (final double textScale in textScales) {
      final String label =
          '${viewport.width.toInt()}x${viewport.height.toInt()} '
          '@ textScale $textScale';

      testWidgets(
        'ProfileSetupScreen wizard renders without exceptions at $label',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          // --- Step 1 renders title and progress text ---
          await tester.pumpWidget(
            buildApp(
              textScale: textScale,
              onDone: () {},
              skillCountsLoader: zeroCountsLoader,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Set up your profile'), findsOneWidget);
          expect(find.text('Step 1 of 4'), findsOneWidget);

          // --- Skip x3 -> Done step; (0, 0) counts -> no FIND MY MATCH ---
          await tester.ensureVisible(find.text('Skip'));
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Skip'));
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Skip'));
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          expect(find.text("You're all set!"), findsOneWidget);
          expect(find.text('GO TO DASHBOARD'), findsOneWidget);
          expect(find.text('FIND MY MATCH'), findsNothing);

          // --- Fresh instance with (1, 1) counts -> FIND MY MATCH shown ---
          // Force a full unmount first: pumping a new ProfileSetupScreen
          // in the same tree position would otherwise be treated as an
          // update, preserving the previous (Done step) State instead of
          // starting fresh on step 1.
          await tester.pumpWidget(const SizedBox.shrink());

          bool finished = false;

          await tester.pumpWidget(
            buildApp(
              textScale: textScale,
              onDone: () {
                finished = true;
              },
              skillCountsLoader: oneEachCountsLoader,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Skip'));
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Skip'));
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.ensureVisible(find.text('Skip'));
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          expect(find.text("You're all set!"), findsOneWidget);
          expect(find.text('FIND MY MATCH'), findsOneWidget);
          expect(find.text('GO TO DASHBOARD'), findsOneWidget);

          // --- Tapping GO TO DASHBOARD calls onDone ---
          // Scroll it into view first: at some viewport/text-scale
          // combinations the Done step's content overflows the
          // SingleChildScrollView's initial scroll offset.
          await tester.ensureVisible(find.text('GO TO DASHBOARD'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('GO TO DASHBOARD'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          expect(finished, isTrue);
        },
      );
    }
  }
}
