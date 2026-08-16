# Spec: Flugwacht

Binding foundation: `design_handoff_flugwacht/flugwacht-fachkonzept.md` (domain
concept) and `design_handoff_flugwacht/README.md` (design handoff) — both German,
kept locally outside the repo. This spec summarizes them, adds technical
decisions, and slices the work into small increments — if they conflict, the
handoff wins.

## Objective

Flugwacht is a deliberately minimal flight tracker (Flutter, iOS + Android) for
individual, manually added flights: enter a flight number and departure date
(plus an optional note), and on the day of the flight the app tracks it
automatically and shows it live on a map. The one question that matters:
*Where are they right now, and when will they arrive?* Typically 1–3 flights at
a time; any feature that does not serve this question does not belong in the app.
The app's UI is multilingual via Flutter's gen-l10n: English is the base
language, German is the second language (informal "Du" form, no emoji).

**Two-stage approach:**

1. **Phase 0 — spike (throwaway code):** feasibility check that live data from
   a provider can be fetched and shown on a map. Deleted completely after the
   proof. *(Done: feasibility confirmed, spike removed.)*
2. **App implementation in small increments** (milestones below), each one
   individually plannable, implementable, and verifiable.

**Planning & tracking on GitHub:** one GitHub milestone per increment, one issue
per task; reviews and feedback happen in issue comments. Implementation is
PR-based: `main` is protected, work happens on `feature/`/`fix/` branches,
merging only after Manuel's approval (details: `.claude/CLAUDE.md`). The repo
holds only this spec as a working copy — it and all other planning files are
deleted once the app is finished (M16; git history keeps them).

## Tech Stack

| Area | Decision |
|---|---|
| Framework | Flutter 3.44.9 (fvm pin in `.fvmrc`), Dart SDK ^3.12.2 |
| State management | `signals` |
| Persistence | `drift` (SQLite) for flights + trail points |
| Settings | `shared_preferences` (`SharedPreferencesAsync`) for the active source and the map style, later the units |
| Routing | `go_router` (tab shell map · list · more + modal "new flight" screen) |
| Map (OSM raster) | `flutter_map` with OSM tiles; the tile user agent carries the bundle ID read via `package_info_plus`, caching is flutter_map's built-in tile cache at its defaults |
| Map (reduced style) | `vector_map_tiles` renders OpenFreeMap's keyless OpenMapTiles vector tiles with a minimal theme built in Dart from the app tokens (light + dark); the tile template comes from the TileJSON because OpenFreeMap moves it with every weekly planet run |
| HTTP | `http`, one source adapter behind an interface (sources are field-identical) |
| Fonts | Bebas Neue + Barlow, bundled at build time — never downloaded at runtime; shipped as assets (plain pubspec `fonts:` or `google_fonts` with local files, decided in M1.3), OFL licenses included |
| Localization | `flutter_localizations` + `intl` via gen-l10n (`l10n.yaml`, ARB files); English is the base/template language (`app_en.arb`), German the second language; device language selects the locale, English is the fallback; set up early (M1.6) so no string is ever hard-coded |
| Icons | Font Awesome Pro `regular` via `font_awesome_flutter` + kit 85fa8e3a78; SVG fallback available locally |
| Notifications | `flutter_local_notifications`, local only, no backend |
| Date and time | native system pickers (`showDatePicker` / `showTimePicker`, `CupertinoDatePicker`); the departure time is optional |
| Time zones | `lat_lng_to_timezone` maps the destination's coordinates to an IANA zone, `timezone` converts the arrival instant into it — both offline; the full database variant is required because the reduced ones drop linked zones like Europe/Amsterdam |

Dependency versions are always looked up at add time (pub.dev), never guessed.

**Data sources** (exactly one active, no merging, no failover; rate limit
1 request/s per source): adsb.lol (default) · adsb.fi · airplanes.live. Route
resolved separately via `vradarserver/standing-data` (local copy preferred),
once per flight, cached. Explicitly rejected: OpenSky, own receiver, history,
paid sources.

## Commands

