# Dual-Site Foundations + Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the "Honey Bold" design-system tokens into this Rails app, then stand up the dual-site (personal + Norman Simplified) routing/layout skeleton that renders with the brand applied.

**Architecture:** One Rails app, split by request host (see `docs/superpowers/specs/2026-06-17-dual-site-architecture-design.md`). Route constraints map each domain into its own controller namespace; the layout binds at a per-namespace base controller (no host detection in `ApplicationController`). Design tokens are imported as CSS custom properties into the Tailwind v4 entry; both per-site layouts consume the same tokens with distinct skins via a `data-site` hook.

**Tech Stack:** Rails 8.1, Propshaft, importmap-rails, tailwindcss-rails (Tailwind v4), ERB. Design system source: claude.ai/design project `4b468235-bdea-44c5-bad8-c608d6d3bdac` (read with the `DesignSync` tool).

**Source-of-truth note:** Token CSS and (later) UI-kit sections are authored in the claude.ai/design project. Steps that create those files **fetch them verbatim** via `DesignSync(get_file)` rather than retyping, to avoid transcription drift. The repo is the deployment target; the cloud project is the design source.

---

## File Structure

**Part 1 — foundations (card #115)**
- Create: `app/assets/stylesheets/design_system/colors.css` — color ramps + semantic aliases (verbatim from source)
- Create: `app/assets/stylesheets/design_system/typography.css` — type scale, families, roles (verbatim)
- Create: `app/assets/stylesheets/design_system/spacing.css` — spacing/radius/shadow/motion/layout (verbatim)
- Create: `app/assets/stylesheets/design_system/base.css` — page canvas, body type, links, focus ring (authored here)
- Modify: `app/assets/tailwind/application.css` — `@import` the design system

**Part 2 — skeleton (card #114)**
- Create: `app/controllers/personal/base_controller.rb`, `app/controllers/personal/pages_controller.rb`
- Create: `app/controllers/studio/base_controller.rb`, `app/controllers/studio/pages_controller.rb`
- Create: `app/views/layouts/personal.html.erb`, `app/views/layouts/studio.html.erb`
- Create: `app/views/shared/_flash.html.erb`, `app/views/shared/_fonts.html.erb`
- Create: `app/views/personal/pages/home.html.erb` (migrated), `app/views/personal/pages/about.html.erb` (placeholder)
- Create: `app/views/studio/pages/home.html.erb`, `app/views/studio/pages/services.html.erb` (placeholders)
- Create: `test/integration/site_routing_test.rb`
- Modify: `config/routes.rb`, `config/environments/development.rb`
- Remove: `app/controllers/general_controller.rb`, `app/views/general/index.html.erb`, `test/controllers/general_controller_test.rb`

**Fonts:** the design system's `tokens/fonts.css` uses a remote `@import` (Google Fonts). We do **not** import that into Tailwind (the v4 bundler is unreliable with remote `@import`). Instead the families load via a `<link>` in `app/views/shared/_fonts.html.erb`, rendered by both layouts.

---

## Part 1 — Design-system foundations (card #115)

### Task 1: Import the design tokens

**Files:**
- Create: `app/assets/stylesheets/design_system/colors.css`
- Create: `app/assets/stylesheets/design_system/typography.css`
- Create: `app/assets/stylesheets/design_system/spacing.css`
- Modify: `app/assets/tailwind/application.css`

- [ ] **Step 1: Fetch the three token files verbatim from the design project**

For each path below, call `DesignSync(get_file, projectId: "4b468235-bdea-44c5-bad8-c608d6d3bdac", path: <src>)` and write the returned `content` exactly to `<dest>`:

| src (in design project) | dest (in repo) |
|---|---|
| `tokens/colors.css` | `app/assets/stylesheets/design_system/colors.css` |
| `tokens/typography.css` | `app/assets/stylesheets/design_system/typography.css` |
| `tokens/spacing.css` | `app/assets/stylesheets/design_system/spacing.css` |

Do not edit the contents. (Reference: `colors.css` defines `--surface-page`, `--text-strong`, `--brand`, etc.; `typography.css` defines `--font-display/-sans/-mono`, the `--fs-*` scale, and `.t-display/.t-heading/.t-body/.t-label`; `spacing.css` defines `--space-*`, `--radius-*`, `--shadow-*`, `--container`.)

- [ ] **Step 2: Import the tokens into the Tailwind entry**

Replace the contents of `app/assets/tailwind/application.css` with:

```css
@import "tailwindcss";

/* Honey Bold design-system tokens (source: claude.ai/design 4b468235…) */
@import "../stylesheets/design_system/colors.css";
@import "../stylesheets/design_system/typography.css";
@import "../stylesheets/design_system/spacing.css";
@import "../stylesheets/design_system/base.css";
```

(Note: `base.css` is created in Task 2; this `@import` is added now so the entry is final after Part 1. The build in Step 3 will fail until Task 2 if run before then — run Task 2 before building, or temporarily omit the `base.css` line. Recommended: do Task 2's file creation first, then build once.)

- [ ] **Step 3: Build Tailwind and verify a token is emitted**

Run: `bin/rails tailwindcss:build`
Expected: exits 0.

Run: `grep -c -- "--surface-page" app/assets/builds/tailwind.css`
Expected: a count `>= 1` (the token survived into the build).

- [ ] **Step 4: Commit**

```bash
git add app/assets/stylesheets/design_system/colors.css \
        app/assets/stylesheets/design_system/typography.css \
        app/assets/stylesheets/design_system/spacing.css \
        app/assets/tailwind/application.css app/assets/builds/tailwind.css
git commit -m "feat(design): import Honey Bold design tokens into Tailwind pipeline"
```

### Task 2: Base layer (page canvas, body type, links, focus)

**Files:**
- Create: `app/assets/stylesheets/design_system/base.css`

- [ ] **Step 1: Write the base layer**

Create `app/assets/stylesheets/design_system/base.css`:

```css
/* ==========================================================================
   Base layer — applies the Honey Bold tokens to the document.
   Tailwind Preflight already resets; this sets brand defaults on top.
   ========================================================================== */

html {
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
}

body {
  margin: 0;
  background: var(--surface-page);
  color: var(--text-body);
  font-family: var(--font-sans);
  font-size: var(--fs-base);
  line-height: var(--lh-normal);
  letter-spacing: var(--track-normal);
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

a {
  color: var(--text-link);
  text-decoration: none;
}
a:hover { text-decoration: underline; }

::selection {
  background: var(--brand-tint);
  color: var(--text-strong);
}

:focus-visible {
  outline: none;
  box-shadow: var(--shadow-focus);
  border-radius: var(--radius-xs);
}
```

- [ ] **Step 2: Build and verify the base layer is present**

Run: `bin/rails tailwindcss:build`
Expected: exits 0.

Run: `grep -c -- "var(--surface-page)" app/assets/builds/tailwind.css`
Expected: count `>= 1`.

- [ ] **Step 3: Commit**

```bash
git add app/assets/stylesheets/design_system/base.css app/assets/builds/tailwind.css
git commit -m "feat(design): add base layer applying brand tokens to the document"
```

---

## Part 2 — Dual-site skeleton (card #114)

> Each task here is end-to-end testable via an integration test that sets the request host. Test env has empty `config.hosts`, so `host!` works without host-authorization config. The dev-hosts config (Task 6) only matters for real local browsing.

### Task 3: Studio site (normansimplified.com)

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/studio/base_controller.rb`, `app/controllers/studio/pages_controller.rb`
- Create: `app/views/studio/pages/home.html.erb`
- Create: `app/views/layouts/studio.html.erb`
- Create: `app/views/shared/_flash.html.erb`, `app/views/shared/_fonts.html.erb`
- Test: `test/integration/site_routing_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/integration/site_routing_test.rb`:

```ruby
require "test_helper"

class SiteRoutingTest < ActionDispatch::IntegrationTest
  test "studio host root renders the studio layout" do
    host! "normansimplified.com"
    get "/"
    assert_response :success
    assert_select "body[data-site=studio]"
  end

  test "studio localhost subdomain renders the studio layout" do
    host! "normansimplified.localhost"
    get "/"
    assert_response :success
    assert_select "body[data-site=studio]"
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bin/rails test test/integration/site_routing_test.rb`
Expected: FAIL (no route/controller/layout yet).

- [ ] **Step 3: Add the studio host constraint to routes**

In `config/routes.rb`, add the host regex and constraint block at the **top** of the `draw` block (above the existing `get "general/index"` line; leave everything else intact for now):

```ruby
Rails.application.routes.draw do
  studio_host = /(\A|\.)normansimplified\.(com|localhost)\z/

  constraints(host: studio_host) do
    scope module: :studio, as: :studio do
      root "pages#home"
    end
  end

  # ---- existing routes unchanged below ----
  get "general/index"
  # ... (rest of file as-is) ...
```

- [ ] **Step 4: Create the studio controllers**

Create `app/controllers/studio/base_controller.rb`:

```ruby
module Studio
  class BaseController < ApplicationController
    layout "studio"

    def current_site = :studio
    helper_method :current_site
  end
end
```

Create `app/controllers/studio/pages_controller.rb`:

```ruby
module Studio
  class PagesController < BaseController
    def home; end
  end
end
```

- [ ] **Step 5: Create the shared partials**

Create `app/views/shared/_fonts.html.erb`:

```erb
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,500;12..96,600;12..96,700;12..96,800&family=Hanken+Grotesk:ital,wght@0,400;0,500;0,600;0,700;0,800;1,400;1,500&family=Spline+Sans+Mono:ital,wght@0,400;0,500;0,600;1,400&display=swap">
```

Create `app/views/shared/_flash.html.erb` (extracted from the current `application.html.erb`):

```erb
<% if notice.present? %>
  <div class="notice gap-x-6 bg-indigo-600 px-6 py-2.5 sm:px-3.5 sm:before:flex-1" data-notification-target="notice">
    <button data-action="notification#close" class="text-white float-right text-2xl cursor-pointer -mt-1">&times;</button>
    <div class="mx-auto max-w-2xl text-center">
      <p class="text-sm leading-6 text-white"><%= notice %></p>
    </div>
  </div>
<% end %>
<% if alert.present? %>
  <div class="alert gap-x-6 bg-red-600 px-6 py-2.5 sm:px-3.5 sm:before:flex-1 items-center" data-notification-target="alert">
    <button data-action="notification#close" class="text-white float-right items-center text-2xl cursor-pointer -mt-1">&times;</button>
    <div class="mx-auto max-w-2xl text-center">
      <p class="text-sm leading-6 text-white"><%= alert %></p>
    </div>
  </div>
<% end %>
```

- [ ] **Step 6: Create the studio layout**

Create `app/views/layouts/studio.html.erb`:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "Norman Simplified" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= render "shared/fonts" %>
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body data-site="<%= current_site %>" data-controller="notification">
    <%= render "shared/flash" %>
    <%= yield %>
  </body>
</html>
```

- [ ] **Step 7: Create the studio home placeholder**

Create `app/views/studio/pages/home.html.erb`:

```erb
<main class="mx-auto max-w-3xl px-6 py-20">
  <p class="t-label" style="color: var(--text-accent)">Norman Simplified</p>
  <h1 class="t-display" style="font-size: var(--fs-4xl); color: var(--text-strong)">
    Software, simplified.
  </h1>
  <p class="mt-4" style="color: var(--text-muted); max-width: var(--measure)">
    Placeholder home for normansimplified.com. Real content lands in cards #124–#128.
  </p>
</main>
```

- [ ] **Step 8: Run the test to verify it passes**

Run: `bin/rails test test/integration/site_routing_test.rb`
Expected: PASS (2 runs, 0 failures). The studio host renders `body[data-site=studio]`.

- [ ] **Step 9: Commit**

```bash
git add config/routes.rb app/controllers/studio app/views/studio app/views/layouts/studio.html.erb \
        app/views/shared/_flash.html.erb app/views/shared/_fonts.html.erb test/integration/site_routing_test.rb
git commit -m "feat(sites): add Norman Simplified (studio) site behind host constraint"
```

### Task 4: Personal site (spencernorman.io) + migrate home

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/personal/base_controller.rb`, `app/controllers/personal/pages_controller.rb`
- Create: `app/views/layouts/personal.html.erb`
- Create: `app/views/personal/pages/home.html.erb` (moved from `general/index.html.erb`)
- Remove: `app/controllers/general_controller.rb`, `app/views/general/index.html.erb`, `test/controllers/general_controller_test.rb`
- Test: `test/integration/site_routing_test.rb` (extend)

- [ ] **Step 1: Add failing tests for the personal host**

Append two tests inside `SiteRoutingTest` in `test/integration/site_routing_test.rb`:

```ruby
  test "personal host root renders the personal layout" do
    host! "spencernorman.io"
    get "/"
    assert_response :success
    assert_select "body[data-site=personal]"
  end

  test "personal localhost subdomain renders the personal layout" do
    host! "spencernorman.localhost"
    get "/"
    assert_response :success
    assert_select "body[data-site=personal]"
  end
```

- [ ] **Step 2: Run to verify the new tests fail**

Run: `bin/rails test test/integration/site_routing_test.rb`
Expected: the two new tests FAIL (personal root currently renders `general#index`, whose layout has no `data-site`).

- [ ] **Step 3: Rewrite routes.rb to final form**

Replace the entire `config/routes.rb` with:

```ruby
Rails.application.routes.draw do
  personal_host = /(\A|\.)spencernorman\.(io|localhost)\z/
  studio_host   = /(\A|\.)normansimplified\.(com|localhost)\z/

  # ---- Norman Simplified (normansimplified.com) ----
  constraints(host: studio_host) do
    scope module: :studio, as: :studio do
      root "pages#home"
    end
  end

  # ---- Personal portfolio (spencernorman.io) ----
  constraints(host: personal_host) do
    scope module: :personal, as: :personal do
      root "pages#home"
    end
  end

  # ---- Legacy demo / auth features (relocation tracked in card #117) ----
  resource :registration
  resource :session
  resource :qr_session
  get "qr_sessions", to: "qr_sessions#qr_sign_in", as: :qr_sign_in
  get "date_parser/index"
  post "date_parse" => "date_parser#parse", as: :date_parse

  get "up" => "rails/health#show", as: :rails_health_check

  # Default root for any non-site host (bare localhost, IP) -> personal home.
  # Keeps `root_path` defined for the legacy controllers that still use it.
  root "personal/pages#home"
end
```

- [ ] **Step 4: Create the personal controllers**

Create `app/controllers/personal/base_controller.rb`:

```ruby
module Personal
  class BaseController < ApplicationController
    layout "personal"

    def current_site = :personal
    helper_method :current_site
  end
end
```

Create `app/controllers/personal/pages_controller.rb`:

```ruby
module Personal
  class PagesController < BaseController
    def home; end
  end
end
```

- [ ] **Step 5: Move the existing home view into the personal namespace**

Run:
```bash
git mv app/views/general/index.html.erb app/views/personal/pages/home.html.erb
```
(Content is unchanged — it already uses `new_registration_path` and the GitHub link, both still valid. Visual restyle to the Hero design is a later card, #118.)

- [ ] **Step 6: Create the personal layout**

Create `app/views/layouts/personal.html.erb`:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) || "Spencer Norman" %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= render "shared/fonts" %>
    <%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body data-site="<%= current_site %>" data-controller="notification">
    <%= render "shared/flash" %>
    <%= yield %>
  </body>
</html>
```

- [ ] **Step 7: Remove the now-dead general controller and its test**

Run:
```bash
git rm app/controllers/general_controller.rb test/controllers/general_controller_test.rb
```
(The `general/index.html.erb` view was already moved in Step 5. No remaining route references `general#index`.)

- [ ] **Step 8: Run the full test suite**

Run: `bin/rails test`
Expected: all green. Specifically `test/integration/site_routing_test.rb` is 4 runs / 0 failures, and no test references the removed `general` controller.

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat(sites): add personal site namespace, migrate home, retire general controller"
```

### Task 5: Secondary pages + cross-host isolation + dev hosts

**Files:**
- Modify: `config/routes.rb`
- Create: `app/views/personal/pages/about.html.erb`, `app/views/studio/pages/services.html.erb`
- Modify: `app/controllers/personal/pages_controller.rb`, `app/controllers/studio/pages_controller.rb`
- Modify: `config/environments/development.rb`
- Test: `test/integration/site_routing_test.rb` (extend)

- [ ] **Step 1: Add failing isolation tests**

Append inside `SiteRoutingTest`:

```ruby
  test "personal pages are unreachable on the studio host" do
    host! "normansimplified.com"
    assert_raises(ActionController::RoutingError) { get "/about" }
  end

  test "studio pages are unreachable on the personal host" do
    host! "spencernorman.io"
    assert_raises(ActionController::RoutingError) { get "/services" }
  end
```

- [ ] **Step 2: Run to verify they fail**

Run: `bin/rails test test/integration/site_routing_test.rb`
Expected: the two new tests FAIL (no `/about` or `/services` routes exist yet, so `get` raises before the assertion can scope it — they fail because the routes are not yet defined per-host).

- [ ] **Step 3: Add the secondary routes (host-scoped)**

In `config/routes.rb`, add one line inside each constraint's `scope` block:

Studio block becomes:
```ruby
  constraints(host: studio_host) do
    scope module: :studio, as: :studio do
      root "pages#home"
      get "services", to: "pages#services"
    end
  end
```

Personal block becomes:
```ruby
  constraints(host: personal_host) do
    scope module: :personal, as: :personal do
      root "pages#home"
      get "about", to: "pages#about"
    end
  end
```

- [ ] **Step 4: Add the controller actions and placeholder views**

In `app/controllers/personal/pages_controller.rb` add `def about; end`. In `app/controllers/studio/pages_controller.rb` add `def services; end`.

Create `app/views/personal/pages/about.html.erb`:
```erb
<main class="mx-auto max-w-3xl px-6 py-20">
  <h1 class="t-heading" style="font-size: var(--fs-3xl); color: var(--text-strong)">About</h1>
  <p class="mt-4" style="color: var(--text-muted)">Placeholder. Real content: card #119.</p>
</main>
```

Create `app/views/studio/pages/services.html.erb`:
```erb
<main class="mx-auto max-w-3xl px-6 py-20">
  <h1 class="t-heading" style="font-size: var(--fs-3xl); color: var(--text-strong)">Services</h1>
  <p class="mt-4" style="color: var(--text-muted)">Placeholder. Real content: card #125.</p>
</main>
```

- [ ] **Step 5: Run to verify isolation tests pass**

Run: `bin/rails test test/integration/site_routing_test.rb`
Expected: 6 runs / 0 failures. `/about` resolves on the personal host but raises `RoutingError` on the studio host (and vice versa for `/services`).

- [ ] **Step 6: Allow the `*.localhost` dev hosts**

In `config/environments/development.rb`, add inside the `Rails.application.configure do` block:

```ruby
  # Allow the per-site dev hosts (browser-native *.localhost resolution).
  config.hosts << "spencernorman.localhost"
  config.hosts << "normansimplified.localhost"
```

- [ ] **Step 7: Manually verify both sites render in dev**

Run: `bin/dev` (boots web + tailwind watch per `Procfile.dev`).
Visit `http://spencernorman.localhost:3000` → personal home, warm paper canvas, brand fonts.
Visit `http://normansimplified.localhost:3000` → studio home placeholder.
Expected: both load 200, visibly distinct, no host-authorization error.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat(sites): add per-site secondary pages, cross-host isolation tests, dev hosts"
```

---

## Out of scope (separate plans / cards)

- **UI-kit translation** — porting `ui_kits/portfolio/` (Nav, Hero, Timeline, Contact, Footer, Icons) from React JSX to ERB partials styled with the tokens. Cards #116/#118/#121/#122/#123. This is the next plan after foundations land; each section is fetched via `DesignSync(get_file)` and translated.
- **Component partials** — Button/Card/Badge/etc. as ERB helpers, built on demand as sections need them.
- **Norman Simplified skin** — a distinct palette over the shared tokens (`data-site="studio"` overrides). Cards #124–#128.
- **Legacy demo cleanup** — fate of sessions/registrations/date_parser/qr. Card #117.
- **Deploy** — Hatchbox DNS/SSL for both domains. Card #131.

## Success criteria

- `bin/rails tailwindcss:build` emits the brand tokens (`--surface-page`, etc.) into `app/assets/builds/tailwind.css`.
- `spencernorman.io` renders the personal layout (`body[data-site=personal]`); `normansimplified.com` renders the studio layout; neither reaches the other's secondary routes (`RoutingError`).
- `ApplicationController` contains no host-detection logic; `current_site` is set structurally by each namespace base controller.
- Both sites load in local dev via `*.localhost` with the Honey Bold fonts and canvas applied.
- `bin/rails test` is green.
