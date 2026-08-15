import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals/signals_flutter.dart';

import '../../app_icons.dart';
import '../../domain/flight.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/app_segmented_control.dart';
import '../widgets/departure_date_picker.dart';
import 'new_flight_form.dart';

class NewFlightScreen extends StatefulWidget {
  const NewFlightScreen({super.key, this.today});

  /// The day the selectable date range is built around; defaults to the
  /// current day.
  final DateTime? today;

  @override
  State<NewFlightScreen> createState() => _NewFlightScreenState();
}

class _NewFlightScreenState extends State<NewFlightScreen> {
  late final _form = NewFlightForm(today: widget.today ?? DateTime.now());
  final _inputControllers = {
    for (final kind in FlightLookupKind.values) kind: TextEditingController(),
  };
  final _noteController = TextEditingController();

  @override
  void dispose() {
    for (final controller in _inputControllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    _form.dispose();
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
                  const SizedBox(height: AppSpacing.screenPaddingLarge * 2),
                  Center(
                    child: SignalBuilder(
                      builder: (context) => AppPrimaryButton(
                        label: localizations.newFlightSubmit,
                        onPressed: _form.isValid.value ? () {} : null,
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
