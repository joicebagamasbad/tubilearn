import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tubilearn_project/theme/app_theme.dart';
import 'package:tubilearn_project/view/onboarding_screen.dart';

void main() {
  const List<Size> viewports = <Size>[
    Size(360, 640),
    Size(320, 568),
  ];

  const List<double> textScales = <double>[1.0, 1.25];

  Widget buildApp({
    required double textScale,
    required VoidCallback onFinished,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
        ),
        child: OnboardingScreen(
          onFinished: onFinished,
        ),
      ),
    );
  }

  for (final Size viewport in viewports) {
    for (final double textScale in textScales) {
      final String label =
          '${viewport.width.toInt()}x${viewport.height.toInt()} '
          '@ textScale $textScale';

      testWidgets(
        'OnboardingScreen renders without exceptions at $label',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          // --- Page 1 renders title and NEXT button ---
          await tester.pumpWidget(
            buildApp(
              textScale: textScale,
              onFinished: () {},
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Welcome to TubiLearn'), findsOneWidget);
          expect(find.text('NEXT'), findsOneWidget);

          // --- Tap NEXT twice -> GET STARTED shown, Skip gone ---
          await tester.tap(find.text('NEXT'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('NEXT'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          expect(find.text('GET STARTED'), findsOneWidget);
          expect(find.text('Skip'), findsNothing);

          // --- Tapping Skip on page 1 calls onFinished ---
          // Force a full unmount first: pumping a new OnboardingScreen in
          // the same tree position would otherwise be treated as an
          // update, preserving the previous (page 3) State instead of
          // starting fresh on page 1.
          await tester.pumpWidget(const SizedBox.shrink());

          bool finished = false;

          await tester.pumpWidget(
            buildApp(
              textScale: textScale,
              onFinished: () {
                finished = true;
              },
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          expect(finished, isTrue);
        },
      );
    }
  }
}
