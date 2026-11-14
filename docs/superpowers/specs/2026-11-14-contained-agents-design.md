# Norman Simplified: AI agents at work, under your control (v3)

Date: 2026-11-14

Source: the owner's pivot brief ("Self-Hosted Claude Agents Pivot"), amended by
him in conversation several times, including in a parallel planning
conversation whose direction he preferred. This document amends the v2 message
(`2026-11-12-studio-message-v2-design.md`). Where this document is silent, v2
still applies.

## Why

Small and mid-sized businesses want AI doing real work: reading the documents
that come in, drafting the replies, reconciling the numbers. What holds an
owner back is a fair question nobody has answered for them: where does our
customer data go, and what can this thing do without asking?

v2 sells the same buyer a review of their paperwork. v3 keeps that buyer and
changes what is sold: an agent that does one recurring job, inside limits the
business sets.

## The message

> I put AI agents to work in your everyday operations: connected to the tools
> you already use, set up around how you work, and clear about when to ask a
> person.

What the owner decided, in order:

1. **Not Claude only.** Whichever agent stack fits the job.
2. **A closed(ish) box, not necessarily inside the customer's building.** The
   promise is control, not location.
3. **Not only engineering work.** The buyer is a business that wants AI in its
   day-to-day workflows. Engineering teams are a second audience, not the home
   page.
4. **The box can be the customer's own VPS.** A rented server in the customer's
   own account, so they own it and control it.
5. **Lead with the work and the control, not the hosting.** Where the agent
   runs is one choice inside the offer. Start with one workflow and a pilot
   with a measurable result. The review is for when it is not yet clear which
   job to start with.

## The box

An employee should be able to describe it in one breath: "It can read this
inbox, look up these records, and prepare a response. It needs approval before
it sends a quote or changes an account."

In the words the site uses:

- **A defined job.** One piece of work, written down, with a test for whether
  it was done right.
- **Named limits.** The agent can reach only the inboxes, folders and systems
  in the scope.
- **A person approves.** The agent drafts and prepares. Anything sent to a
  customer or changed in a system of record waits for a person, unless the
  scope says otherwise for a specific step.
- **A record.** Every run is logged where you can read it.
- **Your accounts and keys.** The model is used through a business account in
  your name. Norman Simplified holds nothing you cannot revoke.
- **Where it runs is your choice.** Either the model vendor's hosted service
  under your business account, or a server you own: a VPS in your own hosting
  account, holding the agent, its files, its credentials and its history.
- **If we stop working together, you keep everything and it keeps running.**

The buyer's worry is rarely phrased as infrastructure. It is "can it email the
wrong customer?" and "can it change our prices?". The site answers those first
and hosting second.

What the box is not:

- It is not offline. Each time the agent needs the model, the text it is
  working on is sent to the model provider. The site says this wherever it
  says "your server" or "you control".
- A server you own does not run itself. It needs updates, backups and someone
  watching it. That is what Ongoing support is for.
- A VPS is only as controlled as its setup: the firewall, who can sign in and
  how, encrypted backups, and credentials limited to what the job needs.
- It is not AI everywhere. The work combines the software the business already
  has, ordinary automation, and AI only where something has to be read and
  interpreted.

Design rule for every agent built: if the agent or its server is down, the work
waits in a queue and people can do it the old way. Nothing the business depends
on stops. This is what makes business-hours support honest.

## Who it is for

A solo consultant cannot sell to companies with procurement and vendor security
reviews. The target is a business where the person with the problem can also
say yes.

**Company**

- Roughly 20 to 200 people, few or no engineers on staff
- Several people handling the same recurring requests, documents or updates
- That work passes between email and two or more business systems
- An owner or operations manager who answers for the delays and mistakes
- Enough volume that fixing it is worth real money: as a guide, a job that
  takes about 15 hours a week of someone's time, or one where a faster answer
  wins orders
- Software that can give usable access to the information the job needs

**First industries to test in outbound** (not named as a restriction on the
site): wholesale distributors and commercial service companies. Example jobs
for the site come from these: a quote prepared from an emailed request against
approved pricing and stock; an incoming request turned into a job record with
the missing details chased.

**The moment they buy**

- One recurring job is backing up or eating a named person's week
- Staff are already using personal AI accounts for work, and the owner does not
  know what has been pasted where
- A customer, insurer or contract has asked how the business uses AI

**People**

- Buyer: the owner, a general manager, or the head of operations
- The person who does the job today is in the room

