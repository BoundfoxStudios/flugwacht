import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../domain/day_time.dart';
import '../../../l10n/app_localizations.g.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

/// Opens the time picker the platform is at home with — the Material dialog on
/// Android, the wheel in a sheet on iOS.
Future<DayTime?> showDepartureTimePicker({
  required BuildContext context,
  required DayTime initialTime,
}) async {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return showModalBottomSheet<DayTime>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _CupertinoTimeSheet(initialTime: initialTime),
    );
  }
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initialTime.hour, minute: initialTime.minute),
  );
  return pickedTime == null
      ? null
      : DayTime(pickedTime.hour, pickedTime.minute);
}

class _CupertinoTimeSheet extends StatefulWidget {
  const _CupertinoTimeSheet({required this.initialTime});

  final DayTime initialTime;

  @override
  State<_CupertinoTimeSheet> createState() => _CupertinoTimeSheetState();
}

class _CupertinoTimeSheetState extends State<_CupertinoTimeSheet> {
  late var _selectedTime = widget.initialTime;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.grid * 2,
                ),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(_selectedTime),
                  child: Text(
                    localizations.newFlightDatePickerConfirm,
                    style: AppTextStyles.bodyLargeEmphasis.copyWith(
                      color: switch (Theme.of(context).brightness) {
                        Brightness.light => AppColors.linkLight,
                        Brightness.dark => AppColors.linkDark,
                      },
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                initialDateTime: DateTime(
                  2026,
                  1,
                  1,
                  widget.initialTime.hour,
                  widget.initialTime.minute,
                ),
                onDateTimeChanged: (time) =>
                    _selectedTime = DayTime(time.hour, time.minute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
