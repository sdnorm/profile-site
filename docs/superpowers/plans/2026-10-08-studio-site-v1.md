# Norman Simplified Site v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship normansimplified.com v1, four pages ("Technology, simplified.") in the Clear Workshop skin, with a working "Request a call" inquiry form.

**Architecture:** Everything lives in the existing `studio` host-constraint namespace (`Studio::BaseController`, `layouts/studio`). A tableless `Studio::Inquiry` plus `InquiryMailer` mirrors the personal contact flow (Turnstile + Mailgun + Turbo Stream panel swap). The studio skin is a scoped `studio.css` overriding semantic tokens; shared components first get de-Honeyed so they read tokens instead of raw palette variables.

**Tech Stack:** Rails 8, Hotwire (Turbo, Stimulus via importmap), Tailwind v4 + design-system CSS, Minitest (no mocks), `bin/ci`.

**Spec:** `docs/superpowers/specs/2026-10-08-studio-site-v1-design.md`
**Copy source:** `docs/superpowers/plans/2026-10-08-studio-site-v1-copy.md` (final words for every page; use it verbatim unless it conflicts with the spec)

---

## Lanes and order

| Lane | Owner | Tasks | Files owned |
|------|-------|-------|-------------|
| Backend | Claude | 1, 2, 3, 4 | `config/routes.rb`, `app/controllers/studio/**`, `app/models/studio/**`, `app/mailers/inquiry_mailer.rb`, `app/views/inquiry_mailer/**`, `test/**` |
| UI | Codex | 5, 6, 7, 8, 9, 10, 11 | `app/assets/**`, `app/javascript/controllers/**`, `app/views/layouts/studio.html.erb`, `app/views/studio/**` (after Task 1 / Task 4 hand them over) |
| Verify | Claude | 12 | none |

Order: Task 1 first (creates routes and placeholder views). Then Tasks 2–4 (Claude) run **in parallel with** Tasks 5–6 (Codex), because their files don't overlap. Tasks 7–10 need Task 1. Task 11 needs Task 4. Task 12 comes last.

Rules for every task: run `bin/rails test` before committing, one commit per task, branch `studio-site-v1`, no AI attribution in commits, never touch `app/views/personal/**` (the token refactor in Task 5 must leave the personal site pixel-identical).

## File map

```
config/routes.rb                                   # studio routes (T1)
app/controllers/studio/pages_controller.rb         # home, ai_integration, how_we_work (T1)
app/controllers/studio/inquiries_controller.rb     # new, create (T4)
app/models/studio/inquiry.rb                       # tableless inquiry (T2)
app/mailers/inquiry_mailer.rb                      # new_inquiry (T3)
app/views/inquiry_mailer/new_inquiry.{text,html}.erb (T3)
app/views/studio/inquiries/{new.html.erb,create.turbo_stream.erb,_form.html.erb,_success.html.erb} (T4, restyled T11)
app/views/studio/pages/{home,ai_integration,how_we_work}.html.erb (T1 placeholders → T8–T10)
app/views/studio/pages/_*.html.erb                  # section partials (T7–T10)
app/views/layouts/studio.html.erb                  # meta, nav, footer (T7)
app/assets/stylesheets/design_system/colors.css    # new semantic tokens (T5)
app/assets/stylesheets/design_system/components.css, portfolio.css  # tokens only (T5)
app/assets/stylesheets/design_system/studio.css    # Clear Workshop skin (T6)
app/assets/tailwind/application.css                # import studio.css (T6)
app/javascript/controllers/{nav,explorer}_controller.js (T7, T9)
test/integration/site_routing_test.rb              # (T1)
test/integration/studio_pages_test.rb              # (T1, extended T7–T10)
test/models/studio/inquiry_test.rb                 # (T2)
test/mailers/inquiry_mailer_test.rb                # (T3)
test/controllers/studio/inquiries_controller_test.rb # (T4)
```

---

### Task 1: Studio routes, page actions, placeholder views (Claude)

