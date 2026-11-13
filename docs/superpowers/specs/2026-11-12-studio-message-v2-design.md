# Norman Simplified: one message, one offer (v2)

Date: 2026-11-12

## Why

Two audits of the v1 site (UI/UX and content) reached the same verdict: a cold
visitor cannot tell what to buy. The headline states no outcome, there is no
price on the first screen, the buyer is asked to choose between three lanes,
nine named products and twelve priced catalog builds before anyone has looked at
their problem, and the one offer built for an unsure buyer is small print.

v2 gives the site one message and one obvious first purchase. Everything else
becomes "what happens after".

## The message

> I help B2B operations teams cut repetitive paperwork and data entry, starting
> with a clear decision about what to fix first.

Buyer: owners and operations leads at B2B companies whose teams retype
documents, chase paperwork, or run a core process out of a spreadsheet or an
aging tool. Not developers. Not healthcare (see "Healthcare" below).

## The offer

**Workflow Review. $4,500 fixed fee. Two weeks.** (Formerly "Signal Audit".)

What the buyer gets:

- Four conversations with the people who do the work
- Three recurring processes compared: where the time goes and what it costs
- One recommended first change, in writing
- A budget range for making that change, with the assumptions shown
- A plain go or no-go recommendation
- A 45-minute walkthrough of the report

Terms: the report is theirs whether or not they continue. $2,000 of the fee is
credited toward any implementation project with Norman Simplified that starts
within 60 days.

After the review the buyer can stop, do the work in-house, or ask for a
separately scoped, fixed-price implementation.

The only call to action anywhere is **Request a call**. It leads to the form.

## Hero (home page)

- Headline: **Less retyping. Less chasing paperwork.**
- Subhead: I'm Spencer Norman. I help B2B operations teams find and fix
  repetitive back-office work. Start with a two-week Workflow Review for $4,500:
  we look at three of your processes, pick the first change worth making, and
  you get a written recommendation with a budget. Then you decide whether to go
  ahead.
- Button: Request a call (links to the form with `interest: "audit"`)
- Line under the button: Tell me what is taking your team's time. I reply by
  email within two business days.
- The price and the button must both be visible on the first screen at
  1440x900 and at 390x844.

## Names

One name per thing, in plain words, everywhere. Old names must not appear in
visible copy.

| Old | New |
|---|---|
| Signal Audit | Workflow Review |
| Adopt (lane) | Tools and training |
| Automate (lane) | Workflow automation |
| Build (lane) | Custom software |
| Pick | Tool recommendation |
| Rollout | Staff rollout |
| Desk Hours | Monthly working sessions |
| Wire | Workflow automation (the project itself) |
| Flow Care | Automation support |
| Pilot | Pilot |
| Integration | Full integration |
| Rescue of an old app / Legacy Rescue | Existing app repair |
| Managed AI Ops | Ongoing operations support |
| catalog / "menu of shapes" | Examples |

Internal keys stay as they are: the `interest` values `adopt`, `automate`,
`build`, `audit`, `not_sure`, analytics event names and params, CSS class names,
element ids used as link anchors (`#adopt`, `#automate`, `#build`, `#faq`), and
all URLs. Only labels people read change.

## Prices

Unchanged, but stated without contradiction:

- Workflow Review: $4,500 fixed, two weeks
- Tools and training: Tool recommendation $3,500 fixed (10 days); Staff rollout
  $8,500 fixed (3 weeks, up to 30 people); Monthly working sessions $2,500 a month
- Workflow automation: projects start at $7,500 (about 3 weeks); Automation
  support $1,500 a month
- Custom software: Pilot starts at $18,000 (3-4 weeks); Full integration starts
  at $36,000 (6-8 weeks); Existing app repair starts at $40,000; Ongoing
  operations support starts at $6,500 a month

Rules:

- "Fixed fee" only for the three fixed prices. Everything else is "starts at",
  followed by "your written proposal sets the fixed fee before work begins".
- A lane summary must not describe deliverables from a more expensive package
  than the price next to it.
- The twelve examples lose their individual prices. One line covers them:
  "Projects like these start at $18,000. Your proposal gives one fixed price,
  what it includes, and any running costs."
- Drop the Fractional AI Lead mention.

## Home page structure

1. Hero (above)
2. What the Workflow Review is: the six deliverables, the terms, what they keep
   if they stop, a Request a call button. Section id `review`.
3. Three ways the work gets done, for the buyer who already knows what they
   need: Tools and training from $3,500, Workflow automation from $7,500, Custom
   software from $18,000. One line each plus a "What's included" link to the
   matching section of How we work. Section id stays `services`.
