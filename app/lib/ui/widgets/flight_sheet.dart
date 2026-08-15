import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/flight_state.dart';
import '../../domain/source_id.dart';
import '../../domain/unit_conversion.dart';
import '../../l10n/app_localizations.g.dart';
import '../screens/list_sections.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';
import 'flight_labels.dart';
import 'flight_state_badge.dart';
import 'pager_dots.dart';
import 'state_timeline.dart';

/// The sheet over the map: peeking it names the flight and its arrival, opened
/// it adds the timeline, the flight's numbers and the source.
class FlightSheet extends StatefulWidget {
  const FlightSheet({
    required this.entries,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
    this.onOpenChanged,
  });

  static const _snapDuration = Duration(milliseconds: 180);
  static const _pageDuration = Duration(milliseconds: 200);

  /// Travel of a drag that counts as a pull to the other snap position.
  static const _snapThreshold = 24.0;

  static const _grabberSize = Size(36, 4);
  static const _grabberPadding = EdgeInsets.symmetric(vertical: 4);
  static const _peekGap = 6.0;
  static const _openGap = 8.0;
  static const _timeHeight = 0.95;
  static const _dataRowGap = 8.0;
  static const _dataRowPadding = 10.0;
  static const _dataLabelGap = 1.0;

  final List<FlightListEntry> entries;
  final int selectedIndex;

  /// Reports the page the sheet settled on, so the selection follows a swipe.
  final ValueChanged<int> onSelected;

  /// Lets the map hide what the open sheet would cover.
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<FlightSheet> createState() => _FlightSheetState();
}

class _FlightSheetState extends State<FlightSheet> {
  final _pages = ScrollController();
  var _isOpen = false;
  var _isSwiping = false;
  var _dragTravel = 0.0;

  @override
  void initState() {
    super.initState();
    _showPage(widget.selectedIndex, animate: false);
  }

  @override
  void didUpdateWidget(covariant FlightSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entries.length != oldWidget.entries.length) {
      _showPage(widget.selectedIndex, animate: false);
    } else if (widget.selectedIndex != oldWidget.selectedIndex) {
      _showPage(widget.selectedIndex, animate: true);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = switch (Theme.of(context).brightness) {
      Brightness.light => _SheetColors.light,
      Brightness.dark => _SheetColors.dark,
    };
    final gap = _isOpen ? FlightSheet._openGap : FlightSheet._peekGap;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        boxShadow: [colors.shadow],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (_) => _dragTravel = 0,
        onVerticalDragUpdate: (details) =>
            _dragTravel += details.primaryDelta ?? 0,
        onVerticalDragEnd: (_) => _snap(),
        child: AnimatedSize(
          duration: FlightSheet._snapDuration,
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPaddingLarge,
              AppSpacing.grid * 2,
              AppSpacing.screenPaddingLarge,
              (_isOpen ? AppSpacing.cardPadding : AppSpacing.grid * 2.5) +
                  MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Grabber(color: colors.grabber, onTap: _toggle),
                if (widget.entries.length > 1) ...[
                  SizedBox(height: gap),
                  PagerDots(
                    count: widget.entries.length,
                    activeIndex: widget.selectedIndex,
                  ),
                ],
                SizedBox(height: gap),
                LayoutBuilder(
                  builder: (context, constraints) =>
                      NotificationListener<ScrollNotification>(
                        onNotification: _onPageScroll,
                        child: SingleChildScrollView(
                          controller: _pages,
                          scrollDirection: Axis.horizontal,
                          physics: const PageScrollPhysics(),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final entry in widget.entries)
                                SizedBox(
                                  width: constraints.maxWidth,
                                  child: _FlightPage(
                                    entry: entry,
                                    colors: colors,
                                    isOpen: _isOpen,
                                    gap: gap,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Only a swipe changes the selection: a set of flights that changed size
  /// settles the pages too, and that must not page the selection away.
  bool _onPageScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _isSwiping = notification.dragDetails != null;
      return false;
    }
    final width = notification.metrics.viewportDimension;
    if (notification is! ScrollEndNotification || !_isSwiping || width == 0) {
      return false;
    }
    _isSwiping = false;
    final index = (notification.metrics.pixels / width).round().clamp(
      0,
      widget.entries.length - 1,
    );
    if (index != widget.selectedIndex) {
      widget.onSelected(index);
    }
    return false;
  }

  /// Runs after the frame so the pages exist and their extent already matches
  /// a set of flights that just changed.
  void _showPage(int index, {required bool animate}) =>
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pages.hasClients) {
          return;
        }
        final offset = index * _pages.position.viewportDimension;
        if (offset == _pages.offset) {
          return;
        }
        if (animate) {
          unawaited(
            _pages.animateTo(
              offset,
              duration: FlightSheet._pageDuration,
              curve: Curves.easeInOut,
            ),
          );
        } else {
          _pages.jumpTo(offset);
        }
      });

  void _toggle() => _setOpen(!_isOpen);

  void _snap() {
    if (_dragTravel.abs() < FlightSheet._snapThreshold) {
      return;
    }
    _setOpen(_dragTravel.isNegative);
  }

  void _setOpen(bool isOpen) {
    if (isOpen == _isOpen) {
      return;
    }
    setState(() => _isOpen = isOpen);
    widget.onOpenChanged?.call(isOpen);
  }
}

class _FlightPage extends StatelessWidget {
  const _FlightPage({
    required this.entry,
    required this.colors,
    required this.isOpen,
    required this.gap,
  });

