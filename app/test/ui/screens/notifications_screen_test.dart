import 'package:flugwacht/data/live_activities/live_activity_service.dart';
import 'package:flugwacht/data/notifications/notification_service.dart';
import 'package:flugwacht/data/settings/live_activity_setting.dart';
import 'package:flugwacht/data/settings/notification_setting.dart';
import 'package:flugwacht/domain/flight_notification.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/screens/notifications_screen.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/widgets/controls/app_switch_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../support/test_dependencies.dart';

Future<
  ({
    NotificationSetting notifications,
    FakeNotificationService service,
    LiveActivitySetting liveActivities,
  })
>
pumpNotificationsScreen(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  NotificationPermission permission = NotificationPermission.granted,
  LiveActivityAvailability liveActivities = LiveActivityAvailability.enabled,
}) async {
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
      home: NotificationsScreen(
        notificationSetting: notificationSetting,
        notificationService: notificationService,
        liveActivitySetting: liveActivitySetting,
        liveActivityService: liveActivityService,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    notifications: notificationSetting,
    service: notificationService,
    liveActivities: liveActivitySetting,
  );
}

void main() {
  testWidgets(
    'groups the flight moments and the flight day by when they send',
    (tester) async {
      await pumpNotificationsScreen(tester);

      expect(
        tester.getTopLeft(find.text('During the flight')).dy,
        lessThan(tester.getTopLeft(find.text('On the flight day')).dy),
      );
      for (final label in ['Departed', 'Arriving soon (~30 min)', 'Landed']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Remind me on the flight day'), findsOneWidget);
    },
  );

  testWidgets('turns a notification on and marks its row', (tester) async {
    final settings = await pumpNotificationsScreen(tester);

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
    final settings = await pumpNotificationsScreen(
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
      final settings = await pumpNotificationsScreen(
        tester,
        permission: permission,
      );

      await tester.tap(find.text('Landed'));
      await tester.pumpAndSettle();

      expect(settings.service.permissionRequests, 0, reason: permission.name);
    }
  });

  testWidgets('a switch going off asks for nothing', (tester) async {
    final settings = await pumpNotificationsScreen(
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
    await pumpNotificationsScreen(tester);

    expect(
      find.textContaining('only arrive while Flugwacht is open'),
      findsOneWidget,
    );
  });

  testWidgets('names what the flight day reminder sends', (tester) async {
    await pumpNotificationsScreen(tester);

    expect(
      find.text(
        'Flugwacht sends you a notification on the flight day, so you can '
        'put the flight on your lock screen from there.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpNotificationsScreen(tester, locale: const Locale('de'));

    expect(find.text('Während des Flugs'), findsOneWidget);
    expect(find.text('Am Flugtag'), findsOneWidget);
    expect(find.textContaining('solange Flugwacht offen ist'), findsOneWidget);
  });

  testWidgets('leaves arming a Live Activity off the page', (tester) async {
    await pumpNotificationsScreen(tester);

    expect(find.text('Live Activities'), findsNothing);
    expect(find.text('On the lock screen on flight day'), findsNothing);
  });

  testWidgets('points at the system settings while notifications are off', (
    tester,
  ) async {
    await pumpNotificationsScreen(
      tester,
      permission: NotificationPermission.denied,
    );

    expect(find.textContaining('system settings'), findsOneWidget);
  });

  testWidgets('hides the system hint while the permission is granted', (
    tester,
  ) async {
    await pumpNotificationsScreen(tester);

    expect(find.textContaining('system settings'), findsNothing);
  });

  testWidgets('promises nothing when the device could set none of them up', (
    tester,
  ) async {
    await pumpNotificationsScreen(
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

  testWidgets('drops the flight day where the device shows no activities', (
    tester,
  ) async {
    await pumpNotificationsScreen(
      tester,
      liveActivities: LiveActivityAvailability.unsupported,
    );

    expect(find.text('On the flight day'), findsNothing);
    expect(find.text('Remind me on the flight day'), findsNothing);
  });

  testWidgets('reminds on the flight day until the user says otherwise', (
    tester,
  ) async {
    final settings = await pumpNotificationsScreen(tester);
    expect(settings.liveActivities.remindsOnFlightDay.value, isTrue);

    await tester.tap(find.text('Remind me on the flight day'));
    await tester.pumpAndSettle();

    expect(settings.liveActivities.remindsOnFlightDay.value, isFalse);
  });
}
