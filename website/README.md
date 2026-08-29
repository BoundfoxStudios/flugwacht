# flugwacht.app

The marketing one-pager for Flugwacht. Angular, built to fully static HTML:
English at the root, German under `de/`. No server, no analytics, no third-party
requests at runtime.

## Commands

Run everything from this folder.

| Command                | What it does                                           |
| ---------------------- | ------------------------------------------------------ |
| `npm run setup`        | Installs dependencies with `.env` loaded (see below)   |
| `npm start`            | Dev server on the source locale                        |
| `npm run build`        | Static production build into `dist/website/browser`    |
| `npm run format`       | Formats every file with Prettier                       |
| `npm run format:check` | Fails on an unformatted file, as CI does               |
| `npm run extract-i18n` | Regenerates `projects/website/src/locale/messages.xlf` |

German copy lives in `projects/website/src/locale/messages.de.xlf`. A missing
translation fails the build, so both locales stay complete.

## Deployment

Merging to `main` builds the site and replaces the contents of the
`deployment/production` branch with the output; Netcup pulls that branch through
a webhook. A pull request that touches the website publishes the same way to
`deployment/preview`, which an access-restricted subdomain serves. All pull
requests share that branch, so the last build wins.

## Font Awesome Pro

The icons come from Font Awesome Pro, which is served from a private npm
registry. `.npmrc` points at it and reads the token from the environment:

```
//npm.fontawesome.com/:_authToken=${FONTAWESOME_NPM_TOKEN}
```

The token is never committed. Locally it lives in a git-ignored `.env`:

```bash
cp .env.example .env    # then fill in the token
npm run setup           # dotenvx loads .env, then runs npm ci
```

`setup` reaches dotenvx through `npx` instead of depending on it, because
`npm ci` wipes `node_modules` and would pull a locally installed copy out from
under the running process. The same wrapper works for adding a package:

```bash
npx @dotenvx/dotenvx run -- npm install <package>
```

CI needs no `.env`: a variable that already exists in the environment takes
precedence over `.env`, so a plain `npm ci` with the token exported as a secret
works unchanged.

Only installs need the token – `npm start` and `npm run build` never talk to the
registry. Without it, `npm ci` fails with `npm error code E401` on the
`@fortawesome` packages. A warm npm cache can mask this locally, so a cold
install is the honest check.

## Fonts

Bebas Neue and Barlow are self-hosted under `projects/website/public/fonts/`,
converted to WOFF2 from the same files the app bundles. Their OFL licenses ship
next to them.
