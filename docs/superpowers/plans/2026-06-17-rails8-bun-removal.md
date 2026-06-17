# Rails 8 Upgrade + Remove bun Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade profile-site from Rails 7.1 to Rails 8.1 and move the entire build pipeline into the Rails ecosystem — Propshaft assets, importmap JS, the standalone Tailwind v4 binary for CSS, and the SQLite-backed solid stack — removing bun/Node completely. Deploy stays on Hatchbox.

**Architecture:** Migrate in green-checkpoint phases. Phase A bumps the framework to Rails 8 + Propshaft while bun still builds assets (isolates the framework jump). Phase B swaps bun → importmap. Phase C swaps cssbundling → tailwindcss-rails v4. Phase D adopts the solid stack (replaces Redis). Phase E removes bun cruft, updates the Dockerfile, adds omakase tooling, and writes deploy docs. Every task ends green: the existing 14-test Minitest suite passes (minus the one pre-existing `DateParserTest` failure) and the app boots.

**Tech Stack:** Rails ~> 8.1, Ruby 3.3.0, Propshaft, importmap-rails, tailwindcss-rails (Tailwind v4), solid_cache/solid_queue/solid_cable, SQLite (sqlite3 ~> 2), Puma 8, Hotwire (Turbo + Stimulus).

**Reference spec:** `docs/superpowers/specs/2026-06-17-rails8-bun-removal-design.md`

---

## Baseline note

The suite has **one pre-existing failure** before any work starts:
`DateParserTest#test_parse_'next_Monday_at_early_morning'` (a DST edge case). Throughout
this plan, "tests green" means **14 runs, 1 failure, 0 errors** — that same failure and
nothing new. If errors appear or the failure count rises, stop and investigate.

---

## Phase A — Framework upgrade: Rails 8.1 + Propshaft (bun still builds assets)

### Task A1: Branch and confirm baseline

**Files:** none (git + verification only)

- [ ] **Step 1: Create the working branch**

```bash
git checkout -b upgrade-rails-8-remove-bun
```

- [ ] **Step 2: Ensure gems are installed**

```bash
bundle install
```
Expected: "Bundle complete!" (no errors).

- [ ] **Step 3: Record the baseline test result**

Run: `bin/rails test`
Expected: `14 runs, 14 assertions, 1 failures, 0 errors, 0 skips` — the single failure
is `DateParserTest#test_parse_'next_Monday_at_early_morning'`. This is the baseline.

