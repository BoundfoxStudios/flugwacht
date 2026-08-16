import 'package:flugwacht/domain/units.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/widgets/flight/flight_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  late AppLocalizations english;
  late AppLocalizations german;

  setUpAll(() async {
    english = await AppLocalizations.delegate.load(const Locale('en'));
    german = await AppLocalizations.delegate.load(const Locale('de'));
  });

  test('shows a cruising altitude in feet, grouped like the metric value', () {
    expect(
      altitudeLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.aviation,
        altitudeFeet: 37000,
      ),
      '37,000 ft',
    );
    expect(
      altitudeLabel(
        localizations: german,
        numbers: NumberFormat.decimalPattern('de'),
        units: Units.aviation,
        altitudeFeet: 37000,
      ),
      '37.000 ft',
    );
  });

  test('shows a cruising speed in knots', () {
    expect(
      speedLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.aviation,
        groundSpeedKnots: 473,
      ),
      '473 kt',
    );
  });

  test('rounds the raw values to whole feet and knots', () {
    expect(
      altitudeLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.aviation,
        altitudeFeet: 36975.6,
      ),
      '36,976 ft',
    );
    expect(
      speedLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.aviation,
        groundSpeedKnots: 472.4,
      ),
      '472 kt',
    );
  });

  test('converts to meters and kilometers per hour for metric units', () {
    expect(
      altitudeLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.metric,
        altitudeFeet: 37000,
      ),
      '11,278 m',
    );
    expect(
      speedLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.metric,
        groundSpeedKnots: 473,
      ),
      '876 km/h',
    );
  });

  test('has no label without a measurement', () {
    expect(
      altitudeLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.aviation,
        altitudeFeet: null,
      ),
      isNull,
    );
    expect(
      speedLabel(
        localizations: english,
        numbers: NumberFormat.decimalPattern('en'),
        units: Units.aviation,
        groundSpeedKnots: null,
      ),
      isNull,
    );
  });
}
