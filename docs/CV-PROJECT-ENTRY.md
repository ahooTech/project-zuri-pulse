# 📄 CV-PROJECT-ENTRY.md

> **Your CV should be a receipt of problems solved, not a list of tools watched.** Everything below is 100% truthful to what you actually built and debugged in this project, phrased the way a hiring manager reads impact. Paste it under a **Projects / Hands-On Portfolio** section (not under employment), and let the upcoming phases (Kubernetes, CI/CD, Terraform, multi-cloud) add more bullets later.

---

## 📄 CV-READY PROJECT ENTRY (Paste This)

**ZuriShop — Containerized Multi-Service Retail Platform** | *DevOps Portfolio Project* | 2026
*Stack: Docker, Docker Compose, Python (FastAPI), PostgreSQL, Redis, Elasticsearch, Prometheus, Grafana, NGINX, PowerShell, REST/JSON, Linux*

- Designed, containerized, and operated a 14-container retail platform: 7 Python/FastAPI microservices, NGINX storefront, PostgreSQL, Redis, Elasticsearch, Prometheus, Grafana, and postgres-exporter.
- Hardened container security and reduced image footprint using **multi-stage Docker builds**, completely stripping `pip` and build tooling from the final runtime image to minimize the CVE attack surface.
- Enforced **12-factor application principles** by externalizing all database credentials into gitignored `.env` files with Compose interpolation, ensuring zero secrets in version control and a seamless migration path to Kubernetes Secrets.
- Replaced fragile in-memory state with PostgreSQL as the source of truth: 3-schema data model (catalog / inventory / orders), migration-style bootstrap (`init.sql`), threaded connection pooling, and **atomic inventory reservation** (`UPDATE … RETURNING` + `CHECK` constraints) that eliminates oversell race conditions at the database layer.
- Engineered automated **cache eviction** by implementing Time-To-Live (TTL) expirations on Redis session keys, preventing memory leaks and Out-Of-Memory (OOM) crashes from abandoned shopping carts.
- Built full-stack observability: Prometheus scraping 8 targets (including database metrics via postgres_exporter), custom Grafana dashboards (request rate, error-budget burn, DB health), and structured JSON logging across every service.
- Executed chaos-engineering and incident-response drills: injected payment-gateway outages, triaged DNS/connection failures through structured logs, and implemented **graceful degradation** (clean HTTP 503 instead of raw 500 stack traces) with visual error-rate recovery proof in Grafana.
- Diagnosed and resolved a multi-layer Redis persistence bug — "ghost" keys surviving restarts due to default RDB snapshots, container writable layers, and an image-declared anonymous volume — then enforced true ephemeral cache behavior (`--save "" --appendonly no`, `--renew-anon-volumes`).
- Proved stateful resilience through crash testing: PostgreSQL orders survived infrastructure restarts via persistent volumes while Redis correctly lost transient carts; documented stale connection-pool behavior and its Kubernetes liveness-probe remedy.
- Automated platform verification with a 15-check PowerShell smoke-test suite (service health, DB connectivity, search indexing, end-to-end checkout) designed as a CI-ready deployment gate; fixed cross-platform pitfalls including UTF-8 payload encoding and swallowed exceptions.
- Resolved Elasticsearch 8.x client incompatibilities (connection/SSL defaults, deprecated query syntax, missing-index crashes) and made the search API degrade gracefully to empty results instead of 500 errors.
- Fixed a browser CORS failure between the storefront and APIs, and designed the production-grade remedy: single-origin routing through an Ingress controller.
- Integrated a legacy PowerShell reporting workload with modern REST APIs to produce enterprise CSV reconciliation reports, demonstrating hybrid/legacy operations.
- Authored a 7-workflow end-to-end operations runbook (golden-path transaction, search lifecycle, load generation, chaos drill, stateful resilience, automated health gate) used for operational validation and stakeholder demos.

---

## 🧾 THE "PROBLEMS WE SOLVED" LEDGER (Your Interview Defense)

Every CV line above maps to a real bug you hit. Keep this list in your head (or notes) so you can defend any bullet with a story:

**1. Elasticsearch indexing returned 500.**
*Real problem:* `/search/index` failed with a 500 because of ES 8.x connection/SSL defaults.
*What you did:* Pinned the client to `==8.13.0`, fixed client initialization, and disabled enrollment/SSL.
*Defends CV bullet:* The Elasticsearch resilience bullet.

**2. Storefront search failed with `TypeError: Failed to fetch`.**
*Real problem:* The browser blocked cross-origin calls from the storefront to the search API.
*What you did:* Root-caused it as a CORS failure, added CORS middleware, and designed the production remedy (single-origin Ingress routing).
*Defends CV bullet:* The CORS bullet.

**3. Application logs were drowned by monitoring noise.**
*Real problem:* Constant `/metrics` and `/healthz` scrapes flooded the logs, hiding real business events.
*What you did:* Implemented structured JSON logging and time-window filtering (`--since` + pattern matching) to cut through the noise.
*Defends CV bullet:* The observability bullet.

**4. State was lost on every restart; there was no source of truth.**
*Real problem:* Services held data in memory, so every restart wiped products, stock, and orders.
*What you did:* Introduced PostgreSQL with a 3-schema model, `init.sql` migration bootstrap, connection pooling, and health-gated startup ordering.
*Defends CV bullet:* The PostgreSQL bullet.