**Files:**
- Modify: `config/routes.rb` (studio constraint block)
- Modify: `app/controllers/studio/pages_controller.rb`
- Create: `app/views/studio/pages/ai_integration.html.erb`, `app/views/studio/pages/how_we_work.html.erb`
- Test: `test/integration/studio_pages_test.rb`, `test/integration/site_routing_test.rb`

- [ ] **Step 1: Write the failing tests**

`test/integration/studio_pages_test.rb`:
```ruby
require "test_helper"

class StudioPagesTest < ActionDispatch::IntegrationTest
  setup { host! "normansimplified.com" }

  test "studio pages render in the studio layout" do
    [ "/", "/ai-integration", "/how-we-work" ].each do |path|
      get path
      assert_response :success, "expected #{path} to render"
      assert_select "body[data-site=studio]"
    end
  end
end
```

Append to `test/integration/site_routing_test.rb` (inside the class):
```ruby
  test "studio-only pages are not reachable on the personal host" do
    host! "spencernorman.io"
    [ "/ai-integration", "/how-we-work", "/contact" ].each do |path|
      get path
      assert_response :not_found, "expected #{path} to 404 on the personal host"
    end
  end
```

- [ ] **Step 2: Run to verify they fail**

Run: `bin/rails test test/integration/studio_pages_test.rb test/integration/site_routing_test.rb`
Expected: StudioPagesTest fails (404 on `/ai-integration`). The personal-host test may already pass (no route), which is fine because it guards the boundary.

- [ ] **Step 3: Implement**

`config/routes.rb` studio block becomes:
```ruby
  constraints(host: studio_host) do
    scope module: :studio, as: :studio do
      root "pages#home"
      get  "ai-integration", to: "pages#ai_integration", as: :ai_integration
      get  "how-we-work",    to: "pages#how_we_work",    as: :how_we_work
      get  "contact",        to: "inquiries#new",        as: :contact
      post "contact",        to: "inquiries#create"
    end
  end
```

`app/controllers/studio/pages_controller.rb`:
```ruby
module Studio
  class PagesController < BaseController
    def home; end
    def ai_integration; end
    def how_we_work; end
  end
end
```

`app/views/studio/pages/ai_integration.html.erb`:
```erb
<main class="mx-auto max-w-3xl px-6 py-20"><h1 class="t-display">AI integration</h1></main>
```

`app/views/studio/pages/how_we_work.html.erb`:
```erb
<main class="mx-auto max-w-3xl px-6 py-20"><h1 class="t-display">How we work</h1></main>
```

(`/contact` routes to `inquiries#new`, which arrives in Task 4. Until then the personal-host 404 test still passes and nothing links to it.)

- [ ] **Step 4: Run tests**

