# flugwacht.app

The marketing one-pager for Flugwacht. Angular, built to fully static HTML:
English at the root, German under `de/`. No server, no analytics, no third-party
requests at runtime.

## Commands

Run everything from this folder.

| Command | What it does |
| --- | --- |
| `npm start` | Dev server on the source locale |
| `npm run build` | Static production build into `dist/website/browser` |
| `npm run extract-i18n` | Regenerates `projects/website/src/locale/messages.xlf` |

German copy lives in `projects/website/src/locale/messages.de.xlf`. A missing
translation fails the build, so both locales stay complete.

## Font Awesome Pro

The icons come from Font Awesome Pro, which is served from a private npm
registry. `.npmrc` points at it and reads the token from the environment:

```
//npm.fontawesome.com/:_authToken=${FONTAWESOME_NPM_TOKEN}
```

The token is never committed. Set it before installing:

```bash
export FONTAWESOME_NPM_TOKEN=your-font-awesome-pro-token
npm ci
```

Without it, `npm ci` fails with `npm error code E401` on the `@fortawesome`
packages. A warm npm cache can mask this locally, so a cold install is the
honest check.

## Fonts

Bebas Neue and Barlow are self-hosted under `projects/website/public/fonts/`,
converted to WOFF2 from the same files the app bundles. Their OFL licenses ship
next to them.
