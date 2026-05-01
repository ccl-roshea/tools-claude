# Discovery: Handmade Home Decor Two-Sided Marketplace

**Date:** 2026-04-29
**Status:** Discovery complete, ready for execution
**Chunks:** 4

## Execution order

1. **Chunk 1: Integrate Clerk (auth & accounts)** — no dependencies
2. **Chunk 2: Integrate Stripe Connect (payments & payouts)** — depends on Chunk 1 (specifically: stable user/seller identity model that Stripe Connect accounts can attach to)
3. **Chunk 3: Marketplace core (listings + search + cart + checkout + orders + messaging)** — depends on Chunk 1 (user/seller identity), Chunk 2 (checkout API + held-funds order state machine + webhook idempotency model)
4. **Chunk 4: Integrate PostHog (analytics)** — depends on Chunks 1, 2, 3 (specifically: each upstream chunk owns and emits its own events; Chunk 4 wires them up and builds dashboards)

**Parallelism notes:** For MVP, sessions run sequentially (operator can only drive one /superpowers session at a time). However:
- After Chunk 1 completes, the *catalog/listings sub-design* of Chunk 3 could theoretically parallelize with Chunk 2 — but in practice we sequence Chunk 2 first because Chunk 3's checkout and order state depend on Chunk 2's design.
- Chunk 4's event-schema work is light-touch wiring; if /superpowers ever supports parallel dispatch, Chunk 4 can start the moment Chunks 1-3 each define their event surface.

## Framing

A two-sided online marketplace ("Etsy for handmade home decor") with a **curated custom-commission flow** as the differentiator. Buyers browse and purchase physical goods or commission custom work; sellers list products, accept orders, fulfill, and get paid. The platform takes a 10% commission and holds funds during the order/shipping window to enable dispute refunds. Pre-launch, target ~500 sellers and ~10k buyers by end of year 1, must ship in 3 months on a small (4-6 fullstack-TS) team with no payments or ops experience, on Vercel + managed services only.

The strategic stance: **custom UX (because the curated commission flow is the differentiation), aggressive buy on commodity subsystems** (auth, payments, analytics).

### Original statement

> We need a platform with auth, billing, a marketplace, and analytics

### Key reframes

- "Billing" → marketplace payments with held funds, split payouts, US 1099-K filing, KYC for sellers. Vastly larger and more regulated than the original word implied; this is the chunk most at risk and most worth buying.
- "Marketplace" → listings + search + cart + checkout + orders + messaging (V1). Reviews/ratings deferred to V2.
- "Analytics" → split into (a) founder funnel + retention and (b) per-seller dashboards. Operational/observability metrics deferred to ops tooling (Vercel + Sentry).
- Sharetribe / Shopify-multi-vendor considered as whole-problem replacements; rejected because the curated commission flow is the product differentiation and doesn't fit those models well.

## Confirmed constraints

- **3-month ship to MVP** — driven by ~5 months of runway; treat as hard.
- **Team: 4-6 fullstack TypeScript engineers, no payments domain experience, no dedicated ops** — pushes hard toward managed services for any high-risk subsystem.
- **Vercel + managed services only** — no self-hosted infra, no k8s, no control plane. Any candidate requiring self-hosting is a non-starter.
- **Two-sided marketplace, mostly physical goods + custom commissions** — the marketplace pattern is "Etsy-for-X", not "SaaS" or "Uber-for-X".
- **Held funds with 10% platform commission** — money flows buyer → platform → seller; platform must be able to refund mid-shipping.
- **US-first launch** — implies 1099-K filing obligations for the platform; payments provider must handle this.
- **Auth scope:** consumer email + Google + magic link; guest checkout; buyer/seller role separation. No SSO/B2B.
- **Marketplace V1 scope:** listings + search + cart + checkout + orders + messaging. Reviews/ratings out of V1.
- **Analytics V1 scope:** founder funnel/retention + per-seller dashboards. Ops metrics deferred.

## Tested choices