### Task A2: Bump Rails, sqlite3, puma, rqrcode; swap sprockets → propshaft

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock` (via bundler)

- [ ] **Step 1: Edit the framework/runtime gems in `Gemfile`**

Replace the `rails` line:
```ruby
gem "rails", "~> 8.1"
```

Replace `gem "sprockets-rails"` with:
```ruby
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
```

Replace `gem "sqlite3", "~> 1.4"` with:
```ruby
gem "sqlite3", "~> 2.1"
```

Replace `gem "rqrcode", "~> 2.0"` with:
```ruby
gem "rqrcode", "~> 3.0"
```

Leave `gem "puma", ">= 5.0"` as-is (it will resolve to Puma 8).

- [ ] **Step 2: Resolve the bundle**

```bash
bundle update rails propshaft sqlite3 rqrcode puma
```
Expected: bundler installs Rails 8.1.x, propshaft, sqlite3 2.x, rqrcode 3.x, puma 8.x and
their dependencies; "Bundle complete!".

- [ ] **Step 3: Commit the gem bump (config fixes follow)**

```bash
git add Gemfile Gemfile.lock
git commit -m "Bump to Rails 8.1, propshaft, sqlite3 2, rqrcode 3, puma 8"
```

### Task A2b: Bump Ruby 3.3.0 → 3.4.8

**Why:** Rails 8.1's `actionview` uses Ruby 3.4-only syntax (anonymous rest parameter
within a block); it does not parse on Ruby 3.3 despite the gemspec claiming `>= 3.2.0`.
Ruby 3.4.8 is already installed locally via asdf.

**Files:**
- Modify: `.ruby-version`
- Modify: `Gemfile:3`
- Modify: `Gemfile.lock` (via bundler)

- [ ] **Step 1: Update `.ruby-version`**

Replace its contents with:
```
ruby-3.4.8
```

- [ ] **Step 2: Update the `ruby` pin in `Gemfile`**

Change line 3 from `ruby "3.3.0"` to:
```ruby
ruby "3.4.8"
```

- [ ] **Step 3: Re-resolve under Ruby 3.4.8**

```bash
ruby -v                # confirm asdf now selects 3.4.8 (from .ruby-version)
bundle install
```
Expected: Ruby 3.4.8 active; "Bundle complete!". (The Dockerfile `RUBY_VERSION` ARG is
updated later in Task E2.)

- [ ] **Step 4: Commit**

```bash
git add .ruby-version Gemfile Gemfile.lock
git commit -m "Bump Ruby to 3.4.8 (required by Rails 8.1)"
```

### Task A3: Reconcile framework config for Rails 8 + Propshaft

**Files:**
- Modify: `config/application.rb`
- Delete: `app/assets/config/manifest.js`
- Modify: `config/initializers/assets.rb` (only if it references sprockets-specific options)

- [ ] **Step 1: Bump the defaults in `config/application.rb`**

Change `config.load_defaults 7.1` to:
```ruby
config.load_defaults 8.0
```
(If the file has no `load_defaults` line, add it inside the `Application` class.)

- [ ] **Step 2: Delete the Sprockets manifest (Propshaft auto-discovers assets)**

```bash
git rm app/assets/config/manifest.js
```

- [ ] **Step 3: Check the assets initializer for Sprockets-only directives**

Run: `cat config/initializers/assets.rb`
If it contains only the default `Rails.application.config.assets.version` /
`assets.paths` / `precompile` lines, leave it — Propshaft honors `assets.paths`. Remove
any line that errors on boot (verified next step). Most likely no change is needed.

- [ ] **Step 4: Verify the app boots and assets still build via bun**

```bash
bin/rails runner "puts Rails.version"        # expect 8.1.x
bun run build && bun run build:css           # bun still wired up in Phase A
bin/rails test
```
Expected: Rails 8.1.x prints; both bun builds succeed; tests green (14/1 failure/0 errors).

- [ ] **Step 5: Smoke-test the running app**

```bash
bin/dev
```
Visit `http://localhost:3000`, click between Home and other pages (Turbo navigation),
confirm Tailwind styling renders. Stop the server (Ctrl-C).

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "Reconcile config for Rails 8 + Propshaft; drop sprockets manifest"
```

---

## Phase B — JS: bun/jsbundling → importmap-rails

### Task B1: Swap jsbundling-rails for importmap-rails

**Files:**
- Modify: `Gemfile`
- Create: `config/importmap.rb`
- Create: `bin/importmap`
- Modify: `app/javascript/application.js`
- Modify: `app/javascript/controllers/index.js`
- Modify: `app/views/layouts/application.html.erb:10`
- Delete: `app/assets/builds/application.js`, `app/assets/builds/application.js.map`

- [ ] **Step 1: Swap the gem**

In `Gemfile`, replace:
```ruby
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
```
with:
```ruby
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
```

- [ ] **Step 2: Install**

```bash
bundle install
```
Expected: importmap-rails installed; "Bundle complete!".

- [ ] **Step 3: Create `config/importmap.rb`**

```ruby
# Pin npm packages by running ./bin/importmap

pin "application"
pin_all_from "app/javascript/controllers", under: "controllers"
```
(`@hotwired/turbo-rails`, `@hotwired/stimulus`, and `@hotwired/stimulus-loading` are
auto-pinned by the turbo-rails and stimulus-rails engines — no explicit pins needed.)

- [ ] **Step 4: Create `bin/importmap`**

```ruby
#!/usr/bin/env ruby
require_relative "../config/application"
require "importmap/commands"
```
Then:
```bash
chmod +x bin/importmap
```

- [ ] **Step 5: Rewrite `app/javascript/application.js`**

Move the form-reset listener here (it was in `controllers/index.js`) so it survives the
switch to eager controller loading:
```js
// Entry point for the importmap-managed JavaScript
import "@hotwired/turbo-rails"
import "./controllers"

document.addEventListener("turbo:submit-end", (event) => {
  if (event.target.id === "date-parse-form") {
    event.target.reset()
  }
})
```

- [ ] **Step 6: Rewrite `app/javascript/controllers/index.js` to eager-load**

```js
import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("controllers", application)
```
(`controllers/application.js` and `controllers/notification_controller.js` are unchanged.)

- [ ] **Step 7: Update the layout to emit importmap tags**

In `app/views/layouts/application.html.erb`, replace line 10:
```erb
    <%= javascript_include_tag "application", "data-turbo-track": "reload", type: "module" %>
