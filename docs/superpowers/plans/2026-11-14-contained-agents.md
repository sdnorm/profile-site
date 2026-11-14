# AI Agents Under Your Control (v3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn normansimplified.com from "back-office workflow review" to "AI agents doing one job in your business, inside limits you set", led by a $9,500 pilot.

**Architecture:** The studio site stays static ERB on `Studio::PagesController` with the tableless `Studio::Inquiry` form. Three new pages are plain actions on that controller. Notes are ERB templates listed by a tableless `Studio::Note` and served by a small `Studio::NotesController`. Existing partials are retargeted in place; one new home partial is added.

**Tech Stack:** Rails 8, Hotwire, ERB, Minitest integration tests. Ruby 4.0.9 via mise.

**Spec:** `docs/superpowers/specs/2026-11-14-contained-agents-design.md`. Read it first. It amends `docs/superpowers/specs/2026-11-12-studio-message-v2-design.md`, which still governs voice, pricing wording and proof.

## Global Constraints

- Run every command through mise: `mise exec -- bin/rails test ...`, `mise exec -- bin/ci`.
- Rails views, Hotwire and Stimulus only. No new gems or JavaScript dependencies.
- Existing `interest` keys (`audit`, `adopt`, `automate`, `build`, `not_sure`), analytics events and params, anchors (`#adopt`, `#automate`, `#build`, `#review`, `#services`, `#faq`) and URLs keep working.
- Prices, verbatim: Pilot `$9,500` fixed fee, three to four weeks. Agent Readiness Review `$3,500` fixed fee, one week, credited in full toward a pilot that starts within 60 days. Full build starts at `$18,000`. Your own server starts at `$6,500`. Support `$750` a month (Basic) and `$1,500` a month (Standard), business hours, three-month minimum. Half to start.
- "Fixed fee" only for the pilot and the review. Everything else is "starts at", followed by "your written proposal sets the fixed fee before work begins".
- The model sentence, verbatim, wherever a page says "your server", "you own" or "you control": `This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider.`
- Never in visible copy: "never leaves", "air-gapped" as a claim, "revolutionary", "transformative", "private beta", an announcement date, any client result, percentage, testimonial or deployment count, any industry named as a target or an exclusion.
- "Workflow Review", `$4,500`, `$5,500` and `$15,000` appear nowhere on the site.
- First person ("I"), plain words, short sentences. On owner-facing pages every technical term has plain words next to it. Only `/engineering-teams` may use "sandbox", "inference provider" and similar unglossed.
- Every "Request a call" link keeps `data-controller="analytics"`, `data-action="click->analytics#track"`, `cta_clicked`, `request_a_call`, a location param, and an interest param equal to the `interest` in its href when there is one.
- Every page has exactly one `h1` and one meta description. New pages reuse existing classes (`ns-section`, `ns-editorial-grid`, `ns-section-heading`, `ns-prose`, `ns-lead`, `ns-actions`, `ns-how__lane`, `ns-review__outline`, `sn-btn`, `sn-card`). Add CSS only where a task says so.
- This repository is public: no revenue targets, capacity, prospect names, outbound or reply templates.
- Commit messages describe the change only. No Co-Authored-By trailers and no tool attribution.
- Do not touch `app/views/personal`, credentials, or production. Do not merge. Merging to `main` auto-deploys and takes the shared server down for about ten minutes, so the owner decides when the three pull requests merge.

## Review Focus

- A note URL with an unknown or hostile slug (`/notes/nope`, `/notes/..%2F..%2Flayouts%2Fstudio`). Expected: 404, and no template outside the notes folder is ever rendered. Test in Task 9.
- An old link still in the wild (`/contact?interest=audit`, `interest=build`, `interest=crypto`). Expected: `audit` preselects "Agent Readiness Review", v2 keys still preselect, unknown falls back to "Not sure yet". Test in Task 1.
- A reader takes "a server you own" to mean nothing is sent out. Expected: the model sentence is on every page that makes the ownership claim. Tests in Tasks 2, 3, 4, 7, 8, 9.
- Two different things called "Pilot" at two prices. The v2 "Custom software" lane has a package named Pilot at $18,000. Expected: after this work the only Pilot is $9,500. Tests in Tasks 4 and 5.
- A new studio page is served on spencernorman.io, or missing from the sitemap, or has an untracked contact link. Expected: 404 on the personal host, listed in the studio sitemap, canonical on the www host, analytics attributes on every contact link. Tests in Task 6, re-run after Tasks 7 to 9.

---

## Pinned copy

Tests assert these strings exactly. Do not paraphrase them.