- **Custom marketplace platform (selected) vs. Sharetribe (rejected) vs. Shopify multi-vendor + manual ops (rejected).** Selected because the curated commission flow is the differentiator and doesn't bolt cleanly onto Sharetribe; Shopify-manual was too operationally heavy at projected scale.
- **Buy aggressively on commodity subsystems (selected) vs. build everything (rejected).** The strategic stance after considering Technique B alternatives.
- **V1 search: Postgres pg_trgm / built-in (selected) vs. Algolia / Typesense / Meilisearch (deferred to V2).** Tested per red-team finding 2; chosen to keep Chunk 3 from going shallow on cart/checkout/orders. Revisit when search quality complaints surface.
- **V1 messaging: asynchronous polled, no real-time, no moderation beyond report-and-block (selected) vs. real-time chat (rejected).** Tested per red-team finding 3; chosen to keep V1 scope tractable.

## Chunk 1: Integrate Clerk (auth & accounts)

### Problem statement

Stand up consumer authentication for a two-sided marketplace using **Clerk** as the identity provider. Support email + password, Google OAuth, and optional magic link sign-in. Support guest checkout (anonymous cart that converts to a Clerk user at checkout). Define a stable buyer-vs-seller role separation that downstream chunks (Stripe Connect KYC, marketplace listing ownership) can attach to. Build the minimum account-profile UI on top of Clerk's components. Out of scope: KYC for sellers (lives in Chunk 2), seller-specific onboarding UX beyond the account profile, organization/team auth.

### Constraints (inherited + chunk-specific)

- All top-level constraints apply.
- Auth provider must be Clerk (chosen in Phase 3.5).
- Must work with guest checkout (anonymous → identified user attribution; coordinates with Chunks 2, 3, 4).
- Buyer/seller role separation must be **stable and queryable** — Stripe Connect (Chunk 2) needs to look up sellers by Clerk user id.

### Open choices (for the executor to resolve)

- Where to store the role flag: Clerk public metadata vs. Clerk private metadata vs. own database with a join on Clerk user id.
- How to model role transitions (a buyer becoming a seller).
- Profile fields beyond Clerk defaults (display name, shop name for sellers, profile photo).
- Email verification policy at signup (immediate vs. deferred).
- Session length and refresh policy.

### Dependencies

None.

### Recommended executor

`/superpowers:brainstorming` (then `/superpowers:writing-plans`).

## Chunk 2: Integrate Stripe Connect (payments & payouts)

### Problem statement

Integrate **Stripe Connect (Express accounts)** to enable buyer→seller payments with a 10% platform commission, held funds during the order window, refundable mid-shipping for disputes, and US 1099-K platform tax filing. Sellers onboard via Stripe-hosted KYC (no custom KYC build). Implement an order state machine that maps to Stripe's separate-charges-and-transfers (or destination charges) flow, with **idempotent webhook handling on Vercel serverless functions** as a hard concern (Stripe retries; Vercel functions have timeout and cold-start behavior; missing idempotency causes double-charges or double-refunds). Plan refund and dispute flows. Out of scope: seller subscription fees (V2), non-US tax handling, payment methods beyond Stripe's defaults.

### Constraints (inherited + chunk-specific)

- All top-level constraints apply.
- Must use a payments provider that **handles 1099-K filing for the platform** (red-team finding 1, hard).
- Must use Stripe Connect (chosen in Phase 3.5).
- Vercel function timeouts and cold-start behavior constrain webhook design (red-team finding 5). Webhooks **must be idempotent** and may need a queue / durable write if processing exceeds function timeout.
- Held-funds model required (separate-charges-and-transfers, or holding the destination-charge transfer).
- Seller KYC must be Stripe-hosted (Express) — no custom KYC.

### Open choices (for the executor to resolve)

- Separate-charges-and-transfers vs. destination charges with deferred transfer (each has different held-funds semantics).
- Order state machine: which states map to which Stripe lifecycle events; how to handle partial refunds, partial fulfillment.
- Webhook architecture: direct serverless handler vs. webhook → durable queue (e.g., Inngest, QStash, Upstash Workflow) → worker. **Idempotency strategy is mandatory** — operator flagged this loudly.
- Seller onboarding UX flow (when in the seller-signup journey is the Stripe Connect onboarding kicked off).
- How to surface payouts and earnings to sellers (custom UI vs. Stripe Express dashboard link-out).
- Refund authorization rules (who can refund: buyer-initiated, seller-initiated, platform-initiated, automatic-on-dispute).
- 1099-K configuration: confirm "platform controls pricing" vs. "Stripe controls pricing" classification — affects who files what.

