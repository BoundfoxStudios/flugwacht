import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.g.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_tokens.dart';

/// Opens the date picker the platform is at home with — the Material dialog on
/// Android, the wheel in a sheet on iOS.
Future<DateTime?> showDepartureDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _CupertinoDateSheet(
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
  }
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

class _CupertinoDateSheet extends StatefulWidget {
  const _CupertinoDateSheet({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CupertinoDateSheet> createState() => _CupertinoDateSheetState();
}

class _CupertinoDateSheetState extends State<_CupertinoDateSheet> {
  late var _selectedDate = widget.initialDate;

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
                  onTap: () => Navigator.of(context).pop(_selectedDate),
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
                mode: CupertinoDatePickerMode.date,
                initialDateTime: widget.initialDate,
                minimumDate: widget.firstDate,
                maximumDate: widget.lastDate,
                onDateTimeChanged: (date) => _selectedDate = date,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