```
cd app

Setup:    flutter pub get
Analyze:  flutter analyze
Format:   dart format .
Tests:    flutter test
App:      flutter run                 (on the host: iOS simulator/device)
Sandbox:  flutter run -d web-server   (fallback only; no iOS/Android builds in the sandbox)
```

Icon exports are regenerated with `tools/icon-generator/generate-icons.sh`
from the repo root (requires Docker; renders via a pinned librsvg container);
the script is idempotent, writes the staging exports to
`assets/icon/generated/`, and copies them into `app/ios/` and `app/android/`.

## Project Structure

```
app/       → Flutter app (iOS + Android)
  lib/data/    → source adapters (readsb API), fix normalization, route lookup, drift DB
  lib/domain/  → models (Flight, Fix, Route), state machine, arrival estimate
  lib/ui/      → screens (map, list, new flight, settings), widgets, theme/tokens
  test/        → mirrors lib/ (data/, domain/, ui/)
assets/    → repo-level branding: logo/ (mark + lockup SVGs), icon/ (SVG masters + generated/ platform exports)
tools/     → repo-level tooling; icon-generator/ renders all launcher/store images from the SVG masters
website/   → project website (planned, does not exist yet)
backend/   → possible later expansion stage (only if unavoidable — Manuel's call)
design_handoff_flugwacht/ → design reference, untracked local copy; deleted in M16
```

## Code Style

English code, zero comments by default, no abbreviations in identifiers,
`flutter_lints`, small composed widgets with `const` constructors, private
widget classes instead of helper methods. Example of the intended style:

```dart
class FixTimestamp {
  static DateTime fromSeenPos({required double seenPosSeconds, required num serverNowMilliseconds}) {
    final milliseconds = (serverNowMilliseconds - seenPosSeconds * 1000).round();
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }
}
```

UI copy is localized from the start — no hard-coded strings in widgets; English
is the base language, German copy uses the informal "Du" form, no emoji in
either language. Design tokens exactly as in the
handoff README (yellow trio `#ffeb3b`/`#ffc107`/`#ffa726` never substituted,
Bebas Neue + Barlow, 4px grid, hit targets ≥ 44px, motion 150–200ms
ease-in-out).

## Testing Strategy

`flutter_test`; tests run headless in the sandbox. Only the app's own behavior
is tested — focused on the domain, where the known pitfalls live:

- Fix normalization: `alt_baro == "ground"`, `track` instead of `heading`,
  `seen_pos` + server `now` → absolute UTC timestamp, callsign trimming
  (8 characters, space-padded)
- State machine: planned → waiting → live ⇄ no signal → ended | missed —
  derived from the flight's facts and the clock, never stored. Flight-day
  window: 00:00 local on the departure day until 24:00 local on the following
  day (nominal 48 h), half-open, recomputed from the calendar components at
  every evaluation so it crosses midnight and DST by construction. Freshness
  threshold `maximumLivePositionAge` (15 min, also used by the M8 freshness
  display); a position timestamped in the future counts as fresh. Landing ends
  a flight early (ever airborne + last known on ground → ended), an approved
  deviation from the domain concept, which binds ended to the window end
- Hex safeguard: callsign cross-check on hex queries, fall back to callsign
  search on mismatch
- Search anchor: a flight that has never been seen is only searched for from
  its scheduled departure minus 2 h (clamped to the window start), so the
  previous day's rotation of a daily callsign is not adopted at midnight;
  without a stored time the search starts with the window
- IATA→ICAO mapping including Ryanair/Wizz/easyJet detection
- Arrival estimate: remaining great-circle distance / ground speed, anchored
  on the fix timestamp so a position that stops coming in freezes its
  estimate; no estimate without a route, without a position, on the ground,
  or below a ground speed of 50 kn
- Source adapter: request URLs per source and lookup kind (registration path
  differs on airplanes.live), empty `ac` array as successful empty result,
  network errors / non-2xx / malformed payloads mapped onto the sealed result —
  via `MockClient`, no live HTTP in tests
