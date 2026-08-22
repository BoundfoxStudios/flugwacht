import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/data/settings/live_activity_setting.dart';
import 'package:flugwacht/data/settings/notification_setting.dart';
import 'package:flugwacht/data/settings/source_setting.dart';
import 'package:flugwacht/data/settings/units_setting.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/domain/source_id.dart';
import 'package:flugwacht/domain/units.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/more_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/controls/app_radio_row.dart';
import 'package:flugwacht/ui/widgets/controls/app_switch_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_dependencies.dart';

Future<
  ({
    SourceSetting source,
    UnitsSetting units,
    NotificationSetting notifications,
    FakeNotificationService service,
    LiveActivitySetting liveActivities,
  })
>
pumpMoreScreen(
  WidgetTester tester, {
  String version = '1.4.2',
  Locale locale = const Locale('en'),
  NotificationPermission permission = NotificationPermission.granted,
  LiveActivityAvailability liveActivities = LiveActivityAvailability.enabled,
}) async {
  final sourceSetting = await createTestSourceSetting();
  final unitsSetting = await createTestUnitsSetting();
  final notificationSetting = await createTestNotificationSetting();
  final notificationService = createTestNotificationService(
    permission: permission,
  );
  final liveActivitySetting = await createTestLiveActivitySetting();
  final liveActivityService = createTestLiveActivityService();
  liveActivityService.availability.value = liveActivities;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildLightTheme(),
      home: MoreScreen(
        sourceSetting: sourceSetting,
        unitsSetting: unitsSetting,
        notificationSetting: notificationSetting,
        notificationService: notificationService,
        liveActivitySetting: liveActivitySetting,
        liveActivityService: liveActivityService,
        packageInfo: testPackageInfo(version: version),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    source: sourceSetting,
    units: unitsSetting,
    notifications: notificationSetting,
    service: notificationService,
    liveActivities: liveActivitySetting,
  );
}

bool isSelected(WidgetTester tester, String label) => tester
    .widget<AppRadioRow>(find.widgetWithText(AppRadioRow, label))
    .isSelected;