Run: `bin/rails test`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add config/routes.rb app/controllers/studio/pages_controller.rb app/views/studio/pages test/integration
git commit -m "feat(studio): routes and placeholder pages for site v1"
```

Hand-off: `app/views/studio/pages/**` now belongs to Codex.

---

### Task 2: `Studio::Inquiry` model (Claude)

**Files:**
- Create: `app/models/studio/inquiry.rb`
- Test: `test/models/studio/inquiry_test.rb`

- [ ] **Step 1: Write the failing test**

```ruby
require "test_helper"

class Studio::InquiryTest < ActiveSupport::TestCase
  def build(**attrs) = Studio::Inquiry.new({ email: "a@b.com", message: "We drown in PDFs." }.merge(attrs))

  test "valid with email and message" do
    assert build.valid?
  end

  test "interest defaults to not_sure" do
    assert_equal "not_sure", build.interest
  end

  test "invalid without email, with a malformed email, or without a message" do
    assert_not build(email: "").valid?
    assert_not build(email: "nope").valid?
    assert_not build(message: "").valid?
  end

  test "interest must be a known lane" do
    Studio::Inquiry::INTERESTS.each { |i| assert build(interest: i).valid?, i }
    assert_not build(interest: "crypto").valid?
  end

  test "interest_label is human readable" do
    assert_equal "Build", build(interest: "build").interest_label
    assert_equal "Signal Audit", build(interest: "audit").interest_label
    assert_equal "Not sure yet", build.interest_label
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bin/rails test test/models/studio/inquiry_test.rb`
Expected: FAIL, `uninitialized constant Studio::Inquiry`.

- [ ] **Step 3: Implement**

`app/models/studio/inquiry.rb`:
```ruby
module Studio
  # A "Request a call" submission from normansimplified.com. Tableless: it is emailed, not stored.
  class Inquiry
    include ActiveModel::Model
    include ActiveModel::Attributes

    INTEREST_LABELS = {
      "adopt" => "Adopt",
      "automate" => "Automate",
      "build" => "Build",
      "audit" => "Signal Audit",
      "not_sure" => "Not sure yet"
    }.freeze
    INTERESTS = INTEREST_LABELS.keys.freeze

    attribute :name, :string
    attribute :email, :string
    attribute :company, :string
    attribute :interest, :string, default: "not_sure"
    attribute :message, :string

    validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :message, presence: true
    validates :interest, inclusion: { in: INTERESTS }

    def interest_label = INTEREST_LABELS.fetch(interest, interest.to_s.humanize)
  end
end
```

- [ ] **Step 4: Run tests**

Run: `bin/rails test test/models/studio/inquiry_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/models/studio/inquiry.rb test/models/studio/inquiry_test.rb
git commit -m "feat(studio): Studio::Inquiry tableless model"
```

---

### Task 3: `InquiryMailer` (Claude)

**Files:**
- Create: `app/mailers/inquiry_mailer.rb`, `app/views/inquiry_mailer/new_inquiry.text.erb`, `app/views/inquiry_mailer/new_inquiry.html.erb`
- Test: `test/mailers/inquiry_mailer_test.rb`

- [ ] **Step 1: Write the failing test**

```ruby
require "test_helper"

class InquiryMailerTest < ActionMailer::TestCase
  test "new_inquiry builds the email" do
    inquiry = Studio::Inquiry.new(name: "Jane Doe", email: "jane@acme.com", company: "Acme Supply",
                                  interest: "build", message: "Our order intake is all PDFs.")
    mail = InquiryMailer.new_inquiry(inquiry)

    assert_equal [ "spencernorman@hey.com" ], mail.to
    assert_equal [ "jane@acme.com" ], mail.reply_to
    assert_equal "New Norman Simplified inquiry (Build) from Jane Doe", mail.subject
    assert_match "Acme Supply", mail.body.encoded
    assert_match "Our order intake is all PDFs.", mail.body.encoded
  end

  test "subject falls back to email when name is blank" do
    inquiry = Studio::Inquiry.new(email: "jane@acme.com", message: "Hi")
    assert_equal "New Norman Simplified inquiry (Not sure yet) from jane@acme.com",
                 InquiryMailer.new_inquiry(inquiry).subject
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bin/rails test test/mailers/inquiry_mailer_test.rb`
Expected: FAIL, `uninitialized constant InquiryMailer`.

- [ ] **Step 3: Implement**

`app/mailers/inquiry_mailer.rb`:
```ruby
class InquiryMailer < ApplicationMailer
  def new_inquiry(inquiry)
    @inquiry = inquiry
    sender_label = inquiry.name.presence || inquiry.email

    mail(
      to: Rails.application.credentials.dig(:contact, :recipient) || "spencernorman@hey.com",
      from: Rails.application.credentials.dig(:mailgun, :from).presence || "Norman Simplified <no-reply@spencernorman.io>",
      reply_to: inquiry.email,
      subject: "New Norman Simplified inquiry (#{inquiry.interest_label}) from #{sender_label}"
    )
  end
end
```

`app/views/inquiry_mailer/new_inquiry.text.erb`:
```erb
New Norman Simplified inquiry

Interest: <%= @inquiry.interest_label %>
Name:     <%= @inquiry.name.presence || "(not provided)" %>
Company:  <%= @inquiry.company.presence || "(not provided)" %>
Email:    <%= @inquiry.email %>

Message:
<%= @inquiry.message %>
```

`app/views/inquiry_mailer/new_inquiry.html.erb`:
```erb
<h2>New Norman Simplified inquiry</h2>
<p><strong>Interest:</strong> <%= @inquiry.interest_label %></p>
<p><strong>Name:</strong> <%= @inquiry.name.presence || "(not provided)" %></p>
<p><strong>Company:</strong> <%= @inquiry.company.presence || "(not provided)" %></p>
<p><strong>Email:</strong> <%= @inquiry.email %></p>
<p><strong>Message:</strong></p>
<%= simple_format(@inquiry.message) %>
```

- [ ] **Step 4: Run tests**

Run: `bin/rails test test/mailers/inquiry_mailer_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/mailers/inquiry_mailer.rb app/views/inquiry_mailer test/mailers/inquiry_mailer_test.rb
git commit -m "feat(studio): InquiryMailer for Request-a-call submissions"
```

---

### Task 4: `Studio::InquiriesController` and functional form views (Claude)

**Files:**
- Create: `app/controllers/studio/inquiries_controller.rb`
- Create: `app/views/studio/inquiries/new.html.erb`, `create.turbo_stream.erb`, `_form.html.erb`, `_success.html.erb`
- Test: `test/controllers/studio/inquiries_controller_test.rb`

- [ ] **Step 1: Write the failing test**

```ruby
require "test_helper"

class Studio::InquiriesControllerTest < ActionDispatch::IntegrationTest
  setup { host! "normansimplified.com" }

  def valid_params = { studio_inquiry: { name: "Jane", email: "jane@acme.com", interest: "automate", message: "Invoices by hand." } }

  test "new renders the form with interest preselected from the query" do
    get studio_contact_path(interest: "build")
    assert_response :success
    assert_select "body[data-site=studio]"
    assert_select "select[name='studio_inquiry[interest]'] option[selected][value=build]"
  end

  test "new ignores an unknown interest" do
    get studio_contact_path(interest: "crypto")
    assert_response :success
    assert_select "select[name='studio_inquiry[interest]'] option[selected][value=not_sure]"
  end

  test "valid turbo submission sends one email and renders success" do
    # Turnstile secret is blank in test, so Turnstile::Verification bypasses (no mock needed).
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post studio_contact_path, params: valid_params, as: :turbo_stream
    end
    assert_response :success
    assert_match "inquiry_panel", @response.body
    assert_match "Request received", @response.body
    assert_match "(Automate)", ActionMailer::Base.deliveries.last.subject
  end

  test "invalid turbo submission re-renders the form (422) and sends nothing" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post studio_contact_path, params: { studio_inquiry: { email: "", message: "" } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_match "inquiry_panel", @response.body
  end

  test "html fallback: success redirects with 303, errors re-render with 422" do
    post studio_contact_path, params: valid_params
    assert_response :see_other
    assert_redirected_to studio_contact_path
    follow_redirect!
    assert_match "Request received", @response.body

    post studio_contact_path, params: { studio_inquiry: { email: "nope", message: "" } }
    assert_response :unprocessable_entity
    assert_select "form[action='#{studio_contact_path}']"
  end
end
```

- [ ] **Step 2: Run to verify it fails**

Run: `bin/rails test test/controllers/studio/inquiries_controller_test.rb`
Expected: FAIL, `uninitialized constant Studio::InquiriesController`.

- [ ] **Step 3: Implement the controller**

`app/controllers/studio/inquiries_controller.rb`:
```ruby
module Studio
  class InquiriesController < BaseController
    def new
      @inquiry = Inquiry.new(interest: requested_interest)
      @sent = flash[:inquiry_sent].present?
    end

    def create
      @inquiry = Inquiry.new(inquiry_params)

      if @inquiry.valid? && turnstile_verified?
        InquiryMailer.new_inquiry(@inquiry).deliver_now
        @sent = true
      end

      respond
    rescue => e
      Rails.logger.error("Inquiry delivery failed: #{e.class}: #{e.message}")
      @inquiry.errors.add(:base, "Couldn't send right now. Please try again in a moment.")
      respond
    end

    private

    def inquiry_params
      params.require(:studio_inquiry).permit(:name, :email, :company, :interest, :message)
    end

    def requested_interest
      Inquiry::INTERESTS.include?(params[:interest]) ? params[:interest] : "not_sure"
    end

    def turnstile_verified?
      verified = Turnstile::Verification.new(
        token: params["cf-turnstile-response"], remote_ip: request.remote_ip
      ).verified?
      @inquiry.errors.add(:base, "Please complete the verification and try again.") unless verified
      verified
    end

    def respond
      respond_to do |format|
        format.turbo_stream { render :create, status: (@sent ? :ok : :unprocessable_entity) }
        format.html do
          if @sent
            redirect_to studio_contact_path, status: :see_other, flash: { inquiry_sent: true }
          else
            render :new, status: :unprocessable_entity
          end
        end
      end
    end
  end
end
```

- [ ] **Step 4: Implement the functional views** (Codex restyles them in Task 11; keep these ids and field names)

`app/views/studio/inquiries/new.html.erb`:
```erb
<% content_for :title, "Request a call · Norman Simplified" %>
<main class="mx-auto max-w-2xl px-6 py-20">
  <h1 class="t-display">Request a call</h1>
  <div id="inquiry_panel">
    <% if @sent %>
      <%= render "studio/inquiries/success" %>
    <% else %>
      <%= render "studio/inquiries/form", inquiry: @inquiry %>
    <% end %>
  </div>
</main>
```

`app/views/studio/inquiries/create.turbo_stream.erb`:
```erb
<%= turbo_stream.update "inquiry_panel" do %>
  <% if @sent %>
    <%= render "studio/inquiries/success" %>
  <% else %>
    <%= render "studio/inquiries/form", inquiry: @inquiry %>
  <% end %>
<% end %>
```

`app/views/studio/inquiries/_form.html.erb`:
```erb
<%# locals: inquiry %>
<%= form_with model: inquiry, scope: :studio_inquiry, url: studio_contact_path, class: "sn-contact-form" do |f| %>
  <% if inquiry.errors[:base].any? %>
    <div class="sn-form-alert" role="alert"><%= inquiry.errors[:base].to_sentence %></div>
  <% end %>

  <div class="sn-field">
    <%= f.label :name, "Name", class: "sn-field__label" %>
    <%= f.text_field :name, class: "sn-input", autocomplete: "name" %>
  </div>

  <div class="sn-field">
    <%= f.label :email, class: "sn-field__label" do %>Work email<span class="sn-field__req"> *</span><% end %>
    <%= f.email_field :email, class: "sn-input", autocomplete: "email" %>
    <% if inquiry.errors[:email].any? %>
      <span class="sn-field__hint">Email <%= inquiry.errors[:email].first %></span>
    <% end %>
  </div>

  <div class="sn-field">
    <%= f.label :company, "Company", class: "sn-field__label" %>
    <%= f.text_field :company, class: "sn-input", autocomplete: "organization" %>
  </div>

  <div class="sn-field">
    <%= f.label :interest, "What are you interested in?", class: "sn-field__label" %>
    <%= f.select :interest, Studio::Inquiry::INTEREST_LABELS.invert, {}, class: "sn-input" %>
  </div>

  <div class="sn-field">
    <%= f.label :message, class: "sn-field__label" do %>What work keeps getting done by hand?<span class="sn-field__req"> *</span><% end %>
    <%= f.text_area :message, class: "sn-textarea" %>
    <% if inquiry.errors[:message].any? %>
      <span class="sn-field__hint">Message <%= inquiry.errors[:message].first %></span>
    <% end %>
  </div>

  <% sitekey = Rails.application.credentials.dig(:turnstile, :site_key) %>
  <% if sitekey.present? %>
    <div data-controller="turnstile" data-turnstile-sitekey-value="<%= sitekey %>"></div>
  <% end %>

  <button type="submit" class="sn-btn sn-btn--primary sn-btn--lg sn-btn--block"><span>Request a call</span></button>
<% end %>
```

`app/views/studio/inquiries/_success.html.erb`:
```erb
<div class="sn-contact-success" role="status">
  <h2>Request received</h2>
  <p>Thanks. Spencer will reply by email within two business days.</p>
</div>
```

- [ ] **Step 5: Run tests**

Run: `bin/rails test`
Expected: all pass.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/studio/inquiries_controller.rb app/views/studio/inquiries test/controllers/studio
git commit -m "feat(studio): Request-a-call inquiry form with Turnstile and Turbo"
```

Hand-off: `app/views/studio/inquiries/**` now belongs to Codex for Task 11.

---

### Task 5: De-Honey shared components with semantic tokens (Codex)

**Files:**
- Modify: `app/assets/stylesheets/design_system/colors.css` (`:root` semantic block, ~lines 49–76)
- Modify: `app/assets/stylesheets/design_system/components.css` (lines 44–49, 60–78, 100–111, 141–142, 160–166, 184, 205, 215)
- Modify: `app/assets/stylesheets/design_system/portfolio.css` (lines 18, 30)

- [ ] **Step 1: Add semantic tokens to `colors.css`** that default to today's values, next to the existing semantic block:
```css
  /* Component roles: skins override these, never the raw palette */
  --surface-hover:        var(--paper-100);
  --surface-hover-strong: var(--paper-200);
  --surface-inverse-hover: var(--ink-700);
  --border-hover:         var(--ink-300);
  --brand-soft:           var(--honey-50);
  --brand-soft-border:    var(--honey-200);
  --brand-soft-text:      var(--honey-700);
  --brand-dot:            var(--honey-500);
  --icon-muted:           var(--ink-400);