- Rate limiting: ≥ 1 s start-to-start spacing per source, serialization, FIFO
  order, per-source independence — driven by `fake_async`, the suite never
  really waits; the limit applies per adapter instance, so the app constructs
  exactly one adapter per source

Widget tests only for own behavior (e.g. the state timeline renders the correct
active state), no framework tests.

## Boundaries

**Always:**
- Respect the 1 request/s rate limit per source; exactly one active source,
  never merge
- Fix normalization as defined in the domain concept (binding), trail points
  carry their source ID
- Treat coverage gaps as a regular state, never as an error UI
- Attribution visible (active source + © OpenStreetMap, plus © OpenMapTiles while the reduced style renders)
- `flutter analyze` + `flutter test` before every commit; conventional commits,
  title line only
- Take design tokens and measurements pixel-perfect from the handoff README

**Ask first:**
- New dependencies beyond the ones defined above
- Deviations from the hi-fi design or the domain concept
- Background polling approach (iOS BGTaskScheduler limits — per the handoff,
  explicitly to be decided with the user)
- drift schema changes after the schema's first release

**Never:**
- Reintroduce OpenSky, an own receiver, history, or paid sources
- Add a backend/server/accounts to the core tracking (per the handoff,
  everything stays local on the device); a backend as a later expansion stage is
  Manuel's explicit call
- Demo flight in the empty state
- Substitute brand colors
- Commit or push directly to `main` (PR workflow); merge PRs without approval
- Commit credentials, tokens, or license keys — the repo will become public
- Modify the design handoff folder (exception: deletion in M16)
- Add features that are not in the handoff

## Increments (milestones of the app implementation)

Ordered by dependency; each increment is broken into GitHub issues before
implementation (one milestone per increment), implemented, tested, and committed
(commits reference their issue). Detailed design and measurements per screen:
handoff README.

| # | Increment | Core |
|---|---|---|
| M1 | Foundation | Theme/tokens, fonts, FA Pro setup, tab scaffold with go_router (map · list · more), light/dark, localization scaffold, CI/CD (format/analyze/test, Android + iOS builds, automated delivery to TestFlight and the Play internal test track), app icons + app name + launch screens |
| M2 | Domain core | Fix model + normalization, source adapter (readsb interface, 3 sources), tests |
| M3 | Flight model | Flight + state machine (6 states, midnight-crossing window), tests |
| M4 | Persistence | drift schema: flights + trail points (with source ID), auto cleanup after 24 h |
| M5 | New flight | Modal form, segmented control (flight number/registration/hex), IATA→ICAO, route lookup (standing-data), "found" preview card, native date picker plus an optional departure time |
| M6 | List | Hero cell with mini map, state timeline, regular/planned rows, empty state, FAB, "past" section |
| M7 | Map | Full-screen `flutter_map`, markers + ping, trail (flown/planned), bottom sheet (peek/open), flight switching via swipe/tap |
| M8 | Polling | Foreground polling engine, live ⇄ no-signal transitions, hex↔callsign safeguard, freshness display |
| M9 | Arrival | Estimate (remaining distance / ground speed), destination local time + user time, "~" display for stale data |
| M10 | Sources | Switcher, trail segments colored per source, legend card, "try another source" |
| M11 | Map style | Reduced style + toggle button, persist the choice (technology decision here) |
| M12 | Settings | Source, units (metric/aviation), notification switches, footnotes |
| M13 | Notifications | Local: departed · arriving soon (~30 min) · landed |
| M14 | Background | Feasibility of background polling (iOS limits) — investigation, decision with the user |
| M15 | Polish | About/licenses page, "ended/missed" detail states |
| M16 | Cleanup | Delete `SPEC.md`, the local design handoff folder, and any remaining planning files; check for spike leftovers |

## Success Criteria (app overall)

- All screens match the hi-fi board pixel-perfect (light + dark)
- An added flight runs through the state sequence correctly and survives app
  restarts
- Coverage gaps and "route unknown" appear as regular states
- `flutter analyze` clean, all tests green

## Open Questions

- Background polling on iOS (M14, with the user)
- FA Pro kit setup may need the user's license access on the host
- Content of the about/licenses page (M15)
