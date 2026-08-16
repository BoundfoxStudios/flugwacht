import 'package:flugwacht/main.dart';
import 'package:flugwacht/ui/screens/list_screen.dart';
import 'package:flugwacht/ui/screens/map_screen.dart';
import 'package:flugwacht/ui/screens/more_screen.dart';
import 'package:flugwacht/ui/screens/new_flight_screen.dart';
import 'package:flugwacht/ui/widgets/app_primary_button.dart';
import 'package:flugwacht/ui/widgets/app_tab_bar.dart';
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

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(find.byType(ListScreen), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.byType(MoreScreen), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.byType(MapScreen), findsOneWidget);
  });

  testWidgets('new flight opens without the tab bar and can be closed', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.text('List'));
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