| Surface | Exact text |
|---|---|
| Home `h1` | `Put AI agents to work. Keep control of what they can do.` |
| Home title, layout fallback title | `AI agents for everyday operations \| Norman Simplified` |
| Home description, layout fallback description | `Put AI agents to work on one recurring job, with limits you set and a person approving what goes out. Pilots are $9,500 fixed fee with Spencer Norman.` |
| Pilot price line | `$9,500 fixed fee. Three to four weeks.` |
| Review price line | `$3,500 fixed fee. One week.` |
| Review credit line | `The full $3,500 is credited toward a pilot that starts within 60 days.` |
| Model sentence | `This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider.` |
| Review page `h1` | `Agent Readiness Review` |
| Review page title | `Agent Readiness Review \| Norman Simplified` |
| Review page description | `A one-week Agent Readiness Review for $3,500. Find out which job an AI agent should take first, what it would be allowed to do, and what it costs.` |
| How we work `h1` | `Start with one job` |
| How we work description | `A pilot on one job is $9,500 fixed fee. Not sure where to start? The Agent Readiness Review is $3,500. See what each includes and what follows.` |
| Contact description | `Tell Spencer which job you want off someone's desk. He replies by email within two business days to discuss a 25-minute call.` |
| Examples description | `Examples of jobs an AI agent can take on, with a person approving the exceptions. See a sample, possible projects, and how we agree what to measure.` |
| Explainer `h1` | `Where your agent runs` |
| Explainer title | `Where your AI agent runs \| Norman Simplified` |
| Explainer description | `Your own server or the vendor's hosted service: what is stored where, what is sent to the AI model, and what it takes to keep running.` |
| Engineering `h1` | `AI agents for engineering teams` |
| Engineering title | `AI agents for engineering teams \| Norman Simplified` |
| Engineering description | `Agents for broken builds, alert triage and pull request review, with a clear answer on what the agent can reach and what leaves your network.` |
| Vendor check line | `Checked against vendor documentation on 14 November 2026.` |
| Independence line | `Norman Simplified is independent and is not affiliated with Anthropic.` |
| Notes index `h1` / title | `Notes` / `Notes \| Norman Simplified` |
| Notes index description | `Plain explanations of how AI agents handle your business data, from Spencer Norman.` |

Interest keys and labels, in form order:

```ruby
INTEREST_LABELS = {
  "not_sure" => "Not sure yet",
  "pilot" => "Pilot",
  "audit" => "Agent Readiness Review",
  "agents" => "Full build",
  "setup" => "Your own server",
  "support" => "Ongoing support",
  "adopt" => "Tools and training",
  "automate" => "Workflow automation",
  "build" => "Custom software"
}.freeze
```

Studio paths, used by every test that loops pages. Each task appends its own:

```ruby
STUDIO_PATHS = %w[/ /agent-readiness-review /where-agents-run /engineering-teams /how-we-work /ai-integration /notes /notes/what-leaves-your-business /notes/your-server-or-the-vendors /contact]
```

## File structure

- `app/models/studio/inquiry.rb`: interest keys and labels, the single source for form order.
- `app/models/studio/note.rb` (new): the list of notes. Slug, title, description.
- `app/controllers/studio/pages_controller.rb`: three new empty actions.
- `app/controllers/studio/notes_controller.rb` (new): index and show.
- `app/views/studio/pages/_control.html.erb` (new): the "what control means" home section.
- `app/views/studio/pages/agent_readiness_review.html.erb`, `where_agents_run.html.erb`, `engineering_teams.html.erb` (new).
- `app/views/studio/notes/index.html.erb`, `what_leaves_your_business.html.erb`, `your_server_or_the_vendors.html.erb` (new).
- Existing studio partials, `how_we_work.html.erb`, `ai_integration.html.erb`, `inquiries/new.html.erb`, `inquiries/_form.html.erb`, `layouts/studio.html.erb`, the sitemap builder, `config/routes.rb`: modified.
- `test/test_helper.rb`: holds `STUDIO_PATHS`.

---

# Pull request 1: the offer

### Task 1: Inquiry interests

**Files:**
- Modify: `app/models/studio/inquiry.rb`
- Modify: `app/views/studio/inquiries/_form.html.erb:22-29`
- Test: `test/models/studio/inquiry_test.rb`, `test/controllers/studio/inquiries_controller_test.rb`

**Interfaces:**
- Produces: `Studio::Inquiry::INTEREST_LABELS` (ordered hash above), `INTERESTS = INTEREST_LABELS.keys.freeze`, valid keys `pilot`, `agents`, `setup`, `support`.

- [ ] **Step 1: Write the failing tests**

In `inquiry_test.rb`, change the `audit` label assertion and add:

```ruby
assert_equal "Agent Readiness Review", build(interest: "audit").interest_label
assert_equal "Pilot", build(interest: "pilot").interest_label
assert_equal "Full build", build(interest: "agents").interest_label
assert_equal "Your own server", build(interest: "setup").interest_label
assert_equal "Ongoing support", build(interest: "support").interest_label
assert_equal %w[not_sure pilot audit agents setup support adopt automate build], Studio::Inquiry::INTERESTS
```

In `inquiries_controller_test.rb`, add:

```ruby
test "new preselects new and old interests, and lists them in order" do
  { "pilot" => "Pilot", "audit" => "Agent Readiness Review", "build" => "Custom software" }.each do |key, label|
    get studio_contact_path(interest: key)
    assert_select "select[name='studio_inquiry[interest]'] option[selected][value=#{key}]", text: label
  end
  get studio_contact_path(interest: "crypto")
  assert_select "select[name='studio_inquiry[interest]'] option[selected][value=not_sure]"
  assert_equal Studio::Inquiry::INTEREST_LABELS.values, css_select("select[name='studio_inquiry[interest]'] option").map(&:text)
end
```

- [ ] **Step 2: Run and confirm failure**

Run: `mise exec -- bin/rails test test/models/studio/inquiry_test.rb test/controllers/studio/inquiries_controller_test.rb`
Expected: FAIL on the `audit` label and the unknown `pilot` key.

- [ ] **Step 3: Implement**

Replace the hash in the model with the pinned one. In the form, build `interest_options` from `Studio::Inquiry::INTEREST_LABELS.map { |key, label| [ label, key ] }`. Change the form heading `The workflow` to `The job`, and the message placeholder to `The job, who does it today, and the tools it touches.`

- [ ] **Step 4: Run and confirm pass**

