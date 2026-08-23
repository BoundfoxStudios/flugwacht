# Flugwacht — Project Rules

## Reference Files

- `domain.md` (this folder): binding domain invariants – fix normalization,
  identity and route rules, coverage gaps, state machine, source rules, and
  the standing local-only boundary.
- `design.md` (this folder): binding design rules and the never-do list –
  brand, typography, layout and motion, language and copy.

## Language

- Everything in the repository and on GitHub is written in English: docs,
  README, issues, milestones, PRs, code, commits. German is used only in the
  chat with Manuel. The app's own UI copy is German (a deliberate product
  decision).

## Git & GitHub

- Unlike the global rule, Claude may push in this project.
- PR-based workflow: `main` is protected, no direct commits or pushes to
  `main`. All work happens on a `feature/` or `fix/` branch and goes through a
  pull request against `main`.
- PRs are merged only after Manuel's approval (PR approval or comment); never
  merge without it. Merge method: plain merge commit — no rebase, no squash.
  The merge commit is the only commit that does not follow conventional
  commits; every regular commit does (keeps a later release-please adoption
  possible).
- Planning and tracking happen through GitHub issues and milestones; commits
  reference their issue.
- Never append commits to a PR that is already under review — Manuel merges
  quickly, and late pushes get orphaned by the branch auto-delete. New changes
  get their own small PR.

## Repository Layout

- Monorepo: the Flutter app lives in `app/` — run all Flutter/Dart commands
  there. `website/` (planned) and possibly `backend/` (later expansion stage)
  will join next to it.
- The logo masters live in `app/assets/logo/` because Flutter only bundles
  assets from inside the package; the app renders them with `flutter_svg`.
  The app-icon masters stay in `assets/icon/`, they are build-time input only.

## Callsigns

A flight number is not the string an aircraft transmits, and the two are kept
apart:

- The stored identity is the standing data's form, which strips a short
  number's leading zeros (`CFG16`), while aircraft transmit it padded to three
  digits (`CFG016`). The live sources match the exact string, so a callsign
  query always carries both forms. A flight number the user typed is stored as
  typed, zeros included.
- An airline that markets a flight under a number of its own puts a marketing
  digit in front of the number it files: Condor sells DE2016 and flies as
  CFG016. No rule derives that. The standing data gives it away by carrying
  the same route under both numbers, which is the only evidence the app
  accepts, and only for a number of the full four digits.

## iOS Live Activity

The Lock Screen card lives in its own widget extension target
(`FlugwachtLiveActivityExtension`, `app/ios/FlugwachtLiveActivity/`), driven
from Dart through the `live_activities` plugin. What is not obvious from the
code:

- The extension's folder is a synchronized group: files dropped into it join
  the target automatically, resources included. That is why Bebas Neue and
  Barlow sit there a second time — the extension has its own bundle and cannot
  reach the Flutter assets.
- **`Embed Foundation Extensions` must run before Flutter's `Thin Binary`
  script phase.** Xcode appends new embed phases at the end, which makes every
  build fail with a dependency cycle.
- The attributes type has to be named exactly `LiveActivitiesAppAttributes` and
  carry exactly `id: UUID` plus a `ContentState` with `appGroupId`. It is the
  plugin's contract; a renamed or extended type makes ActivityKit accept the
  activity and never show it.
- The card's data does not travel in the activity. The plugin writes it into
  the App Group under `"<attributes.id>_<key>"`, and the extension reads it
  from there through `context.attributes`.
- Every payload carries every key. The plugin only clears a key that arrives
  as an explicit null, and a create would throw on one — so a fact that stops
  applying is sent as an empty string or a zero timestamp, never omitted.
- `getAllActivitiesIds()` does **not** answer in the ids the app starts cards
  with — it returns ActivityKit's own. Use `getActivityState(activityId)`,
  which matches the custom id.
- Only the documented self-updating views keep running while the app is
  closed: `Text(timerInterval:)` and `ProgressView(timerInterval:)`. They do
  not expose their current value, so nothing can be positioned along them.
- Everything else on a closed card is redrawn exactly once: when the stale
  date passes. The plugin hands that date to the system only where it creates
  an activity, so `LiveActivityStaleDate` in the app target renews it on every
  put — it finds the card by the url in its payload, because the plugin keeps
  the hash of the app's activity id to itself.
- iOS ends a card on its own after eight hours and leaves it on the Lock
  Screen for up to four more. Dropping such a card's id without dismissing the
  card first puts the flight's next one beside it instead of in its place. An
  unanswered `getActivityState` is not that case: right after a cold start
  ActivityKit has not always loaded its activities, and a card it stays silent
  about is left alone.
- `app/ios/Runner/` is a plain group, unlike the extension's folder: a file
  added there reaches the target only through `project.pbxproj` (build file,
  file reference, group children, sources phase).
- A widget extension hosts only widget previews. A plain SwiftUI `#Preview` in
  that target fails with "Unsupported preview type" and can wedge Xcode.
- `flutter pub get` on Linux empties the generated Swift package that wires the
  iOS plugins. After working in the sandbox, run `flutter build ios
  --config-only` on the Mac before building in Xcode.

## Credentials

- The repo will become public. Never commit credentials, tokens, or license
  keys — not in config files and not in the history. Anything that needs
  credentials (e.g. the Font Awesome Pro setup) is configured outside the repo
  (environment variables, host configuration) and only documented in the repo
  as placeholders/instructions.