**Not a fit**

- A business that needs a system with no outside connection at all
- A chatbot for a public website
- An enterprise with a procurement process
- A job that happens a few times a year

The site states fit in plain words on the Agent Readiness Review page ("A good
fit if", "Probably not a fit if"). Following v2, it neither targets nor
excludes any industry by name.

**Second audience: engineering teams.** A software team that wants agents on
its own systems (broken builds, alert triage, pull request review) and needs to
tell its security owner what the agent can touch. They get one page, not the
home page.

A named list of businesses that match the main profile is kept **outside this
repository**.

## Offers

The only call to action is **Request a call**. The call decides which of the
two starting points fits.

**Pilot. $9,500 fixed fee. Three to four weeks.** The usual first step. One
agent doing one job, on the vendor's hosted service under the customer's
business account, with a written acceptance test agreed before work starts.

**Agent Readiness Review. $3,500 fixed fee. One week.** For a business that
does not yet know which job to start with, or needs the decision in writing
before spending more. It replaces the Workflow Review.

- Up to three conversations with the people who do the work
- Up to three recurring jobs compared: where the time goes, and which one an
  agent should take first
- What the agent would see, what it would be allowed to do, and where a person
  approves
- Where it should run, with the reasoning
- A budget range to build it and a monthly figure to run it
- A plain go or no-go recommendation
- A 45-minute walkthrough of the report

The review runs on conversations, documents and screen shares over one week.
It needs no passwords and no access to the customer's systems. A mutual NDA is
signed first if the customer asks. The report is theirs whether or not they
continue, and the full $3,500 is credited toward a pilot with Norman Simplified
that starts within 60 days.

**After a pilot or a review:**

- **Full build. Starts at $18,000.** The job taken to production, or further
  jobs added.
- **Your own server. Starts at $6,500.** Optional. The box moved to, or built
  on, a VPS in the customer's own hosting account: sign-in, firewall, backups,
  monitoring, documentation and handoff.
- **Ongoing support. Two fixed monthly plans.** Business hours, not on-call,
  three-month minimum.
  - Basic, $750 a month: updates, backups, monitoring, up to 2 hours of
    changes, reply by the next business day.
  - Standard, $1,500 a month: the same, with up to 6 hours of changes and a
    same-day reply.

Model usage and hosting are billed by the vendors to the customer's own
accounts. The proposal gives an estimate of both.

Payment terms stay as v2: half to start.

Pricing rules from v2 hold: "fixed fee" only where the price is one number;
everything else is "starts at", followed by "your written proposal sets the
fixed fee before work begins".

The v2 kinds of work (Tools and training, Workflow automation, Custom software)
stay on How we work with their prices, under one heading, "Other work".

## Goals

- An owner with no technical background can say within one screen what is
  sold, what it costs to start, and why their data is safe to hand over.
- Every claim about where data goes is true and specific.
- Outbound and inbound conversations can start against the offer within two
  weeks.

## Non-goals

- A blog engine, CMS or newsletter
- Comparisons of AI vendors
- Hosting customers' agents on Norman Simplified's own servers

## Anti-goals

These make the work a failure even if it ships:

- Any sentence a reader could take as "your data never leaves".
- Any implied client result, deployment count, or partnership with a vendor.
- A home page that speaks to engineers and owners at once.
- Jargon an owner has to look up: "inference", "sandbox", "control plane",
  "self-hosted" without the plain words next to it.

## Messaging rules

- Wherever a page says "your server" or "you own it", the same section says
  that text is sent to the model provider when the agent uses the model.
- "Stays on your server" describes where things are stored and where the agent
  runs. It never describes what the model sees.
- Never claim offline or air-gapped operation.
- Name the operating work plainly: updates, backups, monitoring.
- Concrete jobs before any claim. No "revolutionary", "transformative", or
  similar.
- Vendor product names appear only where a fact needs them. One footer line on
  any page that names one: "Norman Simplified is independent and is not
  affiliated with Anthropic." No vendor logos.
- Any page stating vendor facts carries a visible "Checked against vendor
  documentation on <date>" line. Where a fact in this document and the vendor's
  documentation differ on the day a page is written, the documentation wins and
  the builder does not need sign-off.

Voice is v2's: first person, plain words, short sentences, outcomes before
tools. The engineering page may use precise technical terms.

## Proof

v2's rule holds: nothing on the site may state or imply a result that was not
measured.

- **Background**, as now.
- **The implementation example stays on the home page.** Records extracted into
  a review queue, with uncertain fields held for a person, is an agent in a box
  with a person approving. Keep v2's labelling and the one line saying it was
  built during employment.
- **Reference build.** The owner sets up one box on a VPS of his own with one
  agent doing a real job and a review queue, and writes it up. It becomes a
  note and a second example. Until it exists the site does not mention it.
- **The report outline** on the review page, labelled as the outline of the
  deliverable.

## Pages

**Home** (`/`)

1. Hero. Headline: **Put AI agents to work. Keep control of what they can
   do.** Subhead introduces Spencer, names two example jobs, and gives the
   pilot and its price. One Request a call button (`interest: "pilot"`). The two-business-day reply line stays. Price and
   button visible on the first screen at 1440x900 and 390x844.
2. How a pilot works: one job, the limits, the approval step, the acceptance
   test. Then one short block: "Not sure which job to start with?" with the
   Agent Readiness Review at $3,500 and a link to its page. Section id stays
   `review`.
3. What "control" means: the seven points from "The box", and what it is not.
4. What can follow: Full build, Your own server, Ongoing support, each with a
   "What's included" link to How we work. Section id stays `services`.
5. Who does the work, with the implementation example.
6. After you send the form: unchanged from v2.
7. FAQ: Is our data sent anywhere? Do we need technical staff? What if the
   agent gets something wrong? What if we stop working with you? Who owns the
   work?
8. Closing Request a call.

**Agent Readiness Review** (`/agent-readiness-review`, new). The full offer:
fit and not fit, how the week runs, what the customer provides, the report
outline, terms, what can follow.

**Where your agent runs** (`/where-agents-run`, new). The explainer in plain
words: your own server compared with the vendor's hosted service; what is
stored where; what is sent to the model provider and when; who can sign in;
what happens when the server is down; what it takes to keep it running. A
diagram in HTML and CSS, not an image.

**For engineering teams** (`/engineering-teams`, new). Agents for broken
builds, alert triage and pull request review. This page carries the detailed
hosting levels, using Claude Managed Agents as the worked example. Facts
checked against Anthropic's documentation on 2026-11-14
(`platform.claude.com/docs/en/managed-agents/`: `self-hosted`,
`choosing-an-environment`):

| Level | What you host | What reaches the vendor | Access |
|---|---|---|---|
| Vendor-hosted, scoped | Nothing. You set network rules and credentials. | Conversation, tool results, the sandbox's files and state, skills, memory stores | Beta |
| Your sandboxes | The workers and sandboxes where tools run | Conversation, tool results, skills, memory stores. Files and processes stay on your worker. Web search and web fetch still run on the vendor's side. | Beta |
| Your service and your sandboxes | The server (`cma-server`), PostgreSQL 16 or later, workers and sandboxes. Session history is stored with you. | Each model call sends the conversation so far, including tool inputs and results, to the inference provider: Anthropic by default, or Amazon Bedrock, Google Cloud, Microsoft Foundry, or your own gateway | By request through an Anthropic account team |

Do not print an announcement date or the words "private beta" unless a vendor
source is linked. The brief's date of 12 November 2026 could not be confirmed
from the documentation. The page says the customer runs and secures the server,
database and sandboxes and installs each release.

**How we work** (`/how-we-work`). Leads with the pilot and the Agent Readiness
Review, then Full build, Your own server and Ongoing support, then the five steps and payment
terms. Below that, "Other work" keeps the three v2 kinds of work with their
prices and existing anchors (`#adopt`, `#automate`, `#build`).

**Examples** (`/ai-integration`). Stays in the nav. Its examples are jobs an
agent can do, so the intro is reworded to say so. Structure unchanged.

**Notes** (`/notes`, `/notes/:slug`, new). Articles as plain ERB templates. No
database, no Markdown gem. Launch with two, written for the main buyer:

- "What actually leaves your business when you use an AI tool"
- "Your own server or the vendor's: where an AI agent should run"

The brief's four Claude-specific articles are for the engineering audience and
follow later.

**Contact.** Lead copy turns to "the job you want off someone's desk".
Interest options, in order: Not sure yet, Pilot, Agent Readiness Review, Full
build, Your own server, Ongoing support, then the three v2 kinds of work.

**Nav.** How a pilot works (home `#review`), Examples, How we work, Request a
call. Where
your agent runs and For engineering teams are linked from the home page and the
footer.

**Titles and descriptions.** Home title "AI agents for everyday operations |
Norman Simplified". Every page keeps exactly one meta description and one h1.
New pages join the sitemap.

## Approaches considered

1. **Claude Managed Agents specialist for engineering teams**, as the brief was
   written. Rejected by the owner: one vendor, one gated product, and a buyer he
   does not want to be limited to.
2. **Engineering teams first, stack neutral.** The previous draft of this
   document. Rejected by the owner: too narrow.
3. **Business owners first, with a server they own as the headline.** The
   previous draft. Superseded: the owner preferred leading with the work and
   the control, with hosting as a choice and a pilot as the first step.
4. **Business owners first; lead with one workflow and a pilot; control stated
   in the buyer's words; own server as an option; engineering teams on one
   page.** Chosen. It keeps the buyer the site already speaks to, uses the one
   real example the owner has, gives a lighter first purchase, and needs no
   gated vendor access to deliver.
5. **Add agents as a fourth kind of work on the v2 site.** Least work.
   Rejected: the visitor would again have to choose before anyone has looked at
   their problem.

## Constraints

- Rails views, Hotwire and Stimulus only. No new gems or JavaScript
  dependencies.
- Existing `interest` keys, analytics events and params, anchors and URLs keep
  working. `audit` stays the key for the review and its label becomes "Agent
  Readiness Review". New keys: `pilot`, `agents` (Full build), `setup` (Your
  own server), `support`.
