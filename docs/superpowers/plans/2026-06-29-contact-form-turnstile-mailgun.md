# Contact Form (Turnstile + Mailgun + Turbo) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the personal site's stub contact form into a working, bot-protected form that verifies a Cloudflare Turnstile token server-side, emails Spencer via Mailgun, and gives Turbo-driven feedback.

**Architecture:** Turbo `form_with` POSTs to `Personal::ContactsController#create`. The controller validates a non-persisted `ContactMessage` (ActiveModel), verifies the Turnstile token via a `TurnstileVerifier` service (Cloudflare siteverify, no Worker), sends `ContactMailer.new_message(...).deliver_now` through Mailgun, and responds with a Turbo Stream that updates `#contact_panel` (success or re-rendered form). Secrets live in regenerated Rails encrypted credentials.

**Tech Stack:** Rails 8.1, Hotwire (Turbo + Stimulus), importmap, Tailwind v4, `mailgun-ruby`, Minitest. Spec: `docs/superpowers/specs/2026-06-29-contact-form-turnstile-mailgun-design.md`.

**Build/test independence:** Turnstile verification bypasses (returns true) when its credential is blank; the mailer runs in `:test` mode under test. So all tasks are buildable and testable before real Mailgun/Turnstile keys exist.

---

## REVISION (2026-06-29) — `sdnorm/development-skills` house rules

After Tasks 1–2 landed, the build was redirected to follow the team's `rails` skill. Changes to the tasks below:

- **No service objects.** Task 3's `app/services/turnstile_verifier.rb` is replaced by a **tableless model** `app/models/turnstile/verification.rb` (`Turnstile::Verification`, `ActiveModel::Model` + `ActiveModel::Attributes`, instance method `#verified?`). No `app/services/`.
- **`ContactMessage`** uses `ActiveModel::Attributes` (`attribute :x, :string`) rather than `attr_accessor` (small refactor of Task 2's output).
- **No mocking libraries** (also Minitest 6 removed `minitest/mock`). Tests use fixtures + plain dependency injection: `Turnstile::Verification` exposes an injectable `http` writer; controller integration tests rely on the blank-secret **bypass** for the happy path. No `.stub`.
- **Controller** (Task 6) orchestrates: `@contact_message.valid?` then `Turnstile::Verification.new(...).verified?`; Turnstile/delivery failures are added to `@contact_message.errors[:base]`; one re-render path; failure responds `:unprocessable_entity`.
- Form partial (Tasks 6/7) renders `contact_message.errors` (base + per-field) instead of `verification_error`/`delivery_error` locals.

The authoritative corrected code for Tasks 3/6/7 is carried in the implementer dispatch prompts. Everything else (Mailgun, Turbo flow, credentials) is unchanged.

---

### Task 1: Add Mailgun gem and regenerate credentials

**Files:**
- Modify: `Gemfile`
- Replace: `config/credentials.yml.enc` (regenerated)
- Create: `config/master.key` (generated, gitignored)

- [ ] **Step 1: Add the gem**

In `Gemfile`, after the `gem "jbuilder"` line (line ~30), add:

```ruby
# Send transactional email via Mailgun
gem "mailgun-ruby", "~> 1.3"
```

- [ ] **Step 2: Install**

Run: `bundle install`
Expected: `Bundle complete`, `mailgun-ruby` resolved.

- [ ] **Step 3: Remove the un-decryptable credentials file**

The existing `config/credentials.yml.enc` decrypts to empty and its master key is lost, so `credentials:edit` would fail to decrypt. Remove it so a fresh one is generated:

Run: `rm config/credentials.yml.enc`

- [ ] **Step 4: Regenerate credentials non-interactively with the secret structure**

Run:
```bash
cat > /tmp/cred_editor.sh <<'SH'
#!/bin/sh
cat > "$1" <<'YML'
turnstile:
  site_key: ""
  secret_key: ""
mailgun:
  api_key: ""
  domain: ""
  from: "Spencer Norman <no-reply@spencernorman.io>"
contact:
  recipient: "spencernorman@hey.com"
YML
SH
chmod +x /tmp/cred_editor.sh
EDITOR=/tmp/cred_editor.sh bin/rails credentials:edit
```
Expected: `File encrypted and saved.` This creates a new `config/master.key` and `config/credentials.yml.enc`.

- [ ] **Step 5: Verify the structure decrypts**

Run: `bin/rails runner 'puts Rails.application.credentials.dig(:contact, :recipient)'`
Expected: `spencernorman@hey.com`

- [ ] **Step 6: Confirm master.key is gitignored**

Run: `git check-ignore config/master.key && echo IGNORED`
Expected: `IGNORED` (it is — `.gitignore` line 35).

- [ ] **Step 7: Commit**

```bash
git add Gemfile Gemfile.lock config/credentials.yml.enc
git commit -m "chore: add mailgun-ruby and regenerate empty credentials

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

(Note: `config/master.key` is intentionally NOT committed. It must be copied to the `main` checkout and set as `RAILS_MASTER_KEY` in Hatchbox.)

---

### Task 2: ContactMessage form object

**Files:**
- Create: `app/models/contact_message.rb`
- Test: `test/models/contact_message_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/models/contact_message_test.rb`:

```ruby
require "test_helper"

class ContactMessageTest < ActiveSupport::TestCase
  test "valid with email and message" do
    assert ContactMessage.new(email: "a@b.com", message: "hi there").valid?
  end

  test "invalid without email" do
    assert_not ContactMessage.new(message: "hi there").valid?
  end

  test "invalid without message" do
    assert_not ContactMessage.new(email: "a@b.com").valid?
  end

  test "invalid with a malformed email" do
    assert_not ContactMessage.new(email: "nope", message: "hi there").valid?
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bin/rails test test/models/contact_message_test.rb`
Expected: FAIL — `uninitialized constant ContactMessage`.

- [ ] **Step 3: Implement the model**

Create `app/models/contact_message.rb`:

```ruby
class ContactMessage
  include ActiveModel::Model

  attr_accessor :name, :email, :message

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true
end
```

- [ ] **Step 4: Run to verify it passes**

Run: `bin/rails test test/models/contact_message_test.rb`
Expected: PASS — 4 runs, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/models/contact_message.rb test/models/contact_message_test.rb
git commit -m "feat: add ContactMessage form object

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: TurnstileVerifier service

**Files:**
- Create: `app/services/turnstile_verifier.rb`
- Test: `test/services/turnstile_verifier_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/services/turnstile_verifier_test.rb`:

```ruby
require "test_helper"

class TurnstileVerifierTest < ActiveSupport::TestCase
  test "bypasses and returns true when secret is unconfigured" do
    Rails.application.credentials.stub(:dig, nil) do
      assert TurnstileVerifier.call("any-token")
    end
  end

  test "returns false for a blank token when configured" do
    Rails.application.credentials.stub(:dig, "secret") do
      assert_not TurnstileVerifier.call("")
    end
  end

  test "returns true when siteverify reports success" do
    fake = Object.new
    def fake.body = '{"success":true}'
    Rails.application.credentials.stub(:dig, "secret") do
      Net::HTTP.stub(:post_form, fake) do
        assert TurnstileVerifier.call("good-token")
      end
    end
  end

  test "returns false when siteverify reports failure" do
    fake = Object.new
    def fake.body = '{"success":false}'
    Rails.application.credentials.stub(:dig, "secret") do
      Net::HTTP.stub(:post_form, fake) do
        assert_not TurnstileVerifier.call("bad-token")
      end
    end
  end

  test "fails closed on a network error" do
    Rails.application.credentials.stub(:dig, "secret") do
      Net::HTTP.stub(:post_form, ->(*) { raise SocketError, "boom" }) do
        assert_not TurnstileVerifier.call("good-token")
      end
    end
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bin/rails test test/services/turnstile_verifier_test.rb`
Expected: FAIL — `uninitialized constant TurnstileVerifier`.

- [ ] **Step 3: Implement the service**

Create `app/services/turnstile_verifier.rb`:

```ruby
require "net/http"
require "json"

# Verifies a Cloudflare Turnstile token server-side via siteverify.
# Fails closed (returns false) on a blank token or any network/parse error.
# Bypasses (returns true) when no secret is configured, so the form is usable
# in development/test before real keys exist.
class TurnstileVerifier
  ENDPOINT = "https://challenges.cloudflare.com/turnstile/v0/siteverify".freeze

  def self.call(token, remote_ip: nil)
    secret = Rails.application.credentials.dig(:turnstile, :secret_key)
    return true if secret.blank?
    return false if token.blank?

    params = { secret: secret, response: token }
    params[:remoteip] = remote_ip if remote_ip.present?

    response = Net::HTTP.post_form(URI(ENDPOINT), params)
    JSON.parse(response.body)["success"] == true
  rescue => e
    Rails.logger.warn("Turnstile verification error: #{e.class}: #{e.message}")
    false
  end
end
```

- [ ] **Step 4: Run to verify it passes**

Run: `bin/rails test test/services/turnstile_verifier_test.rb`
Expected: PASS — 5 runs, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/services/turnstile_verifier.rb test/services/turnstile_verifier_test.rb
git commit -m "feat: add server-side Turnstile verifier

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: ContactMailer and mailer views

**Files:**
- Modify: `app/mailers/application_mailer.rb`
- Create: `app/mailers/contact_mailer.rb`
- Create: `app/views/contact_mailer/new_message.html.erb`
- Create: `app/views/contact_mailer/new_message.text.erb`
- Test: `test/mailers/contact_mailer_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/mailers/contact_mailer_test.rb`:

```ruby
require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  test "new_message builds the inquiry email" do
    cm = ContactMessage.new(name: "Jane Doe", email: "jane@acme.com", message: "We have a billing problem.")
    mail = ContactMailer.new_message(cm)

    assert_equal ["spencernorman@hey.com"], mail.to
    assert_equal ["jane@acme.com"], mail.reply_to
    assert_match "Jane Doe", mail.subject
    assert_match "We have a billing problem.", mail.body.encoded
  end

  test "subject falls back to email when name is blank" do
    cm = ContactMessage.new(email: "jane@acme.com", message: "Hi")
    assert_match "jane@acme.com", ContactMailer.new_message(cm).subject
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bin/rails test test/mailers/contact_mailer_test.rb`
Expected: FAIL — `uninitialized constant ContactMailer`.

- [ ] **Step 3: Update ApplicationMailer default from**

Replace the contents of `app/mailers/application_mailer.rb`:

```ruby
class ApplicationMailer < ActionMailer::Base
  default from: "Spencer Norman <no-reply@spencernorman.io>"
  layout "mailer"
end
```

- [ ] **Step 4: Implement ContactMailer**

Create `app/mailers/contact_mailer.rb`:

```ruby
class ContactMailer < ApplicationMailer
  def new_message(contact_message)
    @contact_message = contact_message
    sender_label = contact_message.name.presence || contact_message.email

    mail(
      to: Rails.application.credentials.dig(:contact, :recipient) || "spencernorman@hey.com",
      from: Rails.application.credentials.dig(:mailgun, :from).presence || "Spencer Norman <no-reply@spencernorman.io>",
      reply_to: contact_message.email,
      subject: "New portfolio inquiry from #{sender_label}"
    )
  end
end
```

- [ ] **Step 5: Create the mailer views**

Create `app/views/contact_mailer/new_message.text.erb`:

```erb
New portfolio inquiry

Name:  <%= @contact_message.name.presence || "(not provided)" %>
Email: <%= @contact_message.email %>

Message:
<%= @contact_message.message %>
```

Create `app/views/contact_mailer/new_message.html.erb`:

```erb
<h2>New portfolio inquiry</h2>
<p><strong>Name:</strong> <%= @contact_message.name.presence || "(not provided)" %></p>
<p><strong>Email:</strong> <%= @contact_message.email %></p>
<p><strong>Message:</strong></p>
<p><%= simple_format(@contact_message.message) %></p>
```

- [ ] **Step 6: Run to verify it passes**

Run: `bin/rails test test/mailers/contact_mailer_test.rb`
Expected: PASS — 2 runs, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add app/mailers/ app/views/contact_mailer/ test/mailers/contact_mailer_test.rb
git commit -m "feat: add ContactMailer for inquiry emails

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Configure Mailgun delivery

**Files:**
- Modify: `config/environments/production.rb`
- Modify: `config/environments/development.rb`

- [ ] **Step 1: Configure production delivery**

In `config/environments/production.rb`, find the line
`# config.action_mailer.raise_delivery_errors = false` (line ~79) and add immediately after it:

```ruby
  config.action_mailer.delivery_method = :mailgun
  config.action_mailer.mailgun_settings = {
    api_key: Rails.application.credentials.dig(:mailgun, :api_key),
    domain:  Rails.application.credentials.dig(:mailgun, :domain)
    # US region is the gem default; EU would add api_host: "api.eu.mailgun.net"
  }
  config.action_mailer.default_url_options = { host: "spencernorman.io" }
```

- [ ] **Step 2: Configure development delivery (only when keys exist)**

In `config/environments/development.rb`, find
`config.action_mailer.perform_caching = false` (line ~42) and add immediately after it:

```ruby

  # Use Mailgun in development only when configured; otherwise leave the default
  # so the form works locally without keys (delivery silently no-ops).
  if Rails.application.credentials.dig(:mailgun, :api_key).present?
    config.action_mailer.delivery_method = :mailgun
    config.action_mailer.mailgun_settings = {
      api_key: Rails.application.credentials.dig(:mailgun, :api_key),
      domain:  Rails.application.credentials.dig(:mailgun, :domain)
    }
  end
  config.action_mailer.default_url_options = { host: "spencernorman.localhost", port: 3000 }
```

- [ ] **Step 3: Verify both environments boot**

Run: `RAILS_ENV=production SECRET_KEY_BASE=dummy bin/rails runner 'puts ActionMailer::Base.delivery_method'`
Expected: `mailgun`

Run: `bin/rails runner 'puts ActionMailer::Base.delivery_method'`
Expected: `test` in the test default, or the development default (`:smtp`) — NOT an error. (Dev has no keys, so the `if` is skipped.)

- [ ] **Step 4: Commit**

```bash
git add config/environments/production.rb config/environments/development.rb
git commit -m "feat: configure Mailgun delivery (prod always, dev when keyed)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Route, controller, and Turbo Stream response

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/personal/contacts_controller.rb`
- Create: `app/views/personal/contacts/create.turbo_stream.erb`
- Test: `test/controllers/personal/contacts_controller_test.rb`

> The frontend partials referenced by the turbo_stream view (`personal/pages/_contact_form`, `personal/pages/_contact_success`) are created in Task 7. To keep this task's tests green on their own, create minimal versions now and finalize them in Task 7. Each step below is explicit.

- [ ] **Step 1: Add the route**

In `config/routes.rb`, inside the personal host constraint, add the `post "contact"` line so the block reads:

```ruby
  # ---- Personal portfolio (spencernorman.io) ----
  constraints(host: personal_host) do
    scope module: :personal, as: :personal do
      root "pages#home"
      post "contact", to: "contacts#create", as: :contact
    end
  end
```

- [ ] **Step 2: Verify the route name**

Run: `bin/rails routes -g contact`
Expected: a row showing `personal_contact POST /contact personal/contacts#create`.

- [ ] **Step 3: Create minimal frontend partials (finalized in Task 7)**

Create `app/views/personal/pages/_contact_form.html.erb`:

```erb
<%# locals: contact_message, verification_error:, delivery_error: %>
<%= form_with model: contact_message, url: personal_contact_path, class: "sn-contact-form" do |f| %>
  <% if local_assigns[:verification_error].present? %>
    <div class="sn-form-alert" role="alert"><%= verification_error %></div>
  <% end %>
  <% if local_assigns[:delivery_error].present? %>
    <div class="sn-form-alert" role="alert"><%= delivery_error %></div>
  <% end %>
  <div class="sn-field">
    <%= f.label :email, "Email", class: "sn-field__label" %>
    <%= f.email_field :email, class: "sn-input" %>
  </div>
  <div class="sn-field">
    <%= f.label :message, "Message", class: "sn-field__label" %>
    <%= f.text_area :message, class: "sn-textarea" %>
  </div>
  <button type="submit" class="sn-btn sn-btn--primary sn-btn--lg sn-btn--block"><span>Send message</span></button>
<% end %>
```

Create `app/views/personal/pages/_contact_success.html.erb`:

```erb
<div class="sn-contact-success" style="display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; min-height: 268px; gap: 14px;">
  <h3 style="font-family: var(--font-display); font-weight: 700; font-size: 22px; color: var(--text-strong); margin: 0;">Message sent</h3>
  <p style="font-size: 15px; color: var(--text-muted); margin: 0; max-width: 30ch;">Thanks — I'll get back to you within a day.</p>
</div>
```

- [ ] **Step 4: Create the turbo_stream response view**

Create `app/views/personal/contacts/create.turbo_stream.erb`:

```erb
<% if @outcome == :success %>
  <%= turbo_stream.update "contact_panel" do %>
    <%= render "personal/pages/contact_success" %>
  <% end %>
<% else %>
  <%= turbo_stream.update "contact_panel" do %>
    <%= render "personal/pages/contact_form",
          contact_message: @contact_message,
          verification_error: @verification_error,
          delivery_error: @delivery_error %>
  <% end %>
<% end %>
```

- [ ] **Step 5: Write the failing controller test**

Create `test/controllers/personal/contacts_controller_test.rb`:

```ruby
require "test_helper"

class Personal::ContactsControllerTest < ActionDispatch::IntegrationTest
  setup { host! "spencernorman.io" }

  test "missing fields re-render the form and send nothing" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post personal_contact_path,
        params: { contact_message: { name: "", email: "", message: "" } },
        as: :turbo_stream
    end
    assert_response :success
    assert_match "contact_panel", @response.body
  end

  test "a failed Turnstile check sends nothing" do
    TurnstileVerifier.stub(:call, false) do
      assert_no_difference "ActionMailer::Base.deliveries.size" do
        post personal_contact_path,
          params: { contact_message: { email: "a@b.com", message: "hello there" },
                    "cf-turnstile-response": "tok" },
          as: :turbo_stream
      end
    end
    assert_response :success
  end

  test "a valid submission sends one email" do
    TurnstileVerifier.stub(:call, true) do
      assert_difference "ActionMailer::Base.deliveries.size", 1 do
        post personal_contact_path,
          params: { contact_message: { name: "Jane", email: "a@b.com", message: "hello there" },
                    "cf-turnstile-response": "tok" },
          as: :turbo_stream
      end
    end
    assert_response :success
  end
end
```

- [ ] **Step 6: Run to verify it fails**

Run: `bin/rails test test/controllers/personal/contacts_controller_test.rb`
Expected: FAIL — `uninitialized constant Personal::ContactsController`.

- [ ] **Step 7: Implement the controller**

Create `app/controllers/personal/contacts_controller.rb`:

```ruby
module Personal
  class ContactsController < BaseController
    def create
      @contact_message = ContactMessage.new(contact_params)

      if @contact_message.invalid?
        return render_panel(:form)
      end

      unless TurnstileVerifier.call(params["cf-turnstile-response"], remote_ip: request.remote_ip)
        @verification_error = "Please complete the verification and try again."
        return render_panel(:form)
      end

      ContactMailer.new_message(@contact_message).deliver_now
      render_panel(:success)
    rescue => e
      Rails.logger.error("Contact delivery failed: #{e.class}: #{e.message}")
      @delivery_error = "Couldn't send right now — please try again in a moment."
      render_panel(:form)
    end

    private

    def contact_params
      params.require(:contact_message).permit(:name, :email, :message)
    end

    def render_panel(outcome)
      @outcome = outcome
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path(anchor: "contact") }
      end
    end
  end
end
```

- [ ] **Step 8: Run to verify it passes**

Run: `bin/rails test test/controllers/personal/contacts_controller_test.rb`
Expected: PASS — 3 runs, 0 failures. (Turnstile is stubbed; the valid case delivers via `:test`.)

- [ ] **Step 9: Commit**

```bash
git add config/routes.rb app/controllers/personal/contacts_controller.rb \
        app/views/personal/contacts/ app/views/personal/pages/_contact_form.html.erb \
        app/views/personal/pages/_contact_success.html.erb \
        test/controllers/personal/contacts_controller_test.rb
git commit -m "feat: contact form endpoint with Turnstile gate + Turbo response

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Wire the frontend (form, widget, Stimulus, layout, CSS)

**Files:**
- Rewrite: `app/views/personal/pages/_contact.html.erb`
- Finalize: `app/views/personal/pages/_contact_form.html.erb`
- Finalize: `app/views/personal/pages/_contact_success.html.erb`
- Create: `app/javascript/controllers/turnstile_controller.js`
- Delete: `app/javascript/controllers/contact_controller.js`
- Modify: `app/views/layouts/personal.html.erb`
- Modify: `app/assets/stylesheets/design_system/portfolio.css`

- [ ] **Step 1: Rewrite the contact section to use the panel + form partial**

Replace the entire contents of `app/views/personal/pages/_contact.html.erb`:

```erb
<%# Contact — inverse CTA with a working, bot-protected form (Turnstile + Mailgun) %>
<section id="contact" style="background: var(--surface-inverse); color: var(--text-on-inverse);">
  <div class="sn-contact-grid" style="max-width: var(--container); margin: 0 auto; padding: 84px 32px; display: grid; grid-template-columns: 1fr 1fr; gap: 64px; align-items: center;">
    <div>
      <h2 style="font-family: var(--font-display); font-weight: 800; font-size: clamp(34px,4.4vw,52px); letter-spacing: -0.035em; line-height: 1.02; color: var(--paper-50); margin: 0;">
        Let's build something<br>that lasts.
      </h2>
      <p style="font-size: 17px; line-height: 1.6; color: var(--ink-300); max-width: 42ch; margin: 22px 0 0;">
        Open to staff and senior Rails roles, plus select consulting through Norman Simplified. If you've got a complex, high-stakes workflow that needs simplifying, I'd love to hear about it — drop a note using the form and I'll get back to you.
      </p>
    </div>

    <div id="contact_panel" class="sn-contact-card" style="background: var(--paper-50); border-radius: var(--radius-2xl); padding: 28px; box-shadow: var(--shadow-lg);">
      <%= render "personal/pages/contact_form", contact_message: ContactMessage.new, verification_error: nil, delivery_error: nil %>
    </div>
  </div>
</section>
```

- [ ] **Step 2: Finalize the form partial (styled fields, errors, widget)**

Replace the entire contents of `app/views/personal/pages/_contact_form.html.erb`:

```erb
<%# locals: contact_message, verification_error:, delivery_error: %>
<%= form_with model: contact_message, url: personal_contact_path, class: "sn-contact-form" do |f| %>
  <% if local_assigns[:verification_error].present? %>
    <div class="sn-form-alert" role="alert"><%= verification_error %></div>
  <% end %>
  <% if local_assigns[:delivery_error].present? %>
    <div class="sn-form-alert" role="alert"><%= delivery_error %></div>
  <% end %>

  <div class="sn-field">
    <%= f.label :name, "Name", class: "sn-field__label" %>
    <%= f.text_field :name, class: "sn-input", placeholder: "Jane Doe" %>
  </div>

  <div class="sn-field">
    <%= f.label :email, class: "sn-field__label" do %>Email<span class="sn-field__req"> *</span><% end %>
    <%= f.email_field :email, class: "sn-input", placeholder: "you@company.com" %>
    <% if contact_message.errors[:email].any? %>
      <span class="sn-field__hint">Email <%= contact_message.errors[:email].first %></span>
    <% end %>
  </div>

  <div class="sn-field">
    <%= f.label :message, "What are you building?", class: "sn-field__label" do %>What are you building?<span class="sn-field__req"> *</span><% end %>
    <%= f.text_area :message, class: "sn-textarea", placeholder: "A few sentences on the problem…" %>
    <% if contact_message.errors[:message].any? %>
      <span class="sn-field__hint">Message <%= contact_message.errors[:message].first %></span>
    <% end %>
  </div>

  <% sitekey = Rails.application.credentials.dig(:turnstile, :site_key) %>
  <% if sitekey.present? %>
    <div data-controller="turnstile" data-turnstile-sitekey-value="<%= sitekey %>" style="margin-top: 2px;"></div>
  <% end %>

  <button type="submit" class="sn-btn sn-btn--primary sn-btn--lg sn-btn--block"><span>Send message</span></button>
<% end %>
```

- [ ] **Step 3: Finalize the success partial (with check icon)**

Replace the entire contents of `app/views/personal/pages/_contact_success.html.erb`:

```erb
<div class="sn-contact-success" style="display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; min-height: 268px; gap: 14px;">
  <div style="width: 52px; height: 52px; border-radius: 50%; background: var(--success-tint); color: var(--success); display: flex; align-items: center; justify-content: center;">
    <svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>
  </div>
  <h3 style="font-family: var(--font-display); font-weight: 700; font-size: 22px; letter-spacing: -0.02em; color: var(--text-strong); margin: 0;">Message sent</h3>
  <p style="font-size: 15px; color: var(--text-muted); margin: 0; max-width: 30ch;">Thanks — I'll get back to you within a day.</p>
</div>
```

- [ ] **Step 4: Add the Turnstile Stimulus controller**

Create `app/javascript/controllers/turnstile_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Explicitly renders the Cloudflare Turnstile widget. Turbo navigations don't
// fire window.onload, so we render on connect and wait for the async script.
export default class extends Controller {
  static values = { sitekey: String }

  connect() {
    if (!this.sitekeyValue) return
    this.renderWhenReady()
  }

  renderWhenReady() {
    if (window.turnstile) {
      this.widgetId = window.turnstile.render(this.element, {
        sitekey: this.sitekeyValue,
        action: "turnstile-spin-v1",
      })
    } else {
      this.readyTimer = setTimeout(() => this.renderWhenReady(), 100)
    }
  }

  disconnect() {
    if (this.readyTimer) clearTimeout(this.readyTimer)
    if (this.widgetId && window.turnstile) window.turnstile.remove(this.widgetId)
  }
}
```

- [ ] **Step 5: Delete the obsolete stub controller**

Run: `git rm app/javascript/controllers/contact_controller.js`

- [ ] **Step 6: Add the Turnstile script to the personal layout head**

In `app/views/layouts/personal.html.erb`, add this line immediately before `<%= stylesheet_link_tag "tailwind", ... %>`:

```erb
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?render=explicit" async defer></script>
```

- [ ] **Step 7: Update contact CSS (remove stub toggles, add alert style)**

In `app/assets/stylesheets/design_system/portfolio.css`, replace the block:

```css
/* ---- Contact form: submit -> success ---- */
.sn-contact-form { display: flex; flex-direction: column; gap: 16px; }
.sn-contact-card .sn-contact-success { display: none; }
.sn-contact-card.is-sent .sn-contact-form { display: none; }
.sn-contact-card.is-sent .sn-contact-success { display: flex; }
```

with:

```css
/* ---- Contact form ---- */
.sn-contact-form { display: flex; flex-direction: column; gap: 16px; }
.sn-form-alert {
  font-family: var(--font-sans);
  font-size: 14px;
  color: var(--danger);
  background: var(--danger-tint);
  border-radius: var(--radius-md);
  padding: 10px 12px;
}
```

- [ ] **Step 8: Build and run the full suite**

Run: `bin/rails tailwindcss:build`
Expected: exits 0.

Run: `bin/rails test`
Expected: all green (model + verifier + mailer + controller + existing routing tests).

- [ ] **Step 9: Commit**

```bash
git add app/views/personal/pages/_contact.html.erb \
        app/views/personal/pages/_contact_form.html.erb \
        app/views/personal/pages/_contact_success.html.erb \
        app/javascript/controllers/turnstile_controller.js \
        app/views/layouts/personal.html.erb \
        app/assets/stylesheets/design_system/portfolio.css \
        app/assets/builds/tailwind.css
git commit -m "feat: wire contact form to Turbo + Turnstile widget

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Manual verification (no real keys)

**Files:** none (verification only)

- [ ] **Step 1: Confirm CSP does not block Cloudflare**

Run: `grep -rn "content_security_policy" config/initializers/ 2>/dev/null || echo "no CSP initializer"`
Expected: `no CSP initializer` (Rails default initializer is absent/commented, so `csp_meta_tag` emits nothing restrictive). If a CSP IS configured, add `https://challenges.cloudflare.com` to `script_src` and `frame_src` and note it.

- [ ] **Step 2: Boot the app**

Run (background): `bin/rails server -p 3033 -b 127.0.0.1`
Then load `http://spencernorman.localhost:3033/#contact`.

- [ ] **Step 3: Verify the form submits via Turbo with the bypass**

With no Turnstile site key set, the widget div is absent and the server bypass returns true. Fill in a valid email + message, submit, and confirm the panel swaps to "Message sent" without a full page reload (no flash of white, URL unchanged).

Expected: success panel renders in place. Check the server log shows a `ContactMailer#new_message` delivery (in dev without Mailgun keys, the default delivery method no-ops without raising).

- [ ] **Step 4: Verify validation feedback**

Submit with an empty message. Expected: the panel re-renders the form in place with the "Message can't be blank" hint; no page reload.

- [ ] **Step 5: Final report**

Summarize: tests green, form works end-to-end with the bypass, and the remaining manual steps for the user (populate credentials with real Turnstile + Mailgun values via `bin/rails credentials:edit`, create the Turnstile widget, copy `master.key` to main + Hatchbox).

---

## What the user must do after this plan (real keys)

1. Create a Turnstile widget (Cloudflare dashboard or the turnstile-spin `widget-create.sh`) for domains `spencernorman.io`, `localhost`, `127.0.0.1`. Note the **site key** and **secret key**.
2. Get the Mailgun **API key** (US region) and a **verified sending domain**.
3. Run `bin/rails credentials:edit` and fill in `turnstile.site_key`, `turnstile.secret_key`, `mailgun.api_key`, `mailgun.domain`, and confirm `mailgun.from` is on the verified domain.
4. Copy `config/master.key` into the `main` checkout and set `RAILS_MASTER_KEY` in Hatchbox.

## Self-review notes (coverage vs spec)

- Server-side verification → Task 3 + Task 6. Mailgun → Task 1, 4, 5. Credentials → Task 1. Turbo feedback → Task 6, 7. Stimulus re-render gotcha → Task 7 Step 4. Tests → Tasks 2,3,4,6. Error handling (invalid/turnstile/delivery) → Task 6 Step 7. Out-of-scope items remain untouched.
