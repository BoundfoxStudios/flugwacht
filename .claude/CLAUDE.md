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

## Credentials

- The repo will become public. Never commit credentials, tokens, or license
  keys — not in config files and not in the history. Anything that needs
  credentials (e.g. the Font Awesome Pro setup) is configured outside the repo
  (environment variables, host configuration) and only documented in the repo
  as placeholders/instructions.
