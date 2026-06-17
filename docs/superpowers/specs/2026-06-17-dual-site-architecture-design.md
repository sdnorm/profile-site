# Dual-Site Architecture Design

**Date:** 2026-06-17
**Status:** Approved
**Related:** Fizzy card #114 (Norman Simplified board)

## Goal

Serve two distinct brands from this single Rails app:

- **spencernorman.io** — personal portfolio (audience: hiring managers / collaborators)
- **normansimplified.com** — Norman Simplified company site (audience: prospective clients)

The two sites share the same Ruby app, component library, and deploy, but each has its
own layout, navigation, palette, and content. They are separate brands, not one site with
a shared shell.

## Decisions

| Question | Decision |
|----------|----------|
| Brand relationship | Two separate brands, each with its own domain |
| Domains | `spencernorman.io` (personal), `normansimplified.com` (studio) |
| Hosting model | One Rails app, split by request host |
| Visual sharing | Shared component system, distinct per-site skins |
| Site identity source | The route constraint (structural), not runtime host inspection |

## Architecture

### 1. Routing — host constraint selects the namespace

Each domain is matched by a host constraint that scopes routes into a per-site controller
namespace. The constraint is the single source of truth for "which site." The regex anchors
on the registrable domain so production hosts, `www.` subdomains, and `*.localhost` dev
hosts all match.

```ruby
# config/routes.rb
constraints(host: /(\A|\.)spencernorman\.(io|localhost)\z/) do
  scope module: :personal, as: :personal do
    root "pages#home"
    # about, work, skills, contact, ...
  end
end

constraints(host: /(\A|\.)normansimplified\.(com|localhost)\z/) do
  scope module: :studio, as: :studio do
    root "pages#home"
    # services, work, about, contact, ...
  end
end
```

Internal module names: `personal` and `studio`. `studio` is the in-code name for Norman
Simplified — short and brand-neutral in code.

### 2. Layout binds at the namespace base controller

The routes file maps a request to a controller#action, not directly to a layout. Because
the constraint already decides the namespace, the layout is anchored to the namespace via a
base controller. `ApplicationController` performs **zero** host detection — site identity is
structural.

```ruby
# app/controllers/personal/base_controller.rb
class Personal::BaseController < ApplicationController
  layout "personal"
  def current_site = :personal
  helper_method :current_site
end

# app/controllers/studio/base_controller.rb
class Studio::BaseController < ApplicationController
  layout "studio"
  def current_site = :studio
  helper_method :current_site
end
```

Every page controller inherits from its namespace base, e.g.
`Personal::PagesController < Personal::BaseController`.

**Why this over a runtime `current_site` derived from the host:**

- `ApplicationController` does no host parsing — the route is the single source of truth.
- `current_site` is explicit per namespace; no fragile host-string matching. Works identically
  for production domains, `*.localhost`, and any future alias.
- Adding a third surface later = one constraint block + one base controller. Self-contained.

### 3. Shared design system, distinct skins

- Shared component partials live in `app/views/shared/` (buttons, cards, section wrappers,
  nav, footer). Both sites render the same markup.
- One Tailwind config. Per-site palette and typography are applied via CSS custom properties
  set on each layout's `<body>` (e.g. `data-site="personal"` / `data-site="studio"`), so the
  same components are reskinned rather than duplicated.
- Layouts `app/views/layouts/personal.html.erb` and `app/views/layouts/studio.html.erb` carry
  the per-site `<head>` (title, meta) and the `data-site` hook.

### 4. Local development

Use browser-native `*.localhost` resolution — no `/etc/hosts` edits:

- `http://spencernorman.localhost:3000`
- `http://normansimplified.localhost:3000`

The host constraints match these via the `localhost` alternation in the regex. A `?site=`
query override (or `SITE` env) is provided as a fallback for quick switching when needed.

### 5. Existing auth / demo features

The current sessions, registrations, date parser, and QR sign-in features were portfolio
demos for a job application. Under this architecture they belong under the **personal**
namespace as "proof of skills," or are removed. That decision and migration are tracked
separately in Fizzy card #117 and are out of scope for this spec.

## Out of scope (tracked elsewhere)

- DNS, SSL, and production deploy for both domains — card #131.
- Cleanup/repurposing of legacy 37signals demo features — card #117.
- Visual design system specifics (palette, type scale, components) — card #115.

## Success criteria

- Visiting `spencernorman.io` renders the personal layout; `normansimplified.com` renders the
  studio layout; neither can reach the other's routes.
- `ApplicationController` contains no host-detection logic.
- Both sites are reachable and visually distinct in local dev via `*.localhost`.
- Adding a new page to either site requires only a route inside the correct constraint block
  and a controller inheriting the namespace base.
