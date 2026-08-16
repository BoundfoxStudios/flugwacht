import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../app_icons.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_tokens.dart';
import '../widgets/chrome/settings_card.dart';

/// The questions live ADS-B data provokes, answered once instead of in
/// footnotes all over the app.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const _sectionGap = 14.0;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(localizations.faqTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.grid * 2,
          AppSpacing.screenPadding,
          AppSpacing.screenPaddingLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: _sectionGap,
          children: [
            for (final entry in _entriesOf(localizations))
              _FaqCard(question: entry.question, answer: entry.answer),
          ],
        ),
      ),
    );
  }

  List<({String question, String answer})> _entriesOf(
    AppLocalizations localizations,
  ) => [
    (
      question: localizations.faqOtherServicesQuestion,
      answer: localizations.faqOtherServicesAnswer,
    ),
    (
      question: localizations.faqArrivalAccuracyQuestion,
      answer: localizations.faqArrivalAccuracyAnswer,
    ),
    (
      question: localizations.faqTrailStartQuestion,
      answer: localizations.faqTrailStartAnswer,
    ),
    (
      question: localizations.faqFlightNotFoundQuestion,
      answer: localizations.faqFlightNotFoundAnswer,
    ),
    (
      question: localizations.faqTrailGapsQuestion,
      answer: localizations.faqTrailGapsAnswer,
    ),
    (
      question: localizations.faqFlightsDisappearQuestion,
      answer: localizations.faqFlightsDisappearAnswer,
    ),
    (
      question: localizations.faqLateNotificationQuestion,
      answer: localizations.faqLateNotificationAnswer,
    ),
    (
      question: localizations.faqDataOriginQuestion,
      answer: localizations.faqDataOriginAnswer,
    ),
    (
      question: localizations.faqAccountQuestion,
      answer: localizations.faqAccountAnswer,
    ),
  ];
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.question, required this.answer});

  static const _chevronSize = 14.0;

  final String question;
  final String answer;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SettingsCard(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      children: [
        Row(
          spacing: AppSpacing.cardPadding,
          children: [
            Expanded(
              child: Text(widget.question, style: theme.textTheme.bodyLarge),
            ),
            FaIcon(
              _isExpanded ? AppIcons.chevronUp : AppIcons.chevronDown,
              size: _FaqCard._chevronSize,
              color: theme.textTheme.bodySmall?.color,
            ),
          ],
        ),
        if (_isExpanded)
          Text(
            widget.answer,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
      ],
    );
  }
}
