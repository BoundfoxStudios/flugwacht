# Flugwacht — Projektregeln

## Git & GitHub

- Abweichend von der globalen Regel darf Claude in diesem Projekt selbst pushen.
- PR-basierter Workflow: `main` ist geschützt, keine direkten Commits oder Pushes
  auf `main`. Jede Arbeit läuft auf einem `feature/`- oder `fix/`-Branch und geht
  per Pull Request gegen `main`.
- PRs werden erst nach Manuels Freigabe gemerged (Approval oder Kommentar im PR);
  ohne Freigabe niemals mergen. Merge-Methode: Rebase, damit die
  Conventional-Commit-Titel auf `main` erhalten bleiben.
- Planung und Tracking laufen über GitHub-Issues und -Milestones; Commits
  referenzieren ihr Issue. Die Spec liegt in `SPEC.md` (Feedback-Kanal: Issue #1).

## Credentials

- Das Repo wird öffentlich. Niemals Credentials, Tokens oder Lizenzschlüssel
  committen — auch nicht in Konfigurationsdateien oder der Historie. Alles, was
  Zugangsdaten braucht (z. B. das Font-Awesome-Pro-Setup), wird außerhalb des
  Repos konfiguriert (Umgebungsvariablen, Host-Konfiguration) und im Repo nur
  als Platzhalter/Anleitung dokumentiert.
