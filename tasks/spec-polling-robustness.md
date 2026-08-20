# Spec: Polling robustness (#151, #217, #218)

Working paper for the change; the binding project spec stays `SPEC.md`. Two
rules of `SPEC.md` change with this work and are edited in the PR that ships
them (search anchor, identity guard). This file is deleted with the rest of the
planning files in M17.

## Objective

Three findings share one root: a flight the app cannot see says nothing about
why, and two of the guards that decide whether it is looked up at all are built
on values the app never verified.

- A flight can stay unsearched for its whole flight day because one entered
  departure time was read on the wrong clock (#217).
- The state in which the user knows the least, `waiting`, is the one state with
  no explanation and no remedy (#218).
- A registration or hex flight can adopt the same airframe's next rotation and
  grow a wrong trail (#151).

Success looks like: every pollable flight is actually polled inside its flight
day window, an open sheet always says what the app is doing, and no flight ever
draws a leg that is not the one the user added.

## Capability map

| Module id | Responsibility | Depends on | Issue |
|---|---|---|---|
| `departure-time-truth` | The new-flight form never stores a clock it did not verify | - | #217 (part 1) |
| `search-anchor-floor` | The search anchor gets an upper bound | - | #217 (part 2) |
| `identity-pinning` | Registration and hex flights pin their callsign on first contact and guard it afterwards | - | #151 |
| `waiting-state-affordances` | `waiting` explains itself and offers the source switch | `search-anchor-floor` | #218 |

Build order: `departure-time-truth`, `search-anchor-floor`, `identity-pinning`
(independent of each other) then `waiting-state-affordances`.

## Assumptions

1. `SPEC.md` stays the only specification of the repository; this paper feeds
   its two rule changes and then dies with M17.
2. #217 part 1 concerns the flight-number path only. Registration and hex
   flights never have a route, their departure time is deliberately device
   time and the form already says so.
3. Polling stays foreground-only. "Since when" in the waiting copy names the
   instant the search window opened, not uptime.
4. A fix without a callsign pins nothing and rejects nothing (#151): a guard
   invented from missing data would be worse than no guard.

## Commands

Unchanged, from `SPEC.md`; run inside `app/`:

```
flutter analyze
flutter test
dart format .
```

## Project structure

No new directories. Touched trees: `app/lib/domain/` (anchor, identity),
`app/lib/ui/screens/` (new-flight form), `app/lib/ui/widgets/flight/` (sheet),
`app/lib/l10n/` (copy), mirrored under `app/test/`.

## Code style

As `SPEC.md`: English code, no comments unless they carry what the code cannot,
no abbreviations, small private widget classes, localized copy in both ARBs
with English as the template. New copy uses the informal "Du" form in German,
no emoji, en dash instead of em dash.

---

## Module: `departure-time-truth` (#217, part 1)

### Problem

`_saveFlight` stores `DepartureTimeInterpretation.device` whenever the preview
is not `FlightPreviewFound` at the moment of the tap
(`new_flight_screen.dart:364-368`), and the route lookup sits behind a 400 ms
debounce plus network requests while the save button unlocks as soon as the
flight number parses. Saving inside that gap stores the ticket's wall clock as
device time and no route. The doc comment at `new_flight_screen.dart:285-286`
promises the device clock is never a silent guess; the save path breaks that
promise.

### Change

- `NewFlightPreview` gets a fourth state, `FlightPreviewSearching`. It is
  entered as soon as the input parses as a flight number, covers the debounce
  and the request, and ends only with `FlightPreviewFound` or
  `FlightPreviewRouteUnknown`.
- The preview card renders the searching state as its own content: the card's
  existing shape, a short line plus a small progress indicator, so the state
  reads as motion and not as a result.
- The save button is disabled while the preview is searching.
- The departure-time zone row shows a searching hint instead of the device
  fallback line while the lookup runs; the fallback line stays for a resolved
  lookup without a route and for registration and hex flights.

### Acceptance criteria

- No flight can be saved while a route lookup for the entered flight number is
  pending, and the form visibly says that a lookup is running.
- A saved flight carries either a route with `originLocal` (switch on), or a
  resolved lookup with `device` - never an interpretation decided while a
  lookup was in flight.
- The zone row never announces the device fallback while the lookup runs.

### Verification

`flutter test test/ui/screens/new_flight_preview_test.dart test/ui/screens/new_flight_screen_test.dart`

- The preview reports `FlightPreviewSearching` for a parsable flight number
  before the debounce elapses.
- The submit button is disabled while searching and enabled again once the
  lookup resolves to route-unknown.
- Regression: with a route lookup that resolves late, the saved flight carries
  the route and `originLocal` instead of `device`.

### Files

`lib/ui/screens/new_flight_preview.dart`, `lib/ui/screens/new_flight_preview_card.dart`,
`lib/ui/screens/new_flight_screen.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`

---

## Module: `search-anchor-floor` (#217, part 2)

### Problem

`searchStartsAt` clamps the anchor upwards to the window start but has no upper
bound (`poll_planning.dart:20-32`). An entered time that names another zone's
wall clock, or is simply wrong by more than the two hours of lead time, moves
the anchor by the full offset and can block every request for the whole flight
day while the flight sits in `waiting`.

### Change

The anchor is clamped on both sides:

```dart
const maximumSearchDelay = Duration(hours: 6);

DateTime searchStartsAt(Flight flight) {
  final window = FlightDayWindow.forDepartureDate(flight.departureDate);
  final departureInstant = departureInstantOf(flight);
  if (departureInstant == null) {
    return window.start;
  }
  final anchor = departureInstant.subtract(searchLeadTime);
  final latest = window.start.add(maximumSearchDelay);
  if (anchor.isBefore(window.start)) {
    return window.start;
  }
  return anchor.isAfter(latest) ? latest : anchor;
}
```

A flight that has never been seen is therefore searched for from 06:00 device
local on its departure date at the latest. The lead time keeps its job for a
correctly entered time; the cap keeps one wrong number from costing a whole
window.

`SPEC.md`'s search anchor bullet (Testing Strategy) gains the cap in the same
PR: the anchor is never later than six hours after the window start.

### Acceptance criteria

- A departure time that names another zone's wall clock (17:45 at WMKK entered
  on a device in Europe/Berlin) yields an anchor no later than window start
  plus six hours.
- A departure time more than two hours later than the real departure yields the
  same bound.
- A flight without a departure time still starts with the window.
- An anchor before the window start is still clamped up to the window start.
- `SPEC.md` describes the rule that ships.

### Verification

`flutter test test/domain/poll_planning_test.dart`

### Files

`lib/domain/poll_planning.dart`, `test/domain/poll_planning_test.dart`, `SPEC.md`

---

## Module: `identity-pinning` (#151)

### Problem

The callsign cross-check only protects flight-number flights
(`poll_planning.dart:169-176`): there is an expected callsign to compare
against. A registration or hex flight that never saw its landing stays
pollable for the rest of its 48 h window, and a later poll can find the same
airframe on its next rotation, apply the fix and revive the flight on the wrong
leg.

### Change

Adopt first, then guard, for registration and hex flights:

- The first applied fix inside the flight's window whose trimmed callsign is
  not empty pins that callsign as the flight's `expectedCallsign`. Only the
  callsign is pinned; the stored hex address is left untouched.
- Once a callsign is pinned, a fix whose trimmed callsign differs is rejected
  as `PollIdentityRejected`, the same path the flight-number lookup already
  takes.
- A fix without a callsign is applied and pins nothing.
- A rejection for a registration or hex flight leaves the stored identity
  alone: the entered value is the only identity there is, and there is no
  callsign search to fall back to.
- Flight-number flights keep their current behaviour unchanged.

`SPEC.md`'s hex-safeguard bullet (Testing Strategy) gains the registration and
hex case in the same PR.

### Acceptance criteria

- A registration flight that saw a fix with callsign X rejects a later fix with
  callsign Y: no tracking update, no trail point, state stays `noSignal`.
- The same holds for a hex-entered flight.
- A first fix without a callsign is applied and leaves `expectedCallsign` null,
  so a later fix with a callsign can still pin it.
- A rejection does not clear the flight's stored hex address or lookup value.

### Verification

`flutter test test/domain/poll_planning_test.dart test/data/polling_engine_test.dart`

### Files

`lib/domain/poll_planning.dart`, `lib/data/polling_engine.dart`,
`test/domain/poll_planning_test.dart`, `test/data/polling_engine_test.dart`,
`SPEC.md`

---

## Module: `waiting-state-affordances` (#218)

### Problem

Every affordance for a missing signal is gated on `noSignal`
(`flight_sheet.dart:334-337` and `345-366`), so a `waiting` flight shows
"wartet auf Signal" and nothing else. It looks exactly like an app that is not
polling, which is what it looked like on 2026-08-20 while the app was right and
the aircraft was genuinely absent from every feeder network.

### Change

An open sheet of a `waiting` flight shows an info box in the same shell as
`NoSignalInfoBox`, with two variants decided by `searchStartsAt(flight)`
against the clock:

- Search running: names the identity the app is searching for
  (`flight.lookupValue`, the way every screen names a flight) and the instant
  the search started, plus the existing reassurance that receivers are often
  missing for one to two hours.
- Search not started yet: names the instant it will start and why, instead of
  an unexplained wait.

The footer's source-switch link is offered for a `waiting` flight whose search
is running. A flight whose search has not started yet does not get the link:
the active source is not the reason it sees nothing, and offering the remedy
there would point at the wrong cause.

The list row is unchanged: `flightRowWaitingForSignal` stays one short line.

New copy, English template plus German:

| Key | English |
|---|---|
| `mapSheetWaitingInfo` | Searching for {identity} since {time}. Receivers are often missing for one to two hours, the trail starts as soon as one sees the aircraft. |
| `mapSheetWaitingScheduledInfo` | The search for {identity} starts at {time}. Until then a flight with the same number from yesterday could be mistaken for this one. |

### Acceptance criteria

- An open sheet of a `waiting` flight whose search is running states that the
  app is searching, for which identity and since when, and offers the source
  switch.
- An open sheet of a `waiting` flight whose search has not started yet names
  the instant it will start.
- The list row of a waiting flight still reads as one short line.
- Nothing changes for `live`, `noSignal`, `planned`, `ended` or `missed`.

### Verification

`flutter test test/ui/widgets/flight/flight_sheet_test.dart test/ui/widgets/flight/flight_row_test.dart`

### Files

`lib/ui/widgets/flight/flight_sheet.dart`,
`lib/ui/widgets/flight/no_signal_info_box.dart` (or a sibling for the waiting
variant), `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`,
`test/ui/widgets/flight/flight_sheet_test.dart`

---

## Testing strategy

As `SPEC.md`: only the app's own behaviour, `flutter_test`, headless. Domain
changes are proven in `test/domain/`, the polling side in `test/data/`, and the
new copy through widget tests that assert what the sheet says in each waiting
variant. No test asserts framework behaviour, and no test does live HTTP.

## Boundaries

**Always:** run `flutter analyze` and `flutter test` before each commit; keep
copy localized in both ARBs; keep the design tokens and the 44 px hit target of
the source-switch link; one PR per module against `main`, merged only after
Manuel's approval.

**Ask first:** any further change to the flight day window or the state
machine; a drift schema change (none is planned, the pinned callsign uses the
existing `expectedCallsign` column).

**Never:** poll outside a flight's window; merge sources; introduce background
polling; change the `noSignal` copy that already works.

## Delivery

Milestone M17 Cleanup, one PR per module in build order. #217 is referenced by
two PRs (`Refs #217`), the second one closes it; #151 and #218 are closed by
their own PR.

## Success criteria

- A flight entered with a foreign departure time is polled inside its window,
  proven by a domain test on the anchor.
- A flight saved during a pending route lookup carries a verified clock.
- A registration flight cannot adopt its airframe's next rotation.
- A waiting flight's sheet always answers "is this thing even looking?".
- `flutter analyze` clean, all tests green, `SPEC.md` matching the shipped
  rules.

## Open questions

- The save gate blocks for as long as the route lookup runs. Its bound is the
  `RouteLookup` timeout of 10 s per request, and a dead network resolves at the
  first timeout. Accepted as is unless the wait should get its own deadline.
- The source-switch link is deliberately withheld from a waiting flight whose
  search has not started yet, which reads the acceptance criterion of #218
  narrowly. Say so if it should show for every waiting flight.
