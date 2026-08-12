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
  merge without it. Merge method: rebase, so the conventional commit titles are
  preserved on `main`.
- Planning and tracking happen through GitHub issues and milestones; commits
  reference their issue. The spec lives in `SPEC.md` (feedback channel:
  issue #1).

## Credentials

- The repo will become public. Never commit credentials, tokens, or license
  keys — not in config files and not in the history. Anything that needs
  credentials (e.g. the Font Awesome Pro setup) is configured outside the repo
  (environment variables, host configuration) and only documented in the repo
  as placeholders/instructions.
