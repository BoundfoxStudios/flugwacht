import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

import '../../data/flight_repository.dart';
import '../../data/map_style_setting.dart';
import '../../domain/trail_point.dart';
import '../../l10n/app_localizations.g.dart';
import '../map_selection.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_fab.dart';
import '../widgets/flight_hero_cell.dart';
import '../widgets/flight_row.dart';
import '../widgets/map_visuals.dart';
import 'flight_list.dart';
import 'list_empty_state.dart';
import 'list_sections.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    required this.flightRepository,
    required this.mapSelection,
    required this.mapStyleSetting,
    required this.tileSources,
    super.key,
    this.clock = DateTime.now,
  });

  final FlightRepository flightRepository;

  /// Written when a hero cell is tapped, so the map opens on that flight.
  final MapSelection mapSelection;

  /// Reads the current time; injectable so the minute ticker stays testable.
  final DateTime Function() clock;

  /// Handed to the hero cells.
  final MapStyleSetting mapStyleSetting;
  final MapTileSources tileSources;

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
            : _FlightSections(
                sections: sections,
                today: _flightList.now.value,
                repository: widget.flightRepository,
                mapStyleSetting: widget.mapStyleSetting,
                tileSources: widget.tileSources,
                onFlightSelected: (flightId) => _openOnMap(context, flightId),
              );
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

  void _openOnMap(BuildContext context, int flightId) {
    widget.mapSelection.flightId.value = flightId;
    context.go('/map');
  }
}

class _FlightSections extends StatelessWidget {
  const _FlightSections({
    required this.sections,
    required this.today,
    required this.repository,
    required this.mapStyleSetting,
    required this.tileSources,
    required this.onFlightSelected,
  });

  final FlightListSections sections;
  final DateTime today;
  final FlightRepository repository;
  final MapStyleSetting mapStyleSetting;
  final MapTileSources tileSources;
  final ValueChanged<int> onFlightSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final rows = [...sections.waiting, ...sections.planned];
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
            for (final entry in sections.active)
              _HeroCell(
                key: ValueKey(entry.flight.id),
                entry: entry,
                now: today,
                repository: repository,
                mapStyleSetting: mapStyleSetting,
                tileSources: tileSources,
                onTap: () => onFlightSelected(entry.flight.id),
              ),
            for (final entry in rows) _PaddedRow(entry: entry, now: today),
            if (sections.past.isNotEmpty) ...[
              const _PastSectionLabel(),
              for (final entry in sections.past)
                _PaddedRow(entry: entry, now: today),
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
  const _PaddedRow({required this.entry, required this.now});

  static const padding = EdgeInsets.fromLTRB(
    AppSpacing.screenPadding,
    0,
    AppSpacing.screenPadding,
    AppSpacing.cardPadding,
  );

  final FlightListEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: FlightRow(flight: entry.flight, state: entry.state, now: now),
  );
}

/// Feeds the hero cell of one airborne flight with its stored trail.
class _HeroCell extends StatefulWidget {
  const _HeroCell({
    required this.entry,
    required this.now,
    required this.repository,
    required this.mapStyleSetting,
    required this.tileSources,
    required this.onTap,
    super.key,
  });

  final FlightListEntry entry;
  final DateTime now;
  final FlightRepository repository;
  final MapStyleSetting mapStyleSetting;
  final MapTileSources tileSources;
  final VoidCallback onTap;

  @override
  State<_HeroCell> createState() => _HeroCellState();
}

class _HeroCellState extends State<_HeroCell> {
  final _trail = signal<List<TrailPoint>>(const []);
  late final StreamSubscription<List<TrailPoint>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.repository
        .watchTrail(widget.entry.flight.id)
        .listen((trail) => _trail.value = trail);
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _trail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: _PaddedRow.padding,
    child: SignalBuilder(
      builder: (context) => FlightHeroCell(
        flight: widget.entry.flight,
        state: widget.entry.state,
        trail: _trail.value,
        now: widget.now,
        onTap: widget.onTap,
        mapStyleSetting: widget.mapStyleSetting,
        tileSources: widget.tileSources,
      ),
    ),
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
