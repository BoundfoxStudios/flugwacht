import 'package:flugwacht/domain/flight_card.dart';
import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/l10n/app_localizations_en.g.dart';
import 'package:flugwacht/ui/widgets/flight/live_activity_labels.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final AppLocalizations localizations = AppLocalizationsEn();

  setUpAll(() => initializeDateFormatting(localizations.localeName));

  FlightCard card({
    String? note,
    ({String origin, String destination})? route,
    FlightState state = FlightState.live,
    bool hasProbablyLanded = false,
    DateTime? arrivesAt,
    DateTime? landedAt,
  }) => FlightCard(
    designator: 'LH433',
    state: state,
    hasProbablyLanded: hasProbablyLanded,
    note: note,
    route: route,
    arrivesAt: arrivesAt,
    landedAt: landedAt,
  );

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('platform wording', () {
    /// Apple's terms mean nothing on Android, and Android has no established
    /// name for what it shows, so it names the effect rather than a feature.
    test('gives iOS Apple\'s vocabulary', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(liveActivityArmLabel(localizations), contains('Live Activity'));
      expect(
        liveActivityDisabledHint(localizations),
        contains('Live Activities'),
      );
      expect(
        liveActivitySettingsHint(localizations),
        contains('Live Activity'),
      );
    });

    test('gives Android its own', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(liveActivityArmLabel(localizations), contains('lock screen'));
      expect(
        liveActivityArmLabel(localizations),
        isNot(contains('Live Activity')),
      );
      expect(
        liveActivityDisabledHint(localizations),
        isNot(contains('Live Activities')),
      );
      expect(
        liveActivitySettingsHint(localizations),
        isNot(contains('Live Activity')),
      );
    });
  });

  group('card text', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

    test('heads the card with the flight and its note', () {
      expect(
        flightCardText(localizations, card(note: 'Mama')).title,
        'LH433 · Mama',
      );
    });

    test('heads a flight without a note with the flight alone', () {
      expect(flightCardText(localizations, card()).title, 'LH433');
    });

    test('puts the route in front of what the flight is doing', () {
      final text = flightCardText(
        localizations,
        card(route: (origin: 'FRA', destination: 'JFK')),
      );

      expect(text.body, startsWith('FRA → JFK'));
    });

    test('says the arrival it still counts towards', () {
      final text = flightCardText(
        localizations,
        card(arrivesAt: DateTime(2026, 3, 17, 14, 35)),
      );

      expect(text.body, contains('arrival'));
      expect(text.body, isNot(contains('~')));
    });

    /// The app never fakes precision: an estimate it could not confirm says so.
    test('marks an arrival it could not confirm', () {
      final text = flightCardText(
        localizations,
        card(
          state: FlightState.noSignal,
          arrivesAt: DateTime(2026, 3, 17, 14, 35),
        ),
      );

      expect(text.body, contains('~'));
    });

    test('says when the flight touched down', () {
      final text = flightCardText(
        localizations,
        card(state: FlightState.ended, landedAt: DateTime(2026, 3, 17, 14, 32)),
      );

      expect(text.body, contains('landed'));
    });

    test('says the estimate ran out before the app saw the landing', () {
      final text = flightCardText(
        localizations,
        card(hasProbablyLanded: true, arrivesAt: DateTime(2026, 3, 17, 14, 35)),
      );

      expect(text.body, 'probably landed');
    });

    test('falls back to the state where no time is known', () {
      final text = flightCardText(
        localizations,
        card(state: FlightState.waiting),
      );

      expect(text.body, localizations.flightRowWaitingForSignal);
    });
  });
}
