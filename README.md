# cleohmedia.com — positioning site

Bilingual positioning page for [Cleoh Media](https://cleohmedia.com),
deployed to GitHub Pages from this repo.

Design spec: `docs/superpowers/specs/2026-08-22-positioning-site-design.md`

## Stack

- **Jekyll 4** (via the `jekyll` gem — we build with Actions, not the
  `github-pages` gem)
- **Tailwind CSS v4** (via `tailwindcss-ruby`, Bundler-managed)
- **daisyUI 5** (vendored as `vendor/daisyui.js`; the `cm-light`/`cm-dark`
  palettes are lifted from the `cm` app and live in `assets/css/tailwind.css`)

No dependency is version-pinned — the Gemfile names gems without
constraints and CI resolves `ruby-version: "ruby"` to the latest stable
release. `Gemfile.lock` is the record of what is actually installed.

## Local development

```bash
bundle install
brew install librsvg imagemagick   # OG card + favicon renderers
bundle exec rake dev
# → http://localhost:4000/
```

`rake dev` runs `tailwindcss --watch` and `jekyll serve --livereload` in
parallel.

## Building and checking

```bash
bundle exec rake build   # CSS + OG cards + favicon + icons + Jekyll → _site/
bundle exec rake check   # asserts the spec's structural guarantees
```

`rake check` also runs in CI, after the build and before publishing. It
enforces: both locales built, no call to action anywhere (no `<form>`,
no `<input>`, no link to the app), no third-party requests, correct
canonical/hreflang, and no copy hardcoded outside `_data/i18n.yml`.

## Editing copy

All copy is in `_data/i18n.yml`. Templates contain none. Spanish is
Rioplatense with voseo — "Guardá", "vos podés", "acá", never "aquí".

## Adding a language

1. Append an entry to `locales:` in `_data/i18n.yml` (`code`, `path`,
   `label`, `html_lang`, `og_locale`).
2. Add a top-level block with the same keys as `es:`.
3. Create the stub page (e.g. `pt/index.html`) with `lang: pt` and
   `permalink: /pt/` in the front-matter, including the same sections as
   `en/index.html`.
4. Add `assets/images/og-card-<code>.svg`.

No template changes are needed — `head.html`, `lang-switch.html` and the
Rakefile all derive their behaviour from the `locales` list.

## A note on the logo gradient

`assets/images/logo.svg` uses `gradientUnits="userSpaceOnUse"`. This is
not cosmetic. The mark's middle stroke is a perfectly horizontal line, so
its object bounding box has zero height — and an element with a
zero-height bbox is **not rendered** when its paint references a gradient
in the default `objectBoundingBox` units. With the original gradient the
mark silently lost one of its three converging strokes in every renderer.
Keep `userSpaceOnUse` (and the same coordinates) if you edit the file.

## Release checklist (the human half of the spec's §11)

`rake check` covers the mechanical items. Before announcing the site:

- [ ] Legible in both light and dark (`prefers-color-scheme`)
- [ ] No horizontal scroll at 375px; layer blocks stack 01→04
- [ ] Language switcher round-trips `/` → `/en/` → `/?lang=es` → `/` with
      no redirect loop
- [ ] Both OG cards preview correctly on X and LinkedIn — CI renders text
      with DejaVu Sans, which is wider than the local macOS font; verify
      the deployed PNG, not the local one

## Deploy

Push to `master` → `.github/workflows/deploy.yml` builds and deploys.

## DNS

The `cleohmedia.com` zone lives in **Route 53** and already carries `app`
and `staging` records for the Phoenix application, plus an SES identity on
the apex domain. This site claims the **apex only** — do not touch the
existing records.

After the first successful deploy:

1. Add A records for the apex pointing at GitHub Pages' four IPv4
   addresses, and AAAA records for the IPv6 set. **Read the current
   addresses from GitHub's Pages documentation** — do not copy them from
   any document, including this one; they change.
2. Add `www.cleohmedia.com` as a CNAME to the Pages host.
3. Enable *Enforce HTTPS* in the repo's Pages settings once the
   certificate is issued.
4. Confirm the SES identity on the apex still verifies — adding apex A
   records must not disturb its TXT/DKIM records.
