<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="app/assets/logo/logo-dark.svg">
    <img src="app/assets/logo/logo-light.svg" alt="Flugwacht logo: a stylized radar eye" width="96">
  </picture>
</p>

<h1 align="center">Flugwacht</h1>

A deliberately minimal flight tracker for individual, manually added flights —
a Flutter app for iOS and Android. The app's user interface is in German.

Flugwacht answers exactly one question: **Where are they right now, and when
will they arrive?** Enter a flight number and departure date (optionally with a
note like "Anna & Ben"), and on the day of the flight the app tracks it
automatically and shows it live on a map. No airspace overview, no account, no
backend — everything stays local on your device.

## Features

- Live map with flight trail and an arrival estimate, shown in both destination
  local time and your own time
- States instead of error screens: planned · waiting · live · no signal ·
  ended · missed — coverage gaps over oceans are normal and are shown as
  exactly that
- Three switchable community data sources: adsb.lol, adsb.fi, airplanes.live
- Local notifications: departed · arriving soon · landed
- Light and dark theme

## Status

Under active development. Planning and progress are tracked through GitHub
issues and milestones.

## Development

The repository is a monorepo: the Flutter app lives in `app/`; a website and
possibly a backend will join later. The Flutter version is pinned via
[fvm](https://fvm.app) (`app/.fvmrc`).

```
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

### App icons

Launcher icons, launch screens, and the Play Store listing icon are rendered
from the SVG masters in `assets/icon/` by
`tools/icon-generator/generate-icons.sh`. The script only requires Docker: it
renders inside a pinned Alpine container
(`tools/icon-generator/icons.dockerfile`), which keeps the host clean and the
PNG output
reproducible across machines. It writes every export to
`assets/icon/generated/` and copies the app images into `app/ios/` and
`app/android/`. The Play listing icon
(`assets/icon/generated/store/play-store-512.png`) is uploaded manually in the
Play Console.

### Font Awesome Pro

The app depends on the private package repository
`BoundfoxStudios/font-awesome-flutter-pro`, which bundles licensed Font Awesome
Pro icons that must not appear in a public repository. Building the app
therefore requires read access to that repository — without it,
`flutter pub get` fails. CI authenticates through a GitHub App installation
token.

## Data and licenses

Flight data comes from the community networks [adsb.lol](https://adsb.lol)
(ODbL), [adsb.fi](https://adsb.fi) and [airplanes.live](https://airplanes.live) —
free for private use, with no guarantees about availability or freshness.
Route lookup via
[vradarserver/standing-data](https://github.com/vradarserver/standing-data).
Map data © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.
