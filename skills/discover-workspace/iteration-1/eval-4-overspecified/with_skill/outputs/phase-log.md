# Phase log — eval-4-overspecified (with skill)

## Phase 1: DISCOVER

**Entered:** Turn 1 (user prompt).
**Exited:** Turn 19 (operator approves moving on).

### Technique D firings

| Turn | Specific | Classification | Outcome |
|------|----------|---------------|---------|
| 2-5 | Express | CHOICE | Explored Fastify / Hono / NestJS. Selected Fastify (TS + schema validation). |
| 6-7 | Postgres | CONSTRAINT | Existing cluster, ops approval bar. Locked in. |
| 8-9 | AWS ECS | Mixed: AWS = constraint, ECS specifically = CHOICE | ECS-as-runtime deferred to Phase 3.5 research alongside App Runner / Fargate / Lambda. |
| 14-15 | AWS (platform) | CONSTRAINT | Postgres in AWS VPC, ops vetoes external exposure. |
| 16-17 | Cognito | CONSTRAINT | Existing user pool, mobile app reuses. |

### Technique B firings

| Turn | Trigger | Frames offered | Outcome |
|------|---------|----------------|---------|
| 10-11 | Initial framing stabilizing after three specifics challenged | (1) Self-built Fastify container; (2) PostgREST/Supabase auto-generated REST; (3) Reductive: don't add a new service — fold into existing app or expose DB view through existing gateway | Frame 1 selected. Frame 2 rejected (want code-level control over auth and shaping). Frame 3 rejected (mobile + partner is real external surface). |

Reductive frame qualitatively differs from frames 1 and 2: frames 1 and 2 both deploy a new service; frame 3 deploys *no* new service. Not a "smaller version" of frame 1.

### Soft-signal proposal to move on

Triggered at turn 18 — running summary presented, operator approved moving to chunking at turn 19.

## Phase 2: CHUNK

**Entered:** Turn 20.
**Exited:** Turn 21 (operator approves single-chunk).

Applied chunking signals:
- Multiple subsystems: NO
- Mixed tech domains: NO
- >3-5 design decisions: borderline but tightly coupled
- Natural dependency boundaries: NO
- Operator signaled decomposition: NO

Verdict: single-chunk. Operator agreed.

## Phase 3: RED-TEAM

**Entered:** Turn 22 (mode-shift announced).
**Exited:** Turn 23 (operator addresses each finding).

| # | Severity | Topic | Operator response |
|---|----------|-------|-------------------|
| 1 | DISCUSS | VPC-reach must be a research filter | Accept |
| 2 | DISCUSS | API key lifecycle hand-waved | Accept |
| 3 | DISCUSS | Observability + deploy pipeline not explored | Accept |
| 4 | MINOR | API contract style (REST conventions, OpenAPI) | Defer (executor concern) |
| 5 | DISCUSS | Partner keys in app DB vs Secrets Manager | Defer (note for v2) |
| 6 | DISCUSS | Existence question — Supabase / PostgREST / Hasura need formal eval | Accept |

Findings 1, 2, 3, 6 fold into chunk modifications and Phase 3.5 search scope.

## Phase 3.5: RESEARCH (build-vs-buy)

**Entered:** Turn 24.
**Exited:** Turn 25 (operator approves classifications).

### Whole-problem search

Query: `managed REST API platform Postgres backend 2026 Supabase Render Railway Fly.io alternatives`

Candidates evaluated:

| Tool | Classification | Reason |
|------|---------------|--------|
| Supabase (cloud) | Reject | Requires Supabase-managed Postgres or self-hosting Supabase against existing cluster; auth would duplicate Cognito. Self-hosting in VPC is bigger ops lift than building Fastify service. |
| PostgREST | Inspire | Interface ideas (RLS-driven auth, schema-as-API) borrowed. Operator wants code-level control of request shaping. |
| Hasura CE | Reject | Primary surface is GraphQL; consumers (mobile, partner) want REST. Inverting the surface adds friction. |

### Per-chunk search (compute)

Query: `deploy Node Express container managed platform vs AWS ECS 2026 cost comparison` + filter "must reach Postgres in private AWS VPC."

| Candidate | Classification | Reason |
|-----------|---------------|--------|
| AWS App Runner | Adopt fully (recommended default) | Managed, scale-to-zero, VPC connector to private RDS, AWS-native. Best match for sub-50 RPS + low-idle + private VPC. |
| AWS ECS Fargate | Inspire / fallback | Original target. Viable if App Runner has feature gap; documented as fallback. |
| AWS Lambda + API Gateway | Adopt partially / alternative | Serverless, scale-to-zero by definition. Cold-start + Fastify-on-Lambda rough edges. Documented as alternative. |
| Render | Reject | Cannot reach private AWS VPC Postgres without exposing DB or VPN. Network-driven, specific. |
| Railway | Reject | Same — no native VPC peering to AWS RDS in private subnet. |
| Fly.io | Reject | Same — would require WireGuard / private-network bridging that ops vetoed. |

### Reverse sunk-cost check

Applied to the Render/Railway/Fly.io rejection. Operator's earlier answer (AWS = constraint because Postgres in private VPC) holds — rejection is constraint-driven, not "we want to build it ourselves" preference.

## Phase 4: ARTIFACT

Written to `docs/discovery/rest-api-fastify-postgres-aws.md` (path inside the discovery artifact; for this eval saved at the eval outputs directory as `discovery-artifact.md`). Per eval instructions, no commit and no dispatch.

**STOP — eval halts before Phase 5 (DISPATCH).**

## Self-assessment vs. eval assertions

| # | Assertion | Met? |
|---|-----------|------|
| 1 | Phase 1 executes with at least one Socratic clarifying question | YES |
| 2 | Technique D challenges Express | YES (turn 2) |
| 3 | Technique D challenges Postgres | YES (turn 6) |
| 4 | Technique D challenges AWS ECS | YES (turn 8) |
| 5 | At least 2 of 3 specifics challenged via D | YES — all 3 |
| 6 | Technique B fires at least once | YES (turn 10) |
| 7 | B presents exactly 3 framings (current / alt / reductive) | YES |
| 8 | Reductive frame qualitatively different | YES — "no new service at all" vs "deploy a new service" |
| 9 | Phase 3.5 executes with at least one WebSearch invocation | YES (2 calls) |
| 10 | Phase 3.5 surfaces at least one managed/serverless alternative (Supabase, Render, Railway, Fly.io, Neon, Vercel, PlanetScale) | YES — Supabase, Render, Railway, Fly.io all surfaced |
| 11 | At least one alternative evaluated against constraints | YES — all evaluated for VPC-reach, cost, lock-in |
| 12 | Each candidate gets classification with specific reason — not vague | YES — every reject reason names the conflict |
