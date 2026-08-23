import 'package:flugwacht/main.dart';
import 'package:flugwacht/ui/screens/about_screen.dart';
import 'package:flugwacht/ui/screens/faq_screen.dart';
import 'package:flugwacht/ui/screens/list_screen.dart';
import 'package:flugwacht/ui/screens/map_screen.dart';
import 'package:flugwacht/ui/screens/more_screen.dart';
import 'package:flugwacht/ui/screens/new_flight_screen.dart';
import 'package:flugwacht/ui/screens/notifications_screen.dart';
import 'package:flugwacht/ui/widgets/chrome/app_tab_bar.dart';
import 'package:flugwacht/ui/widgets/controls/app_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/test_dependencies.dart';

Future<GoRouter> pumpApp(WidgetTester tester) async {
  final router = await createTestAppRouter();
  await tester.pumpWidget(FlugwachtApp(router: router));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('starts on the map tab', (tester) async {
    final router = await pumpApp(tester);

    expect(find.byType(MapScreen), findsOneWidget);
    expect(router.state.uri.toString(), '/map');
  });

  testWidgets('switching tabs shows the selected screen', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Flights'));
    await tester.pumpAndSettle();
    expect(find.byType(ListScreen), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byType(MoreScreen), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets('the settings card opens the about screen and comes back', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('About Flugwacht'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('About Flugwacht'));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(router.state.uri.toString(), '/more/about');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(MoreScreen), findsOneWidget);
    expect(find.byType(AboutScreen), findsNothing);
  });

  testWidgets('the settings card opens the faq screen and comes back', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Frequently asked questions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Frequently asked questions'));
    await tester.pumpAndSettle();

    expect(find.byType(FaqScreen), findsOneWidget);
    expect(router.state.uri.toString(), '/more/faq');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(MoreScreen), findsOneWidget);
    expect(find.byType(FaqScreen), findsNothing);
  });

  testWidgets('the settings card opens the notifications page and comes back', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(router.state.uri.toString(), '/more/notifications');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(MoreScreen), findsOneWidget);
    expect(find.byType(NotificationsScreen), findsNothing);
  });

  testWidgets('a tapped notification brings the map back to the front', (
    tester,
  ) async {
    final notifications = createTestNotificationService();
    final router = await createTestAppRouter(
      notificationService: notifications,
    );
    await tester.pumpWidget(FlugwachtApp(router: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    notifications.tap(7);
    await tester.pumpAndSettle();

    expect(find.byType(MapScreen), findsOneWidget);
    expect(router.state.uri.toString(), '/map');
  });

  testWidgets('new flight opens without the tab bar and can be closed', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('Flights'));
    await tester.pumpAndSettle();
    // A fresh install has no flight, so the empty state carries the only way
    // into the modal.
    await tester.tap(find.byType(AppPrimaryButton));
    await tester.pumpAndSettle();

    expect(find.byType(NewFlightScreen), findsOneWidget);
    expect(find.byType(AppTabBar), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(ListScreen), findsOneWidget);
    expect(find.byType(AppTabBar), findsOneWidget);
  });
}