- This repository is public. No revenue targets, capacity, prospect names,
  outbound templates or reply templates in code, copy or docs.
- House rules: no service objects, Minitest with fixtures, no mocking.

## Delivery

Three pull requests, each shippable alone:

1. Home, Agent Readiness Review page, How we work, Examples intro, contact
   options, nav, titles, sitemap, tests.
2. Where your agent runs, and For engineering teams.
3. Notes, with the first two articles. The owner approves article text before
   merge.

## Outside the repository

The owner's, kept in a private document, alongside the pull requests:

- A list of about 30 named businesses that match "Who it is for", each with
  the buyer's name and the reason they are on the list
- A short outbound note and a one-page summary of the review, put in front of
  10 to 15 of them before the site is treated as settled. Ask each whether a
  smaller paid pilot would be easier to say yes to than the review.
- Reply templates for inbound enquiries
- LinkedIn versions of the two articles
- The reference build

## Left to the builder

- Section layout, CSS and the explainer diagram, within the existing design
  system
- How notes are routed and listed, within the constraints above
- Exact wording of every sentence not quoted here, within the messaging rules
- The layout's fallback title and description, which still carry v2 wording
- Test structure. At minimum: every page that says "your server" also says
  text is sent to the model provider; the v2 retired-names test keeps passing
  with "Workflow Review" added to it for the home page; new pages meet the
  title, description, h1 and Request a call checks; new pages are in the studio
  sitemap, carry canonical URLs and analytics attributes, and return 404 on the
  personal host (`search_indexing_test`, `site_routing_test`, `analytics_test`
  all loop over the studio paths).

