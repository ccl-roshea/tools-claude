# Discovery: REST API on Fastify + existing Postgres + AWS-private compute

**Date:** 2026-04-29
**Status:** Discovery complete, ready for execution
**Chunks:** 1 (single chunk — no decomposition needed)

## Execution order

1. Chunk 1: `rest-api-fastify-postgres-aws` (no dependencies)

Single chunk; no parallelism considerations.

## Framing

A new public-facing REST API service consumed by the company's mobile app and one or more partner integrations. The service is a Fastify application written in TypeScript, talking to the existing Postgres cluster in the company's AWS VPC, authenticating mobile users via the existing Cognito user pool, and authenticating partners via API keys it issues and stores itself. Compute defaults to AWS App Runner (with VPC connector to private RDS), with ECS Fargate as a documented fallback and Lambda + API Gateway as an alternative. The service must be reachable from the public internet and must reach Postgres without exposing the database externally. Expected initial scale is sub-50 RPS at peak with unknown growth.

### Original statement

> Build a REST API using Express with Postgres and deploy to AWS ECS

### Key reframes

- **Express → Fastify.** Operator typed Express by habit, not by constraint. Alternatives explored (Fastify, Hono, NestJS); Fastify chosen for TypeScript story and built-in schema validation.
- **AWS ECS specifically → AWS compute, runtime TBD.** Operator picked ECS by association ("AWS = ECS"). The actual constraint is AWS itself (Postgres lives in private VPC). Within AWS, App Runner is a better fit than ECS for sub-50 RPS with scale-to-zero needs. ECS becomes fallback, not default.
- **"REST API" → "REST API for mobile + partners with Cognito + per-partner API keys."** Auth was implicit in the original statement; surfacing it changed the chunk's scope and added API-key lifecycle as an open choice.
- **Reductive frame considered and rejected.** "Don't deploy a new service — fold into an existing one or expose DB views" was rejected because the consumers (mobile app, partner integrations) are external surfaces and there's no existing service that's the right home.

## Confirmed constraints

- **AWS as the deployment platform** — the Postgres cluster lives in the company's AWS VPC; ops will not expose it to the public internet or peer it to a third-party provider. Compute must reach it from inside AWS or via an explicit ops-approved bridge.
- **Postgres as the data store** — existing cluster, ops approval required to introduce any new database. Reuse the cluster.
- **Cognito as the identity provider for end users** — existing user pool, mobile app already authenticates against it. Reuse.
- **Public-internet-reachable API surface** — consumers are a mobile app and external partner integrations; the API cannot be VPC-internal.
- **Mobile + partner is the real external surface** — there is no existing service that's the right home; this is genuinely a new deployable.

## Tested choices

- **Web framework: Fastify.** Considered: Express (default per original prompt), Hono, NestJS. Fastify selected for TypeScript ergonomics and built-in JSON-schema validation; Express dismissed as no-skin-in-game habit; Hono dismissed because no edge-runtime requirement; NestJS dismissed as overkill for a small service.
- **Deployment shape: self-built containerized service.** Considered: PostgREST / Supabase / Hasura ("schema-as-API" frame) and "no new service" frame. Both rejected — see Research outcomes for the formal evaluation.
- **Compute target (default): AWS App Runner.** Considered: ECS Fargate, Lambda + API Gateway, Render, Railway, Fly.io. App Runner selected as default; ECS Fargate kept as documented fallback; Lambda recorded as alternative; non-AWS PaaS rejected by VPC-reach constraint. See Research outcomes.

## Chunk 1: rest-api-fastify-postgres-aws

### Problem statement

Design and plan implementation of a new REST API service: a Fastify (TypeScript) application running on AWS App Runner (with VPC connector to a private RDS Postgres), authenticating mobile users via an existing Cognito user pool, and authenticating partners via service-issued API keys. The service is consumed by the company's mobile app (Cognito-authenticated) and one or more partner integrations (API-key-authenticated). Expected scale is sub-50 RPS at peak with unknown growth; scale-to-zero is desirable. Postgres is the existing cluster; the service does not own its database. The API surface is public-internet-reachable but must reach Postgres without exposing the DB externally. Observability, CI/CD, and IaC are part of this chunk's scope.