Same command. Expected: PASS. Fix any other assertion in those two files or `test/mailers/inquiry_mailer_test.rb` that pinned "Workflow Review".

- [ ] **Step 5: Commit**

```bash
git add app/models/studio/inquiry.rb app/views/studio/inquiries/_form.html.erb test/models/studio/inquiry_test.rb test/controllers/studio/inquiries_controller_test.rb test/mailers/inquiry_mailer_test.rb
git commit -m "Add pilot, full build, server and support interests to the contact form"
```

### Task 2: Home page

**Files:**
- Modify: `app/views/studio/pages/home.html.erb`, `_hero.html.erb`, `_review.html.erb`, `_lanes.html.erb`, `_about.html.erb`, `_faq.html.erb`, `_cta.html.erb`
- Create: `app/views/studio/pages/_control.html.erb`
- Modify: `app/views/layouts/studio.html.erb:4,6` (fallback title and description)
- Test: `test/integration/studio_pages_test.rb`

**Interfaces:**
- Consumes: `interest=pilot` and `interest=audit` from Task 1.
- Produces: home section ids `review`, `control`, `services`, `faq`; lane links to `/how-we-work#agents`, `#setup`, `#support` (Task 4 creates those anchors); a link to `/agent-readiness-review` (Task 3 creates the route, so this task links with a literal path and Task 3 swaps in the helper).

- [ ] **Step 1: Replace the home assertions**

Set the `/` description in the meta loop to the pinned home description. Replace `home leads with the outcome...` with:

```ruby
test "home leads with the pilot, states the limits, and offers the review second" do
  get "/"
  assert_select "h1", "Put AI agents to work. Keep control of what they can do."
  assert_select ".ns-hero" do
    assert_select "*", text: /\$9,500/
    assert_select "a[href='/contact?interest=pilot']", text: "Request a call", count: 1
  end
  assert_select "#review", text: /\$9,500 fixed fee\. Three to four weeks\./
  assert_select "#review", text: /\$3,500 fixed fee\. One week\./
  assert_select "#review a[href='/agent-readiness-review']"
  assert_select "#control", text: /This is not offline\. When the agent uses the AI model, the text it is working on is sent to the model provider\./
  assert_select "#control li, #control dt", minimum: 7
  assert_select "#services [data-lane]", 3
  %w[agents setup support].each { |lane| assert_select "#services [data-lane=#{lane}] a[href='/how-we-work##{lane}']" }
  [ "$18,000", "$6,500", "$750" ].each { |price| assert_match price, @response.body }
  assert_select "#about", text: /Implementation example/
  [ "Is our data sent anywhere?", "Do we need technical staff?", "What if the agent gets something wrong?", "What if we stop working with you?", "Who owns the work when it is done?" ].each do |question|
    assert_select "#faq summary", text: question
  end
end
```

Add `Workflow Review|\$4,500|\$5,500|\$15,000|never leaves|revolutionary|transformative|private beta` to the `retired` regex in the retired-names test.

- [ ] **Step 2: Run and confirm failure**

Run: `mise exec -- bin/rails test test/integration/studio_pages_test.rb`
Expected: the new home test fails; the retired-names test fails on `/`, `/how-we-work`, `/ai-integration` and `/contact` (later tasks clear the last three).

- [ ] **Step 3: Rewrite the sections**

`home.html.erb`: pinned title and description; render order `hero`, `review`, `control`, `lanes`, `about`, `process`, `faq`, `cta`.

`_hero.html.erb`: pinned `h1`. Lead: `I'm Spencer Norman. I set up AI agents that do one recurring job in your business, such as preparing a quote from an emailed request or turning an incoming request into a job record. The agent works inside limits you set, and a person approves what goes out. Start with a pilot on one job for <strong>$9,500</strong>, fixed fee, in three to four weeks.` One button, `interest: "pilot"`, location `hero`. Note line: `Tell me which job is taking your team's time. I reply by email within two business days.`

`_review.html.erb`: keep `id="review"` and the `ns-review__outline` list. Heading `How a pilot works`, lead the pinned pilot price line. Outline label: `What a pilot includes.` Four rows: `One job` (one piece of recurring work, written down), `The limits` (the inboxes, folders and systems the agent can reach, and nothing else), `The approval step` (what waits for a person before it is sent or changed), `The acceptance test` (how we both check it was done right, agreed before work starts). Then: `The pilot runs under a business account in your name. If we stop working together, you keep everything.` Button `interest: "pilot"`, location `pilot`. Then a second block, `h3` `Not sure which job to start with?`, the pinned review price line, one sentence on what the review decides, the pinned credit line, and a text link `What the review includes` to `/agent-readiness-review`.

`_control.html.erb`: `section#control`, heading `What control means`. The seven points from the spec's "The box" as a list, each a bold term and one sentence: A defined job. Named limits. A person approves. A record. Your accounts and keys. Where it runs is your choice. If we stop working together, you keep everything and it keeps running. Under it, a short `What it is not` list of three: the model sentence verbatim; a server you own needs updates, backups and someone watching it; AI is used only where something has to be read and interpreted, alongside your existing software and ordinary automation. End with one sentence: `If the agent is down, the work waits in a queue and your team can do it the old way.`

`_lanes.html.erb`: heading `After a pilot`, lead `What can follow once one job is working.` Cards: `data-lane="agents"` `Full build` `from $18,000`, the job taken to production or further jobs added; `data-lane="setup"` `Your own server` `from $6,500`, the agent moved to a server in your own hosting account; `data-lane="support"` `Ongoing support` `from $750 a month`, updates, backups, monitoring and changes in business hours. Each links to its `/how-we-work` anchor. Note: `Full build and your own server are starting prices. Your written proposal sets the fixed fee before work begins.`

