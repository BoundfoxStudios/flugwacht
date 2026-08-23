# Design Reference

Binding design rules distilled from the original design handoff. The token
values themselves live in code (`app/lib/ui/theme/app_tokens.dart`); this file
keeps the rules and the never-do list, not a token dump.

## Brand

- Yellow trio `#ffeb3b` / `#ffc107` (primary accent) / `#ffa726` – exact,
  never substituted. Yellow stays the only accent color, in dark mode too.
- Typography: Bebas Neue for display and labels (always caps, leading 1.0)
  plus Barlow for body text. Fonts are bundled at build time, never
  downloaded at runtime.
- Logo: the "Radar-Auge" mark; wordmark FLUGWACHT in Bebas Neue, no subtitle.
- Icons: Font Awesome Pro, style `regular`, via `font_awesome_flutter` (the
  Pro setup is configured outside the repo, see Credentials in `CLAUDE.md`).
- Boundfox branding stays subtle: the fox appears only on the about page.

## Layout & Motion

- 4 px spacing grid; minimum text size 11 px.
- Hit targets ≥ 44 px.
- Motion 150–200 ms, ease-in-out, no bounces – animations stay minimal.
- Radius scale: sheet 16 · cards 12 · buttons/fields/boxes 8–10 ·
  pills/badges 999. No strong rounding anywhere else.
- No Material default look: no ripple; press feedback is one step darker
  (yellow → amber) plus a 1 px translate down.

## Language & Copy

- UI copy is localized from the start – no hard-coded strings in widgets.
  English is the base/template language, German the second, in the informal
  "Du" form. The device language selects the locale, English is the fallback.
- Deliberately vague labels for the arrival estimate ("Ankunft ca.",
  "~14:32" on stale data) – never fake precision.

## Never

- Never substitute the brand colors.
- No emoji, in any language and any UI surface.
- No demo flight in the empty state.
- No error UI for coverage gaps or an unknown route (regular states, see
  `domain.md`).
