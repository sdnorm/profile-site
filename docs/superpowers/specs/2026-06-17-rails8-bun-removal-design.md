# Design: Modernize profile-site to Rails 8 omakase, remove bun

**Date:** 2026-06-17
**Status:** Approved (pending spec review)

## Goal

Update every package on the profile site to current major versions and move the
build pipeline fully into the Rails ecosystem — removing `bun` (and Node) entirely.
The result is the standard Rails 8 "omakase" stack: importmap for JS, the
standalone Tailwind binary for CSS, and Propshaft for assets. Deployment stays on
Hatchbox (no Kamal).

## Current state (before)

- **Rails** 7.1.3.2
- **Asset pipeline:** `sprockets-rails` + `app/assets/config/manifest.js`
- **JS:** `jsbundling-rails` building `app/javascript/application.js` with **bun**
  (`bun.config.js`, `bun.lockb`, `package.json`). Content: Turbo + Stimulus, a
  single `notification` Stimulus controller, and a `turbo:submit-end` listener that
  resets `#date-parse-form`.
- **CSS:** `cssbundling-rails` running the Tailwind v3 CLI via bun
  (`tailwind.config.js`, `app/assets/stylesheets/application.tailwind.css` with
  `@tailwind base/components/utilities`).
- **DB:** SQLite, `sqlite3 ~> 1.4`. `config/database.yml` production points at the
  relative path `storage/production.sqlite3`.
- **Ruby** 3.3.0.
- **Deploy:** Hatchbox (Capistrano-style releases). A `Dockerfile` exists that
  installs bun + Node, but Hatchbox does not use it.
- **Tests:** 14 Minitest tests. One pre-existing failure in `DateParserTest`
  (`test_parse_'next_Monday_at_early_morning'`) — a date/DST edge case unrelated to
  packaging; out of scope for this work but noted.

## Target stack (after)

| Area | From | To |
|---|---|---|
| Framework | Rails 7.1.3 | **Rails ~> 8.1** (latest 8.1.x) |
| Asset pipeline | sprockets-rails | **propshaft** |
| JS bundling | jsbundling-rails + bun | **importmap-rails** (no Node) |
| CSS | cssbundling-rails + bun Tailwind v3 | **tailwindcss-rails** (Tailwind **v4**, standalone binary) |
| DB driver | sqlite3 ~> 1.4 | **sqlite3 ~> 2.x** |
| Server | puma 6 | **puma 8** |
| QR codes | rqrcode ~> 2.0 | **rqrcode ~> 3.0** |
| Cache / Jobs / Cable | `redis` gem (Action Cable) | **solid_cache + solid_queue + solid_cable** (Redis removed) |
| Hotwire | turbo-rails 2, stimulus-rails 1.3 | latest |
| Misc | jbuilder, bcrypt, bootsnap, jbuilder, debug, web-console, capybara, selenium-webdriver | latest compatible |

**Ruby bumps 3.3.0 → 3.4.8.** Rails 8.1's `actionview` uses Ruby 3.4-only syntax
(anonymous rest parameter within a block), so although the gemspec claims `>= 3.2.0`, it
does not actually parse on Ruby 3.3. Update `.ruby-version`, the `ruby` pin in `Gemfile`,
and the Dockerfile `RUBY_VERSION` ARG. **Hatchbox action:** set the app's Ruby version to
3.4.8.

### Solid stack (replaces Redis)

The Rails 8 default `solid_*` trio is adopted, backed by SQLite — Redis was never
actually provisioned for this site, so this removes a phantom dependency:

- **solid_cache** — `config.cache_store = :solid_cache_store` (production).
- **solid_queue** — `config.active_job.queue_adapter = :solid_queue`; run **inside
  Puma** via the `solid_queue` plugin (`SOLID_QUEUE_IN_PUMA`) so no separate worker
  process is needed on the single Hatchbox server.
- **solid_cable** — `config/cable.yml` production adapter → `solid_cable`.

Install brings schema files `db/cache_schema.rb`, `db/queue_schema.rb`,
`db/cable_schema.rb` and their `db/*_migrate/` paths. The `redis` gem is removed
from the Gemfile.

### Omakase tooling (per the `rails` house-rules skill)

Add what `rails new` ships in Rails 8 and the skill expects:

- `brakeman` (with `bin/brakeman`)
- `rubocop-rails-omakase` (with `bin/rubocop` + `.rubocop.yml` inheriting the gem)
- `bin/ci` (the Rails 8 `ActiveSupport::ContinuousIntegration` runner) + `config/ci.rb`
  defining: setup, `bin/rails test`, Ruby style, gem audit, `bin/importmap audit`,
  Brakeman. The skill's `bin/rails test:system` step is **omitted** (no `test/system/`
  in this app). The `gh signoff` step is included but only takes effect once
  `gh signoff` is installed for the repo.

`solid_queue`/`solid_cache`/`solid_cable` are **not** adopted — this is a tiny site
that already uses Redis for Action Cable; keeping Redis avoids extra databases and
migrations. (YAGNI.)

## Files removed

