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
  there, and the marketing site in `website/` — run all npm/Angular commands
  there. A `backend/` (later expansion stage) may join them.
- The logo masters live in `app/assets/logo/` because Flutter only bundles
  assets from inside the package; the app renders them with `flutter_svg`.
  The app-icon masters stay in `assets/icon/`, they are build-time input only.

## Website

`website/` is the flugwacht.app one-pager: an Angular app built to fully static
HTML, light mode only, English at the root and German under `de/`. There is no
server, no analytics and no third-party request at runtime. Its own README
covers the commands; what is not obvious from the code:

- **Every asset path must be absolute.** The localized build copies the whole
  public folder into each locale's output, and the German bundle carries
  `<base href="/de/">`, so a relative `fonts/…` would quietly resolve to the
  `de/` copy: it loads, but the German page then re-downloads every font and
  image the English page already cached. Absolute paths give each asset one
  canonical URL and leave the per-locale duplicates unused.
- The locale layout comes from the `i18n` block in `angular.json`
  (`subPath: ""` for `en`, `"de"` for `de`) plus `localize: true`. The root
  component writes `LOCALE_ID` onto the document element, because the localized
  build does not set `<html lang>` by itself.
- Translations are keyed by stable custom ids (`@@hero.title` style) and live in
  `src/locale/messages.de.xlf`; `npm run extract-i18n` regenerates the source
  `messages.xlf`. `i18nMissingTranslation` is `error`, so a forgotten German
  string fails the build rather than shipping English. Copy that would repeat in
  a template loop is written as `$localize` in the component instead.
- The hero teaser is also the meta description, so it lives once in
  `site-copy.ts` and is imported by both.
- **No arbitrary Tailwind values anywhere** (`p-[10px]` and the like). Every
  value the design prescribes resolves to a stock utility; the three brand
  yellows are registered as `brand-yellow`, `brand-accent` and `brand-orange`.
- A base-layer rule in `styles.css` gives every `h1`–`h6` Bebas Neue, uppercase
  and `leading-none`, so heading copy is authored in sentence case and the
  accessible name stays readable. The FAQ question is the one deliberate
  exception and undoes it with `font-sans normal-case leading-normal`.
- Bebas Neue and Barlow are self-hosted as WOFF2 under `public/fonts/`,
  converted from the same TTFs the app bundles, with their OFL licenses.
- Hit targets are at least 44 px everywhere. Where the design's spacing is
  tighter than that, the target is grown with padding and pulled back with a
  negative margin on the surrounding stack (see the footer link columns), so the
  layout keeps its designed spacing.
- Font Awesome Pro comes from a private registry. The committed `.npmrc`
  references `${FONTAWESOME_NPM_TOKEN}`; without it `npm ci` fails with
  `npm error code E401`. A warm npm cache hides that, so verify with a cold one.

## Pipelines & Deployment

Every pipeline is scoped by area: the website is `website/**`, and the app is
everything the website is not, so a change to shared ground (workflows, tooling,
the repository root) keeps building the app instead of losing its coverage to an
outdated path list. `.github/actions/changed-areas` is the one place that draws
that line.

- **A required check has to report, so the job is skipped, not the workflow.** A
  workflow a `paths` filter kept from starting leaves its check pending forever
  and blocks the merge, while a job skipped by an `if` reports success. That is
  why `build.yml` calls `android.yml`/`ios.yml` unconditionally and passes
  `enabled: false`: an `if` on the calling job would rename the check from
  `build-android / build` to `build-android` and leave the required name
  pending. Workflows without a required check (`cd.yml`, `deploy.yml`,
  `deploy-preview.yml`) do use plain `paths` filters, which start no runner at
  all.
- Deploying replaces the contents of `deployment/production` with the build
  output; Netcup (Plesk) pulls that branch through a GitHub webhook. Every pull
  request touching the website publishes to `deployment/preview` the same way,
  served by an access-restricted subdomain. All pull requests share that branch,
  so the last build wins. Both run the same reusable `website-deploy.yml`,
  parameterised by environment, url and branch. Neither a fork's pull request nor
  Dependabot's gets a preview, because neither can reach the secrets.
- **Production pins `ref: main`, the preview follows its trigger.** Without the
  pin a manual `workflow_dispatch` would publish whatever branch the dropdown
  offered straight to flugwacht.app, and two merges landing seconds apart could
  leave the older build on top: the concurrency group serializes the runs but
  does not order them.
- The publish job declares its environment, so an environment-scoped secret
  silently beats the organization one of the same name that `secrets: inherit`
  carries. Both environments hold none today, and duplicating
  `FONTAWESOME_NPM_TOKEN` or the bot key there would surface as an install or
  token failure, not as a configuration error.
- `build-id.txt` beside the site holds the tree hash of the output. An unchanged
  build keeps its id and produces no commit, and because it is served live it is
  the only way to tell whether Plesk has pulled the newest build yet.
- The nightly linkinator run goes against the live site rather than the build
  output, so a file the hosting does not serve fails too. The root
  `linkinator.config.json` keeps a local run identical to CI.

## Localization

The app builds its Material surface on `material_ui`, whose
`MaterialLocalizations` is a different type from the one
`package:flutter/material.dart` still carries. `flutter_localizations` serves
the legacy type, so the generated `AppLocalizations.localizationsDelegates`
never satisfies a `material_ui` widget: English survives on the built-in
`DefaultMaterialLocalizations`, every other locale asserts. What the app and
the widget tests pass instead is `appLocalizationDelegates`
(`app/lib/l10n/app_localization_delegates.dart`), which pairs the generated
delegate with `material_ui`'s own `GlobalMaterialLocalizations.delegates`, a
list that already carries the Cupertino and Widgets delegates. `gen_l10n` has
no option to emit that, so the generated list stays wrong and unused.

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

