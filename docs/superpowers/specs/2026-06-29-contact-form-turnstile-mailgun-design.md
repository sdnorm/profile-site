# Contact Form: Turnstile + Mailgun + Turbo Design

**Date:** 2026-06-29
**Status:** Approved (revised 2026-06-29 to follow `sdnorm/development-skills` house rules)
**Scope:** Personal site (spencernorman.io) contact form only.

**House-rules revision:** Per the `sdnorm/development-skills` `rails` skill — **no service
objects** (business logic in concerns or tableless models), **Minitest with fixtures, no
factories, no mocking libraries** (test via real objects + plain dependency injection),
Hotwire/Turbo + Stimulus. Turnstile verification therefore lives in a tableless model
`Turnstile::Verification` (not `app/services/`), and tests use DI instead of `.stub`
(also necessary because Minitest 6 removed `minitest/mock`).

## Goal

Turn the personal site's contact form from a client-side stub into a working,
bot-protected form that emails Spencer and gives the user real, server-rendered
feedback via Hotwire/Turbo.

Today the form (`app/views/personal/pages/_contact.html.erb` +
`app/javascript/controllers/contact_controller.js`) only toggles a CSS success
state client-side; nothing is sent or delivered.

## Decisions

| Question | Decision |
|----------|----------|
| Turnstile verification | Server-side in Rails (no Cloudflare Worker) |
| Email provider | Mailgun, US region (`api.mailgun.net`) via `mailgun-ruby` gem |
| Destination | `spencernorman@hey.com` (overridable via `contact.recipient` credential) |
| Secrets storage | Rails encrypted credentials, **regenerated fresh** (existing `credentials.yml.enc` decrypts to empty and the master key is lost). New `config/master.key` stays gitignored; `RAILS_MASTER_KEY` set in Hatchbox for production |
| Delivery timing | `deliver_now`, wrapped in rescue for synchronous user feedback |
| Feedback mechanism | Turbo Stream replacing the form panel |

## Request flow

```
Browser (Turbo form POST /contact, body includes cf-turnstile-response token)
  → Personal::ContactsController#create
      1. Build ContactMessage from params; validate (name/email/message)
      2. TurnstileVerifier.call(token, remote_ip) → Cloudflare siteverify
      3. ContactMailer.new_message(contact_message).deliver_now  (Mailgun US)
  → turbo_stream response:
      - success      → replace #contact_panel with the "Message sent" panel
      - invalid form → replace #contact_panel with form + field errors + fresh widget
      - turnstile bad→ replace #contact_panel with form + "Please complete the check" + fresh widget
      - send failure → replace #contact_panel with form + "Couldn't send right now" + fresh widget
```

## Components (each small, single-purpose, testable)

### `app/models/contact_message.rb`
Tableless model: `ActiveModel::Model` + `ActiveModel::Attributes` (house style).
Attributes: `name`, `email`, `message` (all `:string`). Validations: `email` and
`message` presence; `email` format; `name` optional. Gives the controller a thin,
validatable object and supports `form_with model:` plus error re-rendering.

### `app/models/turnstile/verification.rb` (tableless model — NOT a service object)
Tableless model: `ActiveModel::Model` + `ActiveModel::Attributes`. Attributes:
`token`, `remote_ip`, and `secret` (defaults to
`Rails.application.credentials.dig(:turnstile, :secret_key)`). Exposes `#verified?
=> Boolean`: POSTs `secret`, `response` (token), and optional `remoteip` to
`https://challenges.cloudflare.com/turnstile/v0/siteverify` and returns the
`success` boolean. Returns `false` on a blank token or any network/parse error
(fail closed). No new gem (`Net::HTTP`).

**Dev/test bypass:** when `secret` is blank, return `true`, so the form is usable
before real keys exist.

**Testability without mocks (house rule):** the HTTP boundary is injected via a
`http` writer that defaults to the real Cloudflare call. Tests set
`verification.http = ->(**) { { "success" => true } }` (plain DI — no mocking
library), and exercise the bypass / blank-token branches by passing `secret`
explicitly. No `.stub`, no credential mocking.

### `app/controllers/personal/contacts_controller.rb`
`Personal::ContactsController < Personal::BaseController`, `create` only. Reads
`params[:contact_message]` and `params["cf-turnstile-response"]`. Order: validate
the model → if valid, verify Turnstile via
`Turnstile::Verification.new(token:, remote_ip:).verified?` → if verified, deliver.
On a Turnstile failure it adds an error to `@contact_message` (`errors.add(:base,
…)`) so the single re-render path shows it. `respond_to` renders `turbo_stream`
(status `:unprocessable_entity` on failure); a plain `html` fallback redirects to
the home anchor (covers JS-disabled clients).

### `app/mailers/contact_mailer.rb`
`ContactMailer < ApplicationMailer`. `new_message(contact_message)`:
- `to`: `credentials.dig(:contact, :recipient)` (default `spencernorman@hey.com`)
- `from`: `credentials.dig(:mailgun, :from)` (must be on the verified Mailgun domain)
- `reply_to`: the submitter's email (so replies go straight to them)
- `subject`: `"New portfolio inquiry from #{name.presence || email}"`
- Body: name, email, message (text + html templates).

`ApplicationMailer` default `from` updated from the Rails placeholder to the
`mailgun.from` credential.

### Views
- `_contact.html.erb` — section wrapper + `<div id="contact_panel">` containing
  `_contact_form`.