## Open questions for the owner

1. **Payment tied to the acceptance test.** Should the second half of a pilot
   fall due only when the agent passes the agreed test? It is the strongest
   reassurance on offer, and it puts the risk of a badly chosen job on Norman
   Simplified. Until the owner says yes, the site says "half to start" only.
2. **Which hosting companies** the owner is willing to set up and support.

## Prices the owner confirmed

On 2026-11-14 the owner approved: pilot $9,500 fixed; review $3,500 fixed,
one week, credited in full toward a pilot; full build from $18,000; own server
from $6,500; support at $750 and $1,500 a month. These replace the brief's
$5,500 review and $15,000 setup.

## Decisions made by the builder, not the owner

The owner set the direction. He has not confirmed these individually:

- The pilot runs on the vendor's hosted service by default; the customer's own
  server is an optional later step.
- The Agent Readiness Review replaces the Workflow Review rather than sitting
  beside it, and is the second starting point, not the first.
- The review drops from four conversations to three to fit one week.
- The two first industries are for outbound only; the site names none.
- The review needs no passwords and no system access; NDA on request.
- A person approves anything sent or changed, by default.
- The "work waits in a queue" rule, and support as business hours, not on-call.
- The size range and buying moments in "Who it is for".
- Engineering teams get one page, off the primary nav.
- The headline, page URLs, and "Notes" as the section name.
- The two launch articles are written for owners; the brief's Claude-specific
  four come later.
- One agent per pilot, with a written acceptance test.