`_about.html.erb`: keep everything. After the "I built this during that employment." line add nothing; before the example add one sentence: `An agent in a box works the same way: it prepares the work, and a person sees anything it is unsure of.`

`_faq.html.erb`: the five questions in the test, in that order. Answers, two or three sentences each: data (yes: the model sentence in substance, plus what is stored under your accounts); technical staff (no for a pilot on the vendor's hosted service; a server you own needs support, mine or someone else's); mistakes (it drafts, a person approves what goes out, every run is logged, the acceptance test is agreed first); stopping (accounts, keys, configuration and notes are in your name and it keeps running); ownership (keep the current answer).

`_cta.html.erb`: heading `Which job would you hand over first?` Button `interest: "pilot"`, location `cta`.

`studio.html.erb`: fallback title and description from the pinned table.

- [ ] **Step 4: Run and confirm**

Same command. Expected: the home test passes. The retired-names, nav, how-we-work and meta tests still fail for other pages; Tasks 3 to 6 clear them.

- [ ] **Step 5: Commit**

```bash
git add app/views/studio/pages app/views/layouts/studio.html.erb test/integration/studio_pages_test.rb
git commit -m "Lead the home page with the pilot and what control means"
```

### Task 3: Agent Readiness Review page

**Files:**
- Modify: `config/routes.rb` (studio scope), `app/controllers/studio/pages_controller.rb`
- Create: `app/views/studio/pages/agent_readiness_review.html.erb`
- Modify: `app/views/studio/pages/_review.html.erb` (swap the literal path for the helper)
- Test: `test/integration/studio_pages_test.rb`

**Interfaces:**
- Produces: `get "agent-readiness-review", to: "pages#agent_readiness_review", as: :agent_readiness_review`, giving `studio_agent_readiness_review_path`.

- [ ] **Step 1: Write the failing test**

```ruby
test "review page states the offer, the fit, and how the week runs" do
  get "/agent-readiness-review"
  assert_response :success
  assert_select "h1", "Agent Readiness Review"
  assert_match "$3,500 fixed fee. One week.", @response.body
  assert_match "The full $3,500 is credited toward a pilot that starts within 60 days.", @response.body
  assert_select "dl.ns-review__outline > div", 7
  assert_select "h2", text: "A good fit if"
  assert_select "h2", text: "Probably not a fit if"
  assert_match(/no passwords/i, @response.body)
  assert_match "This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider.", @response.body
  assert_select "a[href='/contact?interest=audit']", text: "Request a call", minimum: 1
end
```

Add the path to the meta loop with the pinned description.

- [ ] **Step 2: Run and confirm 404**

Run: `mise exec -- bin/rails test test/integration/studio_pages_test.rb -n "/review page/"`

- [ ] **Step 3: Add the route, the empty action and the page**

Sections, in order: hero (eyebrow `One week. Fixed fee.`, pinned `h1`, pinned price line, one-sentence lead, button `interest: "audit"`); `Outline of the report you receive`, labelled as the deliverable and not a client report, with the seven deliverables from the spec's Offers section as `dl.ns-review__outline` rows; `How the week runs` (the spec's four points: conversations and a list of systems, then the report and walkthrough; conversations, documents and screen shares only; no passwords and no access to your systems; NDA first if you ask); `What I need from you` (the people for up to three conversations, a description of the tools the jobs touch, any contract or policy terms about where data can go); `A good fit if` and `Probably not a fit if` from the spec's "Who it is for", with no industry named; `Afterwards` (stop, do it in-house, or start a pilot, with the pinned credit line and the model sentence); closing button.

- [ ] **Step 4: Run and confirm pass**

- [ ] **Step 5: Commit**

```bash
git add config/routes.rb app/controllers/studio/pages_controller.rb app/views/studio/pages/agent_readiness_review.html.erb app/views/studio/pages/_review.html.erb test/integration/studio_pages_test.rb
git commit -m "Add the Agent Readiness Review page"
```

### Task 4: How we work

**Files:**
- Modify: `app/views/studio/pages/how_we_work.html.erb`
- Test: `test/integration/studio_pages_test.rb`

**Interfaces:**
- Produces: section ids `pilot`, `review-offer`, `agents`, `setup`, `support`, `other`; keeps `adopt`, `automate`, `build`.

- [ ] **Step 1: Replace the how-we-work test**

```ruby
test "how we work leads with the pilot and keeps the other work below" do
  get "/how-we-work"
  assert_select "h1", "Start with one job"
  %w[pilot review-offer agents setup support other adopt automate build].each { |id| assert_select "##{id}", 1 }
  assert_select "#pilot", text: /\$9,500 fixed fee\. Three to four weeks\./
  assert_select "#review-offer", text: /\$3,500 fixed fee\. One week\./
  assert_select "#agents", text: /Starts at \$18,000/
  assert_select "#setup", text: /Starts at \$6,500/
  assert_select "#setup", text: /This is not offline\./
  assert_select "#support", text: /\$750 a month/
  assert_select "#support", text: /\$1,500 a month/
  assert_select "#support", text: /three-month minimum/i
  { "pilot" => "pilot", "review-offer" => "audit", "agents" => "agents", "setup" => "setup", "support" => "support" }.each do |id, interest|
    assert_select "##{id} a[href='/contact?interest=#{interest}']"
  end
  assert_select "#other ~ #adopt"
  assert_no_match(/Pilot<\/h3>\s*<p class="ns-how__price">Starts at \$18,000/, @response.body)
  assert_no_match(/per hour|\/hr/i, @response.body)
end
```