```
- [ ] **Step 2: Replace every raw palette reference** in `components.css` and `portfolio.css` with the matching role: `--paper-0` → `--surface-card`; `--paper-50` on inverse → `--text-on-inverse`; `--paper-100` hover → `--surface-hover`; `--paper-200` → `--surface-hover-strong` (hover) or `--surface-sunken` (fill); `--ink-900` → `--surface-inverse`; `--ink-700` hover → `--surface-inverse-hover`; `--ink-300` → `--border-hover`; `--ink-400` dot → `--icon-muted`; `--honey-50/200/700` → `--brand-soft`/`--brand-soft-border`/`--brand-soft-text`; `--honey-100` → `--brand-tint`; `--honey-500` → `--brand-dot`.
- [ ] **Step 3: Verify none remain**

Run: `grep -nE 'var\(--(honey|paper|ink)-' app/assets/stylesheets/design_system/components.css app/assets/stylesheets/design_system/portfolio.css`
Expected: no output.
- [ ] **Step 4: Verify the personal site is unchanged.** Run `bin/dev`, then screenshot `http://spencernorman.localhost:3000` before (on `main`) and after at 1280px and 390px. They must be identical. Run `bin/rails test`; all pass.
- [ ] **Step 5: Commit** `git commit -am "refactor(design-system): components read semantic tokens, not raw palette"`