### Dependencies

Depends on **Chunk 1** (specifically: a stable seller identity, queryable by Clerk user id, that the Stripe Connect account id can be attached to).

### Recommended executor

`/superpowers:brainstorming` (then `/superpowers:writing-plans`).

## Chunk 3: Marketplace core (listings + search + cart + checkout + orders + messaging)

### Problem statement

Build the **custom marketplace UX** — the only build-from-scratch chunk. Includes: seller-facing listing creation/management (with custom-commission-request as a special listing type); buyer-facing browse/search/filter (V1: Postgres pg_trgm + faceted filters; can revisit with Algolia/Typesense if quality is poor); cart (anonymous → identified at checkout, coordinated with Chunk 1); checkout that hands off to Stripe Connect (Chunk 2's order state machine); order lifecycle UI for both buyer and seller (status, shipping updates, dispute initiation); buyer↔seller messaging tied to listings or orders (V1: asynchronous polled, no real-time, report-and-block-level moderation only). Each piece must emit events for Chunk 4 to consume. Out of scope: reviews/ratings (V2), seller subscription tier (V2), real-time messaging, content moderation beyond report-and-block.

### Constraints (inherited + chunk-specific)

- All top-level constraints apply.
- Stack: Next.js (Vercel-native), Postgres for primary data, no separate search service in V1.
- V1 search: Postgres pg_trgm and basic faceting only.
- V1 messaging: asynchronous polled, no real-time, report-and-block moderation.
- Custom-commission-request is a first-class listing type (the differentiation).
- Each domain (listings, cart, checkout, orders, messaging) **owns its own events** for Chunk 4 to consume.
- Cart must support anonymous → identified-user attribution for Chunk 4 funnel analytics.

### Open choices (for the executor to resolve)

- Database choice (Postgres yes, but: Vercel Postgres / Neon / Supabase / RDS-via-tunnel?).
- Data model for listings, including how custom-commission-request listings differ from standard listings.
- Cart storage (server-side per-user, server-side per-anonymous-session, cookie-based, or a mix).
- Checkout flow integration with Chunk 2's order state machine — exact handoff semantics.
- Order state machine (must align with Stripe Connect's lifecycle from Chunk 2).
- Messaging data model (per-listing thread, per-order thread, or unified inbox).
- Image storage (Vercel Blob, S3, Cloudinary).
- Event schema for analytics (each domain defines its own events; what's the naming convention?).
- Whether to split this chunk if it strains a single /superpowers session (operator approved keeping it whole; revisit during /superpowers).

### Dependencies

Depends on **Chunk 1** (specifically: stable buyer/seller identity model, guest-checkout → identified-user transition flow) and **Chunk 2** (specifically: checkout API surface, held-funds order state machine, webhook event taxonomy that Chunk 3's order UI will react to).

### Recommended executor

`/superpowers:brainstorming` (then `/superpowers:writing-plans`). Note for executor: this is the only chunk *not* dominated by an integration; expect higher decision load. If the brainstorming session strains, split as listings+search vs. checkout+orders+messaging.

## Chunk 4: Integrate PostHog (analytics)

### Problem statement

Integrate **PostHog Cloud** as the product analytics layer. Build founder-facing dashboards (signup → first listing view → first purchase funnel; cohort retention by signup month; commission revenue per cohort) and seller-facing dashboards (per-seller listing views, conversion, revenue, traffic sources) using PostHog Groups (group key = seller id) with filtered views or embedded dashboards. Define a stable cross-chunk event schema and consume the events emitted by Chunks 1-3. Supplement with Vercel Web Analytics for top-of-funnel page views and Core Web Vitals. Out of scope: operational/observability metrics (Sentry/Vercel covers those), real-time alerting, BI / SQL exports.

### Constraints (inherited + chunk-specific)

- All top-level constraints apply.
- Must use PostHog Cloud (chosen in Phase 3.5).
- Each upstream chunk **owns its own events** — Chunk 4 does not dictate event schema, it consumes and dashboards what's emitted (red-team finding 4).
- Per-seller dashboards must respect privacy: a seller sees only their own data.
- Chunk 4 starts only after Chunks 1-3 have at least defined their event surface.

### Open choices (for the executor to resolve)

- Embed strategy for seller-facing dashboards (PostHog embedded dashboards, custom UI consuming PostHog query API, or precomputed aggregates served from our DB).
- Event naming convention and required properties (collaborate retroactively with Chunks 1-3 outputs).
- How to handle anonymous → identified user attribution in PostHog (alias / identify call timing).
- Funnel definitions and cohort definitions for V1.
- PII scrubbing rules.
- Whether to also use Vercel Web Analytics for the top-of-funnel slice (recommended) or rely on PostHog only.

### Dependencies

Depends on **Chunks 1, 2, 3** (specifically: each chunk's event surface — what events are emitted, with what payload, identified or anonymous).

### Recommended executor

`/superpowers:brainstorming` (then `/superpowers:writing-plans`).

## Red-team findings

### Addressed

- **[CRITICAL] Finding 1:** Chunk 2 listed "US 1099-K tax handling" as in-scope, but the team has zero payments experience. Resolution: made "must use a payments provider that files 1099-K for us" a hard constraint on Chunk 2; Stripe Connect Express adopted in Phase 3.5 specifically because it handles this.
- **[CRITICAL] Finding 2:** Chunk 3 bundled search with everything else, risking shallow design. Resolution: declared "Postgres pg_trgm for V1, Algolia/Typesense for V2 if quality is bad" as a tested choice up front; chunk stays whole but search is now a constrained sub-decision rather than an open one.
- **[DISCUSS] Finding 3:** Messaging in Chunk 3 was under-specified ("basic"). Resolution: defined V1 as "asynchronous polled, no real-time, report-and-block moderation only" as a tested choice. Real-time chat deferred.
- **[DISCUSS] Finding 4:** Analytics (Chunk 4) appeared to own the event schema, contradicting the execution order. Resolution: each upstream chunk owns its own events; Chunk 4 wires them up. Captured in Chunk 4's constraints.
- **[DISCUSS] Finding 5:** Vercel function timeouts and cold-start behavior affect Stripe webhook handling. Resolution: captured as a hard constraint on Chunk 2's design; idempotency strategy is mandatory and called out loudly per operator request.

### Accepted risks

- **[MINOR] Finding 6:** Magic-link auth changes the candidate set. Accepted because: surfaced in Phase 3.5 research; Clerk supports magic link in its free tier, no impact.
- **[MINOR] Finding 7:** Guest checkout has cross-chunk implications (Stripe Customer creation, anonymous cart, anonymous → identified attribution). Accepted because: noted in Chunks 1, 2, 3, 4 constraints; no architectural change required, just cross-chunk awareness.

### Dismissed

None.

## Research outcomes (build-vs-buy)

### Overall problem

- **Searched for:** "all-in-one marketplace platform Stripe Connect auth analytics Next.js 2026"
- **Candidates evaluated:** Sharetribe (already considered Phase 1), Shopify multi-vendor (already considered Phase 1), various marketplace SaaS
- **Outcome:** Reject across-the-board adoption — no platform fits the curated-commission-flow differentiation while preserving custom UX control.
- **Effect on chunks:** None — proceed with per-chunk research.

### Chunk 1: Auth & accounts

- **Searched for:** "managed auth provider Next.js Vercel Clerk Auth0 Supabase comparison 2026"
- **Candidates evaluated:**
  - **Clerk** — Adopt fully
    - URL: https://clerk.com
    - Functionality match: ~95%
    - Cost: Free up to 10k MAU; $0.02/MAU after. Year-1 projected cost: ~$10/mo.
    - License: Commercial (proprietary)
    - Maintenance: Active, frequent releases
    - Lock-in: Medium (custom user object schema; migration possible but non-trivial)
    - Integration burden: Low (drop-in Next.js components)
    - Reason: Best DX for Next.js, free tier covers year-1 scale, supports magic link, supports guest-flow patterns.
  - **Auth0** — Reject
    - URL: https://auth0.com
    - Cost: $0.07/MAU. At 10k MAU = ~$700/mo, ~70x Clerk's cost.
    - Reason: Cost vs. Clerk with no enterprise feature actually needed (no SSO, no compliance certifications required at this stage).
  - **Supabase Auth** — Inspire
    - URL: https://supabase.com
    - Reason: Cheapest at scale and good auth, but bundles a Postgres backend that's an independent decision. Not adopted now; revisit if Supabase is later chosen as the primary database in Chunk 3.
- **Outcome:** Chunk replaced with **integration chunk: "Integrate Clerk"**.

### Chunk 2: Payments & payouts

- **Searched for:** "Stripe Connect marketplace payments split payouts 1099-K tax forms 2026" and "Stripe Connect competitors marketplace payments Adyen MarketPay Mangopay 2026"
- **Candidates evaluated:**
  - **Stripe Connect (Express)** — Adopt fully
    - URL: https://stripe.com/connect
    - Functionality match: ~98%
    - Cost: 2.9% + $0.30 per charge + $0.25 + 0.25% per Express payout. No platform fee from Stripe.
    - License: Commercial (PCI burden borne by Stripe)
    - Maintenance: Active, market leader
    - Lock-in: Medium-high (Connect-specific account model)
    - Integration burden: Medium — webhook idempotency on Vercel functions is non-trivial.
    - Reason: Only candidate that handles 1099-K filing for marketplaces *and* has the simple Express onboarding model. Directly satisfies hard constraint from Finding 1.
  - **Adyen for Platforms** — Reject
    - URL: https://www.adyen.com/platforms
    - Reason: Enterprise-tier, designed for high-volume multi-region platforms; minimum-volume requirements typically don't fit a 3-month MVP US-only marketplace.
  - **Mangopay** — Reject
    - URL: https://mangopay.com
    - Reason: European-focused (FCA-authorized EMI), supports 15 currencies vs. Stripe's 135; weaker fit for US-first launch with US 1099-K filing.
  - **Ryft** — Inspire
    - URL: https://ryftpay.com
    - Reason: Cleaner split-payment API but UK-centric and less mature on US 1099-K. Worth watching for V2.
- **Outcome:** Chunk replaced with **integration chunk: "Integrate Stripe Connect (Express)"**.

### Chunk 3: Marketplace core

- **Searched for:** "marketplace platform Sharetribe Mirakl alternatives self-hosted custom 2026"
- **Candidates evaluated:**
  - **Medusa.js** — Reject
    - URL: https://medusajs.com
    - Functionality match: ~60%
    - Reason: B2C single-store-oriented; multi-vendor support requires custom plugins or forking. The differentiator (curated commission flow) lives exactly where Medusa is weakest. Inspire-only on cart/order-line patterns.
  - **Sharetribe Flex** — Reject (already considered Phase 1)
    - URL: https://www.sharetribe.com
    - Reason: Custom commission flow doesn't fit Sharetribe's model; operator confirmed in Technique B that this is the differentiation.
  - **Algolia / Typesense / Meilisearch (search component only)** — Inspire / V2
    - Reason: V1 declared as Postgres pg_trgm per red-team finding 2; revisit if quality is bad.
- **Outcome:** Chunk unchanged — build custom on Next.js + Postgres + Vercel. Note: Medusa.js cart/order-line patterns referenced.

### Chunk 4: Analytics

- **Searched for:** "product analytics PostHog Mixpanel Amplitude pricing self-host comparison 2026"
- **Candidates evaluated:**
  - **PostHog Cloud** — Adopt fully
    - URL: https://posthog.com
    - Functionality match: ~90%
    - Cost: 1M events/mo free; $0.00031/event after. Year-1 projected cost: <$50/mo.
    - License: Commercial cloud or MIT-licensed self-host (escape hatch)
    - Maintenance: Very active
    - Lock-in: Low (event schema is portable; can self-host later)
    - Integration burden: Low (single SDK, autocapture for funnels)
    - Reason: Generous free tier, low integration burden, supports both founder analytics and seller-facing dashboards in one tool via PostHog Groups.
  - **Mixpanel** — Reject
    - URL: https://mixpanel.com
    - Reason: Pricing escalates per-MTU faster than PostHog per-event at projected volumes; weaker self-host story; no use-case advantage over PostHog.
  - **Vercel Web Analytics + Speed Insights** — Inspire / supplement
    - URL: https://vercel.com/analytics
    - Reason: Strong for top-of-funnel and Core Web Vitals (~30% of needs); doesn't do cohorts or per-seller dashboards. Use *alongside* PostHog.
- **Outcome:** Chunk replaced with **integration chunk: "Integrate PostHog"**, supplemented by Vercel Web Analytics.

### Reverse sunk-cost check applied to

- **Medusa.js, Sharetribe Flex** — operator articulated specific reasons (multi-vendor weakness, differentiation conflict). Rejection upheld.
- **Auth0, Adyen, Mangopay** — rejection reasons are cost (Auth0) and geographic fit (Adyen, Mangopay) — specific and defensible.

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

- **Q:** What are users actually doing on this platform? (Marketplace pitch?)
  **A:** "Etsy for handmade home decor — sellers can also offer custom commissions." Two-sided.
  **Impact:** Anchored framing as a B2C two-sided marketplace; surfaced custom-commission flow as the eventual differentiator.

- **Q:** Pre-launch or migrating? Scale?
  **A:** Pre-launch; 500 sellers / 10k buyers by end of year 1; 4-6 fullstack TS engineers; 3-month ship.
  **Impact:** Set the build-vs-buy bar very high — 3 months for 4 from-scratch subsystems is implausible, biases everything toward managed services.

- **Q (Technique D):** Is "3 months" a constraint or a choice?
  **A:** Self-imposed but tied to runway; treat as hard.
  **Impact:** Locked in as constraint.

- **Q (Technique D):** Is "Vercel" a constraint?
  **A:** Yes; team is comfortable, no ops people, no self-hosting.
  **Impact:** Locked in. Eliminated all self-hosted candidates from Phase 3.5 consideration.

- **Q:** What did "billing" mean? (Buyer-pays-seller vs. seller-pays-platform vs. both; held funds?)
  **A:** Both, mainly buyers paying sellers with 10% commission, held funds for dispute window.
  **Impact:** Reframed "billing" as marketplace-payments-with-escrow-and-1099-K — the largest and most regulated chunk.

- **Q:** What did "analytics" mean? (Founder funnel vs. seller-facing vs. ops?)
  **A:** "I just typed it because I'd seen Mixpanel mentioned" — but on reflection, founder funnel + seller-facing dashboards. Ops deferred.
  **Impact:** Reframed analytics; eliminated ops-metrics from V1; chose PostHog because it serves both audiences.

- **Q (Technique B — three framings):** Custom platform vs. Sharetribe-with-skin vs. Shopify-multi-vendor-plus-manual-ops?
  **A:** Custom platform — curated commission flow is the differentiation. Buy aggressively on commodity subsystems.
  **Impact:** Set the strategic stance for the rest of the discovery.

- **Q (red-team Finding 1):** 1099-K is a legal/regulatory tail; team has zero payments experience.
  **A:** Accepted; made "must use a provider that handles 1099-K filing" a hard constraint.
  **Impact:** Stripe Connect Express became the default in Phase 3.5.

- **Q (red-team Finding 2):** Search bundled with cart/checkout/orders will go shallow.
  **A:** Accepted; declare "Postgres pg_trgm for V1" as tested choice, don't split chunk.
  **Impact:** Constrained Chunk 3's open choices; preserved chunk boundary.

- **Q (red-team Finding 5):** Webhook idempotency on Vercel.
  **A:** "Make sure that point is captured loudly in Chunk 2 — the team would miss it."
  **Impact:** Webhook idempotency strategy is now a mandatory, called-out constraint on Chunk 2.

</details>