Set the `/how-we-work` description in the meta loop to the pinned one.

- [ ] **Step 2: Run and confirm failure**

- [ ] **Step 3: Rewrite the top of the page**

Replace the hero and the "What happens after the review" overview (lines 5 to 46). Keep the page title.

Hero: pinned `h1`; lead `A pilot on one job. $9,500 fixed fee. Three to four weeks.`; button `interest: "pilot"`.

Then five sections in the existing `ns-how__lane` shape, each with a button for its interest:

- `#pilot` Pilot: pinned price line; one agent on one job; the limits, the approval step and the acceptance test agreed in writing before work starts; runs on the vendor's hosted service under a business account in your name; AI model usage is billed by the vendor to your account, with an estimate in the proposal.
- `#review-offer` Agent Readiness Review: pinned price line, one sentence, pinned credit line, link to `studio_agent_readiness_review_path`.
- `#agents` Full build: `Starts at $18,000.` plus the proposal sentence.
- `#setup` Your own server: `Starts at $6,500.` plus the proposal sentence; a VPS in your own hosting account; sign-in, firewall, encrypted backups, monitoring, documentation and handoff; hosting billed to you by the hosting company; the model sentence verbatim.
- `#support` Ongoing support: Basic `$750 a month` (updates, backups, monitoring, up to 2 hours of changes, reply by the next business day); Standard `$1,500 a month` (the same, up to 6 hours of changes, same-day reply); business hours, not on-call, three-month minimum.

Before `#adopt`, add `section#other` with heading `Other work` and lead `Work that does not need an agent is still available.` Leave the copy inside `#adopt`, `#automate` and `#build` alone, with three exceptions: rename the `#build` package heading `Pilot` to `First version`; remove every "Workflow Review" mention; and where a credit line names the Workflow Review, drop that clause.

In `What the weeks look like` and `Money and access`, replace Workflow Review wording with pilot wording. Half to start stays.

- [ ] **Step 4: Run and confirm pass**

Run: `mise exec -- bin/rails test test/integration/studio_pages_test.rb`
Expected: the how-we-work test passes and the retired-names test no longer fails on `/how-we-work`.

- [ ] **Step 5: Commit**

```bash
git add app/views/studio/pages/how_we_work.html.erb test/integration/studio_pages_test.rb
git commit -m "Lead How we work with the pilot, review, build, server and support"
```

### Task 5: Contact page and Examples intro

**Files:**
- Modify: `app/views/studio/inquiries/new.html.erb`, `app/views/studio/pages/ai_integration.html.erb:1-25`
- Test: `test/integration/studio_pages_test.rb`

- [ ] **Step 1: Write the failing tests**

```ruby
test "contact page talks about the job and the pilot" do
  get "/contact"
  assert_select "aside", text: /A pilot on one job is \$9,500 fixed fee/
  assert_select "select option[value=pilot]", text: "Pilot"
end

test "examples page presents its examples as jobs for an agent" do
  get "/ai-integration"
  assert_select ".ns-hero a[href='/contact?interest=pilot']", text: "Request a call"
  assert_match "A pilot on one job is $9,500 fixed fee", @response.body
  assert_no_match(/Pilot starts at \$18,000/, @response.body)
end
```

Set the `/contact` and `/ai-integration` descriptions in the meta loop to the pinned ones.

- [ ] **Step 2: Run and confirm failure**

- [ ] **Step 3: Update the two templates**

Contact: pinned description. Lead: `Tell me which job you want off someone's desk. I reply by email within two business days. If it looks like a fit, we set up a 25-minute call.` Keep `You don't need to know the solution yet.` Aside: `The job, the tools it touches, and whether a pilot or a review is the right first step.` then `A pilot on one job is $9,500 fixed fee, over three to four weeks. If you are not sure which job to start with, the Agent Readiness Review is $3,500.`

Examples: pinned description; keep the title, the `h1`, the explorer and the catalog. Hero lead: `These are jobs an agent can take on: reading the documents that come in, chasing approvals, keeping records in step. A person sees the exceptions. They are examples of possible work, not measured results.` Hero button `interest: "pilot"`. Replace the two paragraphs under `One process, connected to your tools` with: `A pilot on one job is $9,500 fixed fee and takes three to four weeks. A full build starts at $18,000. Your written proposal sets the fixed fee before work begins. We agree what to measure before kickoff.` and `Not sure which job to start with? The Agent Readiness Review is $3,500 fixed fee, one week.` Leave the catalog links on `interest=build`.

- [ ] **Step 4: Run and confirm**

Run: `mise exec -- bin/rails test test/integration/studio_pages_test.rb`
Expected: every test passes except the nav test, which Task 6 replaces.

- [ ] **Step 5: Commit**

```bash
git add app/views/studio/inquiries/new.html.erb app/views/studio/pages/ai_integration.html.erb test/integration/studio_pages_test.rb
git commit -m "Point the contact and examples pages at the pilot"
```

### Task 6: Nav, footer, sitemap and the page loops

**Files:**
- Modify: `app/views/studio/pages/_nav.html.erb`, `_footer.html.erb`, `app/views/studio/sitemaps/show.xml.builder`
- Modify: `test/test_helper.rb`, `test/integration/studio_pages_test.rb`, `search_indexing_test.rb`, `site_routing_test.rb`, `analytics_test.rb`

