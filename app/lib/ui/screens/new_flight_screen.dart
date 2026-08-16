import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

import '../../app_icons.dart';
import '../../data/airline_directory.dart';
import '../../data/flight_repository.dart';
import '../../data/notification_service.dart';
import '../../data/notification_setting.dart';
import '../../data/route_lookup.dart';
import '../../domain/calendar_date.dart';
import '../../domain/day_time.dart';
import '../../domain/flight.dart';
import '../../domain/flight_notification.dart';
import '../../domain/flight_number.dart';
import '../../domain/lookup_input.dart';
import '../../l10n/app_localizations.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_segmented_control.dart';
import '../widgets/departure_date_picker.dart';
import '../widgets/departure_time_picker.dart';
import '../widgets/flight_labels.dart';
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
    super.key,
    this.today,
  });

  final FlightRepository flightRepository;
  final AirlineDirectory airlineDirectory;
  final RouteLookup routeLookup;
  final NotificationService notificationService;
  final NotificationSetting notificationSetting;

  /// The day the selectable date range is built around; defaults to the
  /// current day.
  final DateTime? today;

  @override
  State<NewFlightScreen> createState() => _NewFlightScreenState();
}

class _NewFlightScreenState extends State<NewFlightScreen> {
  late final _form = NewFlightForm(today: widget.today ?? DateTime.now());
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
                  const SizedBox(height: AppSpacing.cardPaddingLarge),
                  SignalBuilder(builder: (context) => _previewCard()),
                  const SizedBox(height: AppSpacing.screenPaddingLarge),
                  Center(
                    child: SignalBuilder(
                      builder: (context) => AppPrimaryButton(
                        label: localizations.newFlightSubmit,
                        onPressed: _form.isValid.value && !_isSaving.value
                            ? _saveFlight
                            : null,
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

  Widget _previewCard() {
    final state = _preview.state.value;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 175),
      switchInCurve: Curves.easeInOut,
      child: switch (state) {
        FlightPreviewHidden() => const SizedBox.shrink(),
        _ => NewFlightPreviewCard(
          state: state,
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

    try {
      await widget.flightRepository.addFlight(
        lookupKind: kind,
        lookupValue: switch (kind) {
          FlightLookupKind.flightNumber => flightNumber!.normalized,
          FlightLookupKind.registration => normalizedRegistration(input)!,
          FlightLookupKind.hexAddress => normalizedHexAddress(input)!,
        },
        departureDate: CalendarDate(
          departureDate.year,
          departureDate.month,
          departureDate.day,
        ),
        departureTime: _form.departureTime.value,
        note: note.isEmpty ? null : note,
        expectedCallsign: switch (previewState) {
          FlightPreviewFound(:final callsign) => callsign,
          _ => candidates.isEmpty ? null : candidates.first,
        },
        route: previewState is FlightPreviewFound ? previewState.route : null,
      );
    } finally {
      _isSaving.value = false;
    }
    await _askForNotificationPermission();
    if (mounted) {
      context.pop();
    }
  }

  /// The app asks where the notifications become worth something: right after
  /// the first flight is saved, and only for switches that are on.
  Future<void> _askForNotificationPermission() async {
    final isUndecided =
        widget.notificationService.permission.value ==
        NotificationPermission.notDetermined;
    final wantsAny = FlightNotification.values.any(
      widget.notificationSetting.isEnabled,
    );
    if (isUndecided && wantsAny) {
      await widget.notificationService.requestPermission();
    }
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