**5. Oversell race condition risk in inventory.**
*Real problem:* Read-modify-write reservation logic could allow two checkouts to sell the same stock.
*What you did:* Replaced it with an atomic `UPDATE … RETURNING` guarded by `CHECK (remaining >= 0)` so the database itself prevents overselling.
*Defends CV bullet:* The PostgreSQL bullet.

**6. Killing the payment service produced ugly raw 500 errors.**
*Real problem:* An unhandled `httpx.ConnectError` (DNS removal on container stop) bubbled up as a 500 stack trace.
*What you did:* Caught `httpx.RequestError` and returned a clean HTTP 503, then proved detect → triage → recover with a chaos drill and a Grafana error-burn chart.
*Defends CV bullet:* The chaos-engineering bullet.

**7. A single error was invisible on the dashboards.**
*Real problem:* One failed request renders as ~0.017 req/s on a rate chart — flat and unreadable.
*What you did:* Generated a 60-request failure burst and switched to `increase()[1m]` on a 15-minute window to make the error spike interview-visible.
*Defends CV bullet:* The observability bullet.

**8. Redis "ghost" keys survived restarts.**
*Real problem:* 60 carts came back after restarts due to default RDB snapshots, container writable layers, and an image-declared anonymous volume that Compose reuses on recreate.
*What you did:* Traced all three layers, disabled persistence (`--save "" --appendonly no`), and renewed the anonymous volume (`--renew-anon-volumes`).
*Defends CV bullet:* The Redis persistence bullet.

**9. First request after a Postgres restart returned 500.**
*Real problem:* Application connection pools held dead TCP sockets after the database rebooted.
*What you did:* Identified the stale-pool behavior, documented it, and prescribed Kubernetes liveness probes / pod restarts as the production remedy.
*Defends CV bullet:* The stateful resilience bullet.

**10. The smoke test failed with 422s and silent failures.**
*Real problem:* PowerShell's `Invoke-RestMethod` sent JSON with the wrong encoding, and `catch` blocks swallowed the real errors.
*What you did:* Forced UTF-8 byte-array payloads, added `.Trim()` for hidden carriage returns, surfaced exception messages — 15/15 checks passed.
*Defends CV bullet:* The automation bullet.

**11. Finance needed legacy CSV reconciliation reports.**
*Real problem:* The business still depends on PowerShell-driven on-prem reporting while the platform is modern REST.
*What you did:* Wrote a PowerShell bridge script that pulls live data from the microservices and emits the enterprise CSV format.
*Defends CV bullet:* The legacy integration bullet.

**12. Database passwords were hardcoded in the Compose file and Python code.**
*Real problem:* Hardcoded secrets fail security scans and would be leaked if pushed to Git.
*What you did:* Enforced 12-factor app principles, moved credentials to a gitignored `.env` file, updated Compose to use `${VAR}` interpolation, and made Python fail fast if `DATABASE_URL` is missing.
*Defends CV bullet:* The Secrets Management bullet.

**13. Abandoned shopping carts caused Redis memory bloat.**
*Real problem:* If a user added items but never checked out, the cart stayed in Redis forever, eventually causing an Out-Of-Memory (OOM) crash.
*What you did:* Implemented `redis_client.expire(key, 3600)` to attach a 1-hour Time-To-Live (TTL) to every cart write, ensuring self-cleaning cache eviction.
*Defends CV bullet:* The Cache Eviction bullet.

**14. Docker images were bloated and contained `pip` and build tools.**
*Real problem:* The default `python:3.12-slim` image includes `pip`, increasing the image size and the CVE attack surface.
*What you did:* Upgraded to multi-stage Dockerfiles (`builder` and `runtime` stages), copying only the compiled dependencies and explicitly running `python -m pip uninstall pip -y` in the final stage.
*Defends CV bullet:* The Container Hardening bullet.

---

## ⚠️ HONESTY RULE (Protects You in the Interview)

- **Do NOT claim yet:** AWS/Azure/GCP, Kubernetes, Terraform, CloudFormation, Pulumi, GitHub Actions/Jenkins/GitLab CI. You haven't built them *yet*.
- **Do claim now:** Docker, microservices, PostgreSQL, Redis, Elasticsearch, Prometheus, Grafana, Python, PowerShell, incident response, troubleshooting, documentation, container security, secrets management.
- As you finish Phase 4 (CI/CD), Phase 5 (Kubernetes), and Phases 2–3 (IaC), **add one bullet per phase** using the same "problem → action → measurable result" formula. By Week 10 your CV will cover the entire Pavago JD with evidence.

---

## 🎯 ONE-LINE PROFESSIONAL SUMMARY (Top of CV)

> *DevOps engineer with hands-on experience building and operating secure, containerized microservices platforms. Proven troubleshooting mindset demonstrated through chaos engineering, incident response, database reliability engineering, container hardening, and automated platform verification with Docker, PostgreSQL, Redis, Elasticsearch, Prometheus, Grafana, Python, and PowerShell.*

---

Save this file as `docs/CV-PROJECT-ENTRY.md` in your repo.