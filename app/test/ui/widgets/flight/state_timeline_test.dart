import 'package:flugwacht/domain/flight_state.dart';
import 'package:flugwacht/l10n/app_localization_delegates.dart';
import 'package:flugwacht/l10n/app_localizations.g.dart';
import 'package:flugwacht/ui/theme/app_theme.dart';
import 'package:flugwacht/ui/theme/app_tokens.dart';
import 'package:flugwacht/ui/widgets/flight/state_timeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> pumpTimeline(
  WidgetTester tester, {
  required FlightState state,
  StateTimelineVariant variant = StateTimelineVariant.labeled,
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
}) => tester.pumpWidget(
  MaterialApp(
    locale: locale,
    localizationsDelegates: appLocalizationDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: switch (brightness) {
      Brightness.light => buildLightTheme(),
      Brightness.dark => buildDarkTheme(),
    },
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: StateTimeline(state: state, variant: variant),
      ),
    ),
  ),
);

List<BoxDecoration> dotsOf(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(StateTimeline),
        matching: find.byType(Container),
      ),
    )
    .map((container) => container.decoration)
    .whereType<BoxDecoration>()
    .toList();

List<Color> connectorsOf(WidgetTester tester) => tester
    .widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(StateTimeline),
        matching: find.byType(ColoredBox),
      ),
    )
    .map((box) => box.color)
    .toList();

void main() {
  testWidgets('fills the passed dots and leaves the coming ones hollow', (
    tester,
  ) async {
    await pumpTimeline(tester, state: FlightState.live);

    final dots = dotsOf(tester);
    expect(dots, hasLength(4));
    expect(dots[0].color, AppColors.neutral700);
    expect(dots[1].color, AppColors.neutral700);
    expect(dots[2].color, AppColors.amber);
    expect(dots[2].border?.top.color, AppColors.neutral800);
    expect(dots[3].color, AppColors.white);
    expect(dots[3].border?.top.color, AppColors.neutral300);
  });

  testWidgets('marks the dot of the current state', (tester) async {
    await pumpTimeline(tester, state: FlightState.planned);

    final dots = dotsOf(tester);
    expect(dots[0].color, AppColors.amber);
    expect(dots[1].color, AppColors.white);
  });

  testWidgets('switches the connector color after the current dot', (
    tester,
  ) async {
    await pumpTimeline(tester, state: FlightState.waiting);

    expect(connectorsOf(tester), [
      AppColors.neutral700,
      AppColors.neutral200,
      AppColors.neutral200,
    ]);
  });

  testWidgets('adds the no-signal dot only while it is the current state', (
    tester,
  ) async {
    await pumpTimeline(tester, state: FlightState.noSignal);
    expect(dotsOf(tester), hasLength(5));
    expect(find.text('no signal'), findsOneWidget);

    await pumpTimeline(tester, state: FlightState.live);
    expect(dotsOf(tester), hasLength(4));
    expect(find.text('no signal'), findsNothing);
  });

  testWidgets('draws the current no-signal dot hollow instead of amber', (
    tester,
  ) async {
    await pumpTimeline(tester, state: FlightState.noSignal);

    final current = dotsOf(tester)[3];
    expect(current.color, AppColors.white);
    expect(current.border?.top.color, AppColors.neutral700);
  });

  testWidgets('draws the current no-signal dot hollow in the dark theme', (
    tester,
  ) async {
    await pumpTimeline(
      tester,
      state: FlightState.noSignal,
      brightness: Brightness.dark,
    );

    final current = dotsOf(tester)[3];
    expect(current.color, AppColors.neutral800);
    expect(current.border?.top.color, AppColors.neutral300);
  });

  testWidgets('emphasizes the label of the current state', (tester) async {
    await pumpTimeline(tester, state: FlightState.live);

    expect(
      tester.widget<Text>(find.text('planned')).style?.color,
      AppColors.neutral400,
    );
    final current = tester.widget<Text>(find.text('live'));
    expect(current.style?.color, AppColors.neutral800);
    expect(current.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('paints the active dark label amber, except for no signal', (
    tester,
  ) async {
    await pumpTimeline(
      tester,
      state: FlightState.live,
      brightness: Brightness.dark,
    );
    expect(
      tester.widget<Text>(find.text('live')).style?.color,
      AppColors.amber,
    );

    await pumpTimeline(
      tester,
      state: FlightState.noSignal,
      brightness: Brightness.dark,
    );
    expect(
      tester.widget<Text>(find.text('no signal')).style?.color,
      AppColors.neutral50,
    );
  });

  testWidgets('leaves out the labels in the compact variant', (tester) async {
    await pumpTimeline(
      tester,
      state: FlightState.live,
      variant: StateTimelineVariant.compact,
    );

    expect(find.byType(Text), findsNothing);
    expect(dotsOf(tester), hasLength(4));
  });

  testWidgets('announces the current state in both variants', (tester) async {
    await pumpTimeline(tester, state: FlightState.noSignal);
    expect(find.bySemanticsLabel('no signal'), findsOneWidget);

    await pumpTimeline(
      tester,
      state: FlightState.noSignal,
      variant: StateTimelineVariant.compact,
    );
    expect(find.bySemanticsLabel('no signal'), findsOneWidget);
  });

  testWidgets('renders the german copy', (tester) async {
    await pumpTimeline(
      tester,
      state: FlightState.noSignal,
      locale: const Locale('de'),
    );

    expect(find.text('geplant'), findsOneWidget);
    expect(find.text('wartet'), findsOneWidget);
    expect(find.text('kein Signal'), findsOneWidget);
    expect(find.text('beendet'), findsOneWidget);
  });
}
