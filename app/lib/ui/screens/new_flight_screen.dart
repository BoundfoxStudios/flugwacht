import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';

import '../../app_icons.dart';
import '../../data/live_activities/live_activity_service.dart';
import '../../data/lookup/airline_directory.dart';
import '../../data/lookup/route_lookup.dart';
import '../../data/notifications/notification_service.dart';
import '../../data/persistence/flight_repository.dart';
import '../../data/settings/live_activity_setting.dart';
import '../../data/settings/notification_setting.dart';
import '../../domain/calendar_date.dart';
import '../../domain/day_time.dart';
import '../../domain/flight.dart';
import '../../domain/flight_number.dart';
import '../../domain/lookup_input.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/chrome/notification_offer_dialog.dart';
import '../widgets/controls/app_primary_button.dart';
import '../widgets/controls/app_segmented_control.dart';
import '../widgets/controls/app_switch_row.dart';
import '../widgets/controls/departure_date_picker.dart';
import '../widgets/controls/departure_time_picker.dart';
import '../widgets/flight/flight_labels.dart';
import '../widgets/flight/live_activity_arm_row.dart';
import 'new_flight_form.dart';
import 'new_flight_preview.dart';
import 'new_flight_preview_card.dart';

const _defaultDepartureTime = DayTime(12, 0);

class NewFlightScreen extends StatefulWidget {
  const NewFlightScreen({
    required this.flightRepository,
    required this.airlineDirectory,
    required this.routeLookup,
    required this.notificationService,
    required this.notificationSetting,
    required this.liveActivityService,
    required this.liveActivitySetting,
    super.key,
    this.today,
  });

  final FlightRepository flightRepository;
  final AirlineDirectory airlineDirectory;
  final RouteLookup routeLookup;
  final NotificationService notificationService;
  final NotificationSetting notificationSetting;
  final LiveActivityService liveActivityService;
  final LiveActivitySetting liveActivitySetting;

  /// The day the selectable date range is built around; defaults to the
  /// current day.
  final DateTime? today;

  @override
  State<NewFlightScreen> createState() => _NewFlightScreenState();
}

class _NewFlightScreenState extends State<NewFlightScreen> {
  late final _form = NewFlightForm(
    today: widget.today ?? DateTime.now(),
    armsLiveActivity: widget.liveActivitySetting.armsNewFlights,
  );
  late final _preview = NewFlightPreview(
    form: _form,
    airlineDirectory: widget.airlineDirectory,
    routeLookup: widget.routeLookup,
  );
  final _inputControllers = {
    for (final kind in FlightLookupKind.values) kind: TextEditingController(),
  };
  final _noteController = TextEditingController();
  final _isSaving = signal(false);