void main() {
  testWidgets('offers the selectable sources with the active one marked', (
    tester,
  ) async {
    await pumpMoreScreen(tester);

    expect(find.byType(AppRadioRow), findsNWidgets(selectableSourceIds.length));
    expect(find.text('adsb.lol'), findsOneWidget);
    expect(find.text('adsb.fi'), findsOneWidget);
    expect(find.text('airplanes.live'), findsNothing);
    expect(isSelected(tester, 'adsb.lol'), isTrue);
    expect(isSelected(tester, 'adsb.fi'), isFalse);
  });

  testWidgets('selecting another source persists it and marks its row', (
    tester,
  ) async {
    final settings = await pumpMoreScreen(tester);

    await tester.tap(find.text('adsb.fi'));
    await tester.pumpAndSettle();

    expect(settings.source.activeId.value, SourceId.adsbfi);
    expect(isSelected(tester, 'adsb.fi'), isTrue);
    expect(isSelected(tester, 'adsb.lol'), isFalse);
  });

  testWidgets('switches the units the app displays', (tester) async {
    final settings = await pumpMoreScreen(tester);

    await tester.tap(find.text('Aviation (ft, kt)'));
    await tester.pumpAndSettle();

    expect(settings.units.units.value, Units.aviation);
  });

  testWidgets('turns a notification on and marks its row', (tester) async {
    final settings = await pumpMoreScreen(tester);

    await tester.tap(find.text('Landed'));
    await tester.pumpAndSettle();

    expect(settings.notifications.isEnabled(FlightNotification.landed), isTrue);
    expect(
      tester
          .widget<AppSwitchRow>(find.widgetWithText(AppSwitchRow, 'Landed'))
          .isEnabled,
      isTrue,
    );
    expect(
      settings.notifications.isEnabled(FlightNotification.departed),
      isFalse,
    );
  });

  testWidgets('a switch going on asks the system while it is undecided', (
    tester,
  ) async {
    final settings = await pumpMoreScreen(
      tester,
      permission: NotificationPermission.notDetermined,
    );

    await tester.tap(find.text('Landed'));
    await tester.pumpAndSettle();

    expect(settings.service.permissionRequests, 1);
  });

  testWidgets('a switch going on asks nothing once the answer is known', (
    tester,
  ) async {
    for (final permission in [
      NotificationPermission.granted,
      NotificationPermission.denied,
    ]) {
      final settings = await pumpMoreScreen(tester, permission: permission);

      await tester.tap(find.text('Landed'));
      await tester.pumpAndSettle();

      expect(settings.service.permissionRequests, 0, reason: permission.name);
    }
  });

  testWidgets('a switch going off asks for nothing', (tester) async {
    final settings = await pumpMoreScreen(
      tester,
      permission: NotificationPermission.notDetermined,
    );
    await tester.tap(find.text('Landed'));
    await tester.pumpAndSettle();
    settings.service.permissionRequests = 0;

    await tester.tap(find.text('Landed'));
    await tester.pumpAndSettle();

    expect(settings.service.permissionRequests, 0);
  });

  testWidgets('explains when each notification can reach you', (tester) async {
    await pumpMoreScreen(tester);

    expect(
      find.textContaining('only arrive while Flugwacht is open'),
      findsOneWidget,
    );
  });

  testWidgets('explains the delivery in german too', (tester) async {
    await pumpMoreScreen(tester, locale: const Locale('de'));

    expect(find.textContaining('solange Flugwacht offen ist'), findsOneWidget);
  });

  testWidgets('points at the system settings while notifications are off', (
    tester,
  ) async {
    await pumpMoreScreen(tester, permission: NotificationPermission.denied);

    expect(find.textContaining('system settings'), findsOneWidget);
  });

  testWidgets('hides the system hint while the permission is granted', (
    tester,
  ) async {
    await pumpMoreScreen(tester);

    expect(find.textContaining('system settings'), findsNothing);
  });

  testWidgets('promises nothing when the device could set none of them up', (
    tester,
  ) async {
    await pumpMoreScreen(
      tester,
      permission: NotificationPermission.unavailable,
    );

    expect(
      find.textContaining('could not set notifications up'),
      findsOneWidget,
    );
    expect(find.textContaining('system settings'), findsNothing);
    expect(
      find.textContaining('only arrive while Flugwacht is open'),
      findsNothing,
    );
  });

  testWidgets('names the app version below the about entry', (tester) async {
    await pumpMoreScreen(tester, version: '2.7.0');

    expect(find.textContaining('2.7.0'), findsOneWidget);
  });

  testWidgets('offers the faq above the about entry', (tester) async {
    await pumpMoreScreen(tester);

    expect(
      tester.getTopLeft(find.text('Frequently asked questions')).dy,
      lessThan(tester.getTopLeft(find.text('About Flugwacht')).dy),
    );
  });

  group('live activities', () {
    testWidgets('stays away where the device shows no activities', (
      tester,
    ) async {
      await pumpMoreScreen(
        tester,
        liveActivities: LiveActivityAvailability.unsupported,
      );

      expect(find.text('Remind me on the flight day'), findsNothing);
    });

    testWidgets('reminds on the flight day until the user says otherwise', (
      tester,
    ) async {
      final settings = await pumpMoreScreen(tester);
      expect(settings.liveActivities.remindsOnFlightDay.value, isTrue);

      await tester.ensureVisible(find.text('Remind me on the flight day'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remind me on the flight day'));
      await tester.pumpAndSettle();

      expect(settings.liveActivities.remindsOnFlightDay.value, isFalse);
    });

    testWidgets('names the notification the switch is about', (tester) async {
      await pumpMoreScreen(tester);

      expect(
        find.text(
          'Flugwacht sends you a notification on the flight day, so you can '
          'start the Live Activity from there.',
        ),
        findsOneWidget,
      );
    });
  });
}
