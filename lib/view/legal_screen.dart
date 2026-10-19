import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'legal_content.dart';

enum LegalDocument { terms, privacy }

class LegalScreen extends StatelessWidget {
  const LegalScreen({
    super.key,
    required this.document,
  });

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final bool isTerms = document == LegalDocument.terms;
    final List<LegalSection> sections =
        isTerms ? kTermsSections : kPrivacySections;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTerms ? 'Terms of Use' : 'Privacy Policy'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'Last updated: $kLegalLastUpdated',
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < sections.length; i++) ...<Widget>[
              Text(
                '${i + 1}. ${sections[i].heading}',
                style: AppTextStyles.cardTitle.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sections[i].body,
                style: AppTextStyles.body.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