---

### Task 6: Clear Workshop studio skin (Codex)

**Files:**
- Create: `app/assets/stylesheets/design_system/studio.css`
- Modify: `app/assets/tailwind/application.css` (add the import after `portfolio.css`)

- [ ] **Step 1: Create `studio.css`** scoped to `body[data-site="studio"]`, overriding every semantic token from `colors.css` (including the Task 5 additions). Palette: page `#F5F7FA`, cards `#FFFFFF`, text-strong `#17212B`, brand `#2456C7` (with hover/active darker steps), `--text-on-accent: #FFFFFF`, pale-blue `--brand-tint`/`--brand-soft`, cool grey borders, cobalt focus ring. Type: headings use Hanken at 600–700 with relaxed tracking, body 17px, mono only for process labels. Corners 8–12px, restrained cool shadows.
- [ ] **Step 2: Import it** in `app/assets/tailwind/application.css`: `@import "../stylesheets/design_system/studio.css";`
- [ ] **Step 3: Verify** with `bin/dev`. `normansimplified.localhost:3000` shows the cool skin and `spencernorman.localhost:3000` is unchanged. Check WCAG AA contrast for body text, muted text, and white-on-cobalt buttons. Run `bin/rails test`; all pass.
- [ ] **Step 4: Commit** `git commit -m "feat(studio): Clear Workshop skin"`

