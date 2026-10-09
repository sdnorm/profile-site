# Norman Simplified Site v1 Design

**Date:** 2026-10-08
**Status:** Approved
**Related:** Fizzy cards #124–#128 (Norman Simplified board); builds on
`2026-06-17-dual-site-architecture-design.md`

## Goal

Turn normansimplified.com from a one-line placeholder into a client-acquisition site. The
site's job is to get qualified operators to **request a call**.

## Business decisions (inputs to copy)

| Question | Decision |
|----------|----------|
| Brand line | **Technology, simplified.** |
| Subhead | AI tools, automations, and custom software for operators buried in documents, spreadsheets, and aging tools. |
| Audience | Non-healthcare US B2B operators, ~20–200 people; founder or COO buyer. No single industry named in v1. |
| Healthcare history | Proof only (9,800+ pharmacy locations at United Networks of America; Agent Eva). Not the market. No PHI work, stated in the FAQ. |
| Primary CTA | **Request a call** → `/contact` inquiry form, reply by email. No booking tool in v1. |
| Response promise | "Within two business days." |
| Invented proof | None: no fabricated metrics, testimonials, or client names. |

### Offer lanes (shown on the site)

| Lane | Promise | Price shown | Offers |
|------|---------|-------------|--------|
| Adopt | The right AI tools in people's hands, with a policy and practice. | Starts at $3,500 | Pick ($3,500 exact), Rollout ($8,500 exact), Desk Hours ($2,500/mo) |
| Automate | One recurring workflow, running, without a new app. | Starts at $7,500 | Wire, Flow Care |
| Build | Software and production AI when the spreadsheet or old app is the constraint. | Starts at $18,000 | Pilot, Integration Build, Rescue & Modernize, Managed AI Ops, Fractional AI Lead |

The **Signal Audit ($4,500)** appears as one line under Build for buyers who can't name the
workflow yet. No hourly rate. Build prices above the floor are quoted after a call, in writing.

## Sitemap (v1)

| Path | Action | Purpose |
|------|--------|---------|
| `/` | `studio/pages#home` | Hero, three lanes, proof, how it works, meet Spencer, FAQ, closing CTA |
| `/ai-integration` | `studio/pages#ai_integration` | 12-item AI catalog in 5 groups (Documents, Answers, Workflows, Numbers, Sales & Support), each with who/what/timeline/starts-at/outcome; human review, evals, running costs; recorded workflow explorer |
| `/how-we-work` | `studio/pages#how_we_work` | Lanes in detail with prices, Signal Audit, what follows each engagement |
| `/contact` | `studio/inquiries#new` / `#create` | Inquiry form |

Navigation: Services (`/#services`), AI integration, How we work, **Request a call**. About lives
on the home page.

Deferred: case-study pages, `/work`, `/about`, a live "where could AI help?" tool, blog,
booking tool, analytics events.

## Architecture

Follows the existing dual-site pattern. Everything lives in the `studio` constraint block and
inherits `Studio::BaseController`; nothing touches `personal`.

### Routes

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

### Inquiry flow

- `Studio::Inquiry`: tableless ActiveModel (`app/models/studio/inquiry.rb`) with `name`,
  `email`, `company` (optional), `interest` (one of `adopt`, `automate`, `build`, `audit`,
  `not_sure`; default `not_sure`), `message`. Validates email format, message presence, and
  `interest` inclusion. Kept separate from `ContactMessage` because the fields differ.
- `/contact?interest=build` preselects the interest. Every lane and audit CTA links with its
  interest.
- `Studio::InquiriesController#create`: same shape as `Personal::ContactsController`. It
  validates, verifies Turnstile with the existing `Turnstile::Verification`, delivers
  `InquiryMailer.new_inquiry(inquiry).deliver_now`, and renders a Turbo Stream panel swap
  (200 on success, 422 on errors). HTML fallback re-renders `new` with errors (422) or
  redirects to `studio_contact_path` with a notice (303). Delivery failures are logged and
  shown as a base error, as on the personal site.
- `InquiryMailer#new_inquiry`: to the same recipient credential as `ContactMailer`, reply-to
  the prospect, subject `New Norman Simplified inquiry (<interest>) from <name or email>`.
  v1 reuses the existing Mailgun from-address; a normansimplified.com sending domain is a
  later production task.

### Visual skin: "Clear Workshop"

- Cool off-white `#F5F7FA` page, white cards, graphite `#17212B` text, cobalt `#2456C7` brand,
  pale-blue accent surfaces, white text on cobalt. Thin rules, 8–12px corners, restrained
  shadows, annotated workflow diagrams. Hanken headings 600–700, 17px body, mono for process
  labels only.
- New `app/assets/stylesheets/design_system/studio.css`, scoped to
  `body[data-site="studio"]`, overriding semantic tokens (surface, text, brand, border, focus,
  on-accent, hover/active).
- **Prerequisite refactor:** `components.css` references raw `--honey-*`, `--paper-*`,
  and `--ink-*` palette variables directly. Replace them with semantic aliases whose
  defaults resolve to the current Honey Bold values, so the personal site renders identically.
- Studio partials under `app/views/studio/pages/` (`_nav`, `_hero`, `_lanes`, `_proof`,
  `_process`, `_about`, `_faq`, `_cta`, `_footer`, `_explorer`, `_catalog`). Extract to
  `app/views/shared/` only markup used by both sites. Per-page `<title>` and meta description
  via `content_for` in `layouts/studio.html.erb`.
- Mobile nav via a small Stimulus controller; FAQ via native `<details>`.
- **Recorded explorer** on `/ai-integration`: a clearly labeled fictional vendor invoice →
  extracted fields with confidence → human review → destination system. Static data in the
  view and Stimulus for stepping through it. No model calls.

### Copy

Draft copy lives in the implementation plan's inputs (from Grok); final copy goes straight
into the views. No hype words (revolutionize, unlock, seamless, cutting-edge, leverage).

## Testing (Minitest, no mocking)

- Routing/host isolation: each studio path renders on `normansimplified.localhost` and 404s
  on `spencernorman.localhost`; existing personal routes unchanged (extend
  `test/integration/site_routing_test.rb`).
- `Studio::Inquiry` model validations, including `interest` inclusion and default.
- Inquiries controller: success (mail delivered, 200 turbo stream), invalid (422, no mail),
  `?interest=` preselection, HTML fallback. Turnstile bypasses in test (blank secret), as in
  the personal contacts tests; its failure path stays covered by `verification_test.rb`.
- `InquiryMailer`: recipient, reply-to, subject includes interest.
- Each studio page has its title/meta and a Request-a-call link.
- Personal regression: personal home still renders with Honey Bold tokens after the
  component token refactor.

## Work split

- **Codex:** all UI, meaning the token refactor, `studio.css`, studio views and partials,
  Stimulus controllers, and the explorer.
- **Grok:** copy drafts.
- **Claude:** routes, controllers, model, mailer, tests, integration, and final review.
  Owns anything touching credentials or production (none required for v1).

## Success criteria

- normansimplified.localhost serves all four pages in the Clear Workshop skin; the personal
  site is visually unchanged.
- A prospect can submit an inquiry from any CTA with the right interest preselected, and
  Spencer receives the email with reply-to set.
- `bin/rails test` passes; local CI passes.
- No fabricated metrics, testimonials, or client names anywhere on the site.