  @override
  void dispose() {
    for (final controller in _inputControllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    _preview.dispose();
    _form.dispose();
    _isSaving.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ModalHeader(
              title: localizations.newFlightTitle,
              cancelLabel: localizations.newFlightCancel,
              onCancel: () => context.pop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.grid * 2,
                  AppSpacing.screenPadding,
                  AppSpacing.screenPaddingLarge,
                ),
                children: [
                  SignalBuilder(
                    builder: (context) => AppSegmentedControl(
                      segments: {
                        for (final kind in FlightLookupKind.values)
                          kind: _kindLabel(localizations, kind),
                      },
                      selected: _form.lookupKind.value,
                      onSelected: (kind) => _form.lookupKind.value = kind,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.screenPaddingLarge),
                  SignalBuilder(
                    builder: (context) => _lookupField(localizations),
                  ),
                  SignalBuilder(
                    builder: (context) => _form.showsLowCostCarrierHint.value
                        ? _LowCostCarrierHint(
                            text: localizations.newFlightLowCostCarrierHint,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.cardPaddingLarge),
                  SignalBuilder(
                    builder: (context) => _departureDateField(localizations),
                  ),
                  const SizedBox(height: AppSpacing.cardPaddingLarge),
                  SignalBuilder(
                    builder: (context) => _departureTimeField(localizations),
                  ),
                  SignalBuilder(
                    builder: (context) => _departureTimeZoneRow(localizations),
                  ),
                  const SizedBox(height: AppSpacing.cardPaddingLarge),
                  _LabeledField(
                    label: localizations.newFlightNoteLabel,
                    child: _FieldBox(
                      child: TextField(
                        controller: _noteController,
                        onChanged: (note) => _form.note.value = note,
                        decoration: _fieldDecoration(
                          localizations.newFlightNoteHint,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  SignalBuilder(
                    builder: (context) => LiveActivityArmRow(
                      availability: widget.liveActivityService.availability,
                      isArmed: _form.liveActivityArmed.value,
                      onToggled: (isArmed) =>
                          _form.liveActivityArmed.value = isArmed,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.cardPaddingLarge),
                  SignalBuilder(builder: (context) => _previewCard()),
                  const SizedBox(height: AppSpacing.screenPaddingLarge),
                  Center(
                    child: SignalBuilder(
                      builder: (context) => AppPrimaryButton(
                        label: localizations.newFlightSubmit,
                        onPressed: _canSave ? _saveFlight : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lookupField(AppLocalizations localizations) {
    final kind = _form.lookupKind.value;
    return _LabeledField(
      label: _kindLabel(localizations, kind),
      hint: switch (kind) {
        FlightLookupKind.flightNumber =>
          localizations.newFlightFlightNumberHint,
        FlightLookupKind.registration =>
          localizations.newFlightRegistrationHint,
        FlightLookupKind.hexAddress => localizations.newFlightHexAddressHint,
      },
      child: _FieldBox(
        child: TextField(
          key: ValueKey(kind),
          controller: _inputControllers[kind],
          onChanged: (value) => _form.inputFor(kind).value = value,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          decoration: _fieldDecoration(null),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _departureDateField(AppLocalizations localizations) {
    final departureDate = _form.departureDate.value;
    return _LabeledField(
      label: localizations.newFlightDepartureDateLabel,
      hint: localizations.newFlightDepartureDateHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pickDepartureDate,
        child: _FieldBox(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat(
                    localizations.newFlightDepartureDateFormat,
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(departureDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const FaIcon(
                AppIcons.calendar,
                size: 18,
                color: AppColors.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _departureTimeField(AppLocalizations localizations) {
    final departureTime = _form.departureTime.value;
    return _LabeledField(
      label: localizations.newFlightDepartureTimeLabel,
      hint: localizations.newFlightDepartureTimeHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pickDepartureTime,
        child: _FieldBox(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  departureTime == null
                      ? localizations.newFlightDepartureTimePlaceholder
                      : formatDayTime(
                          context,
                          localizations.newFlightDepartureTimeFormat,
                          departureTime,
                        ),
                  style: departureTime == null
                      ? AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.neutral400,
                        )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (departureTime == null)
                const FaIcon(
                  AppIcons.clock,
                  size: 18,
                  color: AppColors.neutral400,
                )
              else
                IconButton(
                  onPressed: () => _form.departureTime.value = null,
                  tooltip: localizations.newFlightDepartureTimeClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 44,
                    height: 44,
                  ),
                  icon: const FaIcon(
                    AppIcons.xmark,
                    size: 18,
                    color: AppColors.neutral400,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A flight number whose route is still being looked up would decide the
  /// interpretation of the entered time on a clock the app has not verified.
  bool get _canSave =>
      _form.isValid.value &&
      !_isSaving.value &&
      _preview.state.value is! FlightPreviewSearching;

  /// How the entered time is read: origin local while the route names an
  /// origin, otherwise visibly the device clock, never a silent guess.
  Widget _departureTimeZoneRow(AppLocalizations localizations) {
    if (_form.departureTime.value == null) {
      return const SizedBox.shrink();
    }
    return switch (_preview.state.value) {
      FlightPreviewFound() => AppSwitchRow(
        label: localizations.newFlightDepartureTimeOriginLocal,
        isEnabled: _form.departureTimeIsOriginLocal.value,
        onToggled: (isOriginLocal) =>
            _form.departureTimeIsOriginLocal.value = isOriginLocal,
      ),
      FlightPreviewSearching() => _DepartureTimeHint(
        text: localizations.newFlightDepartureTimeSearchingRoute,
      ),
      FlightPreviewLegChoice() ||
      FlightPreviewRouteUnknown() ||
      FlightPreviewHidden() => _DepartureTimeHint(
        text: localizations.newFlightDepartureTimeDeviceFallback,
      ),
    };
  }

  Widget _previewCard() {
    final state = _preview.state.value;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 175),
      switchInCurve: Curves.easeInOut,
      child: switch (state) {
        FlightPreviewHidden() => const SizedBox.shrink(),
        _ => NewFlightPreviewCard(
          state: state,
          onLegChosen: _preview.chooseLeg,
          airlineName: _airlineNameOf(state),
        ),
      },
    );
  }

  String? _airlineNameOf(FlightPreviewState state) {
    if (state is! FlightPreviewFound) {
      return null;
    }
    final callsign = FlightNumber.tryParse(state.callsign);
    return callsign == null
        ? null
        : widget.airlineDirectory.airlineName(callsign.airlineCode);
  }

  Future<void> _saveFlight() async {
    // The second tap of a double tap arrives before the disabled button is
    // rebuilt, so the guard has to sit in the handler.
    if (_isSaving.value) {
      return;
    }
    _isSaving.value = true;
    final kind = _form.lookupKind.value;
    final input = _form.inputFor(kind).value;
    final flightNumber = FlightNumber.tryParse(input);
    final previewState = _preview.state.value;
    final candidates = kind == FlightLookupKind.flightNumber
        ? widget.airlineDirectory.callsignCandidates(flightNumber!)
        : const <String>[];
    final departureDate = _form.departureDate.value;
    final note = _form.note.value.trim();
    final isArmed = _form.liveActivityArmed.value;

    try {
      await widget.flightRepository.addFlight(
        lookupKind: kind,
        lookupValue: switch (kind) {
          // Stored as it was typed: a leading zero is how the airline files a
          // short number and how the aircraft transmits it, while parsing
          // drops it for the standing data.
          FlightLookupKind.flightNumber => FlightNumber.clean(input),
          FlightLookupKind.registration => normalizedRegistration(input)!,
          FlightLookupKind.hexAddress => normalizedHexAddress(input)!,
        },
        departureDate: CalendarDate(
          departureDate.year,
          departureDate.month,
          departureDate.day,
        ),
        departureTime: _form.departureTime.value,
        departureTimeInterpretation:
            previewState is FlightPreviewFound &&
                _form.departureTimeIsOriginLocal.value
            ? DepartureTimeInterpretation.originLocal
            : DepartureTimeInterpretation.device,
        note: note.isEmpty ? null : note,
        liveActivityArmed: isArmed,
        expectedCallsign: switch (previewState) {
          FlightPreviewFound(:final callsign) ||
          FlightPreviewLegChoice(:final callsign) => callsign,
          _ => candidates.isEmpty ? null : candidates.first,
        },
        route: previewState is FlightPreviewFound ? previewState.route : null,
      );
    } finally {
      _isSaving.value = false;
    }
    await widget.liveActivitySetting.rememberArming(isArmed: isArmed);
    await _offerNotifications();
    if (mounted) {
      context.pop();
    }
  }

  /// The app offers the notifications where they become worth something: right
  /// after the first flight is saved, in its own dialog. Only a yes turns the
  /// switches on and reaches the operating system's prompt.
  Future<void> _offerNotifications() async {
    final isUndecided =
        widget.notificationService.permission.value ==
        NotificationPermission.notDetermined;
    if (!isUndecided || widget.notificationSetting.wasOffered || !mounted) {
      return;
    }
    final isAccepted = await showNotificationOfferDialog(context);
    await widget.notificationSetting.rememberOffer();
    if (!isAccepted) {
      return;
    }
    await widget.notificationSetting.enableAll();
    await widget.notificationService.requestPermission();
  }

  Future<void> _pickDepartureTime() async {
    final pickedTime = await showDepartureTimePicker(
      context: context,
      initialTime: _form.departureTime.value ?? _defaultDepartureTime,
    );
    if (pickedTime != null) {
      _form.departureTime.value = pickedTime;
    }
  }

  Future<void> _pickDepartureDate() async {
    final pickedDate = await showDepartureDatePicker(
      context: context,
      initialDate: _form.departureDate.value,
      firstDate: _form.earliestDepartureDate,
      lastDate: _form.latestDepartureDate,
    );
    if (pickedDate != null) {
      _form.departureDate.value = pickedDate;
    }
  }

  InputDecoration _fieldDecoration(String? hint) => InputDecoration(
    border: InputBorder.none,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    hintText: hint,
    hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400),
  );

  String _kindLabel(
    AppLocalizations localizations,
    FlightLookupKind kind,
  ) => switch (kind) {
    FlightLookupKind.flightNumber => localizations.newFlightKindFlightNumber,
    FlightLookupKind.registration => localizations.newFlightKindRegistration,
    FlightLookupKind.hexAddress => localizations.newFlightKindHexAddress,
  };
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.title,
    required this.cancelLabel,
    required this.onCancel,
  });

  final String title;
  final String cancelLabel;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Stack(
      children: [
        Center(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onCancel,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.cardPadding,
              ),
              child: Text(
                cancelLabel,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: switch (Theme.of(context).brightness) {
                    Brightness.light => AppColors.linkLight,
                    Brightness.dark => AppColors.linkDark,
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.hint});

  final String label;
  final Widget child;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.grid * 2),
        child,
        if (hint != null) ...[
          const SizedBox(height: AppSpacing.grid * 1.5),
          Text(
            hint,
            style: AppTextStyles.small.copyWith(color: AppColors.neutral400),
          ),
        ],
      ],
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Center(child: child),
    );
  }
}

class _DepartureTimeHint extends StatelessWidget {
  const _DepartureTimeHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.grid * 1.5),
    child: Text(
      text,
      style: AppTextStyles.small.copyWith(color: AppColors.neutral400),
    ),
  );
}

class _LowCostCarrierHint extends StatelessWidget {
  const _LowCostCarrierHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.grid * 2),
    child: Text(
      text,
      style: AppTextStyles.small.copyWith(
        color: switch (Theme.of(context).brightness) {
          Brightness.light => AppColors.linkLight,
          Brightness.dark => AppColors.linkDark,
        },
      ),
    ),
  );
}