- `_contact_form.html.erb` — `form_with model: @contact_message, url: personal_contact_path`,
  fields styled with existing `sn-field`/`sn-input` classes, the Turnstile widget
  div, and a submit button. Renders ActiveModel errors inline.
- `_contact_success.html.erb` — the existing "Message sent" panel markup.
- `create.turbo_stream.erb` — replaces `#contact_panel` with success or the form
  partial depending on outcome (controller sets an ivar / renders directly).

### `app/javascript/controllers/turnstile_controller.js`
Replaces the old `contact_controller.js`. On `connect()` explicitly calls
`window.turnstile.render(element, { sitekey, action: "turnstile-spin-v1" })`
because Turbo navigations don't fire `window.onload` (auto-render is unreliable
under Turbo). Stores the widget id; on disconnect, `turnstile.remove(id)`. The
Turnstile script tag (`challenges.cloudflare.com/turnstile/v0/api.js`, async
defer, **no** auto-render) is added to the personal layout head.

The old `contact_controller.js` is deleted.

## Mailgun configuration

Add `gem "mailgun-ruby"`. Configure ActionMailer in `production.rb` and
`development.rb`:

```ruby
config.action_mailer.delivery_method = :mailgun
config.action_mailer.mailgun_settings = {
  api_key: Rails.application.credentials.dig(:mailgun, :api_key),
  domain:  Rails.application.credentials.dig(:mailgun, :domain),
  # US region is the gem default; EU would set api_host: "api.eu.mailgun.net"
}
```

`test.rb` keeps `delivery_method = :test` (already set), so tests assert against
`ActionMailer::Base.deliveries`.

## Secrets (Rails encrypted credentials)

The existing `credentials.yml.enc` decrypts to empty and its master key is lost,
so it is **regenerated fresh**: remove the old file, run `bin/rails
credentials:edit` (which creates a new `config/master.key` and
`credentials.yml.enc`), and populate this structure:

```yaml
turnstile:
  site_key: "0x..."     # public; rendered into the widget
  secret_key: "0x..."   # siteverify
mailgun:
  api_key: "..."        # Mailgun API key (US region)
  domain: "mg.example"  # verified sending domain
  from: "Portfolio <postmaster@mg.example>"  # From: on the verified domain
contact:
  recipient: "spencernorman@hey.com"
```

Code reads via `Rails.application.credentials.dig(:group, :key)`.

**Key handling / coordination:**
- The new `config/master.key` is gitignored and lives only in this worktree.
  It must be copied to the `main` checkout when the branch merges, and set as
  `RAILS_MASTER_KEY` in Hatchbox for production.
- `credentials.yml.enc` IS committed (encrypted). Because `main` and other
  worktrees share the repo, regenerating it here replaces the prior (empty)
  one; flag this at merge time so it doesn't collide with the other instance's
  work.

**Non-interactive editing (agent context):** `credentials:edit` opens `$EDITOR`.
To populate it without an interactive editor, point `EDITOR` at a tiny script
that writes the YAML to the temp path Rails passes as `$1`, then re-runs encrypt.
Real secret *values* are supplied by the user later; the build/tests do not need
them (Turnstile bypass when the secret is blank, mailer in `:test` mode).

## Routing

Inside the existing personal host constraint in `config/routes.rb`:

```ruby
constraints(host: personal_host) do
  scope module: :personal, as: :personal do
    root "pages#home"
    post "contact", to: "contacts#create", as: :contact
  end
end
```

## Error handling

- Blank/invalid Turnstile token → `false` from verifier → form re-render with a
  "Please complete the verification" message; no email sent.
- Model invalid → form re-render with field errors; no Turnstile call needed
  (validate first); no email sent.
- Mailgun raises → rescued; form re-render with "Couldn't send right now — try
  again in a moment."; logged.
- Every re-render includes a freshly rendered Turnstile widget (single-use token).

## Testing (Minitest + fixtures, no mocking libraries — house rule)

1. `ContactMessage` (instantiate directly; tableless, no fixture): valid with
   required fields; invalid without email/message; invalid email format.
2. `Turnstile::Verification` (plain DI, no mocks): bypass returns `true` when
   `secret` blank; `false` for blank token when `secret` present; with `http`
   injected, `true`/`false` per Cloudflare `success`; fail-closed when injected
   `http` raises.
3. `Personal::ContactsController` integration (`host! "spencernorman.io"`; the
   blank Turnstile secret means verification bypasses — no mocking needed):
   - missing fields → turbo_stream re-render (422), `deliveries` unchanged.
   - valid params → `deliveries` size +1, turbo_stream success panel.
   (The Turnstile-rejection branch is covered by the `Turnstile::Verification`
   unit tests; the controller wiring is a simple `unless verified?` guard.)
4. `ContactMailer#new_message`: correct `to`, `reply_to`, `subject`, body
   contains the message.

## Out of scope

- Cloudflare Worker deployment (server-side verification replaces it).
- Spam/rate limiting beyond Turnstile.
- Persisting submissions to a database.
- The Norman Simplified (studio) site's contact, if any.

## Success criteria

- Submitting a valid form with a passing Turnstile token emails
  `spencernorman@hey.com` (reply-to = submitter) and the panel swaps to the
  success state without a full page reload.
- A failed/absent Turnstile token never sends an email and shows an inline error.
- No plaintext secret values are committed; secrets live in encrypted
  credentials and `config/master.key` stays gitignored.
- `bin/rails test` is green with Turnstile stubbed and Mailgun in `:test` mode.