4. Who does the work: Spencer, one short background paragraph, one
   implementation example (below).
5. After you send the form: reply within two business days, a 25-minute call,
   a written scope, half to start.
6. FAQ, trimmed to objections not already answered above.
7. Closing Request a call.

Remove from the home page: the "Two projects I can show" block, the duplicated
five-step process (it lives on How we work), Flexfit, the document-pipeline
diagram in the hero (or replace it with a plain summary of the review; it must
not make the site look like a document-extraction shop).

## Proof

There are no measured client results to publish, so nothing on the site may
state or imply one. No time saved, no percentages, no "clients". Instead:

- **What the report contains.** Show the outline of the Workflow Review report
  (its section headings and one line on each) so the buyer can see what $4,500
  buys. Label it as the outline of the deliverable, not a client report.
- **One implementation example**, told once, as before and after: staff retyped
  packet fields by hand; afterwards extracted records went to a review queue and
  uncertain fields were held for a person. Label it "Implementation example".
  It was built during Spencer's employment; say so plainly, once.
- **Background**, one short paragraph: 11 years building software; 2016 to 2025
  lead developer on an API used by 9,800+ locations and a multi-tenant pricing
  platform. Say "pharmacy" at most once, as career history.

Delete defensive asides ("None of them is a client logo wall", "I don't sell a
chat window with nothing behind it", "I would rather decline a poor fit than
discount a fuzzy one", "not a package on the homepage") and the absolute claim
"It does not invent figures that are not in the source".

## Healthcare

Remove every exclusion statement: "I don't take on healthcare projects", the
PHI and BAA lines, and the PHI warning on the contact page and form. Do not add
any healthcare targeting, examples or keywords either. The form's message hint
becomes a generic "Please leave out confidential or personal data."

## Other pages

**How we work** (URL unchanged). Leads with the Workflow Review as the usual
first step, with its full scope and terms. Then the three kinds of work with
their renamed packages and prices, the five steps, and payment terms. Title:
"How it works and what it costs | Norman Simplified".

**AI integration page** (URL unchanged). Becomes examples of work done after a
review. Nav label "Examples". Title "Document and workflow automation |
Norman Simplified". Example groups ship closed on every screen size. Each
example has plain-language name, the problem, and "how we judge the result";
no price; a "Request a call about this" link that names the example in the
form. The four-step sample moves up near the top, is called a "sample"
everywhere, and loses "Do not upload real invoices here".

**Contact.** The form comes first, on phone and desktop; the email field is on
the first phone screen. Lead: "Tell me where paperwork or repeated data entry
slows your team down. I reply by email within two business days. If it looks
like a fit, we set up a 25-minute call." Add "You don't need to know the
solution yet." The interest selector stays, defaults to "Not sure yet", and
uses the new names with "Workflow Review" listed first after "Not sure yet".
The failure message must not send the buyer to another site.

**Nav.** Workflow Review (home `#review`), Examples, How we work, Request a
call.

**Titles and descriptions.** Home title "Back-office workflow improvement |
Norman Simplified"; description "Reduce repetitive paperwork and data entry.
Work directly with Spencer Norman, starting with a two-week Workflow Review for
$4,500." Every page keeps exactly one meta description and one h1.

## Voice

First person, plain words, short sentences. State outcomes the buyer cares
about (time, errors, things falling through) before tools. No jargon without a
plain equivalent ("system of record", "inference cost", "regression set",
"evals"). No hedging, no rebutting imaginary competitors, no guarantees, no
invented numbers.

## Accessibility fixes

- Restore a visible focus style on `#main-content`.
- Disable the button press-scale under `prefers-reduced-motion`.

## Constraints

- Rails views, Hotwire and Stimulus only; no new gems or JS dependencies.
- Keep every analytics data attribute and event working (`cta_clicked`,
  `inquiry_submitted`, `explorer_step_viewed`, `catalog_group_opened`).
- No routes change.
- This repository is public: no revenue targets, capacity or business-plan
  numbers in code, copy or docs.

## Decisions made by the builder, not the owner

The owner asked for the best option on these; they are recommendations he has
not individually confirmed:

- The Workflow Review includes a budget range.
- The $2,000 credit applies to any implementation project, not only custom
  software.
- Examples lose their individual prices.
- Lanes and packages are renamed in plain words.
- The contact form stays on its own page.
- Flexfit and the Fractional AI Lead mention are removed.
