import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tubilearn_project/theme/app_theme.dart';
import 'package:tubilearn_project/view/legal_content.dart';
import 'package:tubilearn_project/view/legal_screen.dart';
import 'package:tubilearn_project/view/widgets/terms_agreement.dart';

void main() {
  const List<Size> viewports = <Size>[
    Size(360, 640),
    Size(320, 568),
  ];

  const List<double> textScales = <double>[1.0, 1.25];

  Widget wrap(Widget child, {double textScale = 1.0}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    );
  }

  test('legal content has the expected section counts', () {
    expect(kTermsSections.length, 11);
    expect(kPrivacySections.length, 9);
  });

  for (final Size viewport in viewports) {
    for (final double textScale in textScales) {
      final String label =
          '${viewport.width.toInt()}x${viewport.height.toInt()} '
          '@ textScale $textScale';

      for (final LegalDocument document in LegalDocument.values) {
        testWidgets('LegalScreen ${document.name} renders at $label',
            (WidgetTester tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;

          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            wrap(LegalScreen(document: document), textScale: textScale),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(find.textContaining('Last updated'), findsOneWidget);
          expect(
            find.text(
              document == LegalDocument.terms
                  ? 'Terms of Use'
                  : 'Privacy Policy',
            ),
            findsOneWidget,
          );

          if (document == LegalDocument.privacy) {
            await tester.scrollUntilVisible(
              find.text('4. AI Match'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('4. AI Match'), findsOneWidget);
          }
        });
      }
    }
  }

  testWidgets('TermsAgreementRow toggles onChanged and shows both links',
      (WidgetTester tester) async {
    bool value = false;

    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return TermsAgreementRow(
                value: value,
                onChanged: (bool v) => setState(() => value = v),
              );
            },
          ),
        ),
      ),
    );

    expect(find.textContaining('Terms of Use', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('Privacy Policy', findRichText: true),
        findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(value, isTrue);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(value, isFalse);
  });

  testWidgets('TermsNotice shows both link names',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(const Scaffold(body: TermsNotice())),
    );

    expect(find.textContaining('Terms of Use', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('Privacy Policy', findRichText: true),
        findsOneWidget);
    expect(find.textContaining('By continuing', findRichText: true),
        findsOneWidget);
  });
}