```
with:
```erb
    <%= javascript_importmap_tags %>
```

- [ ] **Step 8: Remove the bun JS build artifacts**

```bash
git rm app/assets/builds/application.js app/assets/builds/application.js.map
```

- [ ] **Step 9: Verify JS is served via importmap**

```bash
bin/importmap json     # prints the resolved import map incl. application, turbo, stimulus, controllers/*
bin/rails test
```
Expected: import map JSON lists `application`, `@hotwired/turbo-rails`,
`@hotwired/stimulus`, `controllers/notification_controller`; tests green.

- [ ] **Step 10: Smoke-test Stimulus + Turbo in the browser**

```bash
bin/dev
```
Visit the site, trigger a flash notice (e.g. sign in / out), confirm the `×` button
dismisses it (the `notification` Stimulus controller), confirm Turbo navigation works,
and submit the date-parser form to confirm it resets. Check the browser console for no
module errors. Stop the server.

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "Replace jsbundling/bun with importmap-rails"
```

---

## Phase C — CSS: cssbundling/bun Tailwind v3 → tailwindcss-rails (Tailwind v4)

### Task C1: Swap cssbundling-rails for tailwindcss-rails

**Files:**
- Modify: `Gemfile`
- Create: `app/assets/tailwind/application.css`
- Modify: `app/views/layouts/application.html.erb:9`
- Modify: `Procfile.dev`
- Delete: `app/assets/stylesheets/application.tailwind.css`, `tailwind.config.js`

- [ ] **Step 1: Swap the gem**

In `Gemfile`, replace:
```ruby
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"
```
with:
```ruby
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"
```

- [ ] **Step 2: Install**

```bash
bundle install
```
Expected: tailwindcss-rails (4.x, Tailwind v4) installed.

- [ ] **Step 3: Create the Tailwind v4 entry `app/assets/tailwind/application.css`**

```css
@import "tailwindcss";
```
(Tailwind v4 is CSS-config-first; the v3 `tailwind.config.js` and the old
`@tailwind base/components/utilities` directives are no longer used.)

- [ ] **Step 4: Point the layout at the compiled Tailwind output**

In `app/views/layouts/application.html.erb`, replace line 9:
```erb
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```
with:
```erb
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
```
(tailwindcss-rails compiles `app/assets/tailwind/application.css` to
`app/assets/builds/tailwind.css`, served by Propshaft as `tailwind`.)

- [ ] **Step 5: Update `Procfile.dev`**

Replace the whole file with (drop the bun `js:` line; importmap needs no JS build):
```
web: env RUBY_DEBUG_OPEN=true bin/rails server
css: bin/rails tailwindcss:watch
```

- [ ] **Step 6: Remove the old cssbundling/v3 files**

```bash
git rm app/assets/stylesheets/application.tailwind.css tailwind.config.js
```

- [ ] **Step 7: Build the CSS and verify**

```bash
bin/rails tailwindcss:build
ls app/assets/builds/tailwind.css      # exists, non-empty
bin/rails test
```
Expected: a `tailwind.css` is produced; tests green.

- [ ] **Step 8: Visually verify styling is unchanged**

