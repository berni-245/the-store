# Pre-Delivery Brief — CI/CD for The Store

## What is this document?

A structured briefing of all relevant facts, constraints, and open questions I need to resolve **before** drafting the Pre-Delivery architecture proposal. No solution decisions are made here.

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
| Alternative Solutions Considered | At least document what was rejected and why |

**Max length: 4 pages PDF.**

**Critical: the final implementation must match this document exactly.** Any gap = retake.

---

## Application Facts (from `architecture.md`)

### Services & Their Tech Stacks

| Service | Language / Framework | Port | Dockerfile? |
|---|---|---|---|
| UI | Java 21 / Spring Boot | 8080 | Yes |
| Catalog | Go / Gin | — | Yes |
| Cart | Java 21 / Spring Boot | — | Yes |
| Checkout | Node.js / NestJS | — | Yes |
| Orders | Java 21 / Spring Boot | — | Yes |

Each service has its **own Dockerfile** — images can be built independently.

### Data Stores (used in prod-mode, not needed for in-memory mode)

- MySQL (Catalog), DynamoDB (Cart), Redis (Checkout), PostgreSQL (Orders)
- **In-memory fallbacks exist** — useful for a lightweight POC that avoids spinning up full databases.

### Existing Deployment Artifacts

- `dist/kubernetes.yaml` — pre-rendered Kubernetes manifests for all services (generated from Helm charts).
- `local.sh` — spins up a Kind (local Kubernetes) cluster with Helm.
- Helm charts already exist per service (evident from `helm.sh/chart` labels in the manifest).
- E2E tests: Cypress (`src/e2e/`)
- Load tests: Artillery (`src/load-generator/`)
- Health checks on every service (Spring Actuator / NestJS Terminus)

---

## Allowed CI/CD Technologies

- Jenkins
- AWS CodePipeline
- GitHub Actions (or similar — GitLab CI, etc.)
- Helm

Only one (or a combination) of these needs to be chosen. The choice must be justified in the Pre-Delivery doc.

---

## Constraints & Hard Rules

1. **Cost avoidance is strongly recommended** — cloud services that charge money are allowed but the team bears the cost; graders will not accept "too expensive" as an excuse for incompleteness.
2. **Free-tier / local alternatives preferred** — Kind, Minikube, self-hosted Jenkins, GitHub Actions free tier, etc.
3. **Reproducibility** — the solution must be runnable by someone else following the how-to guide.
4. **No partial implementation** — if a pipeline stage is in the diagram, it must work in the demo.

---

## Decided

| Decision | Value | Reason |
|---|---|---|
| Team size | 3 people | — |
| Kubernetes flavor | Kind (local) | Free, no cloud cost |
| CI/CD tool(s) | Jenkins (local) + optionally GitHub Actions | Jenkins is free when self-hosted; multiple tools allowed |
| Cloud cost target | $0 | Strongly preferred |

---

## Open Questions to Answer Before Writing the Pre-Delivery

### Infrastructure

- [ ] Which team member's machine hosts Kind + Jenkins? One machine or all three?
- [ ] Will we use in-memory DB fallbacks or spin up real databases inside Kind? (Affects diagram complexity and CIDR blocks.)
- [ ] What OS runs Jenkins? (Ubuntu on WSL2, native Linux, Docker container?) — needed for the diagram.

### CI/CD Tool Split (if using both Jenkins + GitHub Actions)

- [ ] What does each tool own? e.g. GitHub Actions = CI (build + test + push image), Jenkins = CD (deploy to Kind via Helm)?
- [ ] Or: Jenkins handles everything end-to-end — GitHub Actions only used as a webhook trigger?
- [ ] Single pipeline for all 5 services, or one pipeline per service (one Jenkinsfile per repo/folder)?

### Pipeline Stages to Design

- [ ] Trigger: push to `main`? Pull request? Tag-based release?
- [ ] Stages needed (minimum viable): source → build Docker image → push to registry → deploy to K8s via Helm/kubectl
- [ ] Do we include automated testing stages (unit, E2E, load)? Which ones are realistic for a demo?
- [ ] Image registry: Docker Hub (free, public), GitHub Container Registry (GHCR, free), or local registry inside Kind?

### Scope of POC

- [ ] Deploy all 5 services or a meaningful subset (e.g., UI + Catalog + Cart)?
- [ ] Will the live demo show a full pipeline run from a git push to a running app?
- [ ] What "change" will trigger the demo pipeline? (A small code edit is simplest.)

### Helm Usage

- [ ] Use the existing Helm charts (already present per-service) or write new ones?
- [ ] Will Helm be called from inside the CI pipeline or separately?

---

## Minimum Viable Diagram Elements (for the PDF)

The diagram must include at minimum:
- Developer workstation / GitHub repo (source)
- CI/CD runner (OS, IP if applicable)
- Container registry (with protocol: HTTPS)
- Kubernetes cluster node(s) (OS, CIDR blocks for pods and services)
- The 5 (or scoped) microservice pods
- Protocols on each arrow (HTTPS, HTTP, kubectl API, etc.)

---

## My Sub-Assignment (What to Decide Next)

Before writing the Pre-Delivery PDF, answer these in order:

1. **Choose the infra**: Kind (local) or a free cloud tier? → determines CIDR blocks and OS.
2. **Choose the CI/CD tool**: GitHub Actions is the lowest-friction free option — confirm or reject.
3. **Choose the registry**: GHCR is free and integrates natively with GitHub Actions — confirm or reject.
4. **Define the pipeline stages** and which services are in scope for the demo.
5. **Sketch the architecture diagram** (even on paper) before writing prose.
6. **Document two alternative solutions** and why they were not chosen (needed in the PDF).

---

## Risk Register

| Risk | Mitigation |
|---|---|
| Cloud costs spiral (DynamoDB, SQS) | Use in-memory fallbacks; avoid AWS services that charge per request |
| Implementation drifts from the pre-delivery design | Freeze the design before coding; any change requires updating the PDF first |
| Kind cluster networking is hard to document | Research Kind default CIDRs (`10.96.0.0/12` services, `10.244.0.0/16` pods) upfront |
| Free-tier runner timeout (GitHub Actions 6h limit) | Pipeline should complete in minutes; not a real risk for 5 small services |
| Demo failure during oral presentation | Practice the full pipeline run at least twice before the presentation |