---

### Task 7: Studio layout, nav, footer, per-page meta (Codex)

**Files:**
- Modify: `app/views/layouts/studio.html.erb`
- Create: `app/views/studio/pages/_nav.html.erb`, `_footer.html.erb`, `app/javascript/controllers/nav_controller.js`
- Test: `test/integration/studio_pages_test.rb`

- [ ] **Step 1: Add failing tests** to `StudioPagesTest`:
```ruby
  test "every studio page has a title, meta description, and a Request a call link" do
    [ "/", "/ai-integration", "/how-we-work" ].each do |path|
      get path
      assert_select "title", /Norman Simplified/
      assert_select "meta[name=description][content]"
      assert_select "a[href^='/contact']", minimum: 1
    end
  end

  test "nav links to every v1 page" do
    get "/"
    assert_select "nav a[href='/ai-integration']"
    assert_select "nav a[href='/how-we-work']"
    assert_select "nav a[href^='/contact']", text: /Request a call/
  end
```
- [ ] **Step 2:** Run `bin/rails test test/integration/studio_pages_test.rb` and confirm it fails.
- [ ] **Step 3: Implement.** The layout renders `<meta name="description" content="<%= content_for(:description) || default %>">`, `_nav` (logo, Services `/#services`, AI integration, How we work, primary **Request a call** button), and `_footer` (nav repeat, contact, link to spencernorman.io). The mobile menu uses `nav_controller.js` (toggle `aria-expanded`, Escape closes). No floating overlay CTA. Every page sets `content_for :title` and `:description` from the copy doc.
- [ ] **Step 4:** Run `bin/rails test`; all pass.
- [ ] **Step 5: Commit** `git commit -m "feat(studio): layout, nav, footer, page meta"`

