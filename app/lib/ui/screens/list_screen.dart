import 'dart:async';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../app_icons.dart';
import '../../data/live_activities/live_activity_service.dart';
import '../../data/persistence/flight_repository.dart';
import '../../data/settings/map_style_setting.dart';
import '../../domain/flight.dart';
import '../../domain/trail_point.dart';
import '../../l10n/app_localizations.g.dart';
import '../map_selection.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/chrome/app_fab.dart';
import '../widgets/flight/flight_hero_cell.dart';
import '../widgets/flight/flight_row.dart';
import '../widgets/flight/live_activity_arm_row.dart';
import '../widgets/map/map_visuals.dart';
import 'flight_list.dart';
import 'list_empty_state.dart';
import 'list_sections.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({
    required this.flightRepository,
    required this.mapSelection,
    required this.mapStyleSetting,
    required this.tileSources,
    required this.liveActivityService,
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

  /// Tells the cells whether the device shows Live Activities at all.
  final LiveActivityService liveActivityService;

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
                liveActivityService: widget.liveActivityService,
                onFlightSelected: (flightId) => _openOnMap(context, flightId),
                onFlightDeleted: (flight) =>
                    unawaited(_deleteFlight(context, flight)),
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

  /// The row goes first and the delete follows only when the undo is gone, so
  /// a wrong swipe costs the flight nothing.
  Future<void> _deleteFlight(BuildContext context, Flight flight) async {
    final localizations = AppLocalizations.of(context);
    _flightList.holdDeletion(flight.id);
    final closedReason = await ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            content: Text(localizations.listFlightDeleted(flight.lookupValue)),
            duration: const Duration(seconds: 6),
            // A snackbar with an action persists by default, but here the
            // timeout is what commits the delete — it must keep running.
            persist: false,
            action: SnackBarAction(
              label: localizations.listUndoDelete,
              onPressed: () {},
            ),
          ),
        )
        .closed;
    if (closedReason == SnackBarClosedReason.action) {
      _flightList.releaseDeletion(flight.id);
      return;
    }
    await _flightList.commitDeletion(flight.id);
  }

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
    required this.liveActivityService,
    required this.onFlightSelected,
    required this.onFlightDeleted,
  });

  final FlightListSections sections;
  final DateTime today;
  final FlightRepository repository;
  final MapStyleSetting mapStyleSetting;
  final MapTileSources tileSources;
  final LiveActivityService liveActivityService;
  final ValueChanged<int> onFlightSelected;
  final ValueChanged<Flight> onFlightDeleted;

  /// A card the flight can no longer get makes the switch pointless, so the
  /// past section goes without one.
  FlightLiveActivityControl _liveActivityOf(Flight flight) => (
    availability: liveActivityService.availability,
    onArmed: (isArmed) =>
        unawaited(repository.setLiveActivityArmed(flight.id, isArmed: isArmed)),
  );

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
              _SwipeToDelete(
                key: ValueKey(entry.flight.id),
                flightId: entry.flight.id,
                onDeleted: () => onFlightDeleted(entry.flight),
                child: _HeroCell(
                  key: ValueKey(entry.flight.id),
                  entry: entry,
                  now: today,
                  repository: repository,
                  mapStyleSetting: mapStyleSetting,
                  tileSources: tileSources,
                  liveActivity: _liveActivityOf(entry.flight),
                  onTap: () => onFlightSelected(entry.flight.id),
                ),
              ),
            for (final entry in rows)
              _SwipeToDelete(
                key: ValueKey(entry.flight.id),
                flightId: entry.flight.id,
                onDeleted: () => onFlightDeleted(entry.flight),
                child: FlightRow(
                  flight: entry.flight,
                  state: entry.state,
                  now: today,
                  liveActivity: _liveActivityOf(entry.flight),
                ),
              ),
            if (sections.past.isNotEmpty) ...[
              const _PastSectionLabel(),
              for (final entry in sections.past)
                _SwipeToDelete(
                  key: ValueKey(entry.flight.id),
                  flightId: entry.flight.id,
                  onDeleted: () => onFlightDeleted(entry.flight),
                  child: FlightRow(
                    flight: entry.flight,
                    state: entry.state,
                    now: today,
                  ),
                ),
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

/// Swiping a flight to the left reveals the delete behind it and hands the row
/// over; nothing is asked, because the undo in the snackbar is the way back.
///
/// The row padding sits outside the `Dismissible`: its clipper measures the
/// full widget width, so padding inside would cut the panel off short of the
/// sliding card and expose the scaffold between the two.
///
/// The panel is stacked behind the whole `Dismissible` rather than handed to
/// its `background`, because that one is clipped to the strip the card has
/// already left — the card's rounded trailing corners would cut two notches of
/// scaffold into the seam. Painting the panel behind the card fills them, which
/// in turn needs an opaque card: the planned row is only a dashed outline.
class _SwipeToDelete extends StatefulWidget {
  const _SwipeToDelete({
    required this.flightId,
    required this.onDeleted,
    required this.child,
    super.key,
  });

  static const padding = EdgeInsets.fromLTRB(
    AppSpacing.screenPadding,
    0,
    AppSpacing.screenPadding,
    AppSpacing.cardPadding,
  );

  static const _iconSize = 18.0;

  final int flightId;
  final VoidCallback onDeleted;
  final Widget child;

  @override
  State<_SwipeToDelete> createState() => _SwipeToDeleteState();
}

class _SwipeToDeleteState extends State<_SwipeToDelete> {
  /// Keeps the panel out of the tree — and out of the semantics — while the row
  /// rests on top of it.
  var _swiping = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardShape = BorderRadius.circular(AppRadius.card);
    return Padding(
      padding: _SwipeToDelete.padding,
      child: Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Visibility(
              visible: _swiping,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.error,
                  borderRadius: cardShape,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.screenPaddingLarge,
                    ),
                    child: FaIcon(
                      AppIcons.trash,
                      size: _SwipeToDelete._iconSize,
                      color: theme.colorScheme.onError,
                      semanticLabel: AppLocalizations.of(
                        context,
                      ).listDeleteFlight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Dismissible(
            key: ValueKey(widget.flightId),
            direction: DismissDirection.endToStart,
            onUpdate: _handleUpdate,
            onDismissed: (_) => widget.onDeleted(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: cardShape,
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  void _handleUpdate(DismissUpdateDetails details) {
    final swiping = details.progress > 0;
    if (swiping != _swiping) {
      setState(() => _swiping = swiping);
    }
  }
}

/// Feeds the hero cell of one airborne flight with its stored trail.
class _HeroCell extends StatefulWidget {
  const _HeroCell({
    required this.entry,
    required this.now,
    required this.repository,
    required this.mapStyleSetting,
    required this.tileSources,
    required this.liveActivity,
    required this.onTap,
    super.key,
  });

  final FlightListEntry entry;
  final DateTime now;
  final FlightRepository repository;
  final MapStyleSetting mapStyleSetting;
  final MapTileSources tileSources;
  final FlightLiveActivityControl liveActivity;
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
  Widget build(BuildContext context) => SignalBuilder(
    builder: (context) => FlightHeroCell(
      flight: widget.entry.flight,
      state: widget.entry.state,
      trail: _trail.value,
      now: widget.now,
      onTap: widget.onTap,
      mapStyleSetting: widget.mapStyleSetting,
      tileSources: widget.tileSources,
      liveActivity: widget.liveActivity,
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
