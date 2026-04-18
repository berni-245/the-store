# Pre-Delivery Brief — CI/CD for The Store

## What is this document?

A structured briefing of all relevant facts and constraints needed before drafting the Pre-Delivery architecture proposal. All design decisions are locked here.

---

## The Assignment in One Sentence

Design and implement a CI/CD pipeline that builds and deploys the services of "The Store" (a polyglot microservices e-commerce app) to a Kubernetes cluster, then document the design in a 4-page PDF before touching any code.

---

## What the Pre-Delivery PDF Must Include (Hard Requirements)

| Section | Notes |
|---|---|
| Problem Statement & Context | Why CI/CD matters for this specific app |
| Solution Design | Chosen tool(s), pipeline stages, triggers |
| POC Scope & Use Cases | Which services/flows will be demonstrated |
| Architecture Diagram | Must show CIDR blocks, IP networks, OS, protocols, infra details |
| Alternative Solutions Considered | Document what was rejected and why |

**Max length: 4 pages PDF.**

**Critical: the final implementation must match this document exactly.** Any gap = retake.

---

## Application Facts (from `architecture.md`)

### Services & Their Tech Stacks

| Service | Language / Framework | Dockerfile? |
|---|---|---|
| UI | Java 21 / Spring Boot | Yes |
| Catalog | Go / Gin | Yes |
| Cart | Java 21 / Spring Boot | Yes |
| Checkout | Node.js / NestJS | Yes |
| Orders | Java 21 / Spring Boot | Yes |

Each service has its own Dockerfile — images are built independently.

### Existing Deployment Artifacts

- `dist/kubernetes.yaml` — pre-rendered Kubernetes manifests for all services (generated from Helm charts).
- `local.sh` — spins up a Kind cluster with Helm.
- Helm charts already exist per service.
- Health checks on every service (Spring Actuator / NestJS Terminus).
- E2E tests: Cypress (`src/e2e/`), Load tests: Artillery (`src/load-generator/`).

---

## All Decisions — Locked

### Team & Cost

| Decision | Value |
|---|---|
| Team size | 3 people |
| Cloud cost target | $0 — fully local or free-tier only; self-hosted runners consume zero GitHub Actions minutes |

### Infrastructure

| Decision | Value | Notes |
|---|---|---|
| Kubernetes | Kind (local) | One cluster per team member's machine |
| Default Kind pod CIDR | `10.244.0.0/16` | Used in diagram |
| Default Kind service CIDR | `10.96.0.0/12` | Used in diagram |
| Databases | In-memory fallbacks | Not relevant to demonstrating CI/CD |
| Runner type | Self-hosted GitHub Actions runner | Runs on each team member's machine; needed to reach local Kind API |
| Runner OS | Host machine OS (Windows/Mac/Linux) | Goes in the diagram — must match each team member's actual OS |
| Runner labels | Unique per machine (e.g. `self-hosted, machine-alice`) | Prevents GitHub from round-robining jobs to the wrong machine |

### CI/CD Tools & Responsibilities

| Tool | Responsibility |
|---|---|
| **GitHub Actions** | Full CI/CD — triggered on push to `main`; builds Docker image, runs tests, pushes to GHCR, deploys to Kind via Helm |
| **Helm** | Used by GitHub Actions to deploy each service into Kind |

### Pipeline Design

| Decision | Value |
|---|---|
| Trigger | Push to `main` branch |
| Pipeline structure | One pipeline per service (5 total) — each has its own `.github/workflows/<service>.yml` with a `paths:` filter scoped to `src/<service>/**` |
| Image registry | GHCR (`ghcr.io`) — free, integrates natively with GitHub Actions auth; images set to **public** so Kind nodes can pull without image pull secrets |
| Scope | All 5 services |
| Testing in pipeline | Unit/build-time tests that each service already has; no E2E or load tests in the pipeline |
| Demo trigger | Small code change pushed to `main` — full pipeline run shown live |

### Helm Usage

| Decision | Value |
|---|---|
| Which charts | Reuse existing per-service Helm charts (already present in the repo) |
| Who calls Helm | GitHub Actions (in the CD stage) |

---

## Architecture Flow (Narrative — for diagram reference)

```
Developer pushes to main
        │
        ▼
  GitHub Actions — self-hosted runner on developer's machine
  (runs-on: [self-hosted, machine-<name>])
  ┌─────────────────────────────────────────┐
  │ 1. Checkout source                      │
  │ 2. Build Docker image (per service)     │
  │ 3. Run service unit tests               │
  │ 4. Push image to GHCR (HTTPS)           │
  │ 5. Run helm upgrade --install           │
  │    targeting local Kind cluster         │
  │ 6. Verify pod health (kubectl rollout)  │
  └─────────────────────────────────────────┘
        │
        ▼
  Kind cluster (same machine as the runner)
  ┌─────────────────────────────────────────┐
  │  5 service pods (UI, Catalog, Cart,     │
  │  Checkout, Orders) — in-memory mode     │
  │  Pod network:     10.244.0.0/16         │
  │  Service network: 10.96.0.0/12          │
  └─────────────────────────────────────────┘
```

> Each team member runs this full stack independently on their own machine. The self-hosted runner uses a unique label per machine so GitHub never routes a job to the wrong environment.

---

## Minimum Diagram Elements (for the PDF)

The architecture diagram must explicitly label:

- **Developer workstation** — host OS (each team member's machine); runs the self-hosted runner and Kind
- **GitHub repository** — source of truth, triggers the workflow on push to `main`
- **GitHub Actions self-hosted runner** — same machine as the developer; OS matches the host; labeled uniquely per machine
- **GHCR** — `ghcr.io`, protocol HTTPS (push from runner, pull by Kind)
- **Kind cluster** — pod CIDR `10.244.0.0/16`, service CIDR `10.96.0.0/12`
- **5 service pods** — labeled with service name
- **Protocols on every arrow** — HTTPS (push/pull to GHCR), HTTPS (GitHub→runner webhook), kubectl API (runner→Kind)

---

## What Goes in "Alternative Solutions Considered"

Three alternatives to document and reject in the PDF:

| Alternative | Why rejected |
|---|---|
| AWS CodePipeline | Incurs real AWS costs (ECR, CodeBuild charges); violates $0 constraint |
| Jenkins + GitHub Actions (split CI/CD) | More moving parts, more configuration overhead; GitHub Actions alone handles both CI and CD with less complexity |
| Monolithic single pipeline for all services | Less realistic; a change to one service would rebuild all five; per-service is standard practice |

---

## Risk Register

| Risk | Mitigation |
|---|---|
| Implementation drifts from pre-delivery design | Freeze design before coding; any scope change requires updating the PDF draft first |
| Self-hosted runner can't reach Kind API | Runner runs on the same machine as Kind — direct `localhost` access to the cluster API server |
| Kind CIDR conflicts with host network | Document the CIDRs explicitly; Kind allows override in its config if needed |
| Demo failure during oral presentation | Practice full pipeline run (git push → running pod) at least twice before the presentation |
| Team member machine OS differences affect runner setup | Self-hosted runner install differs per OS — document setup steps for Windows, Mac, and Linux in the how-to guide |
| Runner label misconfiguration routes job to wrong machine | Each workflow file must specify the unique machine label (`runs-on: [self-hosted, machine-<name>]`) — verify this before the demo |
| One team member's machine is off during a push | Job hangs until the runner comes online — acceptable for independent dev environments; not a shared environment |