### Constraints (inherited + chunk-specific)

- AWS as platform (Postgres in private VPC, ops won't expose).
- Postgres as data store (existing cluster, no new DBs).
- Cognito as identity provider for mobile users.
- Public-internet-reachable API surface (mobile + partner consumers).
- **Compute must reach Postgres in private AWS VPC** (this rules out non-AWS managed PaaS without ops-approved network bridges).
- Web framework: Fastify (TypeScript) — settled, do not re-open.

### Open choices (for the executor to resolve)

- **Compute final pick:** App Runner (recommended default) vs ECS Fargate (fallback) vs Lambda + API Gateway (alternative). Decide based on long-poll/streaming needs, per-request idle costs, and CI/CD shape.
- **Partner API key lifecycle:** generation, scoping (which endpoints can a key hit), rotation, revocation, audit log. v1 storage may live in app Postgres; Secrets Manager noted as v2 hardening (deferred).
- **Cognito integration shape:** validate JWTs at the edge (App Runner / API Gateway authorizer) vs in-app Fastify middleware. Token claims → request user context.
- **Observability stack:** CloudWatch logs/metrics by default; Sentry or equivalent for error tracking (decide); structured logging library pick.
- **Deploy + IaC:** AWS CDK vs Terraform vs Copilot vs SAM; CI provider; image registry (ECR).
- **API contract conventions:** REST verbs only vs JSON:API; OpenAPI spec generation (Fastify has first-class support).
- **Schema migration tooling:** existing approach in the Postgres cluster (presumably already established) — the executor should confirm and align.
- **Rate limiting and abuse protection** for the public surface (especially partner keys).

### Dependencies

None — single chunk.

### Recommended executor

`/superpowers:brainstorming` followed by `/superpowers:writing-plans`.

### Notes for the executor

- Operator surfaced and explicitly rejected three "schema-as-API" options (Supabase, PostgREST, Hasura) — do not re-litigate. PostgREST's RLS-driven authorization and schema-as-API patterns are flagged as inspiration only.
- Compute decision is App Runner-first; do not default back to ECS without an explicit reason. ECS Fargate stays as documented fallback because the operator's original prompt named it.
- Partner API key handling was hand-waved in discovery; the red-team flagged lifecycle (rotation, scoping, revocation, audit) as needing explicit treatment. Surface these in the brainstorm.
- Network constraint is the load-bearing one: any compute pick must demonstrate "can talk to private RDS without exposing it."

## Red-team findings

### Addressed

- **[DISCUSS] Finding 1 — VPC-reach must be a research filter.** Resolution: filter applied during Phase 3.5; non-AWS PaaS rejected with specific network-conflict reasons.
- **[DISCUSS] Finding 2 — Partner API key lifecycle hand-waved.** Resolution: added to chunk's "Open choices" with explicit sub-items (rotation, scoping, revocation, audit log).
- **[DISCUSS] Finding 3 — Observability + deploy pipeline never explored.** Resolution: added to chunk's "Open choices" with default lane (AWS-native).
- **[DISCUSS] Finding 6 — Existence question for Supabase / PostgREST / Hasura.** Resolution: formal Phase 3.5 evaluation performed; classifications recorded with specific reasons.

### Accepted risks

- **[MINOR] Finding 4 — API contract style (REST conventions, OpenAPI generation) not explored at discovery level.** Accepted because: this is a /superpowers-level decision; the chunk's Open Choices list captures it.

### Deferred

- **[DISCUSS] Finding 5 — Partner keys in app DB vs Secrets Manager.** Deferred to v2. v1 stores keys in Postgres alongside application data; v2 evaluates Secrets Manager or a separate locked-down schema. Operator's reason: keep MVP scope tight; partner volume is low at launch.

## Research outcomes (build-vs-buy)

### Overall problem

- **Searched for:** `managed REST API platform Postgres backend 2026 Supabase Render Railway Fly.io alternatives`
- **Candidates evaluated:**
  - **Supabase (cloud)** — Reject
    - URL: https://supabase.com
    - Functionality match: ~70% (REST + auth + RLS), but auth duplicates Cognito and DB layer wants Supabase-managed Postgres.
    - Cost: free tier + paid; not the deciding factor.
    - License: Apache 2.0 (self-hosted) / commercial cloud.
    - Maintenance: active.
    - Lock-in: medium (cloud) / low (self-hosted).
    - Integration burden: high — would require self-hosting Supabase inside the AWS VPC to point at the existing Postgres, which is more ops than building the Fastify service.
    - Reason: auth would duplicate Cognito; managed Supabase requires Supabase-owned DB; self-hosting Supabase against existing cluster is heavier than the build-it path.
  - **PostgREST** — Inspire
    - URL: https://postgrest.org
    - Functionality match: ~50% — auto-generates REST from schema, RLS-based authz; doesn't speak Cognito and doesn't shape requests beyond what SQL views express.
    - Cost: free (open source).
    - License: MIT.
    - Maintenance: active.
    - Lock-in: low.
    - Integration burden: medium — easy to deploy, but rewriting auth + request shaping in SQL/RLS is a different discipline than the operator wants.
    - Reason: operator wants code-level control over auth integration (Cognito JWT validation in middleware) and request shaping. RLS-driven authorization and schema-as-API patterns are worth borrowing in the design.
  - **Hasura CE (self-hosted)** — Reject
    - URL: https://hasura.io
    - Functionality match: ~40% for this use case. Primary surface is GraphQL; REST endpoints are derived.
    - Cost: free (CE) / commercial (Cloud, EE).
    - License: Apache 2.0 (CE).
    - Maintenance: active.
    - Lock-in: medium.
    - Integration burden: medium-high — running Hasura adds an operational layer just to expose REST.
    - Reason: consumers (mobile, partner) expect REST; Hasura's primary surface is GraphQL. Inverting the surface adds friction without payoff for this app's shape.
- **Outcome:** Reject all whole-problem replacements. Build the service, but borrow PostgREST's RLS-based authorization patterns where useful.
- **Effect on chunks:** None — single chunk unchanged in shape, but the executor has a documented "we considered these" trail.

### Chunk 1 (compute pick)

- **Searched for:** `deploy Node Express container managed platform vs AWS ECS 2026 cost comparison`
- **Filter applied:** "must reach Postgres in private AWS VPC."
- **Candidates evaluated:**
  - **AWS App Runner** — Adopt fully (recommended default)
    - URL: https://aws.amazon.com/apprunner/
    - Functionality match: ~95% — managed container service, scale-to-zero capable, native VPC connector to private RDS, AWS-native observability and IAM.
    - Cost: pay-per-use (vCPU + memory + requests); strong fit for sub-50 RPS with idle.
    - License: AWS service.
    - Maintenance: active.
    - Lock-in: medium (AWS-tied; container is portable).
    - Integration burden: low — supports container image from ECR, environment-based config, IAM-bound database creds.
    - Reason: best match across constraints (AWS-native, VPC-reach, scale-to-zero, low ops surface) and load profile.
  - **AWS ECS Fargate** — Inspire / fallback
    - URL: https://aws.amazon.com/ecs/
    - Functionality match: ~95% functionally, but operationally heavier than App Runner for this size service.
    - Cost: similar order to App Runner at this scale; ECS control plane is free, Fargate per-task billing applies.
    - License: AWS service.
    - Maintenance: active.
    - Lock-in: medium.
    - Integration burden: medium — task definitions, services, load balancer wiring, more knobs.
    - Reason: documented as fallback because the operator's original prompt named it. Use if App Runner has a feature gap surfaced in /superpowers (e.g., need long-running tasks, larger CPU/memory, custom networking).
  - **AWS Lambda + API Gateway** — Adopt partially / alternative
    - URL: https://aws.amazon.com/lambda/
    - Functionality match: ~80% — Fastify-on-Lambda via `@fastify/aws-lambda` works; cold starts and per-request billing are real considerations; VPC-attached Lambdas reach private RDS.
    - Cost: extremely low at sub-50 RPS with bursty traffic; potentially higher at sustained load.
    - License: AWS service.
    - Maintenance: active.
    - Lock-in: medium-high (more code coupling to Lambda runtime than App Runner).
    - Integration burden: medium — VPC-attached Lambda has cold-start implications; API Gateway adds a layer.
    - Reason: viable alternative if scale-to-zero and per-request billing are dominant; recorded so executor can compare.
  - **Render** — Reject
    - URL: https://render.com
    - Functionality match: ~85% on the API side, but cannot meet the network constraint.
    - Cost: predictable monthly tiers; not the blocker.
    - License: commercial.
    - Maintenance: active.
    - Lock-in: low (container portable).
    - Integration burden: would require exposing Postgres publicly or VPN/peering — both rejected by ops.
    - Reason: cannot reach private AWS VPC Postgres without exposing the DB or building a network bridge ops vetoed. Network constraint, not preference.
  - **Railway** — Reject
    - URL: https://railway.com
    - Functionality match: ~85% on the API side; same network blocker as Render.
    - Cost: usage-based; not the blocker.
    - License: commercial.
    - Maintenance: active.
    - Lock-in: low.
    - Integration burden: same network conflict.
    - Reason: same as Render — no native VPC peering to AWS RDS in private subnet without ops-vetoed exposure.
  - **Fly.io** — Reject
    - URL: https://fly.io
    - Functionality match: ~85% on the API side; same network blocker.
    - Cost: usage-based; not the blocker.
    - License: commercial.
    - Maintenance: active.
    - Lock-in: low.
    - Integration burden: WireGuard / private-network bridging would be required; ops vetoed.
    - Reason: same network constraint.
- **Reverse sunk-cost check:** Applied. Operator's stated AWS-as-platform constraint is grounded in Postgres VPC reachability, not preference for self-build. Rejection of non-AWS PaaS is constraint-driven and specific.
- **Outcome:** Chunk's "compute" open choice narrows from "any AWS compute" to a ranked default — App Runner first, Fargate fallback, Lambda alternative — with non-AWS PaaS documented as evaluated-and-rejected.

## Discovery log (collapsed)

<details>
<summary>Socratic Q&A highlights</summary>

- **Q (Skill, Technique D):** "You mentioned Express. Constraint or choice?"
  **A (Operator):** "I just typed Express because I know it."
  **Impact:** Shifted from "Express baked in" to "framework is open." Fastify selected after a 3-alternative pass.

- **Q (Skill, Technique D):** "Postgres — constraint or choice?"
  **A (Operator):** "Constraint — existing cluster, ops approval bar."
  **Impact:** Locked Postgres in. Eliminated Supabase-managed-DB and Hasura-cloud as candidates downstream.

- **Q (Skill, Technique D):** "AWS ECS — constraint or choice?"
  **A (Operator):** "ECS is a choice — I picked it because we use AWS. AWS itself is more constrained."
  **Impact:** Split AWS (constraint) from ECS (choice). Deferred ECS-vs-App-Runner-vs-Lambda to Phase 3.5; that research changed the default away from ECS.

- **Q (Skill, Technique B):** Three framings — self-built service / PostgREST-style schema-as-API / no-new-service-at-all.
  **A (Operator):** "Frame 1. Mobile + partner makes frame 3 unfit; want code-level auth control so frame 2 is out."
  **Impact:** Confirmed self-build path. Frames 2 and 3 logged as evaluated and rejected with reasons.

- **Q (Skill, Technique D):** "AWS itself — constraint or choice?"
  **A (Operator):** "Constraint — Postgres lives in our AWS VPC, ops won't expose it."
  **Impact:** This is the load-bearing constraint that ruled out Render/Railway/Fly.io in Phase 3.5.

- **Q (Skill, soft-signal proposal):** "Move to chunking?"
  **A (Operator):** "Move on."
  **Impact:** Phase 1 → Phase 2 transition.

- **Q (Skill, Phase 3 finding 6):** "Should we formally evaluate Supabase / PostgREST / Hasura in 3.5?"
  **A (Operator):** "Accept — document the rejections."
  **Impact:** Phase 3.5 produced the evaluated-and-rejected trail so future readers don't re-ask.

</details>