```bash
bin/dev
```
Confirm `bin/dev` now starts only `web` + `css` (no `js`). Visit the site; confirm the
indigo nav buttons, flash banners, and layout render exactly as before. Stop the server.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "Replace cssbundling/bun with tailwindcss-rails (Tailwind v4)"
```

---

## Phase D — Solid stack: replace Redis with solid_cache / solid_queue / solid_cable

### Task D1: Add and install the solid gems

**Files:**
- Modify: `Gemfile`
- Create: `db/cache_schema.rb`, `db/queue_schema.rb`, `db/cable_schema.rb` (+ `db/*_migrate/`)
- Create/Modify: `config/queue.yml`, `config/cache.yml` (whatever the installers generate)
- Modify: `config/environments/production.rb`, `config/puma.rb`, `config/cable.yml`

- [ ] **Step 1: Add the gems and remove redis**

In `Gemfile`, replace:
```ruby
# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"
```
with:
```ruby
# SQLite-backed cache, jobs, and Action Cable [https://github.com/rails/solid_cache]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
```

- [ ] **Step 2: Install**

```bash
bundle install
```
Expected: solid_cache, solid_queue, solid_cable installed; redis removed.

- [ ] **Step 3: Run the official installers**

```bash
bin/rails solid_cache:install solid_queue:install solid_cable:install
```
Expected: generates `db/cache_schema.rb`, `db/queue_schema.rb`, `db/cable_schema.rb`
and their `db/*_migrate/` directories; sets `config.cache_store = :solid_cache_store`,
`config.active_job.queue_adapter = :solid_queue`, and `config.solid_queue.connects_to`
in `config/environments/production.rb`; adds a `solid_cable` production adapter to
`config/cable.yml`; adds `plugin :solid_queue` to `config/puma.rb`. Review the diff:
```bash
git status && git diff
```

### Task D2: Configure the four production databases for Hatchbox

**Files:**
- Modify: `config/database.yml`
- Modify: `config/cable.yml` (confirm dev=async, test=test, prod=solid_cable)

- [ ] **Step 1: Rewrite `config/database.yml`**

development and test stay single-database (Rails 8 keeps solid for production only);
production gets the four-database layout with absolute `shared/` paths:
```yaml
# SQLite. Versions 3.8.0 and up are supported.
default: &default
  adapter: sqlite3
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  timeout: 5000

development:
  <<: *default
  database: storage/development.sqlite3

test:
  <<: *default
  database: storage/test.sqlite3

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

- [ ] **Step 2: Confirm `config/cable.yml`**

Ensure it reads (the installer should have set production to solid_cable; dev stays
async so no local cable DB is needed):
```yaml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: solid_cable
  connects_to:
    database:
      writing: cable
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

- [ ] **Step 3: Verify development still boots and tests pass**

(Development uses a single DB + async job/cable adapters, so no solid DBs are created
locally — solid is exercised in production only.)
```bash
bin/rails test
bin/rails runner "puts ActiveJob::Base.queue_adapter.class"   # dev: async adapter
```
Expected: tests green; no database errors on boot.

- [ ] **Step 4: Production config smoke test (local, throwaway paths)**

Verify the production multi-DB config and solid wiring load without needing the real
Hatchbox paths:
```bash
mkdir -p tmp/prodtest
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production \
  DATABASE_URL= \
  bin/rails runner "puts Rails.application.config.cache_store.inspect; puts ActiveJob::Base.queue_adapter_name" 2>&1 | tail -5
```
Expected: prints `:solid_cache_store` and `solid_queue` with no load errors. (Connecting
to the real DBs happens on the Hatchbox server; this only checks config loads.) If it
errors only because it cannot open `/home/deploy/...`, that is acceptable here — the
config itself is valid.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Adopt solid_cache/queue/cable; remove Redis; multi-DB SQLite for prod"
```

---

## Phase E — Cleanup, tooling, Docker, docs

### Task E1: Remove all remaining bun / Node files

**Files:**
- Delete: `bun.config.js`, `bun.lockb`, `package.json`
- Modify: `.gitattributes`, `.gitignore`

- [ ] **Step 1: Delete the bun/Node files**

```bash
git rm bun.config.js bun.lockb package.json
```

- [ ] **Step 2: Remove the `*.lockb` attribute from `.gitattributes`**

Delete these two lines (the trailing comment + the rule):
```
# See https://bun.sh/docs/install/lockfile
*.lockb diff=lockb
```

- [ ] **Step 3: Remove the `/node_modules` line from `.gitignore`**

Delete the final line:
```
/node_modules
```
(Leave the `/app/assets/builds/*` + `!/app/assets/builds/.keep` lines — Propshaft/Tailwind
output `tailwind.css` there and it should stay gitignored, rebuilt on deploy.)

- [ ] **Step 4: Verify nothing references bun/node**

```bash
grep -rnE --exclude-dir=.git --exclude-dir=docs "bun run|bun install|bun\.sh|bunx|\.lockb|node_modules|jsbundling|cssbundling" . || echo "clean"
bin/rails test
```
Expected: prints "clean" (no functional references remain; docs excluded); tests green.
(The pattern is specific so it does not match "bundle"/"bundler".)

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Remove bun/Node files and references"
```

### Task E2: Update the Dockerfile (remove bun/Node)

**Files:**
- Modify: `Dockerfile`
- Modify: `.dockerignore`

- [ ] **Step 0: Bump the Ruby version ARG**

In `Dockerfile`, change `ARG RUBY_VERSION=3.3.0` to:
```dockerfile
ARG RUBY_VERSION=3.4.8
```
(Matches `.ruby-version` / the `Gemfile` pin set in Task A2b.)

- [ ] **Step 1: Remove the bun install stage from `Dockerfile`**

Delete these blocks from the `build` stage:
```dockerfile
ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
ARG BUN_VERSION=1.0.23
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v${BUN_VERSION}"
```
and:
```dockerfile
# Install node modules
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile
```
Also drop `unzip` from the `apt-get install` line (it was only needed to install bun).
Keep `build-essential curl git libvips pkg-config`. The remaining
`RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile` now compiles Tailwind via the
gem (no Node needed).

- [ ] **Step 2: Remove the `/node_modules/` line from `.dockerignore`**

Delete:
```
/node_modules/
```
(Keep the `/app/assets/builds/*` lines.)

- [ ] **Step 3: Verify the Dockerfile has no bun/node references**

```bash
grep -n -i "bun\|node\|package.json\|unzip" Dockerfile || echo "clean"
```
Expected: "clean" (no matches).

- [ ] **Step 4: Commit**

```bash
git add Dockerfile .dockerignore
git commit -m "Strip bun/Node from Dockerfile"
```

### Task E3: Add omakase tooling (Brakeman, RuboCop omakase, bin/ci)

**Files:**
- Modify: `Gemfile`
- Create: `.rubocop.yml`, `bin/rubocop`, `bin/brakeman`, `bin/ci`, `config/ci.rb`

- [ ] **Step 1: Add the tooling gems**

In `Gemfile`, add to the `group :development, :test do` block (alongside `debug`):
```ruby
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase]
  gem "rubocop-rails-omakase", require: false

  # Audit gems for known CVEs
  gem "bundler-audit", require: false
```

- [ ] **Step 2: Install**

```bash
bundle install
```

- [ ] **Step 3: Create `.rubocop.yml`**

```yaml
inherit_gem:
  rubocop-rails-omakase: rubocop.yml
```

- [ ] **Step 4: Create the binstubs**

`bin/rubocop`:
```ruby
#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
load Gem.bin_path("rubocop", "rubocop")
```

`bin/brakeman`:
```ruby
#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
load Gem.bin_path("brakeman", "brakeman")
```

`bin/ci`:
```ruby
#!/usr/bin/env ruby
require_relative "../config/boot"
require "active_support/continuous_integration"

CI = ActiveSupport::ContinuousIntegration
require_relative "../config/ci.rb"
```

Then make them executable:
```bash
chmod +x bin/rubocop bin/brakeman bin/ci
```

- [ ] **Step 5: Create `config/ci.rb`**

(No `test:system` step — this app has no `test/system/`. The `gh signoff` step only
fires once `gh signoff` is installed for the repo.)
```ruby
# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Tests: Unit & integration", "bin/rails test"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundle exec bundler-audit check --update"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  if success?
    step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  else
    failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  end
end
```

- [ ] **Step 6: Verify the security/style steps run**

```bash
bin/brakeman --quiet --no-pager
bin/importmap audit
bin/rubocop || true   # may report style offenses on legacy code — that is informational
```
Expected: Brakeman completes (0 warnings expected for this small app); importmap audit
reports no known vulnerabilities. RuboCop offenses on pre-existing code are acceptable —
do NOT auto-correct broadly in this task; note them for a follow-up if significant.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "Add omakase tooling: Brakeman, RuboCop omakase, bin/ci"
```

### Task E4: Write the Hatchbox deployment doc and link the house rules

**Files:**
- Create: `docs/deployment-hatchbox.md`
- Modify: `README.md`

- [ ] **Step 1: Create `docs/deployment-hatchbox.md`**

```markdown
# Deploying to Hatchbox

This app deploys to Hatchbox (Capistrano-style releases) with a SQLite database.
No Node/bun is required — JS is served via importmap and CSS is compiled by
`tailwindcss-rails` during `assets:precompile`.

## Ruby version

This app requires **Ruby 3.4.8** (Rails 8.1 does not parse on Ruby 3.3). Set the Ruby
version for the app in Hatchbox to **3.4.8** before deploying the upgrade — it must match
`.ruby-version`.

## Assets

Hatchbox's standard deploy (`bundle install` + `bin/rails assets:precompile`) is
sufficient. `assets:precompile` runs `tailwindcss:build` automatically (the gem hooks
into the precompile chain) and Propshaft fingerprints everything. There is no JS build
step.

## Database: SQLite under `shared/` (REQUIRED)

Hatchbox wipes the app directory on every deploy, so all SQLite files MUST live in the
persistent `shared/` directory. This app uses the Rails 8 solid stack, which means
**four** databases, all configured with absolute paths in `config/database.yml`:

- `primary`  → `/home/deploy/profile-site/shared/production.sqlite3`
- `cache`    → `/home/deploy/profile-site/shared/production_cache.sqlite3`
- `queue`    → `/home/deploy/profile-site/shared/production_queue.sqlite3`
- `cable`    → `/home/deploy/profile-site/shared/production_cable.sqlite3`

### One-time setup on the server

```bash
mkdir -p /home/deploy/profile-site/shared
chown deploy:deploy /home/deploy/profile-site/shared
```

### Remove the DATABASE_URL env var

`config/database.yml` is the single source of truth. **Remove any `DATABASE_URL` env
var in Hatchbox** — it maps only to `primary` and conflicts with the multi-database
config.

### Migrations

`bin/rails db:prepare` (Hatchbox's deploy migration step) creates and migrates all four
databases, including the `cache`/`queue`/`cable` schemas.

## Background jobs

`solid_queue` runs **inside Puma** via `plugin :solid_queue` in `config/puma.rb` — no
separate worker process is needed on the single Hatchbox server.

## Backups

Hatchbox does not back up SQLite automatically. Add a cron job on the server:

```bash
sqlite3 /home/deploy/profile-site/shared/production.sqlite3 \
  ".backup /home/deploy/profile-site/shared/backups/production-$(date +%F).sqlite3"
```

Ship the result off-box (S3/rsync), or use Litestream for continuous replication.

## Constraint: single server only

SQLite is a file, not a server — it works on one machine only. If this app ever needs
horizontal scaling, migrate to Postgres (Hatchbox can provision it).
```

- [ ] **Step 2: Add a deployment pointer to `README.md`**

Append:
```markdown

## Deployment

Deployed to Hatchbox with SQLite. See [docs/deployment-hatchbox.md](docs/deployment-hatchbox.md).
```

- [ ] **Step 3: Commit**

```bash
git add docs/deployment-hatchbox.md README.md
git commit -m "Document Hatchbox + SQLite deployment"
```

---

## Phase F — Final verification

### Task F1: Full-stack verification

**Files:** none (verification only)

- [ ] **Step 1: Clean install from the lockfile**

```bash
bundle install
```
Expected: "Bundle complete!" with Rails 8.1.x.

- [ ] **Step 2: Full test suite**

Run: `bin/rails test`
Expected: `14 runs, ..., 1 failures, 0 errors, 0 skips` (only the pre-existing
`DateParserTest` failure).

- [ ] **Step 3: Production asset precompile (proves no Node needed)**

```bash
SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
```
Expected: succeeds; produces fingerprinted assets incl. `tailwind.css`; no bun/Node
invoked. Clean up afterwards:
```bash
bin/rails assets:clobber
```

- [ ] **Step 4: Boot and manually verify the full app**

```bash
bin/dev
```
Confirm all of the following at `http://localhost:3000`:
- Pages load and Turbo Drive navigation works (Home ↔ other pages).
- Tailwind styling renders identically to before (indigo buttons, banners, layout).
- A flash message's `×` button dismisses it (Stimulus `notification` controller).
- The date-parser form resets after submit (the `turbo:submit-end` listener).
- Browser console shows no module/import errors.
Stop the server.

- [ ] **Step 5: Run the local CI pipeline**

```bash
bin/ci
```
Expected: setup, tests, style, and security steps run. Tests pass (with the known
pre-existing failure noted — if `bin/ci` treats it as a hard failure, that is expected
and documented; the import map audit and Brakeman should pass clean).

- [ ] **Step 6: Confirm the branch is ready**

```bash
git status          # clean working tree
git log --oneline upgrade-rails-8-remove-bun ^main
```
Expected: clean tree; the commit series from Tasks A2 → E4 present.

---

## Post-implementation: deploy checklist (manual, on Hatchbox)

These are NOT code steps — they are the human deploy actions, captured so they are not
forgotten:

- [ ] In Hatchbox: set the app's **Ruby version to 3.4.8** (matches `.ruby-version`).
- [ ] On the server: `mkdir -p /home/deploy/profile-site/shared` (if not already present).
- [ ] **Remove the `DATABASE_URL` env var** from the Hatchbox app environment.
- [ ] Deploy the branch; confirm `bin/rails db:prepare` creates the four `shared/` DBs.
- [ ] Verify the live site loads, styling is intact, and Action Cable/jobs work.
- [ ] Set up the SQLite backup cron job (see `docs/deployment-hatchbox.md`).
```
