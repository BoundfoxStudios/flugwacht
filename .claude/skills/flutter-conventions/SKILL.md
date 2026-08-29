---
name: flutter-conventions
description: Use during Flutter/Dart development – widgets, state, tests, pub. Contains this project's Flutter conventions.
---

# Flutter Conventions

Condensed from the official Flutter AI rules:

- Null-safe; use `!` only when non-null is guaranteed
- Small, composed widgets: private widget classes instead of helper methods,
  `const` constructors where possible, no expensive work in `build()`,
  `ListView.builder` for long lists
- Routing: go_router for deep-linkable navigation, `Navigator` for
  short-lived dialogs
- `package:flutter_lints` in `analysis_options.yaml`; tests with
  `flutter_test`/`package:test`, fakes before mocks
- Full rules: https://github.com/flutter/flutter/blob/main/docs/rules/rules.md

## Project decisions

- State management: `signals` – do not introduce other state packages or
  hand-rolled `ChangeNotifier`/stream solutions
- Persistence: `drift` (SQLite); HTTP via `http` behind a source-adapter
  interface
- UI copy is never hard-coded in widgets: all strings go through gen-l10n
  (`lib/l10n`, English is the template language, German the second)
- English code, zero comments by default, no abbreviations in identifiers
- Tests cover only the app's own behavior (domain logic, edge cases, error
  paths) – never framework behavior
- Write Dart code token-efficiently without reproducing `dart format` line
  breaking by hand – the tool owns formatting. When the change is complete,
  run `dart format .` once in `app/` (CI checks it)
