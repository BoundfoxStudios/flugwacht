<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="app/assets/logo/logo-dark.svg">
    <img src="app/assets/logo/logo-light.svg" alt="Flugwacht logo: a stylized radar eye" width="96">
  </picture>
</p>

<h1 align="center">Flugwacht</h1>

<p align="center">
  <a href="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/checks.yml"><img src="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/checks.yml/badge.svg?branch=main" alt="Checks workflow status"></a>
  <a href="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/cd.yml"><img src="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/cd.yml/badge.svg?branch=main" alt="CD workflow status"></a>
  <a href="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/security-scan.yml"><img src="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/security-scan.yml/badge.svg?branch=main" alt="Security Scan workflow status"></a>
  <a href="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/airline-directory.yml"><img src="https://github.com/BoundfoxStudios/flugwacht/actions/workflows/airline-directory.yml/badge.svg" alt="Airline Directory workflow status"></a>
  <img src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FBoundfoxStudios%2Fflugwacht%2Fmain%2Fapp%2F.fvmrc&query=%24.flutter&label=Flutter&logo=flutter&color=02569B" alt="Pinned Flutter version">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/BoundfoxStudios/flugwacht" alt="License"></a>
  <a href="https://play.google.com/store/apps/details?id=com.boundfoxstudios.apps.flugwacht"><img src="https://img.shields.io/badge/Play_Store-3DDC84?logo=googleplay&logoColor=white" alt="Flugwacht on the Play Store"></a>
  <a href="https://apps.apple.com/us/app/flugwacht/id6801012878"><img src="https://img.shields.io/badge/App_Store-0D96F6?logo=appstore&logoColor=white" alt="Flugwacht on the App Store"></a>
</p>

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

## License

The source code is licensed under the [MIT license](LICENSE). The Flugwacht
name, the logo, and the app icon assets are not covered by it — they remain the
property of Boundfox Studios and may not be used to identify your own builds or
products. The bundled fonts keep their own SIL Open Font License
(`app/assets/fonts/OFL-*.txt`).