## The flight card

An armed flight shows a card for its flight day. What the card is differs per
platform, but everything above the platform is shared: `planLiveActivityAction`,
`liveActivityStaleIn` and the flight state machine decide, and one
`LiveActivityService` implementation per platform carries it out. `main.dart`
picks which, and the copy is chosen the same way (see the Copy section below).

### iOS Live Activity

The Lock Screen card lives in its own widget extension target
(`FlugwachtLiveActivityExtension`, `app/ios/FlugwachtLiveActivity/`), driven
from Dart through the `live_activities` plugin. The app pins upstream's
(`istornz/flutter_live_activities`) `main` by commit in `app/pubspec.yaml`
instead of taking the package from pub.dev: the released 2.5.1 never passes
ActivityKit's relevance score and updates a card through the deprecated call
that carries no `ActivityContent`, so neither the score nor the stale date can
be renewed. `main` carries both, and until a release ships them the dependency
stays a git one. What else is not obvious from the code:

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
  date passes. Every put therefore has to renew that date, which is what the
  `ActivityContent` update path is for.
- The Dynamic Island shows at most two cards and picks them by relevance score,
  which also orders the Lock Screen. `liveActivityRelevanceOf` derives it from
  the flight state, so a flight in the air outranks one that has not left yet.
  A card that never sets a score sits at 0.0, which is why the app must send
  one on every put. Only `waiting`, `noSignal`, `live` and the grace period of
  a landed card ever reach ActivityKit: `planLiveActivityAction` keeps no card
  for a flight outside its flight day and ends a running one without a last
  put, so a `planned` or `missed` score would never be sent.
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

### Android card

An ongoing notification on the `flight_card` channel, built entirely on
`flutter_local_notifications`, which the app already uses for its other
notifications. No native code, no extra permission, and it works on every
supported Android version.

- Deliberately **not** Android 16's promoted "Live Updates" surface (status bar
  chip, Samsung Now Bar). `setRequestPromotedOngoing` only exists from API 36.1,
  and Google's guidance rules out "activities triggered by third parties", which
  a flight someone else operates sits close to. What the app builds is what a
  promoted notification degrades to below that version, so nothing is lost if
  this is ever revisited. Custom `RemoteViews` layouts are out for the same
  reason: they disqualify promotion permanently (#149).
- **The card's channel keeps `IMPORTANCE_DEFAULT` and its sound.** Silent and
  lock-screen-visible are the same switch on Android, and there is no
  configuration that has both: a channel below the default importance is classed
  as silent, and so is one at the default whose sound is taken away (verified on
  a Pixel, 2026-08-23). So the card announces itself once, `onlyAlertOnce` keeps
  every later put quiet, and a user who wants it silent says so in the system
  settings. A channel's importance is fixed at creation: changing it in code
  does nothing to an installed app, so testing a change to it needs a reinstall
  or cleared app data.
- `setUsesChronometer` plus `setChronometerCountDown` is the one thing Android
  draws by itself while the app is closed, and it is the whole point of the
  card. The progress bar is **not** self-running, unlike iOS's
  `ProgressView(timerInterval:)`, so it only moves on app runs.
- Android has no counterpart to iOS's stale date. The same effect is scheduled
  by hand: a second notification under the card's own id, due when the numbers
  stop being true, replaces the card with one that no longer counts. That is why
  the card and its stale update share a notification slot.
- `zonedSchedule` throws on a date in the past, measured against the real clock
  rather than the moment handed in. Tests that reach it need a date ahead of the
  wall clock.
- Every notification slot a flight can occupy is handed out by
  `notification_ids.dart`, cards included, so nothing can cancel or replace
  another notification by accident. Inside one slot it is the opposite on
  purpose: a kind's immediate notification and the reminder pre-scheduled under
  the same id are meant to replace each other, and `cancel` takes a delivered
  notification off the shade just as readily as a pending one. Two rules follow,
  both of them #305: `FlightNotifier` settles the schedule before it delivers
  any event, and it cancels only what `claimArrivingSoonSchedule` confirms was
  still pending, so a poll working from an older copy of the flight cannot take
  a notification another poll has already delivered.
- The card is ended through Android's `timeoutAfter` rather than a scheduled
  dismissal, which Android does not have. `presenceOf` reads
  `getActiveNotifications`: Android never ends a card on its own, so a missing
  one means the user swiped it away.
- A tap on a card reaches the app through the notification service, which
  already receives every payload. The Android `LiveActivityService` therefore
  hands up no tapped flights of its own, and reporting them twice would open the
  flight twice.
- `relevanceScore` has no Android counterpart and is not part of the shared
  service contract; the iOS implementation derives it from the flight itself.

### Copy

Two copy sets, one per platform: iOS keeps Apple's "Live Activity" and "Lock
Screen", Android names the effect instead of a feature, because it has no
established term and Google's "Live Updates" would promise the promoted surface
the app does not build. `live_activity_labels.dart` picks between them off
`defaultTargetPlatform`, and every string exists twice in the ARB files
(`liveActivity*` versus `lockScreen*`).

The card's copy formats times outside any widget, so `main.dart` calls
`initializeDateFormatting` before the polling engine starts. Nothing else loads
the locale's date symbols before the first frame, and the failure would be a
silent missing card rather than a crash.

## Credentials

- The repo will become public. Never commit credentials, tokens, or license
  keys — not in config files and not in the history. Anything that needs
  credentials (e.g. the Font Awesome Pro setup) is configured outside the repo
  (environment variables, host configuration) and only documented in the repo
  as placeholders/instructions.