**Interfaces:**
- Produces: `STUDIO_PATHS` in `test/test_helper.rb`, at this point `%w[/ /agent-readiness-review /how-we-work /ai-integration /contact]`. Tasks 7 to 9 append to it and to the sitemap. The footer renders `content_for(:footer_note)` when a page sets it.

- [ ] **Step 1: Point every loop at `STUDIO_PATHS`**

Define the constant. Use it in: the layout loop, the retired-names loop and the Turnstile loop in `studio_pages_test.rb`; the canonical loop and the sitemap expectation in `search_indexing_test.rb` (keep the `/contact?lane=ai` case); the personal-host 404 list in `site_routing_test.rb` (`STUDIO_PATHS - [ "/" ]`); the studio CTA loop in `analytics_test.rb`. Replace the nav test:

```ruby
test "nav and footer link to the offer and every page" do
  get "/"
  assert_select "nav[aria-label=Primary] a[href='/#review']", text: "How a pilot works"
  assert_select "nav[aria-label=Primary] a[href='/ai-integration']", text: "Examples"
  assert_select "nav[aria-label=Primary] a[href='/how-we-work']"
  assert_select "nav[aria-label=Primary] a[href^='/contact']", text: /Request a call/
  assert_select "nav[aria-label=Footer] a[href='/agent-readiness-review']"
  assert_select ".ns-footer__tagline", "Put AI agents to work. Keep control of what they can do."
end
```

- [ ] **Step 2: Run the four files and confirm the nav, footer and sitemap failures**

Run: `mise exec -- bin/rails test test/integration`

- [ ] **Step 3: Update nav, footer and sitemap**

Nav: `How a pilot works` (home `#review`), `Examples`, `How we work`, `Request a call`. Footer: tagline as tested; links Agent Readiness Review, Examples, How we work, Request a call; below the links, `<%= content_tag :p, content_for(:footer_note), class: "ns-footer__note" if content_for?(:footer_note) %>`. Sitemap: one entry per `STUDIO_PATHS` path, in that order, using the `studio_*_url(**origin)` helpers.

- [ ] **Step 4: Run the whole suite**

Run: `mise exec -- bin/ci`
Expected: PASS.

- [ ] **Step 5: Commit, then open pull request 1**

```bash
git add app/views/studio test
git commit -m "Retarget studio navigation and index the review page"
```

Push the branch and open a pull request titled `Norman Simplified: AI agents under your control, led by a pilot`. Do not merge.

---

# Pull request 2: the explainers

### Task 7: Where your agent runs

**Files:**
- Modify: `config/routes.rb`, `app/controllers/studio/pages_controller.rb`, `app/views/studio/sitemaps/show.xml.builder`, `test/test_helper.rb`
- Create: `app/views/studio/pages/where_agents_run.html.erb`
- Modify: `app/views/studio/pages/_control.html.erb`, `_footer.html.erb` (link to the page)
- Modify: the studio stylesheet under `app/assets/tailwind/` or `app/assets/stylesheets/design_system/` that holds the other `ns-` rules, for the diagram only
- Test: `test/integration/studio_pages_test.rb`

**Interfaces:**
- Produces: `get "where-agents-run", to: "pages#where_agents_run", as: :where_agents_run`; `/where-agents-run` appended to `STUDIO_PATHS` after `/agent-readiness-review`.

- [ ] **Step 1: Write the failing test**

```ruby
test "explainer compares the two places an agent can run and says what is sent out" do
  get "/where-agents-run"
  assert_response :success
  assert_select "h1", "Where your agent runs"
  assert_select "h2", text: "On the vendor's hosted service"
  assert_select "h2", text: "On a server you own"
  assert_select "h2", text: "What is sent to the AI model"
  assert_select "h2", text: "What it takes to keep a server running"
  assert_select "[data-diagram=where-agents-run]", 1
  assert_select "img", 0
  assert_match "This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider.", @response.body
  assert_no_match(/sandbox|inference|control plane/i, Nokogiri::HTML(@response.body).at("main").text)
  assert_select "a[href='/contact?interest=pilot']", minimum: 1
  get "/"
  assert_select "#control a[href='/where-agents-run']"
end
```

Add the path to the meta loop with the pinned title and description.

- [ ] **Step 2: Run and confirm 404**

- [ ] **Step 3: Build the page**

