# How-To Guide — CI/CD for The Store

This guide explains how to set up the system, run the CI/CD pipeline, and how
deployments are performed. It implements the design described in
[`docs/specs/solution.md`](./specs/solution.md).

The pipeline automates the loop **build → test → push → deploy** for five
independent microservices (catalog, cart, checkout, orders, ui), each with its
own Helm chart and its own CI/CD workflows.

---

## 1. Architecture at a glance

```
Developer ──PR──▶ GitHub (main protected)
                     │  CI workflow (per service, path-filtered)
                     ▼
              Self-hosted runner ──build + test──▶ (PR check; nothing published)
                     ▲ polls over HTTPS
   merge to main ────┘
                     │  CD workflow (per service, path-filtered)
                     ▼
              Self-hosted runner
                 ├─ docker build  the-store-<svc>:<commit-sha>
                 ├─ docker push   ghcr.io/<owner>/the-store-<svc>:<commit-sha>
                 ├─ helm upgrade --install <svc> charts/<svc> --set image.tag=<sha>
                 ├─ kubectl rollout status   (health gate)
                 └─ helm rollback <svc>      (only if the rollout fails)
                     │
                     ▼
              Local Kind cluster (127.0.0.1) ── pulls public image from GHCR
```

The runner lives on the team machine, next to the Kind cluster, so it can reach
the cluster's API server on `127.0.0.1` without exposing anything to the
internet. It connects out to GitHub by polling — GitHub never connects in.

---

## 2. Prerequisites

On the machine that hosts the cluster **and** the runner:

| Tool | Why |
|------|-----|
| [Docker](https://docs.docker.com/get-docker/) (running) | Builds images; runs Kind nodes; runs checkout's Testcontainers Redis |
| [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) | Local Kubernetes cluster |
| [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) | Talks to the cluster |
| [Helm](https://helm.sh/docs/intro/install/) | Deploys the per-service charts |

`local.sh` checks for all four before doing anything.

---

## 3. Set up the system (local cluster)

```bash
# Create the Kind cluster, install ingress, build + load images,
# and deploy all 5 charts with Helm.
./local.sh create-cluster

# The Store is then available at:
#   http://localhost
```

Other useful commands:

```bash
./local.sh status          # show cluster + service status
./local.sh rebuild-cluster # delete and recreate from scratch
./local.sh delete-cluster  # tear down
./local.sh e2e-test        # run Cypress e2e tests against the running cluster
```

Locally, the charts deploy the images built on your machine
(`the-store-<svc>:latest`, loaded into Kind). In CD the same charts deploy
SHA-tagged images pulled from GHCR — same charts, same `helm upgrade` command.

---

## 4. Set up the self-hosted runner

The CI and CD workflows declare `runs-on: self-hosted`, so they only run on a
runner you register against the repository.

1. In GitHub: **Settings → Actions → Runners → New self-hosted runner**. Pick
   your OS and **copy the commands shown on that page verbatim** — GitHub fills
   in the registration token for you, e.g.:
   ```bash
   ./config.sh --url https://github.com/<owner>/the-store --token <TOKEN>
   ./run.sh            # starts polling GitHub for jobs
   ```
   `<TOKEN>` is **not** a Personal Access Token you generate — it's the
   short-lived **runner registration token** that page displays (valid ~1 hour,
   single-use, only for registering). If it expires, reload the page to get a
   fresh one. (Not to be confused with `GITHUB_TOKEN`, which the workflows use to
   push to GHCR — see §5.)

2. **Run the agent as a user that can:**
    - **Reach the Kind cluster** — a valid `~/.kube/config` with the `kind-the-store`
      context (created by `./local.sh create-cluster`).
    - **Use Docker** — be in the `docker` group / have access to the Docker socket.
      This is required both for building images and for the **Testcontainers**
      tests that several services run during CI: they launch throwaway containers
      (catalog → MySQL, cart → DynamoDB-local, orders → Postgres, checkout →
      Redis). Nothing is declared in the workflows — each test starts and stops
      its container itself; it only needs a reachable Docker daemon.
    - **Pull the test images** (`mysql:8.0`, `postgres`, `redis:6.0-alpine`, …) on
      the first run of each service's CI (cached afterward).

3. Confirm `helm`, `kubectl`, and `docker` are on the runner user's `PATH`.

> ⚠️ **The Docker daemon must already be running when the runner executes a job.**
> The Testcontainers tests connect to the daemon directly (on Windows via the
> `\\.\pipe\docker_engine` named pipe; on Linux via `/var/run/docker.sock`). If
> the daemon isn't up, those tests fail with **"Could not find a valid Docker
> environment"** while the non-Docker tests still pass — making it look like a
> code failure when it's really an environment one.
> - **Windows/Docker Desktop:** Docker Desktop is a per-user app, so it must be
    >   running in the **same session** as the runner. Enable *Settings → "Start
    >   Docker Desktop when you log in"* and start the runner only after Docker is up.
    >   (A runner installed as a *service* under a different account will not see
    >   Docker Desktop's pipe.)
> - **Linux:** `dockerd` runs as a system service and the socket is always
    >   present, so this is a non-issue — the more robust host for a
    >   Testcontainers-heavy CI plus a local Kind cluster.
    > Quick check on the runner host: `docker version` should print a **Server**
    > section (not just the client).

---

## 5. Configure GitHub: branch protection + GHCR

### Branch protection (enables Caso 2 / Caso 3)
**Settings → Rules → Rulesets → New ruleset → New branch ruleset**:

| Field | What to set |
|-------|-------------|
| **Ruleset Name** | anything, e.g. `protect-main` |
| **Enforcement status** | **Active** (otherwise the rule does nothing) |
| **Target branches** | Add target → **Include default branch** (or pattern `main`) |
| ✅ **Require a pull request before merging** | Set **Required approvals** = `1` (or N) |
| ✅ **Require status checks to pass** | **Add checks** → add the per-service CI checks, e.g. `Build & test catalog` |

⚠️ A status check name only appears in the **Add checks** list *after it has run
at least once* — open one PR first to let CI run, then come back and add it. A
failed CI check then disables the merge button. Leave the other rules (signed
commits, linear history, …) off for this POC.

### GHCR packages must be public (so Kind can pull without a secret)
The **first** CD run creates each package as **private**. For Kind to pull the
image without an `imagePullSecret`, make it public once:

**GitHub → your profile/org → Packages → `the-store-<svc>` → Package settings →
Change visibility → Public.**

No registry secret is needed: the workflows authenticate to GHCR with the
auto-provisioned `GITHUB_TOKEN` (granted push via `permissions: packages: write`).

---

## 6. How the pipeline runs

### CI — on every Pull Request to `main`
File: `.github/workflows/ci-<svc>.yml`. Triggered only when the PR touches that
service (path filter on `src/<svc>/**` and `charts/<svc>/**`). Steps:
1. Checkout.
2. Set up the toolchain (Go / JDK 21 / Node 20).
3. Run the service's tests:
    - catalog → `go test ./...`
    - cart / orders / ui → `./mvnw test`
    - checkout → `yarn test:integration` (Testcontainers Redis + chaos tests)
4. `docker build` the image (tagged `:ci`, **not pushed**).

A failure turns the PR check red and — with branch protection — blocks merging.

### CD — on merge (push) to `main`
File: `.github/workflows/cd-<svc>.yml`. Same per-service path filter. Steps:
1. Checkout.
2. Resolve the lowercase GHCR repo `ghcr.io/<owner>/the-store-<svc>`.
3. `docker login ghcr.io` with `GITHUB_TOKEN`.
4. `docker build -t <repo>:<commit-sha> src/<svc>`.
5. `docker push <repo>:<commit-sha>`.
6. `helm upgrade --install <svc> charts/<svc> --set image.repository=<repo> --set image.tag=<commit-sha>`.
7. `kubectl rollout status deployment/<svc>` — the health gate.
8. On failure only: `helm rollback <svc>` and fail the job.

The **commit SHA is the single source of truth** for the version: it names the
image, the pushed tag, and the deployed tag — so the running pod is always
traceable to an exact commit.

---

## 7. Demonstrating the four use cases

| Case | How to demo |
|------|-------------|
| **Caso 1 — PR opened** | Open a PR editing only `src/catalog/**`. Only `CI - catalog` runs; it builds + tests and reports a check. Nothing is pushed to GHCR. |
| **Caso 2 — PR with errors** | Break a test (e.g. edit a catalog test to fail). The CI check goes red and the merge button is disabled by branch protection. Fix and push → CI re-runs and passes. |
| **Caso 3 — successful merge** | Merge the PR. `CD - catalog` runs: image `ghcr.io/<owner>/the-store-catalog:<sha>` appears in GHCR; `helm upgrade` succeeds; `kubectl rollout status` is green. Verify: `kubectl get pod -n the-store -o jsonpath='{..image}'` shows the SHA tag. |
| **Caso 4 — failed deploy + rollback** | Merge a change that produces a broken image (e.g. a bad start command or a chart pointing at a non-existent tag). `kubectl rollout status` times out, `helm rollback` fires, and the service stays on the previous release. Verify with `helm history <svc> -n the-store`. |

Useful verification commands:
```bash
kubectl get pods -n the-store
helm list -n the-store
helm history catalog -n the-store
kubectl rollout status deployment/catalog -n the-store
```

---

## 8. Known limitations

- **checkout test depth**: checkout's only meaningful suite is the
  Testcontainers-backed `test:integration` (there are no `*.spec.ts` unit
  tests). It is run in CI, but coverage reporting (`test:cov`) is not wired up
  because it targets unit specs that don't exist.
- **Single runner / single cluster**: CI and CD share one self-hosted runner and
  one local Kind cluster, as designed for the POC. Concurrent merges to
  different services are serialized by the runner's job queue.

---

## 9. Windows self-hosted runner: gotchas & troubleshooting

These are the issues we actually hit running the runner on Windows + Docker
Desktop. On a Linux runner most of them simply don't occur (`dockerd` is a
system service, LF is native), so Linux is the smoother host if you have the
choice.

- **`./mvnw` fails in `docker build` with `cannot execute: required file not
  found` (exit 127).** The Maven wrapper was checked out with CRLF line endings;
  copied into the Linux image its `#!/bin/sh` shebang becomes `#!/bin/sh\r`,
  which doesn't exist. The committed `.gitattributes` pins `mvnw`/`*.sh` to LF on
  every checkout, which fixes this. **Gotcha:** the self-hosted runner reuses its
  working directory, so a `mvnw` materialized as CRLF *before* `.gitattributes`
  existed can linger (git won't rewrite a file whose blob is unchanged). Fix it
  once on the runner: delete those files and re-check them out
  (`git -C <workdir> checkout -- src/*/mvnw`), or wipe the runner's repo
  directory; optionally `git config core.autocrlf false` in that checkout.

- **`yarn: command not found` in checkout CI.** `setup-node` provides Node + npm
  but not yarn. The workflow runs `corepack enable` (Corepack ships *with* Node)
  to expose the yarn shim — nothing is installed on the host.

- **Dependency downloads time out on a slow/flaky connection.** checkout uses
  `yarn install --frozen-lockfile --network-timeout 600000`; the Maven services
  pass `-Dmaven.wagon.http.retryHandler.count=3 -Dmaven.wagon.rto=600000` via the
  **`MAVEN_OPTS` env var, not the command line** — PowerShell splits those `-D`
  args into bogus lifecycle phases (`Unknown lifecycle phase ".wagon..."`).

- **A Windows Firewall prompt appears on the first Testcontainers run.** When a
  test container first publishes a port, Windows Defender Firewall asks to allow
  it. If it isn't allowed promptly, the test's `beforeAll` stalls and Jest's 30s
  hook timeout fires. Allow it once (the choice persists).

- **Testcontainers startup occasionally exceeds Jest's 30s hook timeout.** If the
  Redis container is slow to start (cold image pull, Docker Desktop overhead),
  raise the limit by adding `"testTimeout": 120000` to
  `src/checkout/test/jest-e2e.json`.

- **A job seems not to run after opening/updating a PR.** The runner *polls*
  GitHub, so there's pickup latency, and a single runner serializes jobs — give
  it a moment rather than assuming it failed.