---

### Task 8: Home page (Codex)

**Files:**
- Modify: `app/views/studio/pages/home.html.erb`
- Create: `app/views/studio/pages/_hero.html.erb`, `_lanes.html.erb`, `_proof.html.erb`, `_process.html.erb`, `_about.html.erb`, `_faq.html.erb`, `_cta.html.erb`
- Test: `test/integration/studio_pages_test.rb`

- [ ] **Step 1: Add failing test:**
```ruby
  test "home shows the brand line, three lanes with starting prices, and lane CTAs" do
    get "/"
    assert_select "h1", /Technology, simplified/
    assert_select "#services [data-lane]", 3
    [ "$3,500", "$7,500", "$18,000" ].each { |price| assert_match price, @response.body }
    %w[adopt automate build].each { |lane| assert_select "a[href='/contact?interest=#{lane}']" }
    assert_select "details", minimum: 6
  end
```
- [ ] **Step 2:** Run it and confirm it fails.
- [ ] **Step 3: Implement** the sections in the copy doc's Home order: hero (annotated "document → reviewed data → your system" graphic, clearly illustrative), `#services` lanes (each card `data-lane`, starting price, CTA to `/contact?interest=<lane>`, plus the Signal Audit line under Build linking `/contact?interest=audit`), proof (9,800+ pharmacy locations attributed to Spencer's work at United Networks of America, Agent Eva, Flexfit; each labeled employer / consulting / independent product), process, meet Spencer (`#about`), FAQ with native `<details>`, closing CTA.
- [ ] **Step 4:** Run `bin/rails test`; all pass. Check 390px and 1280px in the browser.
- [ ] **Step 5: Commit** `git commit -m "feat(studio): home page"`

---

### Task 9: AI integration page, catalog, recorded explorer (Codex)

**Files:**
- Modify: `app/views/studio/pages/ai_integration.html.erb`
- Create: `app/views/studio/pages/_catalog.html.erb`, `_explorer.html.erb`, `app/javascript/controllers/explorer_controller.js`
- Test: `test/integration/studio_pages_test.rb`

