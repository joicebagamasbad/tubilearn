import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../legal_screen.dart';

/// Shared state for the two tappable "Terms of Use" / "Privacy Policy"
/// links used by [TermsAgreementRow] and [TermsNotice]. The recognizers
/// are owned by the State and disposed with it.
mixin _LegalLinks<T extends StatefulWidget> on State<T> {
  late final TapGestureRecognizer _termsTap =
      TapGestureRecognizer()..onTap = () => _open(LegalDocument.terms);

  late final TapGestureRecognizer _privacyTap =
      TapGestureRecognizer()..onTap = () => _open(LegalDocument.privacy);

  void _open(LegalDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => LegalScreen(document: document),
      ),
    );
  }

  TextSpan linkSpan(String text, TapGestureRecognizer recognizer) {
    return TextSpan(
      text: text,
      recognizer: recognizer,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.underline,
      ),
    );
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }
}

class TermsAgreementRow extends StatefulWidget {
  const TermsAgreementRow({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  State<TermsAgreementRow> createState() => _TermsAgreementRowState();
}

class _TermsAgreementRowState extends State<TermsAgreementRow>
    with _LegalLinks<TermsAgreementRow> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: <Widget>[
          Checkbox(
            value: widget.value,
            onChanged: widget.enabled
                ? (bool? checked) => widget.onChanged(checked ?? false)
                : null,
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.secondary.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                children: <InlineSpan>[
                  const TextSpan(text: 'I agree to the '),
                  linkSpan('Terms of Use', _termsTap),
                  const TextSpan(text: ' and '),
                  linkSpan('Privacy Policy', _privacyTap),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TermsNotice extends StatefulWidget {
  const TermsNotice({super.key});

  @override
  State<TermsNotice> createState() => _TermsNoticeState();
}

class _TermsNoticeState extends State<TermsNotice>
    with _LegalLinks<TermsNotice> {
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Text.rich(
      TextSpan(
        style: AppTextStyles.caption.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        children: <InlineSpan>[
          const TextSpan(text: 'By continuing, you agree to our '),
          linkSpan('Terms of Use', _termsTap),
          const TextSpan(text: ' and '),
          linkSpan('Privacy Policy', _privacyTap),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
