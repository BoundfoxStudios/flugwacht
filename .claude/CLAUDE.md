# Flugwacht — Project Rules

## Language

- Everything in the repository and on GitHub is written in English: docs, spec,
  README, issues, milestones, PRs, code, commits. German is used only in the
  chat with Manuel. The app's own UI copy is German (product decision from the
  design handoff).

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
  reference their issue. The spec lives in `SPEC.md`; spec discussions happen
  directly in the chat.
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