- `bun.config.js`, `bun.lockb`, `package.json`
- `tailwind.config.js` (Tailwind v4 uses CSS-based config)
- `app/assets/config/manifest.js` (Sprockets-only; Propshaft auto-discovers)
- `app/assets/builds/application.js` and `application.js.map` (importmap → no JS build)
- `app/assets/stylesheets/application.tailwind.css` (replaced by `app/assets/tailwind/application.css`)
- `.gitattributes`: the `*.lockb diff=lockb` line
- `.gitignore`: the `/node_modules` line (and keep `/app/assets/builds/*` handling
  reconciled for Propshaft — `builds/` is no longer the JS output dir; Tailwind
  output `app/assets/builds/tailwind.css` is gitignored and built at deploy)

## Files added / changed

- **Gemfile / Gemfile.lock** — gem swaps above; `bundle install`.
- **config/importmap.rb** — pin `@hotwired/turbo-rails`, `@hotwired/stimulus`, and
  `controllers` (via `pin_all_from "app/javascript/controllers"`).
- **app/javascript/application.js** — importmap entry: `import "@hotwired/turbo-rails"`
  then `import "./controllers"`. Preserved.
- **app/javascript/controllers/index.js** — switch to
  `eagerLoadControllersFrom("controllers", application)` (stimulus-rails + importmap
  pattern). **Preserve** the existing `turbo:submit-end` reset listener for
  `#date-parse-form`.
- **app/assets/tailwind/application.css** — Tailwind v4 entry (`@import "tailwindcss";`).
- **app/views/layouts/application.html.erb** — replace
  `javascript_include_tag "application", type: "module"` with
  `javascript_importmap_tags`; CSS via `stylesheet_link_tag "tailwind", "data-turbo-track": "reload"`.
- **Procfile.dev** — drop the `js:` line; `css:` → `bin/rails tailwindcss:watch`.
- **bin/** — add `bin/importmap`, `bin/ci`, `bin/brakeman`, ensure `bin/rubocop`.
- **Solid stack config:**
  - `config/database.yml` — multi-database production block (see Deployment); dev/test
    keep `storage/*.sqlite3` (single primary is fine locally, or mirror the 4-DB shape).
  - `config/cable.yml` — production adapter `solid_cable`.
  - `config/environments/production.rb` — `config.cache_store = :solid_cache_store`,
    `config.active_job.queue_adapter = :solid_queue`, `config.solid_queue.connects_to`.
  - `config/puma.rb` — `plugin :solid_queue` (gated on `SOLID_QUEUE_IN_PUMA`).
  - `db/cache_schema.rb`, `db/queue_schema.rb`, `db/cable_schema.rb` + `db/*_migrate/`.
  - Remove `gem "redis"` from the Gemfile.
- **Dockerfile** — remove the bun install stage, the `package.json bun.lockb` copy,
  and `bun install`. Keep `bundle install` + `assets:precompile` (which now runs
  `tailwindcss:build` automatically — no build-time `tailwindcss:install` needed).
  Update `.dockerignore` if it references node/bun.

## Deployment (Hatchbox, no Kamal)

1. **No Node required on the server.** `bin/rails assets:precompile` triggers
   `tailwindcss-rails`'s precompile hook (`tailwindcss:build`) to produce
   `app/assets/builds/tailwind.css`; importmap serves vendored/pinned JS with no
   build step. Hatchbox's standard `bundle install` + `assets:precompile` deploy
   command is sufficient.
2. **All four SQLite DBs must live under `shared/`** (hatchbox-sqlite house rule).
   The four solid/primary databases are configured with **absolute** paths in the
   committed `config/database.yml` production block:
   ```yaml
   production:
     primary:
       <<: *default
       database: /home/deploy/profile-site/shared/production.sqlite3
     cache:
       <<: *default
       database: /home/deploy/profile-site/shared/production_cache.sqlite3
       migrations_paths: db/cache_migrate
     queue:
       <<: *default
       database: /home/deploy/profile-site/shared/production_queue.sqlite3
       migrations_paths: db/queue_migrate
     cable:
       <<: *default
       database: /home/deploy/profile-site/shared/production_cable.sqlite3
       migrations_paths: db/cable_migrate
   ```
   This is a single-server Hatchbox app with a stable on-disk path, so committing
   absolute paths is safe. **The `DATABASE_URL` env var must be REMOVED from
   Hatchbox** — it only maps to `primary` and would conflict with the multi-database
   config. (Single-server only — SQLite can't span machines; flag if scaling.)
3. **Schema load on deploy.** `bin/rails db:prepare` creates/migrates all four
   databases (Hatchbox's standard deploy command handles this). The `shared/`
   directory must exist (`mkdir -p /home/deploy/profile-site/shared`); SSH in once if
   needed. Document all of this in `docs/deployment-hatchbox.md`.

## Verification

1. `bundle install` resolves cleanly on Rails 8.1.
2. `bin/rails test` — 14 tests; expect the same single pre-existing `DateParserTest`
   failure and **no new** failures/errors.
3. `bin/rails assets:precompile` succeeds (Tailwind builds, no Node).
4. Boot `bin/dev` (or `bin/rails s`), load the site, and confirm:
   - Turbo Drive navigation works (home + other pages).
   - The Stimulus `notification` controller dismisses flash messages.
   - The `#date-parse-form` resets on submit.
   - Tailwind styling renders identically.
5. `bin/ci` runs the pipeline locally (Rubocop/Brakeman may surface advisory
   findings on legacy code; those are reported, not auto-fixed, unless trivial).

## Out of scope

- Fixing the pre-existing `DateParserTest` DST failure (noted, not addressed).
- Migrating Action Cable from Redis to `solid_cable`.
- Switching SQLite to Postgres.
- Any UI/content/feature changes.