- [ ] **Step 1: Add failing test:**
```ruby
  test "ai integration page lists the catalog by job and labels the explorer as a sample" do
    get "/ai-integration"
    %w[Documents Answers Workflows Numbers].each { |group| assert_select "h2, h3", /#{group}/ }
    assert_select "[data-catalog-item]", 12
    assert_select "[data-controller=explorer]"
    assert_match(/sample|fictional/i, css_select("[data-controller=explorer]").text)
  end
```
- [ ] **Step 2:** Run it and confirm it fails.
- [ ] **Step 3: Implement.** Keep the catalog data in an ERB array at the top of `_catalog.html.erb` (same pattern as `personal/pages/_projects.html.erb`): 12 items in 5 groups, each with name, for whom, what it does, timeline, "starts at" price and outcome. Add sections on human review, evals/accuracy and running costs. `_explorer` steps through a fictional vendor invoice: source document → extracted fields with confidence → low-confidence fields flagged for review → record in destination system. Use Stimulus targets for steps and buttons for prev/next, keep it keyboard accessible, and follow `prefers-reduced-motion`. No network or model calls.
- [ ] **Step 4:** Run `bin/rails test`; all pass. Click through the explorer at 390px.
- [ ] **Step 5: Commit** `git commit -m "feat(studio): AI integration page with catalog and sample explorer"`

---

### Task 10: How we work page (Codex)

**Files:**
- Modify: `app/views/studio/pages/how_we_work.html.erb`
- Test: `test/integration/studio_pages_test.rb`

- [ ] **Step 1: Add failing test:**
```ruby
  test "how we work shows exact Adopt prices and the Signal Audit" do
    get "/how-we-work"
    [ "$3,500", "$8,500", "$4,500" ].each { |price| assert_match price, @response.body }
    assert_select "a[href='/contact?interest=audit']"
    assert_no_match(/per hour|\/hr/i, @response.body)
  end
```
- [ ] **Step 2:** Run it and confirm it fails.
- [ ] **Step 3: Implement** from the copy doc. Cover the three lanes in detail: Adopt (Pick $3,500 exact, Rollout $8,500 exact, Desk Hours $2,500/mo), Automate (Wire from $7,500, Flow Care), Build (from $18,000; Pilot, Integration, Rescue & Modernize, Managed AI Ops, Fractional AI Lead without exact prices). Then the Signal Audit at $4,500 with deliverables and the credit toward a build, what happens after each engagement, and payment terms (50% to start, 50% at ship; retainers monthly in advance). No hourly rate.
- [ ] **Step 4:** Run `bin/rails test`; all pass.
- [ ] **Step 5: Commit** `git commit -m "feat(studio): how we work page"`

---

### Task 11: Style the contact page (Codex)

**Files:**
- Modify: `app/views/studio/inquiries/new.html.erb`, `_form.html.erb`, `_success.html.erb`

- [ ] **Step 1: Restyle** to the Clear Workshop skin with copy from the doc: left column for what happens next ("reply within two business days", "25-minute call", "no PHI"), right column for the form. **Do not change** the `inquiry_panel` id, the `studio_inquiry[...]` field names, the form `url`, the Turnstile block, or the "Request received" success heading, because Task 4's tests depend on them.
- [ ] **Step 2:** Run `bin/rails test`; all pass. Submit the form in the browser on `normansimplified.localhost:3000/contact?interest=build` with valid and invalid input.
- [ ] **Step 3: Commit** `git commit -m "feat(studio): style Request-a-call page"`

---

### Task 12: Final verification (Claude)

- [ ] **Step 1:** Run `bin/ci`. Expected: all steps green, signoff runs.
- [ ] **Step 2: Copy guardrails.**

Run: `grep -rniE 'revolutioniz|unlock|seamless|cutting-edge|leverag|testimonial' app/views/studio app/views/layouts/studio.html.erb`
Expected: no output. Manually confirm no invented metrics or client names; the only numbers allowed are prices, timelines, and the attributed 9,800+ / 11+ years facts.
- [ ] **Step 3: Browser pass** on both hosts at 390px and 1280px: all four studio pages, mobile nav, explorer, inquiry submit (valid and invalid), and the personal home unchanged.
- [ ] **Step 4: Review** the full branch diff against the spec's success criteria (superpowers:requesting-code-review).
- [ ] **Step 5:** Push the branch and open a PR with a plain description and no AI attribution. Merge only when Spencer approves (squash).