Sections under the four `h2`s in the test, plus `Who can sign in` and `When the server is down` as further `h2`s. Content comes from the spec's "The box" section: for each of the two places, what is stored there (the agent, its files, its credentials, the record of each run), whose account it is, and who maintains it. "What is sent" carries the model sentence verbatim and says it is true in both places. "Keeping a server running" names updates, backups and monitoring and points to `/how-we-work#support`. "When the server is down" states the queue rule. The diagram is HTML and CSS: two columns (`Vendor's hosted service`, `Your server`), each a stack of labelled boxes, with one arrow labelled `text the agent is working on` from each to a shared `AI model provider` box. Give it `data-diagram="where-agents-run"` and an `aria-label` that says the same in a sentence.

- [ ] **Step 4: Run the suite**

Run: `mise exec -- bin/rails test test/integration`
Expected: PASS, including the sitemap, canonical, personal-host and analytics loops for the new path.

- [ ] **Step 5: Commit**

```bash
git add config/routes.rb app/controllers/studio/pages_controller.rb app/views/studio app/assets test
git commit -m "Add the Where your agent runs explainer"
```

### Task 8: For engineering teams

**Files:**
- Modify: `config/routes.rb`, `app/controllers/studio/pages_controller.rb`, `app/views/studio/sitemaps/show.xml.builder`, `test/test_helper.rb`, `app/views/studio/pages/_footer.html.erb`
- Create: `app/views/studio/pages/engineering_teams.html.erb`
- Test: `test/integration/studio_pages_test.rb`

**Interfaces:**
- Consumes: `content_for(:footer_note)` from Task 6.
- Produces: `get "engineering-teams", to: "pages#engineering_teams", as: :engineering_teams`; path appended to `STUDIO_PATHS` after `/where-agents-run`.

- [ ] **Step 1: Write the failing test**

```ruby
test "engineering page gives the hosting levels with checked vendor facts" do
  get "/engineering-teams"
  assert_response :success
  assert_select "h1", "AI agents for engineering teams"
  [ "broken builds", "alert triage", "pull request review" ].each { |job| assert_match(/#{job}/i, @response.body) }
  assert_select "table tbody tr", 3
  [ "cma-server", "PostgreSQL 16", "Amazon Bedrock", "Google Cloud", "Microsoft Foundry", "Anthropic account team" ].each { |fact| assert_match fact, @response.body }
  assert_match "Checked against vendor documentation on 14 November 2026.", @response.body
  assert_select "footer", text: /Norman Simplified is independent and is not affiliated with Anthropic\./
  assert_match(/to the inference provider/, @response.body)
  assert_match(/install each release/i, @response.body)
  assert_no_match(/private beta|November 12|12 November/i, @response.body)
  assert_select "a[href='/contact?interest=pilot']", minimum: 1
  get "/"
  assert_select "footer a[href='/engineering-teams']"
  assert_select "footer", text: /not affiliated with Anthropic/, count: 0
end
```

Add the path to the meta loop.

- [ ] **Step 2: Run and confirm 404**

- [ ] **Step 3: Build the page**

Before writing, re-read `https://platform.claude.com/docs/en/managed-agents/self-hosted` and `.../choosing-an-environment`. If they differ from the spec's table, the documentation wins: change the page and the date in the check line, and say so in the commit message.

Sections: hero with the pinned `h1` and the three jobs; `What the security owner will ask` (what can it reach, which credentials does it hold, where is its history stored, what is sent to the model); `Three ways to host it`, a `table` with a caption, column headers `Level`, `What you host`, `What reaches the vendor`, `Access`, and the three rows from the spec's engineering table, copied cell for cell, followed by one paragraph saying the levels apply to any agent stack and Claude Managed Agents is the worked example; `What you take on` (you run and secure the server, database and sandboxes, and install each release); the pinned check line; a pilot button. Set `content_for :footer_note` to the pinned independence line. Add `For engineering teams` to the footer links.

- [ ] **Step 4: Run the suite**

Run: `mise exec -- bin/ci`
Expected: PASS.

- [ ] **Step 5: Commit, then open pull request 2**

```bash
git add config/routes.rb app/controllers/studio/pages_controller.rb app/views/studio test
git commit -m "Add the engineering teams page with checked hosting levels"
```

Pull request title: `Explain where an agent runs, for owners and for engineering teams`. Do not merge.

---

# Pull request 3: notes

### Task 9: Notes

**Files:**
- Create: `app/models/studio/note.rb`, `app/controllers/studio/notes_controller.rb`, `app/views/studio/notes/index.html.erb`, `app/views/studio/notes/what_leaves_your_business.html.erb`, `app/views/studio/notes/your_server_or_the_vendors.html.erb`
- Modify: `config/routes.rb`, `app/views/studio/sitemaps/show.xml.builder`, `app/views/studio/pages/_footer.html.erb`, `test/test_helper.rb`
- Test: `test/models/studio/note_test.rb`, `test/integration/studio_notes_test.rb`

**Interfaces:**
- Produces:
  - `Studio::Note = Data.define(:slug, :title, :description)` with `Studio::Note.all -> Array<Studio::Note>`, `Studio::Note.find(slug) -> Studio::Note | nil`, and `#template -> String` returning `"studio/notes/#{slug.underscore}"`.
  - `get "notes", to: "notes#index", as: :notes` and `get "notes/:slug", to: "notes#show", as: :note`.
  - `STUDIO_PATHS` gains `/notes`, `/notes/what-leaves-your-business`, `/notes/your-server-or-the-vendors` before `/contact`.

The two notes:

| Slug | Title (`h1`) | Description |
|---|---|---|
| `what-leaves-your-business` | `What actually leaves your business when you use an AI tool` | `What an AI tool sends to its provider, what stays put, and the questions to ask before you paste in customer data.` |
| `your-server-or-the-vendors` | `Your own server or the vendor's: where an AI agent should run` | `When an AI agent can run on the vendor's hosted service, and when it is worth putting it on a server you own.` |

- [ ] **Step 1: Write the failing tests**

`note_test.rb`:

```ruby
test "find returns a listed note and nothing else" do
  assert_equal "what-leaves-your-business", Studio::Note.find("what-leaves-your-business").slug
  assert_equal "studio/notes/what_leaves_your_business", Studio::Note.find("what-leaves-your-business").template
  [ "nope", "", nil, "../layouts/studio", "what-leaves-your-business/../index" ].each { |slug| assert_nil Studio::Note.find(slug) }
end

test "every note has a template on disk" do
  Studio::Note.all.each { |note| assert Rails.root.join("app/views/#{note.template}.html.erb").exist?, note.slug }
end
```

`studio_notes_test.rb` (`host! "www.normansimplified.com"` in setup):

```ruby
test "index lists every note" do
  get "/notes"
  assert_select "h1", "Notes"
  Studio::Note.all.each { |note| assert_select "a[href='/notes/#{note.slug}']", text: note.title }
end

test "each note renders with its title, description and guardrails" do
  Studio::Note.all.each do |note|
    get "/notes/#{note.slug}"
    assert_response :success
    assert_select "h1", note.title
    assert_select "title", "#{note.title} | Norman Simplified"
    assert_select "meta[name=description][content=?]", note.description
    assert_match "This is not offline. When the agent uses the AI model, the text it is working on is sent to the model provider.", @response.body
    assert_select "a[href='/where-agents-run']", minimum: 1
    assert_select "a[href='/contact?interest=pilot']", text: "Request a call", minimum: 1
    assert_no_match(/\d+%|testimonial|never leaves|revolutionary|transformative/i, Nokogiri::HTML(@response.body).at("main").text)
  end
end

test "unknown and hostile slugs are not found" do
  [ "/notes/nope", "/notes/..%2F..%2Flayouts%2Fstudio", "/notes/index" ].each do |path|
    get path
    assert_response :not_found, path
  end
end
```

- [ ] **Step 2: Run and confirm failure**

Run: `mise exec -- bin/rails test test/models/studio/note_test.rb test/integration/studio_notes_test.rb`

- [ ] **Step 3: Implement**

`Studio::Note.find` looks the slug up in `all` by equality and never builds a path from its argument. `NotesController#show` calls `find`, responds `head :not_found` when it returns nil, and otherwise sets `@note` and renders `@note.template`. `show` sets the title and description from `@note` so the templates hold only the article body. Add `Notes` to the footer links.

Note bodies, 500 to 800 words each, short sections with `h2`s, in the spec's owner-facing voice, each with the model sentence verbatim, a link to `/where-agents-run` and a closing pilot button:

- *What actually leaves your business*: what a staff member pastes into a personal AI account and who holds it afterwards; a personal account compared with a business account in the company's name; what an agent sends each time it uses the model; what stays where it is stored; four questions to ask any AI vendor or consultant before customer data goes in.
- *Your own server or the vendor's*: what each option is in one paragraph; when the hosted service is enough; the three reasons to want your own server (a contract or customer asks where data is stored, the agent holds credentials you want on a machine you control, you want it to keep running whoever you work with); what a server costs you in upkeep; how to decide, and that a pilot can start hosted and move later.

Do not state a vendor's data-use or retention terms as fact. Say what to ask and where the answer is written down.

- [ ] **Step 4: Run the suite**

Run: `mise exec -- bin/ci`
Expected: PASS, including the loops over the three new paths.

- [ ] **Step 5: Commit, then open pull request 3 as a draft**

```bash
git add app/models/studio/note.rb app/controllers/studio/notes_controller.rb app/views/studio config/routes.rb test
git commit -m "Add notes, with the first two articles"
```

Pull request title: `Notes: what leaves your business, and where an agent should run`. Open it as a draft: the owner approves the article text before it is marked ready.

### Task 10: Browser check

**Files:** none unless a check fails; a failure goes back to the task that owns the page.

- [ ] **Step 1: Run `mise exec -- bin/ci`.** Expected: PASS.

- [ ] **Step 2: Boot with `bin/dev` and open `http://normansimplified.localhost:3000`.** At 1440x900 and at 390x844:

- Home: the `h1`, `$9,500` and the Request a call button are all visible without scrolling.
- The hero button opens `/contact?interest=pilot` with Pilot selected. Do not submit.
- `/agent-readiness-review`, `/where-agents-run`, `/engineering-teams`, `/notes` and both notes each show one `h1` and a Request a call button.
- The explainer diagram reads correctly at 390px wide with no horizontal scroll, and so does the engineering table.
- `/how-we-work#support` shows both plans. `/how-we-work#build` shows `First version`, not a second Pilot.
- The mobile menu opens and `How a pilot works` scrolls to the pilot section.
- The independence line shows in the footer of `/engineering-teams` only.

- [ ] **Step 3: Search the views for leftovers**

```bash
grep -rnE "Workflow Review|\\$4,500|\\$5,500|\\$15,000|Technology, simplified|never leaves|private beta" app/views/studio app/views/layouts/studio.html.erb
```

Expected: no output.

---

## Spec coverage

- Message, box, pilot-first offer and prices: Tasks 2, 4, 5.
- Agent Readiness Review: Tasks 1, 3, 4.
- Who it is for, stated as fit: Task 3.
- Explainer and engineering page: Tasks 7, 8.
- Notes and the two launch articles: Task 9.
- Contact options, nav, titles, sitemap, layout fallback: Tasks 1, 2, 6.
- Messaging rules and anti-goals: the retired-names regex (Task 2) and the model-sentence assertions in each page's test.
- Proof: the implementation example stays (Task 2). The reference build is the owner's and is not mentioned on the site.
- Outside the repository (prospect list, outbound note, reply templates, LinkedIn versions, reference build): not in this plan, by the spec.
- Open in the spec and deliberately not built: payment tied to the acceptance test (the site says "half to start"), and a list of supported hosting companies (the site names none).

## Execution note

Tasks 1 to 6 share `studio_pages_test.rb` and the home partials, so one implementer takes them in order. Tasks 7, 8 and 9 each add a route, a sitemap entry and a `STUDIO_PATHS` entry, so they also run in order, not in parallel.
