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
databases, including the `cache`/`queue`/`cable` schemas (loaded from `db/cache_schema.rb`,
`db/queue_schema.rb`, `db/cable_schema.rb`).

## Background jobs

`solid_queue` runs **inside Puma** via `plugin :solid_queue` in `config/puma.rb`, gated on
the `SOLID_QUEUE_IN_PUMA` environment variable — so no separate worker process is needed
on the single Hatchbox server. **Set `SOLID_QUEUE_IN_PUMA=1` in the Hatchbox app
environment** to enable it in production. (It stays off in development/test where the var
is unset.)

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