  final FlightListEntry entry;
  final _SheetColors colors;
  final bool isOpen;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleRow(entry: entry, colors: colors, isOpen: isOpen),
        SizedBox(height: gap),
        Text(
          localizations.mapSheetArrivalPlaceholder,
          style: AppTextStyles.timeLarge.copyWith(
            color: colors.time,
            height: FlightSheet._timeHeight,
          ),
        ),
        if (isOpen) ...[
          SizedBox(height: gap),
          StateTimeline(
            state: entry.state,
            variant: StateTimelineVariant.labeled,
          ),
          SizedBox(height: gap),
          _DataRow(entry: entry, colors: colors),
          SizedBox(height: gap),
          Text(
            localizations.mapSheetSource(activeSourceId.label),
            style: AppTextStyles.caption.copyWith(color: colors.footer),
          ),
        ],
      ],
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: FlightSheet._grabberPadding,
      child: Center(
        child: SizedBox.fromSize(
          size: FlightSheet._grabberSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(
                FlightSheet._grabberSize.height / 2,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.entry,
    required this.colors,
    required this.isOpen,
  });

  final FlightListEntry entry;
  final _SheetColors colors;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final route = flightRouteLabel(localizations, entry.flight.route);
    final showsRoute =
        isOpen && route != null && entry.state != FlightState.noSignal;
    return Row(
      children: [
        Expanded(
          child: Text(
            flightTitle(localizations, entry.flight),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyEmphasis.copyWith(color: colors.title),
          ),
        ),
        const SizedBox(width: AppSpacing.cardPadding),
        if (showsRoute)
          Text(
            route,
            style: AppTextStyles.secondary.copyWith(color: colors.route),
          )
        else
          FlightStateBadge(state: entry.state),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.entry, required this.colors});

  final FlightListEntry entry;
  final _SheetColors colors;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final numbers = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final position = entry.flight.tracking.latestPosition;
    final altitude = metersFromFeet(position?.barometricAltitudeFeet);
    final speed = kilometersPerHourFromKnots(position?.groundSpeedKnots);
    return Container(
      padding: const EdgeInsets.only(top: FlightSheet._dataRowPadding),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FlightSheet._dataRowGap,
        children: [
          _DataColumn(
            label: localizations.mapSheetAltitudeLabel,
            value: altitude == null
                ? null
                : localizations.mapSheetAltitudeValue(numbers.format(altitude)),
            colors: colors,
          ),
          _DataColumn(
            label: localizations.mapSheetSpeedLabel,
            value: speed == null
                ? null
                : localizations.mapSheetSpeedValue(numbers.format(speed)),
            colors: colors,
          ),
          // Freshness is M8; the column holds its place until then.
          _DataColumn(
            label: localizations.mapSheetSignalLabel,
            value: null,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _DataColumn extends StatelessWidget {
  const _DataColumn({
    required this.label,
    required this.value,
    required this.colors,
  });

  final String label;
  final String? value;
  final _SheetColors colors;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.sectionLabelSmall.copyWith(
            color: colors.dataLabel,
          ),
        ),
        const SizedBox(height: FlightSheet._dataLabelGap),
        Text(
          value ?? AppLocalizations.of(context).mapSheetValuePlaceholder,
          style: AppTextStyles.bodyEmphasis.copyWith(color: colors.dataValue),
        ),
      ],
    ),
  );
}

enum _SheetColors {
  light(
    surface: AppColors.white,
    shadow: BoxShadow(
      color: Color(0x17000000),
      blurRadius: 16,
      offset: Offset(0, -6),
    ),
    grabber: AppColors.neutral300,
    title: AppColors.neutral700,
    route: AppColors.neutral500,
    time: AppColors.neutral900,
    hairline: AppColors.neutral100,
    dataLabel: AppColors.neutral400,
    dataValue: AppColors.neutral700,
  ),
  dark(
    surface: AppColors.neutral800,
    shadow: BoxShadow(
      color: Color(0x80000000),
      blurRadius: 16,
      offset: Offset(0, -6),
    ),
    grabber: AppColors.neutral600,
    title: AppColors.neutral300,
    route: AppColors.neutral400,
    time: AppColors.white,
    hairline: AppColors.neutral700,
    dataLabel: AppColors.neutral500,
    dataValue: AppColors.neutral300,
  );

  const _SheetColors({
    required this.surface,
    required this.shadow,
    required this.grabber,
    required this.title,
    required this.route,
    required this.time,
    required this.hairline,
    required this.dataLabel,
    required this.dataValue,
  });

  final Color surface;
  final BoxShadow shadow;
  final Color grabber;
  final Color title;
  final Color route;
  final Color time;
  final Color hairline;
  final Color dataLabel;
  final Color dataValue;

  Color get footer => dataLabel;
}
