import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/flight_repository.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_fab.dart';
import '../widgets/flight_row.dart';
import 'flight_list.dart';
import 'list_sections.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    required this.flightRepository,
    super.key,
    this.clock = DateTime.now,
  });

  final FlightRepository flightRepository;

  /// Reads the current time; injectable so the minute ticker stays testable.
  final DateTime Function() clock;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late final _flightList = FlightList(
    repository: widget.flightRepository,
    clock: widget.clock,
  );

  @override
  void dispose() {
    _flightList.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SignalBuilder(
      builder: (context) {
        final sections = _flightList.sections.value;
        return sections == null || sections.isEmpty
            ? const SizedBox.shrink()
            : _FlightSections(sections: sections, today: _flightList.now.value);
      },
    ),
    floatingActionButton: SignalBuilder(
      builder: (context) => _flightList.sections.value == null
          ? const SizedBox.shrink()
          : AppFab(onPressed: () => context.push('/new-flight')),
    ),
  );
}

class _FlightSections extends StatelessWidget {
  const _FlightSections({required this.sections, required this.today});

  final FlightListSections sections;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final upcoming = [
      ...sections.active,
      ...sections.waiting,
      ...sections.planned,
    ];
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: AppFab.size + AppSpacing.screenPadding * 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ListHeader(
              title: localizations.listTitle,
              date: DateFormat(
                localizations.listHeaderDateFormat,
                Localizations.localeOf(context).toLanguageTag(),
              ).format(today),
            ),
            for (final entry in upcoming) _PaddedRow(entry: entry),
            if (sections.past.isNotEmpty) ...[
              const _PastSectionLabel(),
              for (final entry in sections.past) _PaddedRow(entry: entry),
            ],
          ],
        ),
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.title, required this.date});

  final String title;
  final String date;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingLarge,
        AppSpacing.screenPaddingLarge,
        AppSpacing.screenPaddingLarge,
        AppSpacing.grid * 2.5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: textTheme.headlineLarge)),
          Text(date, style: textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PaddedRow extends StatelessWidget {
  const _PaddedRow({required this.entry});

  final FlightListEntry entry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      0,
      AppSpacing.screenPadding,
      AppSpacing.cardPadding,
    ),
    child: FlightRow(flight: entry.flight, state: entry.state),
  );
}

class _PastSectionLabel extends StatelessWidget {
  const _PastSectionLabel();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.grid,
      AppSpacing.screenPadding,
      AppSpacing.grid * 2,
    ),
    child: Text(
      AppLocalizations.of(context).listPastSectionTitle,
      style: AppTextStyles.sectionLabelLarge.copyWith(
        color: Theme.of(context).textTheme.labelSmall?.color,
      ),
    ),
  );
}
