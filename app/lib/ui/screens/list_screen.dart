import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/flight_repository.dart';
import '../../domain/flight.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_fab.dart';
import 'flight_list.dart';
import 'list_empty_state.dart';
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
        if (sections == null) {
          return const SizedBox.shrink();
        }
        return sections.isEmpty
            ? ListEmptyState(onAddFlight: () => _openNewFlight(context))
            : _FlightSections(sections: sections, today: _flightList.now.value);
      },
    ),
    floatingActionButton: SignalBuilder(
      builder: (context) {
        final sections = _flightList.sections.value;
        return sections == null || sections.isEmpty
            ? const SizedBox.shrink()
            : AppFab(onPressed: () => _openNewFlight(context));
      },
    ),
  );

  void _openNewFlight(BuildContext context) => context.push('/new-flight');
}

class _FlightSections extends StatelessWidget {
  const _FlightSections({required this.sections, required this.today});

  final FlightListSections sections;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final entries = [
      ...sections.active,
      ...sections.waiting,
      ...sections.planned,
      ...sections.past,
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
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.cardPadding,
                ),
                child: _FlightRow(flight: entry.flight),
              ),
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

/// Placeholder row until the designed cells arrive; shows the title line only.
class _FlightRow extends StatelessWidget {
  const _FlightRow({required this.flight});

  final Flight flight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = flight.note;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPaddingLarge,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        note == null ? flight.lookupValue : '${flight.lookupValue} · $note',
        style: theme.textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
