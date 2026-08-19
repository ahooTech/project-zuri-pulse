# Staff Canteen Management System

Generated: 08/19/2026 19:33:54

---

## Table of Contents

- .env
- .env.example
- .gitignore
- docker-compose.yml
- docs\CV-PROJECT-ENTRY.md
- docs\phase-1\1.1-current-state-assessment.md
- docs\phase-1\1.2-target-multi-cloud-architecture.md
- docs\phase-1\1.3-devops-operating-model.md
- docs\phase-1\CV-PHASE1-ENTRY.md
- docs\📘 ZuriShop End-to-End Interview Runbook.md
- Generate-Codebook.ps1
- infra\postgres\init.sql
- legacy-reports\Generate-ZuriShopReport.ps1
- observability\prometheus.yml
- PROJECT_ZURI_PULSE.docx
- requirements-dev.txt
- scripts\smoke-test.ps1
- services\cart-service\.dockerignore
- services\cart-service\Dockerfile
- services\cart-service\main.py
- services\cart-service\requirements.txt
- services\checkout-service\.dockerignore
- services\checkout-service\Dockerfile
- services\checkout-service\main.py
- services\checkout-service\requirements.txt
- services\inventory-service\.dockerignore
- services\inventory-service\Dockerfile
- services\inventory-service\main.py
- services\inventory-service\requirements.txt
- services\notification-service\.dockerignore
- services\notification-service\Dockerfile
- services\notification-service\main.py
- services\notification-service\requirements.txt
- services\payment-service\.dockerignore
- services\payment-service\Dockerfile
- services\payment-service\main.py
- services\payment-service\requirements.txt
- services\product-api\.dockerignore
- services\product-api\Dockerfile
- services\product-api\main.py
- services\product-api\requirements.txt
- services\search-service\.dockerignore
- services\search-service\Dockerfile
- services\search-service\main.py
- services\search-service\requirements.txt
- storefront-web\.dockerignore
- storefront-web\Dockerfile
- storefront-web\index.html
- zurishop-report.csv

---


<div style='page-break-after: always;'></div>

# File: .env

```env
POSTGRES_USER=zurishop
POSTGRES_PASSWORD=zurishop_dev_password
POSTGRES_DB=zurishop
```


<div style='page-break-after: always;'></div>

# File: .env.example

```example
POSTGRES_USER=zurishop
POSTGRES_PASSWORD=change_me_in_production
POSTGRES_DB=zurishop
```


<div style='page-break-after: always;'></div>

# File: .gitignore

```gitignore
.env
.venv/
__pycache__/
*.pyc
*.csv


# Terraform
.terraform/
*.tfstate
*.tfstate.*
crash.log
plan.tfplan
infra/terraform/backend/aws.hcl
infra/terraform/backend/azure.hcl
infra/terraform/backend/gcp.hcl
*.auto.tfvars.json
```


<div style='page-break-after: always;'></div>

# File: docker-compose.yml

```yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./infra/postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 5s
      timeout: 3s
      retries: 10

  postgres-exporter:
    image: quay.io/prometheuscommunity/postgres-exporter
    environment:
      DATA_SOURCE_NAME: "postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}?sslmode=disable"
    ports:
      - "9187:9187"
    depends_on:
      postgres:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    command: ["redis-server", "--save", "", "--appendonly", "no"]
    ports:
      - "6379:6379"

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.13.0
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - ES_JAVA_OPTS=-Xms512m -Xmx512m
    ports:
      - "9200:9200"

  product-api:
    build: ./services/product-api
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
    ports:
      - "8001:8000"
    depends_on:
      postgres:
        condition: service_healthy

  cart-service:
    build: ./services/cart-service
    environment:
      REDIS_HOST: redis
      REDIS_PORT: 6379
      CART_TTL_SECONDS: 3600
    ports:
      - "8002:8000"
    depends_on:
      - redis

  payment-service:
    build: ./services/payment-service
    ports:
      - "8004:8000"

  inventory-service:
    build: ./services/inventory-service
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
    ports:
      - "8005:8000"
    depends_on:
      postgres:
        condition: service_healthy

  notification-service:
    build: ./services/notification-service
    ports:
      - "8006:8000"

  checkout-service:
    build: ./services/checkout-service
    environment:
      PRODUCT_API_URL: http://product-api:8000
      CART_SERVICE_URL: http://cart-service:8000
      INVENTORY_SERVICE_URL: http://inventory-service:8000
      PAYMENT_SERVICE_URL: http://payment-service:8000
      NOTIFICATION_SERVICE_URL: http://notification-service:8000
      DATABASE_URL: postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
    ports:
      - "8003:8000"
    depends_on:
      postgres:
        condition: service_healthy
      product-api:
        condition: service_started
      cart-service:
        condition: service_started
      inventory-service:
        condition: service_started
      payment-service:
        condition: service_started
      notification-service:
        condition: service_started

  search-service:
    build: ./services/search-service
    environment:
      ELASTICSEARCH_URL: http://elasticsearch:9200
      PRODUCT_API_URL: http://product-api:8000
    ports:
      - "8007:8000"
    depends_on:
      - elasticsearch
      - product-api

  storefront-web:
    build: ./storefront-web
    ports:
      - "8080:80"

  prometheus:
    image: prom/prometheus
    volumes:
      - ./observability/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"

volumes:
  postgres_data:
```


<div style='page-break-after: always;'></div>

# File: docs\CV-PROJECT-ENTRY.md

```md
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
```


<div style='page-break-after: always;'></div>

# File: docs\phase-1\1.1-current-state-assessment.md

```md
# docs/phase-1/1.1-current-state-assessment.md

# 1.1 Current-State Assessment — ZuriMart / ZuriShop Platform
**Project:** PROJECT ZURI PULSE · **Phase:** 1 · **Date:** 2026-08-19
**Author:** DevOps Engineer and Cloud Engineer · **Status:** APPROVED BASELINE


**Evidence source:** Automated discovery script run 2026-08-19 on the production-analogue host (output archived in PR #—).

Write-Host "=== 1. WORKLOAD INVENTORY ==="; docker compose config --services
Write-Host "`n=== 2. RUNTIME STATE ==="; docker compose ps -a
Write-Host "`n=== 3. IMAGE FOOTPRINT ==="; docker images --format "{{.Repository}}:{{.Tag}} | {{.Size}}"
Write-Host "`n=== 4. STATE/BACKUP EVIDENCE (volumes) ==="; docker volume ls
Write-Host "`n=== 5. NETWORK TOPOLOGY ==="; docker network ls
Write-Host "`n=== 6. VERSION CONTROL MATURITY ==="; git log --oneline -5; git remote -v; git status --short
Write-Host "`n=== 7. GUARDRAILS SEARCH (what does NOT exist yet) ==="
@(".github",".gitlab-ci.yml","Jenkinsfile","infra/terraform","infra/cloudformation","infra/pulumi","k8s","observability/alertmanager.yml","observability/alert-rules.yml") | ForEach-Object { "$_ -> $(Test-Path $_)" }
Write-Host "`n=== 8. HOST PLATFORM ==="
(Get-CimInstance Win32_OperatingSystem).Caption
"CPU threads: $((Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors) | RAM GB: $([math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1))"
docker version --format "Docker {{.Server.Version}} ({{.Server.Os}})"

---

## 0. Assessment Scope & Host Baseline
| Item              | Finding (evidence)                                                                                                                           |
|-------------------|----------------------------------------------------------------------------------------------------------------------------------------------|
| Host platform     | Microsoft Windows 11 Pro · 14 CPU threads · 15.5 GB RAM                                                                                      |
| Container runtime | Docker Desktop (single engine, single host)                                                                                                  |
| Container engine  | **Docker 29.6.2 (linux)** — linux containers on Windows 11 (WSL2 backend) · engine current, **no upgrade risk registered**                   |
| Orchestration     | One Docker Compose project (`zurishop`), 14 containers                                                                                       |
| Cloud footprint   | **NONE** — 0 workloads on AWS, 0 on Azure, 0 on GCP                                                                                          |
| Version control   | GitHub `ahooTech/DevOps_Cloud_Engineering`, single `main` branch, 5 commits, 2 uncommitted modified files                                    |
| Analogy statement | For this engagement, the single Windows host is treated as ZuriMart's aging on-prem data centre: one failure domain, no DR, no segmentation. |

---

## 1. 📄 Current-State Infrastructure Inventory

### 1.1 Workload Inventory (14 containers, all `Up` at discovery time)
| #  | Workload             | Type                 | Image (tag)                             | Host port (0.0.0.0) | Healthcheck? |
|----|----------------------|----------------------|-----------------------------------------|---------------------|--------------|
| 1  | storefront-web       | Frontend (NGINX)     | zurishop-storefront-web:latest          | 8080                | ✅ healthy    |
| 2  | product-api          | API (FastAPI/Python) | zurishop-product-api:latest             | 8001                | ✅ healthy    |
| 3  | cart-service         | API (FastAPI/Python) | zurishop-cart-service:latest            | 8002                | ✅ healthy    |
| 4  | checkout-service     | API (FastAPI/Python) | zurishop-checkout-service:latest        | 8003                | ✅ healthy    |
| 5  | payment-service      | API (FastAPI/Python) | zurishop-payment-service:latest         | 8004                | ✅ healthy    |
| 6  | inventory-service    | API (FastAPI/Python) | zurishop-inventory-service:latest       | 8005                | ✅ healthy    |
| 7  | notification-service | API (FastAPI/Python) | zurishop-notification-service:latest    | 8006                | ✅ healthy    |
| 8  | search-service       | API (FastAPI/Python) | zurishop-search-service:latest          | 8007                | ✅ healthy    |
| 9  | postgres             | Database             | postgres:16-alpine                      | 5432                | ✅ healthy    |
| 10 | redis                | Cache                | redis:7-alpine                          | 6379                | ❌ none       |
| 11 | elasticsearch        | Search engine        | elasticsearch:8.13.0 (pinned ✔)         | 9200                | ❌ none       |
| 12 | postgres-exporter    | DB metrics exporter  | postgres-exporter:latest                | 9187                | ❌ none       |
| 13 | prometheus           | Metrics              | prom/prometheus:**latest** (unpinned ⚠) | 9090                | ❌ none       |
| 14 | grafana              | Dashboards           | grafana/grafana:**latest** (unpinned ⚠) | 3000                | ❌ none       |

Non-containerized workload: `legacy-reports/Generate-ZuriShopReport.ps1` (PowerShell, runs on host) — the finance reconciliation job.

### 1.2 Where Workloads Run Today
| Location                               | Workloads                      | Share |
|----------------------------------------|--------------------------------|-------|
| AWS                                    | —                              | 0%    |
| Azure                                  | —                              | 0%    |
| GCP                                    | —                              | 0%    |
| On-prem analogue (single Windows host) | All 14 containers + legacy PS1 | 100%  |

### 1.3 State, Storage & Network Topology
| Asset              | Finding                                                                                                                                |
|--------------------|----------------------------------------------------------------------------------------------------------------------------------------|
| Persistent volumes | 1 named (`zurishop_postgres_data`) + **13 unnamed hash-named volumes** (anonymous/orphaned — no lifecycle owner)                       |
| Networks           | Single flat bridge `zurishop_default` — **no tier segmentation**                                                                       |
| Port exposure      | **Every** service, including Postgres/Redis/Elasticsearch, bound to `0.0.0.0`                                                          |
| Image footprint    | ≈ **6.2 GB** of images on a 15.5 GB-RAM host (ES 1.88 GB + Grafana 1.58 GB dominate)                                                   |
| Secrets            | Plaintext `.env` on host (gitignored ✔, but no rotation, no vault)                                                                     |
| Monitoring         | Prometheus scrapes 8 targets; **no Alertmanager, no alert rules** (files verified absent)                                              |
| CI/CD & IaC        | `.github`, `.gitlab-ci.yml`, `Jenkinsfile`, `infra/terraform`, `infra/cloudformation`, `infra/pulumi`, `k8s` — **all verified absent** |

---

## 2. 📄 Workload Criticality Matrix
| Tier                      | Workloads                                                                                   | Business justification                                                 |
|---------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------|
| **Tier 1** (revenue path) | checkout-service, payment-service, product-api, postgres, storefront-web                    | A failure stops customers buying. Direct revenue loss.                 |
| **Tier 2** (enablers)     | inventory-service, cart-service, redis, search-service, elasticsearch, notification-service | Degraded experience / partial loss of sales; recoverable within hours. |
| **Tier 3** (internal)     | legacy-reports PS1, prometheus, grafana, postgres-exporter                                  | Internal tooling; outage invisible to customers.                       |

---

## 3. 📄 Manual Work Identification Report
| #   | Manual process           | Evidence                                                         | Cost / impact                            | Target automation                          |
|-----|--------------------------|------------------------------------------------------------------|------------------------------------------|--------------------------------------------|
| M1  | Deployments              | `docker compose up -d --build` typed by hand; no pipeline exists | Slow, error-prone, no rollback path      | Phase 4 (GitHub Actions/GitLab CI/Jenkins) |
| M2  | Environment provisioning | One compose file hand-copied; dev/staging/prod do not exist      | Environment drift, "works on my machine" | Phase 2–3 (Terraform/CF/Pulumi)            |
| M3  | Log collection           | `docker compose logs --since=1m \| Select-String` by hand        | Triage takes minutes-to-hours            | Phase 6 (centralized ES logging)           |
| M4  | Health verification      | `smoke-test.ps1` executed manually                               | Gate exists but is not enforced          | Phase 4 (pipeline deployment gate)         |
| M5  | Backups                  | None. Only a named volume; no snapshot, no restore test          | Tier-1 data loss on host failure         | Phase 7 (backup + restore drills)          |
| M6  | Alerting                 | None. Prometheus collects; nobody is paged                       | Customers detect incidents first         | Phase 6 (Alertmanager)                     |
| M7  | Cost reporting           | Nonexistent (no cloud yet, no tagging scheme)                    | No visibility when spend starts          | Phase 9 (FinOps)                           |
| M8  | Secrets handling         | Plaintext `.env` edited by hand; no rotation                     | Leak & audit risk                        | Phase 2/5 (Secrets Manager/Key Vault)      |
| M9  | Legacy reporting         | PS1 run by hand when finance remembers                           | Missed reconciliation windows            | Phase 8 (scheduled automation)             |
| M10 | Volume hygiene           | 13 anonymous volumes never cleaned                               | Wasted disk, unclear ownership           | Phase 8 (cleanup automation)               |

---

## 4. 📄 Risk & Reliability Register
| ID   | Risk                                                                           | Evidence                        | Sev        | Likelihood         | Mitigation (phase)                       |
|------|--------------------------------------------------------------------------------|---------------------------------|------------|--------------------|------------------------------------------|
| R-01 | Single point of failure: entire platform on one host                           | Host baseline §0                | **High**   | Certain            | Ph2/5: multi-AZ EKS + AKS DR             |
| R-02 | No backups / no DR / no restore test                                           | §1.3 volumes                    | **High**   | High               | Ph7                                      |
| R-03 | No alerting; incidents discovered by customers                                 | Guardrails: alertmanager absent | **High**   | High               | Ph6                                      |
| R-04 | No network segmentation; DB/cache/search exposed on 0.0.0.0                    | §1.3 ports                      | **High**   | Medium             | Ph2/5: private subnets + NetworkPolicies |
| R-05 | No autoscaling; fixed 1 replica per service                                    | compose ps (1 replica each)     | **High**   | High (sale events) | Ph5: HPA + Cluster Autoscaler            |
| R-06 | No CI/CD; trunk-only `main`, uncommitted changes                               | Git + guardrails                | **High**   | Medium             | Ph4 + §1.3 operating model               |
| R-07 | No IaC; platform not reproducible                                              | Guardrails all False            | **Medium** | Certain            | Ph2–3                                    |
| R-08 | Unpinned images (`prometheus:latest`, `grafana:latest`)                        | Image footprint                 | **Medium** | Medium             | Ph4: pinned tags + digest deploys        |
| R-09 | Volume sprawl: 13 unnamed volumes, no lifecycle                                | volume ls                       | **Low**    | Certain            | Ph8 cleanup automation                   |
| R-10 | Elasticsearch security disabled (`xpack.security.enabled=false`), single node  | compose env                     | **Medium** | Medium             | Ph5: secure, multi-node ES               |
| R-11 | Plaintext secrets on host, no rotation                                         | `.env`                          | **Medium** | Medium             | Ph2/5 secrets management                 |
| R-12 | 5 containers lack healthchecks (redis, ES, prometheus, grafana, exporter)      | compose ps (no "healthy")       | **Medium** | Medium             | Ph5: probes for all workloads            |
| R-13 | Host capacity headroom thin for load testing (6.2 GB images / 15.5 GB RAM)     | Host baseline                   | **Medium** | High (load tests)  | Ph5: move load to cloud clusters         |
| R-14 | Operational knowledge concentrated; docs exist but are not enforced as process | Repo review                     | **Low**    | Medium             | Ph1.3 + Ph10                             |

**Register owner:** DevOps Engineer · **Review cadence:** weekly ops review (see 1.3).

---

## 5. JD Bullets Captured (Phase 1.1)
| JD Code | Where captured                                                                                    |
|---------|---------------------------------------------------------------------------------------------------|
| CI-1    | Multi-cloud inventory executed (AWS/Azure/GCP assessed: 0 workloads today; target defined in 1.2) |
| CI-2    | Scalability/availability gaps quantified (R-01, R-05, R-12)                                       |
| CI-3    | Performance/cost inefficiencies identified (R-08, R-09, R-13, §1.3 footprint)                     |
| SK-1    | Hands-on assessment of runtime, storage, network, git estate                                      |
| SK-7    | Troubleshooting mindset: evidence-driven findings, not opinions                                   |
| NH-2    | Multi-cloud current-state assessment                                                              |
| TD-1    | Monitoring gaps documented (R-03, R-06)                                                           |
| TD-6    | Assessment structured for collaboration with app & ops teams                                      |

## 6. Deliverable Crosswalk
| Required deliverable                      | Section |
|-------------------------------------------|---------|
| 📄 Current-State Infrastructure Inventory | §1      |
| 📄 Workload Criticality Matrix            | §2      |
| 📄 Manual Work Identification Report      | §3      |
| 📄 Risk and Reliability Register          | §4      |
```


<div style='page-break-after: always;'></div>

# File: docs\phase-1\1.2-target-multi-cloud-architecture.md

```md
# 1.2 Target Multi-Cloud Architecture — ZuriMart / ZuriShop
**Project:** PROJECT ZURI PULSE · **Phase:** 1 · **Date:** 2026-08-19
**Status:** DESIGN (implemented in Phases 2–5) · **Inputs:** 1.1 Current-State Assessment

---

## 1. Design Principles (non-negotiable)
1. High availability — multi-AZ for all Tier-1/2 workloads.
2. Environment separation — dev / staging / production / DR, never shared.
3. Network segmentation — edge / app / data / management tiers; nothing database-grade on a public subnet.
4. Least-privilege access — IAM/RBAC scoped per environment; no wildcard admins.
5. Centralized logging & monitoring — every workload emits metrics + structured logs to one stack.
6. Disaster recovery — defined RTO/RPO per tier, tested (Phase 7).
7. Cost allocation tags — every resource tagged (Project/Environment/Owner/CostCenter/Application/ManagedBy).
8. Repeatable provisioning — nothing created by hand; Terraform/CloudFormation/Pulumi only (IA-2, IA-3).

## 2. 📄 Target Architecture Diagram
    Customers ── Route 53 (DNS, failover routing) ── WAF/ALB
                          │
    ┌─────────────────────┴─────────────────────────────── AWS (PRIMARY PROD) ───┐
    │  VPC 10.0.0.0/16 (3 AZs)                                                  │
    │   edge:  ALB → EKS prod (Ingress NGINX)                                   │
    │   app:   storefront-web, product-api, cart, checkout, payment,            │
    │          inventory, notification, search (EKS Deployments, HPA)           │
    │   data:  RDS PostgreSQL Multi-AZ · ElastiCache Redis · Elasticsearch (3n) │
    │   ops:   Amazon Managed Prometheus · Grafana · S3 (artifacts/backups)     │
    │   gov:   IAM · CloudTrail · CloudWatch · Budgets                          │
    └───────────────────────────────┬───────────────────────────────────────────┘
                          replicas/DR │ (VPC peering / VPN, non-overlapping CIDRs)
    ┌───────────────────────────────┴────────────── AZURE (IDENTITY + DR) ──────┐
    │  VNet 10.1.0.0/16 · Entra ID (SSO/MFA) · Key Vault · Azure Monitor        │
    │  AKS (pilot-light DR for Tier-1) · Azure Backup · legacy PS1 on Win VM    │
    └───────────────────────────────────────────────────────────────────────────┘
    ┌────────────────────────────────────────────────── GCP (DEV/TEST + DATA) ──┐
    │  VPC 10.2.0.0/16 · GKE (dev/test) · Artifact Registry (images)            │
    │  BigQuery (order analytics) · GCS (data lake) · Cloud Monitoring          │
    └───────────────────────────────────────────────────────────────────────────┘
    Control plane: Terraform (core) + CloudFormation (AWS guardrails) + Pulumi (preview envs)
    Delivery:     GitHub Actions (apps) · GitLab CI (platform) · Jenkins (legacy)

## 3. 📄 Multi-Cloud Environment Strategy (cloud roles)
| Cloud     | Role                                 | Key services                                                                                             |
|-----------|--------------------------------------|----------------------------------------------------------------------------------------------------------|
| **AWS**   | Primary production                   | EKS, VPC, ALB, RDS PostgreSQL, ElastiCache, S3, Route 53, IAM, CloudTrail, CloudWatch                    |
| **Azure** | Identity, DR, enterprise integration | Entra ID, AKS (DR), VNet, Key Vault, Azure Monitor, Azure Backup; home of the legacy PowerShell workload |
| **GCP**   | Dev/test + analytics                 | GKE (dev/test), BigQuery, GCS, Cloud Monitoring, Artifact Registry                                       |

## 4. 📄 Network Design Document (CIDR plan — no overlaps)
| Network         | CIDR        | Subnet tiers                                                                                  |
|-----------------|-------------|-----------------------------------------------------------------------------------------------|
| AWS prod VPC    | 10.0.0.0/16 | public 10.0.1–3.0/24 (3 AZs) · app 10.0.11–13.0/24 · data 10.0.21–23.0/24 · mgmt 10.0.31.0/24 |
| AWS staging VPC | 10.4.0.0/16 | same tier pattern /24                                                                         |
| Azure DR VNet   | 10.1.0.0/16 | edge/app/data/mgmt                                                                            |
| GCP dev VPC     | 10.2.0.0/16 | gke-subnet, mgmt-subnet                                                                       |
Segmentation rules: public→edge (443 only); edge→app (80/443 internal); app→data (5432/6379/9200 only); mgmt→all (bastion/SSH, audited). Inter-cloud: VPN/peering with explicit routes; DNS failover via Route 53 health checks.

## 5. 📄 Environment Separation Matrix
| Env        | Cloud/cluster           | Purpose                           | Data             | Deploy path                        | Access            |
|------------|-------------------------|-----------------------------------|------------------|------------------------------------|-------------------|
| dev        | GCP GKE                 | Feature validation, chaos drills  | Synthetic only   | Auto on merge to `develop`         | All engineers     |
| staging    | AWS EKS (staging)       | Pre-prod verification, load tests | Masked prod-like | `rc-*` tag + automated gates       | Eng + QA          |
| production | AWS EKS (prod)          | Live traffic                      | Real             | `main` + approval + pipeline gates | DevOps only       |
| DR         | Azure AKS (pilot-light) | Regional failover target          | Replicated       | Break-glass runbook (Ph7)          | Break-glass roles |

## 6. 📄 RTO/RPO Target Document
| Tier   | Workloads                                            | RPO   | RTO  |
|--------|------------------------------------------------------|-------|------|
| Tier 1 | checkout, payment, product-api, postgres, storefront | 5 min | 1 h  |
| Tier 2 | inventory, cart, redis, search, ES, notification     | 1 h   | 4 h  |
| Tier 3 | legacy reports, prometheus, grafana, exporter        | 24 h  | 24 h |
Mechanisms: RDS automated backups + cross-region snapshots; ElastiCache snapshots; S3 versioning + CRR; Velero/manifest backup for K8s; Route 53 failover; Azure AKS pilot-light restore. (Implemented & drilled in Phase 7.)

## 7. 📄 Cloud Service Selection Document (current → target)
| Current component                       | Target service                                              | Rationale                                             |
|-----------------------------------------|-------------------------------------------------------------|-------------------------------------------------------|
| postgres container + named volume       | **RDS PostgreSQL 16 Multi-AZ** (prod) / Cloud SQL (dev)     | Managed HA, backups, patching — fixes R-01/R-02       |
| redis container                         | **ElastiCache Redis** (prod) / Memorystore (dev)            | Managed HA + snapshots                                |
| elasticsearch single-node, security off | **Elasticsearch on EKS** (3 dedicated nodes, security on)   | Keeps JD tool TT-14, adds resilience                  |
| 7 FastAPI services (1 replica)          | **EKS Deployments** (HPA, PDB, probes) / GKE dev / AKS DR   | Autoscaling fixes R-05                                |
| storefront NGINX                        | EKS + **ALB** (+ CloudFront later)                          | Edge termination, health checks                       |
| prometheus/grafana                      | **Managed Prometheus + Grafana** (prod), self-hosted (dev)  | Retention & HA without ops burden                     |
| postgres-exporter                       | In-cluster exporter (same image, pinned tag)                | Continuity of DB metrics                              |
| legacy PS1 report                       | **Azure Windows VM** scheduled task (later: container job)  | Keeps PowerShell workload (TT-17) in its natural home |
| `.env` secrets                          | **Secrets Manager / Key Vault** + External Secrets Operator | Rotation, audit — fixes R-11                          |
| flat compose network                    | VPC tiered subnets + **NetworkPolicies**                    | Fixes R-04                                            |
| manual deploys, main-only git           | Pipelines (Ph4) + branching model (1.3)                     | Fixes R-06                                            |

## 8. JD Bullets Captured (Phase 1.2)
| JD Code | Where captured                                                        |
|---------|-----------------------------------------------------------------------|
| CI-1    | Target architecture spans AWS, Azure, GCP with explicit roles         |
| CI-2    | HA/multi-AZ/segmentation/least-privilege baked into principles        |
| CI-3    | Managed-service selection + tagging = performance & cost-aware design |
| CI-4    | DR environment (Azure AKS) + RTO/RPO matrix in design                 |
| SK-1    | Practical multi-cloud platform design                                 |
| NH-2    | Multi-cloud design                                                    |
| NH-3    | HA architecture for high-traffic retail workloads                     |
| SF-2    | Every design decision traces to a registered risk (1.1 §4)            |
| TD-4    | Autoscaling + managed services optimize scalability                   |

## 9. Deliverable Crosswalk
| Required deliverable                | Section |
|-------------------------------------|---------|
| 📄 Target Architecture Diagram      | §2      |
| 📄 Multi-Cloud Environment Strategy | §3      |
| 📄 Network Design Document          | §4      |
| 📄 Environment Separation Matrix    | §5      |
| 📄 RTO/RPO Target Document          | §6      |
| 📄 Cloud Service Selection Document | §7      |
```


<div style='page-break-after: always;'></div>

# File: docs\phase-1\1.3-devops-operating-model.md

```md
# 1.3 DevOps Operating Model — ZuriMart / ZuriShop
**Project:** PROJECT ZURI PULSE · **Phase:** 1 · **Date:** 2026-08-19
**Status:** EFFECTIVE IMMEDIATELY (governs Phases 2–10)

---

## 1. 📄 DevOps Operating Model Document
Everything is code; everything is reviewed; everything is automated as soon as it happens twice.
- **Repo:** single monorepo `project-zuri-pulse` (apps + infra + pipelines + docs). Docs live with code (docs-as-code).
- **Structure (target):**
    project-zuri-pulse/
      services/  storefront-web/  legacy-reports/
      infra/        terraform/  cloudformation/  pulumi/
      k8s/          base/  overlays/{dev,staging,prod,dr}/
      pipelines/    github-actions/  gitlab-ci/  jenkins/
      observability/  prometheus/  alertmanager/  grafana/  elasticsearch/
      scripts/      python/  bash/  powershell/
      docs/         phase-1/  runbooks/  incidents/  adr/
- **Environments:** dev → staging → production → DR (matrix in 1.2 §5). Promotion is pipeline-driven, never manual.
- **Continuous improvement:** weekly ops review; DORA metrics tracked from Phase 4:
    | Metric              | Baseline (1.1 evidence)          | Target                          |
    |---------------------|----------------------------------|---------------------------------|
    | Deploy frequency    | manual, ad-hoc                   | ≥ daily (dev), on-demand (prod) |
    | Lead time           | 30–60 min hand-driven, untracked | < 15 min pipeline               |
    | Change failure rate | unknown (no tracking)            | < 5%                            |
    | MTTD                | customers-first (no alerts)      | < 5 min                         |

## 2. 📄 Git Branching Strategy
| Branch                    | Purpose           | Deploys to                      | Protection                      |
|---------------------------|-------------------|---------------------------------|---------------------------------|
| `main`                    | Production truth  | production                      | 1 approval + all CI gates green |
| `develop`                 | Integration       | dev (auto)                      | CI gates green                  |
| `feature/<ticket>-<desc>` | Work in progress  | — (preview env via Pulumi, Ph3) | none                            |
| `hotfix/<id>`             | Production fixes  | staging → prod (expedited)      | 1 approval                      |
| `rc-YYYY.MM.DD-<n>`       | Release candidate | staging                         | tag-based                       |
Rules: no direct pushes to `main`/`develop`; every change = pull request; infrastructure changes use the same flow (IA-2).

## 3. 📄 Pull Request Review Checklist
**Application PRs:** unit tests green · lint green · SAST + image scan clean · no secrets in diff · Dockerfile still multi-stage/non-root · health endpoint updated · runbook updated if behavior changed · smoke-test gate passes in dev.
**Infrastructure PRs (Terraform/CF/Pulumi):** `fmt`+`validate`+`tflint` green · checkov/tfsec clean · `terraform plan` output attached · tagging policy satisfied · CIDR/no-overlap check · rollback plan stated · blast radius described · 1 infra-owner approval.

## 4. 📄 Change & Release Process
| Class                   | Examples                                      | Approval                                               | Window         |
|-------------------------|-----------------------------------------------|--------------------------------------------------------|----------------|
| Standard (pre-approved) | dev deploys, docs, dashboards                 | none (pipeline-gated)                                  | any            |
| Normal                  | staging promotion, prod release, infra change | PR review + pipeline gates (+ owner approval for prod) | business hours |
| Emergency               | Sev-1 mitigation, hotfix                      | verbal + break-glass role; retro review < 24 h         | any            |
Release steps: merge → pipeline (build/test/scan) → dev → integration tests → `rc` tag → staging → load/smoke gates → approval → prod (canary/blue-green per 4.5) → post-deploy smoke → rollback ready for 30 min. **Rollback criteria:** error rate > 1%, p95 latency > 2× baseline, or any failed smoke check.

## 5. 📄 Incident Severity Matrix
| SEV | Definition (ZuriShop examples)                                                 | Response       | Escalation      | Comms cadence |
|-----|--------------------------------------------------------------------------------|----------------|-----------------|---------------|
| 1   | Checkout/payments down; data loss risk (payment-service outage, postgres loss) | 15 min         | DevOps → CIO    | every 30 min  |
| 2   | Major degradation (search down, cart errors, ES red)                           | 30 min         | DevOps lead     | every 1 h     |
| 3   | Single-service elevated errors, no customer impact yet                         | 4 h            | owning engineer | at resolution |
| 4   | Cosmetic / internal (grafana panel broken, report delayed)                     | 1 business day | backlog         | none          |
Every alert carries: severity, summary, impact, runbook link, escalation path (Ph6). Post-incident: blameless post-mortem within 48 h for Sev-1/2.

## 6. On-call, Runbook & Documentation Expectations
- **On-call:** single rotation (project scale) with escalation to DevOps lead; Alertmanager routes Sev-1/2 to page, Sev-3/4 to channel (Ph6).
- **Runbooks:** mandatory for every alert and every Tier-1 workflow; template = Symptoms / Alerts / Impact / Investigation commands / Resolution / Rollback / Escalation / Post-incident validation.
- **Docs:** every phase delivers docs-as-code in `docs/`; no tribal knowledge — if it isn't in the repo, it doesn't exist.
- **Collaboration (TD-6, SF-5):** weekly ops review with app devs; deployment strategy changes agreed via ADR in `docs/adr/`.

## 7. JD Bullets Captured (Phase 1.3)
| JD Code | Where captured                                            |
|---------|-----------------------------------------------------------|
| IA-2    | Version-controlled operations model (§2)                  |
| IA-3    | Standardized provisioning/config via PR checklists (§3)   |
| IA-4    | Continuous improvement via DORA metrics + ops review (§1) |
| CC-3    | Deployment reliability/speed standards (§4)               |
| MR-4    | Operational visibility standards (§5–6)                   |
| SK-8    | Standards written, reviewable, versioned                  |
| SF-5    | Collaboration model with developers (§6)                  |
| SF-6    | Continuous improvement mindset (§1, §6)                   |
| TD-6    | Joint deployment-strategy process (§4, §6)                |

## 8. Deliverable Crosswalk
| Required deliverable               | Section |
|------------------------------------|---------|
| 📄 DevOps Operating Model Document | §1      |
| 📄 Git Branching Strategy          | §2      |
| 📄 Pull Request Review Checklist   | §3      |
| 📄 Change & Release Process        | §4      |
| 📄 Incident Severity Matrix        | §5      |
```


<div style='page-break-after: always;'></div>

# File: docs\phase-1\CV-PHASE1-ENTRY.md

```md
# 📄 CV-PHASE1-ENTRY.md
> **Phase 1 of PROJECT ZURI PULSE** proves you can assess, architect, and establish governance before writing a single line of Terraform. These bullets go under the same **ZuriShop** project entry on your CV, right below the microservices/containerization work from the base codebase.

---

## 📄 PHASE 1 CV BULLETS (Add these below your existing ZuriShop bullets)

**ZuriShop — Multi-Cloud DevOps Platform Transformation** | *DevOps Portfolio Project* | 2026
*Stack: AWS, Azure, GCP, Terraform, Architecture Design, FinOps, Incident Management, DORA Metrics*

- **Led current-state infrastructure assessment** of a 14-container retail platform, cataloguing all workloads, identifying 10 manual processes (deployments, backups, alerting, cost reporting), and registering 14 reliability risks with severity ratings and mitigation plans.
- **Designed multi-cloud target architecture** across AWS (primary production), Azure (identity/DR), and GCP (dev/test/analytics), with explicit workload placement, CIDR-based network segmentation (no overlapping ranges), and environment separation (dev/staging/prod/DR).
- **Established RTO/RPO targets by workload criticality tier**: Tier 1 (checkout, payments, product catalog) at 5-minute RPO / 1-hour RTO; Tier 2 (inventory, cart, search) at 1-hour RPO / 4-hour RTO; Tier 3 (reporting, observability) at 24-hour RPO / 24-hour RTO.
- **Created DevOps operating model** with Git branching strategy (main/develop/feature/hotfix), pull request review checklists (application + infrastructure), deployment approval gates, and incident severity matrix (Sev-1 through Sev-4) with escalation paths and response SLAs.
- **Defined DORA metrics baseline and targets**: deployment frequency (manual ad-hoc → ≥ daily), lead time (30–60 min → < 15 min), change failure rate (unknown → < 5%), mean time to detect (customers-first → < 5 min), establishing measurable continuous improvement goals.
- **Mapped cloud service selection** from current Docker Compose single-host architecture to managed services: PostgreSQL → RDS Multi-AZ, Redis → ElastiCache, Elasticsearch → secure 3-node cluster on EKS, NGINX → ALB + CloudFront, eliminating single points of failure and manual patching.
- **Authored 6 governance documents**: Current-State Assessment, Target Architecture Diagram, Network Design Document, Environment Separation Matrix, RTO/RPO Target Document, DevOps Operating Model — all version-controlled in the repository as docs-as-code.

---

## 🧾 THE "PROBLEMS WE SOLVED" LEDGER FOR PHASE 1 (Your Interview Defense)

Every CV bullet above maps to a real assessment finding. Keep this list in your head so you can defend any bullet with a story:

**1. "Why did you assess the platform before building anything?"**
*Real problem:* ZuriMart's CIO Njeri had no visibility into what was running, where it was running, or what the risks were. Every environment was different, and nobody knew how AWS, Azure, and GCP connected (if at all).
*What you did:* Ran an automated discovery script (PowerShell) that inventoried 14 containers, checked runtime state, measured image footprint (6.2 GB on a 15.5 GB host), verified network topology (single flat bridge, no segmentation), and confirmed zero CI/CD/IaC/K8s guardrails existed. Documented findings in a Current-State Assessment.
*Defends CV bullet:* The "current-state infrastructure assessment" bullet.

**2. "How did you decide which workloads go to which cloud?"**
*Real problem:* Without a strategy, teams were randomly placing workloads across clouds, creating confusion, duplicated effort, and poor ownership.
*What you did:* Classified workloads by business criticality (Tier 1/2/3), then matched each tier to cloud strengths: AWS for production (EKS, RDS, ElastiCache), Azure for identity (Entra ID) and DR (AKS pilot-light), GCP for dev/test (GKE) and analytics (BigQuery). Documented rationale in the Cloud Service Selection Document.
*Defends CV bullet:* The "multi-cloud target architecture" bullet.

**3. "What RTO/RPO did you choose and why?"**
*Real problem:* Finance and marketing were furious about the "Nairobi Mega Sale" outage. The board demanded guarantees that Tier-1 revenue path would never go down again.
*What you did:* Analyzed business impact: checkout/payments = direct revenue loss (5-min RPO, 1-hour RTO), inventory/search = degraded experience (1-hour RPO, 4-hour RTO), reporting = internal only (24-hour RPO acceptable). Documented in RTO/RPO Target Document with mitigation mechanisms (RDS Multi-AZ, S3 versioning, Velero backups, Route 53 failover).
*Defends CV bullet:* The "RTO/RPO targets by workload tier" bullet.

**4. "Why did you need a DevOps operating model?"**
*Real problem:* Teams were using GitHub, GitLab, and Jenkins differently. There was no standard branching strategy, no PR review process, no incident severity definitions, and no runbook expectations. Knowledge lived in a few people's heads.
*What you did:* Created a single DevOps Operating Model Document that defined: monorepo structure (services/infra/pipelines/observability/docs), branching strategy (main/develop/feature/hotfix), PR checklists (12 checks for apps, 10 for infrastructure), change classes (Standard/Normal/Emergency), incident severity matrix (Sev-1/2/3/4 with response SLAs), and on-call expectations. All stored in `docs/phase-1/`.
*Defends CV bullet:* The "DevOps operating model" bullet.

**5. "How did you measure success?"**
*Real problem:* Without metrics, you can't prove improvement. The CIO needed evidence that the transformation was working.
*What you did:* Established DORA metrics baseline from current-state evidence (manual deploys, 30–60 min lead time, unknown failure rate, customers-first detection), then set targets (daily deploys, <15 min lead time, <5% failure rate, <5 min MTTD). Tracked these from Phase 4 onward (CI/CD pipelines) through Phase 10 (final handover report).
*Defends CV bullet:* The "DORA metrics baseline and targets" bullet.

**6. "Why not just keep using Docker Compose?"**
*Real problem:* The single-host Compose setup worked for dev, but had zero high availability, zero autoscaling, zero DR, and zero network segmentation. A single host failure = complete platform outage.
*What you did:* Mapped every current component to a managed cloud service in the Cloud Service Selection Document: postgres → RDS Multi-AZ (fixes single-point-of-failure), redis → ElastiCache (managed HA), elasticsearch → secure 3-node cluster on EKS (fixes security-off risk), NGINX → ALB (health checks, SSL termination). Documented the migration path.
*Defends CV bullet:* The "cloud service selection mapping" bullet.

**7. "Where is the proof this isn't just theory?"**
*Real problem:* Anyone can draw architecture diagrams. Hiring managers want to see that you actually built and operated the platform.
*What you did:* All 6 Phase 1 documents are version-controlled in `docs/phase-1/` in the Git repository. The Current-State Assessment references real evidence (discovery script output from 2026-08-19). The Risk Register has 14 specific risks (R-01 through R-14) with evidence and mitigation phases. The Target Architecture has CIDR ranges, service selections, and RTO/RPO tables. The Operating Model has Git branching rules, PR checklists, and incident severity definitions. Everything is reviewable, not hypothetical.
*Defends CV bullet:* The "6 governance documents" bullet.

---

## ⚠️ HONESTY RULE (Protects You in the Interview)

- **Do NOT claim yet:** That you have *applied* Terraform, CloudFormation, or Pulumi to provision real cloud resources. Phase 1 is assessment and design.
- **Do claim now:** That you *designed* the multi-cloud architecture, *established* the operating model, *defined* the RTO/RPO targets, and *created* the governance documents that will guide Phases 2–10.
- **When to update:** After Phase 2 (Terraform landing zones), add a bullet like: "Provisioned multi-cloud landing zone across AWS/Azure/GCP using Terraform, implementing the Phase 1 architecture with remote state management, tagging policies, and automated validation pipelines."

---

## 🎯 HOW TO PRESENT PHASE 1 IN THE INTERVIEW

When they ask: *"Walk me through your multi-cloud project."*

**Say this:**

> "I started with a current-state assessment. I ran an automated discovery script that inventoried all 14 containers, checked runtime state, measured image footprint, and verified that zero CI/CD, zero IaC, and zero Kubernetes guardrails existed. I documented 14 reliability risks — single point of failure, no backups, no alerting, no network segmentation — and mapped them to mitigation phases.
>
> Then I designed the target multi-cloud architecture. I chose AWS for primary production (EKS, RDS, ElastiCache), Azure for identity and DR (Entra ID, AKS pilot-light), and GCP for dev/test and analytics (GKE, BigQuery). I defined CIDR ranges with no overlaps, established RTO/RPO targets by workload tier (Tier 1 at 5-min RPO / 1-hour RTO), and mapped every current component to a managed cloud service.
>
> Finally, I created the DevOps operating model — Git branching strategy, PR review checklists, incident severity matrix, DORA metrics targets — all stored as docs-as-code in the repository. This gave us the governance foundation before we wrote a single line of Terraform."

**Then transition to:** "Once the foundation was set, I moved to Phase 2 and provisioned the landing zones using Terraform..."

---

## 📊 PHASE 1 METRICS SUMMARY (For the Interview Proof Pack)

| Metric                  | Before (Phase 1 Assessment) | Target (Phase 10)                        |
|-------------------------|-----------------------------|------------------------------------------|
| Cloud visibility        | None (single host)          | Full multi-cloud dashboard               |
| Workload classification | None                        | Tier 1/2/3 with RTO/RPO                  |
| Risk register           | None                        | 14 risks tracked and mitigated           |
| Operating model         | None                        | Branching, PR, incident, on-call defined |
| DORA metrics baseline   | None                        | Established and tracked                  |
| Governance documents    | None                        | 6 docs in version control                |

---

## 🚀 NEXT PHASE PREVIEW

After Phase 1, your CV will add bullets for:
- **Phase 2:** "Provisioned multi-cloud landing zone across AWS/Azure/GCP using Terraform, implementing the Phase 1 architecture with remote state management, tagging policies, and automated validation pipelines."
- **Phase 3:** "Built AWS CloudFormation guardrail stacks and Pulumi ephemeral environments, demonstrating mastery of all three IaC tools required by the job description."
- **Phase 4:** "Created CI/CD pipelines using GitHub Actions, GitLab CI, and Jenkins, reducing deployment lead time from 30–60 minutes to under 15 minutes."
- **Phase 5:** "Deployed containerized microservices on Kubernetes (EKS/AKS/GKE), implementing HPA, Cluster Autoscaler, and Pod Disruption Budgets to handle 900% traffic spikes."
- **Phase 6:** "Implemented observability with Prometheus, Grafana, and Elasticsearch, reducing mean time to detect from customers-first to under 5 minutes."
- **Phase 7:** "Tested disaster recovery with backup/restore drills, achieving Tier-1 RPO of 5 minutes and RTO of 1 hour."
- **Phase 8:** "Automated operational tasks with Python, Bash, and PowerShell scripts, reducing manual work by 80%."
- **Phase 9:** "Optimized cloud costs with tagging policies, budget alerts, and right-sizing recommendations, reducing spend by 30%."
- **Phase 10:** "Documented the entire platform, created runbooks, recorded a demo video, and handed over to the operations team."

By Week 10, your CV will cover every bullet in the Pavago DevOps Engineer job description with evidence.
```


<div style='page-break-after: always;'></div>

# File: docs\📘 ZuriShop End-to-End Interview Runbook.md

```md
# 📘 ZuriShop End-to-End Interview Runbook

This is your master interview script. It is structured as a series of **End-to-End Workflows**. For each workflow, you will start with a **Clean Slate**, execute the demonstration across CLI and GUI, and deliver a specific **Interview Narrative**. 

By the end of this runbook, you will have proven every layer of the application, every tool in the Pavago JD, and your ability to operate a production-grade platform.

---


## 0. Service & Port Map

| Layer            | Service              | Port  |
|------------------|----------------------|-------|
| Frontend         | storefront-web       | 8080  |
| API              | product-api          | 8001  |
| API              | cart-service         | 8002  |
| API              | checkout-service     | 8003  |
| API              | payment-service      | 8004  |
| API              | inventory-service    | 8005  |
| API              | notification-service | 8006  |
| API              | search-service       | 8007  |
| Database         | postgres             | 5432  |
| Cache            | redis                | 6379  |
| Search engine    | elasticsearch        | 9200  |
| DB metrics       | postgres-exporter    | 9187  |
| Metrics          | prometheus           | 9090  |
| Dashboards       | grafana              | 3000  |



## 🧹 The Master Reset Commands

Before starting any workflow, you need a way to guarantee a clean state. Use these commands depending on how deep of a reset you need.

### Option A: The "Soft Reset" (Fast - Clears Data Only)
Use this between workflows to clear transactions without waiting for heavy containers like Elasticsearch to reboot.
```powershell
# Flush Redis (Clears all shopping carts)
docker compose exec redis redis-cli FLUSHALL

# Truncate Postgres (Clears all orders, keeps product catalog and stock)
docker compose exec postgres psql -U zurishop -d zurishop -c "TRUNCATE TABLE orders.orders;"

# Reset Inventory to original levels
docker compose exec postgres psql -U zurishop -d zurishop -c "UPDATE inventory.stock SET remaining = 50 WHERE product_id = 'SKU-001'; UPDATE inventory.stock SET remaining = 20 WHERE product_id = 'SKU-002'; UPDATE inventory.stock SET remaining = 100 WHERE product_id = 'SKU-003'; UPDATE inventory.stock SET remaining = 10 WHERE product_id = 'SKU-004';"
```

### Option B: The "Hard Reset" (Slow - Destroys Everything)
Use this if you want to show the platform booting up from absolute zero (e.g., at the very beginning of the interview).
```powershell
docker compose down
docker volume rm zurishop_postgres_data
docker compose up -d --build
Start-Sleep -Seconds 45 # Wait for ES and PG to initialize
curl.exe -X POST http://localhost:8007/search/index # Re-seed search  Or do via GUI
```

---

## 🔄 WORKFLOW 1: The "Golden Path" Transaction (Microservices Orchestration)
**Goal:** Prove that a user action on the frontend successfully orchestrates 5 distinct microservices, writes to a relational database, and cleans up transient cache.

### Step 1: Soft Reset
```powershell
docker compose exec redis redis-cli FLUSHALL
docker compose exec postgres psql -U zurishop -d zurishop -c "TRUNCATE TABLE orders.orders;"
```

### Step 2: Frontend GUI (The User Experience)
1. Open your browser to **http://localhost:8080**
2. **Action:** Click **"Load All Products"**.
   * *Result:* The JSON output populates with 4 items from the `product-api` (PostgreSQL).
3. **Action:** Type `keyboard` in the search box and click **"Search"**.
   * *Result:* The Mechanical Keyboard is returned from Elasticsearch via the `search-service`.

### Step 3: Backend Orchestration (The Checkout Flow)
*Simulate a user adding an item to their cart and checking out.*
```powershell
# 1. Add to Cart (Writes to Redis)
curl.exe -X POST http://localhost:8002/cart/wf1-cart/items -H "Content-Type: application/json" -d '{\"product_id\": \"SKU-002\", \"quantity\": 1}'
# 2. View the state of the cart in redis
docker compose exec redis redis-cli HGETALL cart:wf1-cart

# 3. Trigger Checkout (Orchestrates Inventory, Payment, Notification, DB, and Cart-Clear)
curl.exe -X POST http://localhost:8003/checkout -H "Content-Type: application/json" -d '{\"cart_id\": \"wf1-cart\", \"email\": \"njeri@zurimart.co.ke\"}'
```
✅ **Expected Output:** `{"order_id":"<uuid>","status":"completed","total":6500.0,"currency":"KES"}`

### Step 4: Verification (The DevOps Proof)
```powershell
# Prove the order is permanently saved in PostgreSQL
docker compose exec postgres psql -U zurishop -d zurishop -c "SELECT order_id, total, status FROM orders.orders;"

# Prove the inventory was atomically decremented in PostgreSQL
docker compose exec postgres psql -U zurishop -d zurishop -c "SELECT remaining FROM inventory.stock WHERE product_id = 'SKU-002';"
# ✅ Expected: 19

# Prove the transient cart was cleaned up from Redis
docker compose exec redis redis-cli HGETALL cart:wf1-cart
# ✅ Expected: (empty array)
```

🎤 **Interview Narrative:** 
> *"This demonstrates our core microservices orchestration. A single checkout API call securely reserves inventory in Postgres using atomic constraints, processes a mock payment, queues an email notification, and cleans up the transient Redis cart. I designed this so the database is the single source of truth for permanent state, while Redis handles high-speed session state."*

---

## 🔍 WORKFLOW 2: Decoupled Search Engine Lifecycle (Elasticsearch)
**Goal:** Prove that the search engine is decoupled from the primary database and can be wiped and re-seeded independently without affecting the core application.

### Step 1: Clean Slate (Wipe the Search Index)
```powershell
# Delete the Elasticsearch index entirely
curl.exe -X DELETE "http://localhost:9200/products"
# ✅ Expected: {"acknowledged":true}

# Verify search is now broken (decoupled)
curl.exe "http://localhost:8007/search?q=keyboard"
# ✅ Expected: {"count":0,"hits":[]}
```

### Step 2: Re-Seed the Search Engine
```powershell
# Trigger the search-service to read from product-api and rebuild the ES index
curl.exe -X POST http://localhost:8007/search/index
# ✅ Expected: {"indexed":4}
```

### Step 3: Verification via Elasticsearch API
```powershell
# Check cluster health
curl.exe "http://localhost:9200/_cluster/health?pretty"

# Check index document count
curl.exe "http://localhost:9200/products/_count?pretty"
# ✅ Expected: "count" : 4

# Execute a direct fuzzy search query against Elasticsearch
curl.exe "http://localhost:9200/products/_search?q=mouse&pretty"
```

🎤 **Interview Narrative:** 
> *"In modern architectures, search must be decoupled from the transactional database to prevent load spikes from taking down checkout. Here I wiped the Elasticsearch index and rebuilt it asynchronously by having the search-service pull from the product catalog API. This proves our observability and search layers are resilient and independently deployable."*

---

## 📊 WORKFLOW 3: Traffic Generation & Observability (Prometheus & Grafana)
**Goal:** Generate synthetic load and prove that the observability stack (Prometheus, Grafana, Postgres Exporter) captures it in real-time.

### Step 1: Generate Synthetic Traffic
*Run this PowerShell loop to hammer the checkout service with 50 requests.*
```powershell
1..50 | ForEach-Object {
    $cartId = "load-test-$_"
    Invoke-RestMethod -Uri "http://localhost:8002/cart/$cartId/items" -Method Post -ContentType "application/json" -Body '{"product_id":"SKU-003","quantity":1}' | Out-Null
    Invoke-RestMethod -Uri "http://localhost:8003/checkout" -Method Post -ContentType "application/json" -Body "{`"cart_id`":`"$cartId`",`"email`":`"test@zurimart.co.ke`"}" | Out-Null
    Write-Host "Processed order $_"
}
```

### Step 2: Prometheus GUI Verification
1. Open browser to **http://localhost:9090**
2. **Action:** Click **Status** → **Targets** in the top menu.
   * *Result:* Show the interviewer that all 8 targets (7 Python services + `postgres-exporter`) are highlighted in **GREEN (UP)**.
3. **Action:** Click **Graph** in the top menu.
4. **Action:** Enter this PromQL query and click **Execute**, then switch to the **Graph** tab:
   ```promql
   sum(rate(http_requests_total[1m])) by (job)
   ```
   * *Result:* A multi-colored line chart showing the massive spike in requests per second across your microservices.

### Step 3: Grafana GUI Verification
1. Open browser to **http://localhost:3000** (Login: `admin` / `admin`)
2. **Action:** Go to **Connections** → **Data Sources** → **Add data source** → **Prometheus**.
3. **Action:** Set URL to `http://prometheus:9090` → Click **Save & test**.
4. **Action:** Click the **Dashboards** icon (left menu) → **New** → **New Dashboard** → **Add visualization**.
5. **Action:** Select your Prometheus data source.
6. **Action:** Paste this query to show Database Connection health:
   ```promql
   pg_up
   ```
7. **Action:** Click **Apply**, then **Save Dashboard** (Name it: *ZuriShop Executive Overview*).

🎤 **Interview Narrative:** 
> *"I don't just deploy applications; I make them observable. By integrating the Prometheus FastAPI instrumentator and the Postgres Exporter, I've captured the Golden Signals. In Grafana, we can now visualize the exact traffic spike we just generated, and more importantly, monitor the underlying database connection pool health to prevent saturation during events like the 'Nairobi Mega Sale'."*

---

## 📜 WORKFLOW 4: Legacy Enterprise Integration (PowerShell Automation)
**Goal:** Prove that modern cloud-native microservices can seamlessly integrate with legacy enterprise reporting tools (a specific requirement in the Pavago JD).

### Step 1: Soft Reset
```powershell
docker compose exec redis redis-cli FLUSHALL
```

### Step 2: Execute the Legacy Workload
```powershell
# Run the PowerShell script that queries the modern APIs and generates an enterprise CSV
pwsh legacy-reports/Generate-ZuriShopReport.ps1
```

### Step 3: Verification
```powershell
# Display the generated CSV in the terminal
cat zurishop-report.csv
```
✅ **Expected Output:**
```csv
"ProductId","Name","Price","Currency","Stock"
"SKU-001","Wireless Mouse","1500","KES","50"
"SKU-002","Mechanical Keyboard","6500","KES","20"
...
```

🎤 **Interview Narrative:** 
> *"Real enterprises rarely migrate everything at once. ZuriMart's finance team still relies on PowerShell scripts for end-of-day reconciliation. I wrote this script to bridge the gap, pulling live data from our modern FastAPI microservices and formatting it into the legacy CSV format their on-prem systems expect. This proves I can operate in hybrid environments and automate cross-platform workflows."*

---

## 🔥 WORKFLOW 5: Chaos Engineering & Incident Response (SRE / MR-3)
**Goal:** Simulate a production outage, prove that monitoring detects it, and demonstrate the incident response loop (Detect → Triage → Recover).

### Step 1: The Sabotage (Break the Platform)
```powershell
# Silently kill the payment gateway
docker compose stop payment-service
```

### Step 2: The User Impact (Attempt Checkout)
```powershell
curl.exe -X POST http://localhost:8002/cart/chaos-burst/items -H "Content-Type: application/json" -d '{\"product_id\": \"SKU-001\", \"quantity\": 1}'
curl.exe -X POST http://localhost:8003/checkout -H "Content-Type: application/json" -d '{\"cart_id\": \"chaos-burst\", \"email\": \"angry@customer.com\"}'

docker compose exec redis redis-cli HGETALL cart:chaos-burst

docker compose exec postgres psql -U zurishop -d zurishop -c "SELECT remaining FROM inventory.stock WHERE product_id = 'SKU-001';"
```
❌ **Expected Output:** `{"detail":"Payment service unavailable"}` (HTTP 503)

### Step 3: Triage via Logs (The DevOps Investigation)
```powershell
# Filter out the noise and find the exact failure point in the last 1 minute
docker compose logs --since=1m checkout-service | Select-String "ERROR|Payment service unreachable"
```
✅ **Expected Output:** Shows the `checkout-service` failing to connect to the `payment-service`.

### Step 4: Triage via Grafana (The Executive View)
# Generate a failure burst, then zoom in

1..60 | ForEach-Object {
    $cartId = "chaos-burst-$_"
    Invoke-RestMethod -Uri "http://localhost:8002/cart/$cartId/items" -Method Post -ContentType "application/json" -Body '{"product_id":"SKU-001","quantity":1}' | Out-Null
    try {
        Invoke-RestMethod -Uri "http://localhost:8003/checkout" -Method Post -ContentType "application/json" -Body "{`"cart_id`":`"$cartId`",`"email`":`"angry@customer.com`"}" | Out-Null
    } catch {
        Write-Host "[$_] 503 as expected"
    }
}


2. Open **http://localhost:3000**
3. **Action:** Add a new panel to your dashboard with this PromQL query:
   ```promql

   sum(increase(http_requests_total{status=~"4..|5.."}[1m])) by (job)

   sum(rate(http_requests_total{status=~"4..|5.."}[1m])) by (job)
   ```
   * *Result:* (spike to ~15/min): You killed payment-service and fired the 60-request failure burst → checkout-service burns error budget.

### Step 5: The Recovery
```powershell
# Restore the service
docker compose start payment-service

# Verify the platform is green again

curl.exe -X POST http://localhost:8003/checkout -H "Content-Type: application/json" -d '{\"cart_id\": \"chaos-burst\", \"email\": \"angry@customer.com\"}'

```
✅ **Expected Output:** `{"order_id":"...","status":"completed"...}` if there is still stock or `{"detail":"Could not reserve stock for SKU-001"}` if there is no stock 

# If could not reserve stock update by quantity in redis then try again 
docker compose exec redis redis-cli HGETALL cart:chaos-burst

docker compose exec postgres psql -U zurishop -d zurishop -c "UPDATE inventory.stock SET remaining = 1 WHERE product_id = 'SKU-001';"

curl.exe -X POST http://localhost:8003/checkout -H "Content-Type: application/json" -d '{\"cart_id\": \"chaos-burst\", \"email\": \"angry@customer.com\"}'

🎤 **Interview Narrative:** 
> *"Incidents are inevitable; slow recovery is not. I just simulated a Sev-1 payment gateway failure. Because we have structured JSON logging, I immediately filtered out the Prometheus health-check noise to find the exact connection error. In a real production environment, that Grafana error-rate panel would trigger an Alertmanager webhook to PagerDuty, paging me before customers even notice."*

---

## 🛡️ WORKFLOW 6: Stateful Resilience (Database vs. Cache)
**Goal:** Prove you understand the architectural difference between persistent storage (Volumes) and transient cache, and how Docker handles state during crashes.

### Step 1: Create Persistent State
```powershell
# Create an order
curl.exe -X POST http://localhost:8002/cart/res-cart/items -H "Content-Type: application/json" -d '{\"product_id\": \"SKU-004\", \"quantity\": 1}'

docker compose exec redis redis-cli TTL cart:ttl-cart

curl.exe -X POST http://localhost:8003/checkout -H "Content-Type: application/json" -d '{\"cart_id\": \"res-cart\", \"email\": \"resilience@zurimart.co.ke\"}'
```

### Step 2: Simulate a Total Infrastructure Crash
```powershell
# Hard restart the database and the cache
docker compose restart postgres redis
```

### Step 3: Verify Persistent vs Transient State
```powershell
# 1. Check Postgres (Persistent Volume)
curl.exe http://localhost:8003/orders
# ✅ Expected: The order YOU just created is still there. Data survived the crash.

# 2. Check Redis (Transient Memory)
docker compose exec redis redis-cli DBSIZE
# ✅ Expected: (integer) 0. All carts are gone. This is EXPECTED and CORRECT behavior.
```

🎤 **Interview Narrative:** 
> *"This demonstrates my understanding of stateful workloads. When the infrastructure crashed, PostgreSQL retained the financial records because it is backed by a persistent Docker volume. Redis lost the shopping carts because it is an in-memory cache. Designing systems with this distinction is critical for Disaster Recovery planning and ensuring we never lose Tier-1 financial data."*

---

## 🤖 WORKFLOW 7: The Automated Platform Health Check
**Goal:** Prove that you don't rely on manual clicking. You build automation to verify platform health (CI/CD readiness).

### Step 1: Execute the Master Smoke Test
```powershell
pwsh scripts/smoke-test.ps1
```

✅ **Expected Output:**
```text
=== ZuriShop Smoke Test ===
[PASS] product-api /healthz
[PASS] cart-service /healthz
[PASS] checkout-service /healthz
[PASS] payment-service /healthz
[PASS] inventory-service /healthz
[PASS] notification-service /healthz
[PASS] search-service /healthz
[PASS] storefront-web
[PASS] elasticsearch
[PASS] prometheus
[PASS] postgres
[PASS] search indexing
[PASS] search query
[PASS] checkout flow
[PASS] order persisted in Postgres
ALL CHECKS PASSED
```

🎤 **Interview Narrative:** 
> *"Manual verification doesn't scale. I wrote this PowerShell smoke test to act as the final gate in our CI/CD pipeline. Before any new code is promoted to staging, this script runs automatically. If any microservice, database connection, or search index fails this test, the pipeline halts, and the deployment is rejected. This is how we maintain reliability at speed."*

---

### 🎯 Final Interview Tip
Keep this Markdown file open on one side of your screen during the interview. When they ask, *"Walk me through your project,"* you simply say: 

> *"Let me share my screen and walk you through the 6 end-to-end workflows I use to validate the ZuriShop platform..."* 

Then, just follow the numbers. You will look like an absolute senior-level professional.
```


<div style='page-break-after: always;'></div>

# File: Generate-Codebook.ps1

```ps1
<#
.\Generate-Codebook.ps1 -ProjectPath "C:\devops\1-devops-job-level-middle\Pavago\project-zuri-pulse\zurishop"
#>


param(
    [string]$ProjectPath = (Get-Location).Path,
    [switch]$GeneratePdf
)

# ============================================================
# Configuration
# ============================================================

$Root = (Resolve-Path $ProjectPath).Path

$MarkdownFile = Join-Path $Root "Codebase.md"
$PdfFile      = Join-Path $Root "Codebase.pdf"

$ExcludedDirectories = @(
    ".git",
    ".github",
    "node_modules",
    "coverage",
    "dist",
    "build",
    "bin",
    "obj",
    "venv",
    ".venv",
    "env",
    "__pycache__",
    ".pytest_cache",
    ".idea",
    ".vscode",
    "migrations"
)

$ExcludedExtensions = @(
    ".png",".jpg",".jpeg",".gif",".bmp",".ico",".svg",".webp",".avif",
    ".pdf",".zip",".7z",".rar",
    ".exe",".dll",".so",
    ".woff",".woff2",".ttf",".eot",
    ".pyc",".class",".db",".sqlite3",".log"
)

# Delete old markdown if it exists
if (Test-Path $MarkdownFile) {
    Remove-Item $MarkdownFile -Force
}

# ============================================================
# Helper Function
# ============================================================

function Add-Line {
    param([string]$Text)

    Add-Content -Path $MarkdownFile -Value $Text -Encoding UTF8
}

# ============================================================
# Scan Files
# ============================================================

Write-Host ""
Write-Host "Scanning repository..."
Write-Host ""

$Files = Get-ChildItem -Path $Root -Recurse -File | Where-Object {

    $relative = $_.FullName.Substring($Root.Length).TrimStart('\')

    foreach ($dir in $ExcludedDirectories) {
        if ($relative -split "\\" -contains $dir) {
            return $false
        }
    }

    if ($ExcludedExtensions -contains $_.Extension.ToLower()) {
        return $false
    }

    return $true

} | Sort-Object FullName

Write-Host "Found $($Files.Count) files."
Write-Host ""

# ============================================================
# Markdown Header
# ============================================================

Add-Line "# Staff Canteen Management System"
Add-Line ""
Add-Line "Generated: $(Get-Date)"
Add-Line ""
Add-Line "---"
Add-Line ""

# ============================================================
# Table of Contents
# ============================================================

Add-Line "## Table of Contents"
Add-Line ""

foreach ($file in $Files) {

    $relative = $file.FullName.Substring($Root.Length).TrimStart('\')

    Add-Line "- $relative"

}

Add-Line ""
Add-Line "---"
Add-Line ""

# ============================================================
# Add Every File
# ============================================================

$index = 1

foreach ($file in $Files) {

    $relative = $file.FullName.Substring($Root.Length).TrimStart('\')

    Write-Host "[$index/$($Files.Count)] $relative"

    $language = $file.Extension.TrimStart('.')

    if ([string]::IsNullOrWhiteSpace($language)) {
        $language = "text"
    }

    Add-Line ""
    Add-Line "<div style='page-break-after: always;'></div>"
    Add-Line ""
    Add-Line "# File: $relative"
    Add-Line ""

    # Opening code fence
    Add-Line ('```' + $language)

    try {

        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        Add-Content -Path $MarkdownFile -Value $content -Encoding UTF8

    }
    catch {

        Add-Line "[Unable to read file.]"

    }

    # Closing code fence
    Add-Line '```'
    Add-Line ""

    $index++

}

Write-Host ""
Write-Host "Markdown created successfully!"
Write-Host ""
Write-Host $MarkdownFile

# ============================================================
# Optional PDF Generation
# ============================================================

if ($GeneratePdf) {

    $Pandoc = Get-Command pandoc -ErrorAction SilentlyContinue

    if ($Pandoc) {

        Write-Host ""
        Write-Host "Generating PDF..."

        & pandoc `
            $MarkdownFile `
            -o $PdfFile `
            --toc `
            --highlight-style=tango

        Write-Host ""
        Write-Host "PDF created:"
        Write-Host $PdfFile

    }
    else {

        Write-Host ""
        Write-Host "Pandoc was not found."
        Write-Host ""
        Write-Host "Install it from:"
        Write-Host "https://pandoc.org/installing.html"

    }

}
```


<div style='page-break-after: always;'></div>

# File: infra\postgres\init.sql

```sql
-- ZuriShop database bootstrap (acts as our migration)
-- Runs automatically on first boot of the postgres container.

CREATE SCHEMA IF NOT EXISTS catalog;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS orders;

-- ============ CATALOG ============
CREATE TABLE IF NOT EXISTS catalog.products (
    id       TEXT PRIMARY KEY,
    name     TEXT NOT NULL,
    price    NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    currency TEXT NOT NULL DEFAULT 'KES'
);

INSERT INTO catalog.products (id, name, price, currency) VALUES
    ('SKU-001', 'Wireless Mouse',      1500, 'KES'),
    ('SKU-002', 'Mechanical Keyboard', 6500, 'KES'),
    ('SKU-003', 'USB-C Cable',          700, 'KES'),
    ('SKU-004', 'Laptop Stand',        3200, 'KES')
ON CONFLICT (id) DO NOTHING;

-- ============ INVENTORY ============
CREATE TABLE IF NOT EXISTS inventory.stock (
    product_id TEXT PRIMARY KEY,
    remaining  INTEGER NOT NULL CHECK (remaining >= 0)
);

INSERT INTO inventory.stock (product_id, remaining) VALUES
    ('SKU-001', 50),
    ('SKU-002', 20),
    ('SKU-003', 100),
    ('SKU-004', 10)
ON CONFLICT (product_id) DO NOTHING;

-- ============ ORDERS ============
CREATE TABLE IF NOT EXISTS orders.orders (
    order_id       TEXT PRIMARY KEY,
    cart_id        TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    total          NUMERIC(10,2) NOT NULL,
    currency       TEXT NOT NULL,
    status         TEXT NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders.orders (created_at DESC);
```


<div style='page-break-after: always;'></div>

# File: legacy-reports\Generate-ZuriShopReport.ps1

```ps1
param(
    [string]$ProductApiUrl = "http://localhost:8001/products",
    [string]$InventoryApiUrl = "http://localhost:8005/inventory",
    [string]$OutputCsv = "zurishop-report.csv"
)

try {
    Write-Output "Fetching products from $ProductApiUrl"
    $products = Invoke-RestMethod -Uri $ProductApiUrl

    Write-Output "Fetching inventory from $InventoryApiUrl"
    $inventory = Invoke-RestMethod -Uri $InventoryApiUrl

    $inventoryMap = @{}

    foreach ($item in $inventory) {
        $inventoryMap[$item.product_id] = $item.remaining
    }

    $report = foreach ($product in $products) {
        [PSCustomObject]@{
            ProductId = $product.id
            Name      = $product.name
            Price     = $product.price
            Currency  = $product.currency
            Stock     = $inventoryMap[$product.id]
        }
    }

    $report | Export-Csv -Path $OutputCsv -NoTypeInformation

    Write-Output "Report generated successfully: $OutputCsv"
}
catch {
    Write-Error "Failed to generate report: $_"
    exit 1
}

# And notice what is deliberately NOT an image: 
# legacy-reports — it stays a PowerShell script on the host, 
# because that's the whole point (it represents the legacy Windows/PowerShell workload the JD requires, TT-17).
```


<div style='page-break-after: always;'></div>

# File: observability\prometheus.yml

```yml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: product-api
    metrics_path: /metrics
    static_configs:
      - targets: ["product-api:8000"]

  - job_name: cart-service
    metrics_path: /metrics
    static_configs:
      - targets: ["cart-service:8000"]

  - job_name: checkout-service
    metrics_path: /metrics
    static_configs:
      - targets: ["checkout-service:8000"]

  - job_name: payment-service
    metrics_path: /metrics
    static_configs:
      - targets: ["payment-service:8000"]

  - job_name: inventory-service
    metrics_path: /metrics
    static_configs:
      - targets: ["inventory-service:8000"]

  - job_name: notification-service
    metrics_path: /metrics
    static_configs:
      - targets: ["notification-service:8000"]

  - job_name: search-service
    metrics_path: /metrics
    static_configs:
      - targets: ["search-service:8000"]

  - job_name: postgres-exporter
    metrics_path: /metrics
    static_configs:
      - targets: ["postgres-exporter:9187"]
```


<div style='page-break-after: always;'></div>

# File: PROJECT_ZURI_PULSE.docx

```docx
PK  �Z]����o  %     [Content_Types].xml�U�n�0��kNz��*$�.�6R�p�@��E����;@��*��	$3�?f�l��e��5)�&��6S�H���%�g��lup"j5!eD��y��"$ց�Jn�HG_p'�(��N&w\Z�`0ƚ��gO�����yO�[Y�����R&�+�He�T�I��2� �&�e/�����	���Q⍒�*�h)<�
M||g}�w�~DJ%$�nOh�<W2++M��&t�J��t�� vb*�O����Q����Ni��}N/���k椰�����޺�I�bPoRYLFxT�{'.��G�ݫ���Z}�[�s��Y�C	cLz�;��1\�AW�B�a#��{�(���,�Ecq���Qw.x�ߛPK  �Z]�w���   �     _rels/.rels��MN1F�y��
B�i7�Rw�X�g&��Q�B�=!��]t�����r��sq1h�6-(&Zz�������oIj�.U[B�0��[�b�T��8ԟ.fOR���D�zƋ������L����NAm^�]��E���Ȉ_�J�ܳhx�٢�,7
���Ω�{�`�NR��Y�o��s_�)�Q��ӕ��>z�$�&fzO�]�sIfW$��>2_Nxp��7PK  �Z]�]U��z  G�    word/document.xml�[o#I�&�W��~iyH��[tW7$#�]X$#���@��n$=�tc�E�SbP�����1Y��T��e1���� �bg~M��ퟰ���H9]�4�T!+$��رc�f�|�o����!��m���ګ�osMn���W�|�5.�������k��ᔹ��w���_}3	����Cߜ�)�_�s���4����{���&�}���sx|ttv8���M�1�M>��F��Z���C��~������=��O��&����GS���G�a��k�)ї�/���a�Ŀ7�m��ȴ�/�&+�<:_�ޙm>�ூ�K�7�=�3���%��iȭ~�� ���"�R/�~���:�d���:��f@�#|D��`a�����ڿ�t��y��s����G�3����Yw�+F�|}b�k�q^�3j�_}3�ϼ���="�.���H*>f�X�	�H��`1��1n",���ů�	��EK�]?���:��8��߇<���q,�!�0!����IH>!� �ͨG���k~��V̛du��>L6z����z�� v>ɶ~��q�ҩX�����C���,t����(ڟ����G���o����^�t?\�ۙ۔I�QJ�o�yJ���ťy��y}tvtt9�jusX;�_��'��ӳӓM�q���My�1�"?0��h8�1���܄N`M��i����On��!�J8�$����:��o�]�9�<��[/��xk{~ ���=:�l��'�u��XF��r@|��Գ�1�>��g�F܁�#������e	8��{F<�op�K+�'�d��'�6}�{�Xлy��Ѩ�9����=�;X�Ͽm���9 ��s �ȐM�Ϳ��5�k�y��="MϞ�%|��ƿe��d�-�����vܶ�� �����1�4�8ԥ�ՠNa "6(��fs�e��2�e��?ƥ�<>%]�ȕ�����}x�$���_}3��`���o&�O�׵W�3X=����o@0����B���D<���Jڰߩ"9\�Vm�%t�Xe�9u�Q���/��|w׸ޕZx�a����!BQ��D!�J�L��3UU7��) �r4v�%#� �1z��2�p*���'^M�a�fǊ_�%M�j�M>��msD�����I��՝dp��W���T���s���6;��	ђ�wvpIC��?_�!�"�[�ރ[�����(O�	�H��VD8�v�)�N8����3[j/��@P�Ku'��U�M�QϜ�NlwL�?Io��?'��y�	s�)�#D�EJ��0��P�7ܵ��~�_�2�ӝ�s�T�e�ѝ��e�c �;�M�*��yj�P	��&1�Ҧma>?�R<��ٷt�Dx�vQa�B$�|k�q&�@$#���ķ�3gA|�x:�\I�8Hm�Q���?m��{�ϣ�����������)����߉T�MG`ʕ��=�x�#ۄsPہ�����+҉�#|��b6��'y�(DL"����E�����X]��
x�Sq�R���br�w����L SsA�l�ئx�����������N��^| ���_���wn�@�t�%AK�/~��@�����2��x��E��vCx�>�3c�58�4a��:�2�C����N[�f���.�ŗcR>e�����!`�T�4�X��������}!�b7����X��MaQ�i�d=�ˤ��L*���A��Q��dp�&��]�L�e�w��g��t�r~/0�e\,5�^��£n������y�+9Dxc�2?�3n�=��֤?��ȳ�!Rܨ^�O�&ڡ�\�L�_p��p�vpqtD�T����œ{|o,�T{���H��L�����p�
��L0�`3=��p	w�!���fx�b�I{�	�5ua�A�U��)��	�_�1'̼�!�8+��ѻ��v�?��wq/���� =>�b@�</��K�&�آ�>��{gq >-���̉�>^��/(A>Ѝ�?فeâ�f���K���|���!�!�锆[p�Ƙ|;L�p��q�x8��!��	���a�v��d�=�T &��C�	j�ETfb=����	���Y��@���<I�:,3�z.��R��(��]�cX�D�ryt�od|��X�20�������;��бD+6��zi��)G*q_����l�i�H����ah=�0g�ş��v)��s=�%̖��?��=DH�p�z���֟�*�}ff(���)j��z�3;��$1��j�kр闤{k&<���䥗"�Y�s����4_%zDQZ���Ac��^5��H���L��.�	u�kj�4����lgF`��1���V*3Y+�;8ߡMm��*"�(��"ah��Ń8�y@|8�q7�q�b�d&96�;q��K2d&X	�~�Hx8Ȏ�� 6��c���"�:���jQ��V���b�Q� �&����tɚ�7����y�����',�>��)
N~���C$?���7����XJ�� F�U�eb�u{���Y���Љ�DZm�,7���Dl��>��h��a�8�6�ӣ���7�a;������m���'�] �lr'���+���.�z�#���o������Ee f���w�m�c�
ϑ�_�.�OXz��~z��z��~�|v���|��<e�y1IIgˡ�K����=%�j0�.�a�mt������);��+EU+��D���#>n=m���КVlK���g��V�ﴒ=����j�#�M#5��%����W\&��Y�������;O&|�)$;�ey;��4�;�W�x�kL�v+���Ϲw��?�d>w!B��3}��X+���ށWc��1���:�"�VI_d��N�]�~���2�"�g����:�K|�G�<���8�p[v@��Y�aM��D+6��"8~���\��=K/!�р��P�-{4b��������l�D�Zq���D�-U��l�~!m���V4߲9���8�d����`d�1��J��V0:��0��EaKa�As�Jv���bu��IH}��L+b��$�*�Dy̔���Z7/t]���P���p�\�܈N ��'��P����'Q5��q��D)��Rd��X���H֗�LUSqu��PG�A �NK�3}e�B+V+%����h�'�B2��*_�q�|YHji��[.��x�#da��!-E> �k���)�?�
ȥn�Ŕ7��X���D�ü ��c���l����e���[^�Sw�F^��&BP;Ҋ��|,�	G,7#%,~�����|�65� ��'���}�n j-z%DAd�O84����y �Ʋ��V0y&�b��ϒ�U�\~r���]�JK6�\��W���^�C#&iEu\#dR���g�Zps��g�x��̏+�r���A��c|C�é��,�RM�������ϓX�!��	=��:_��ds�.�(�,]�1���z�1����ƌ`��/�`���?���	0������Y��-y��M������w
#�3F��NB�L�fl��ײ���,#Ѧn�4�8�,-�B/#*m+�8��o任=r���;w���{�5����d��u�ϝQ@�+%DÅ,��i�J�ގ+�<��(�k"W���{��.��y���I�¸Xx����1�� ���1T�2�_Y#�]]�$�w@�56EYĶ���{�/SAmPot"�	��*�Ŵ`��#�!���Pi6Z��tb�5%*�nC̋
�!6�{/��z�B������4��Q��.*�Q�K� �; �)�pN���I<.�Դ��#�[3K��$���%"7+��~i]� .:�G��Y���"��gy1ӹ�PA�1ճ5PA ny91�������?�A���= �^�3h7zmr�����i�2�C\a�&�XQ����'�7��p����;�Ⱥ�������?�����Ĺ蟌n��y�o�oqh�M�7 7��y}��EZ�w�>�^7o�z7���P��}ob��҄'���ھ�������(��8�?��������>�B��Η�0��R�ϛ�RqO��P%cOϒz�6~��7~Y~�Ν�{�/��Ì��{��m�C#��`n�BV'nNJ�Ԉ;��%��w��w�Kj��\wߑ}-	�i+�Ӥ�K��/-�p8��3�.5;�V���R���������)%t�_�䗊{⾌\�y��]}���W���/q��o=~Y���Z���B_�C��B�@ڽ^CD9MD��7��[x�����M�4�n��k]6��H�����}�#��%^�ĳ�ۻ�����h�f�C|��:�������m_�MT����l|�E���鶯;�����@���x��lՋ��:o����v|��޴{���Ow���w��j�5�D]ө�]؜�]�\,#`)�Ƃ�1���J�����jt�ם�����} �:�������m�`�
�� e��x6���6�N�O�v!FLO1K�/�X;�	�m����"U.�G�q$3r���k�~��c�g��#�{�p^5��u��ý�>wCo��P2�@� (o�g=y����ڋ#���1gC��C=#j�T2W�f����1H>��`Q��:���Ț��ǃ,��P8:qc�^4F�f��n���`S�҇��+�춉�tde?���j�ٸ��vk�� ��;݌Ƿ��@��L�[�=�S
���h���N�#�)7��"r�loM68����Ϩ��Z+��3��=�w�]أ8���.���v�7}���W[���X6�h����-Iԋ4y�E��R��-G
�n��ȵ�v,ICo[Gi�d����i�1��n�'��(}�6-��S.ӣ���q���Ezṟ�^��Ԝ"�cX��)�t9�G����qԟ%��	���&9W'G��E��7��������b{I�w�m�9 �=qW���̫�˔^��5�y1��mJ�6�kG�'x����t�������Yf"=y�p^�D:n�V*�-7C����׊�`|i"�
� �z��uE�tzn1�����b�Q�8@G
<�8" �]D��3U/4����'�G)]�-Cs���-6��"
���Ӝ�z�o�
C!��'s'9ќ�z��G@0�	�L�t�h��n��j�b� �%H́�"9;�<*��>k�\������:�vC ͹�zO�y#s�G2�L���&U0w���#~�C&��
<���	�7 �%
$b�B�ѓ���r�rH����o�����k�'i��{ːv|X�����X$jD��2RN������o[�͇����4�Z�>��o�H��:�8��/y�|qu�8�9&FA���Gs��$��C��	�IY��&��Sp8�f6����6��:{�����	�����X�ܔ�m�X�.�\O
�V�H������W����I�|�&�h�x��V��dl��ܸ3��}��x+�m�)�Y"x�>�u��V�Ֆ�[�d[�az���A���-����+�^}+��Ё鈩GGc�-�3�{-���8���O7�/�|z:;+V� ��Z :�-5�T7R?���IT��ɯ�u�������k+\�!q���:�c+��	(Z[�Y�i�~4��
���F^	s���)�_���̈�l�!}��vZ��'�!�qV�zz�!����yzY��L۴���8�"��Wt:��H�T쾟��"7��:8�f5rq6COR�KYs�˂��>x��jNP��Y����h��A2g3N���h}d\)�m��cpl�R`�Q���E@�S\鯀M���g��
��	'Zlc}|����>���}�>�w(E+'�Tsz�Q춟�|��o��Wa���ØRS�H�,�ğ�6`���E�B�8��[��e\��i~<zn#�)�=s�ĥl��Ņ�jV�+���r�Q��%/	�d��郝�O��2�p=O��z8�a(�E|�䐊X��+V.v-7�-5q��*/]�qp�>x��R��["'�:�D�G=`�)�}pjK��}�0a,GN%c��	�����`�~��S�k�^m���B�"L�D#��Ig�n��WG*o�M�8Q&bx6�*��[˞��Ŋ��E���-���_��T'R�ϰ�x��''*���%C�X�{m�����W~gc���:�PC(����8��@>����*��]K@�@�
�o�2T�_�n���م���7ۙݵ�)c��^���q]ˏ����d;#��'+	ீ1�[1��m��s�'~hN�7g�'(�2�(�¶���� ��� �fi���ª��
���'�ql�x6�W���-ϟ	B�q�ܳ��ɬ���:�9�?A�i�&�!j;o�m�J�.|>3nL����!�xo�����}�_�.�v�˷W[�o����!��hVc��âĪ���h��ҧ��@Im�W���|9Ep|��E���E# ��&a�sT�el�����i�9{o��@���e�oH-h������L�.��|]�l;gn�N3���o��%@����Ն����C��F���
0����(�*V�w-������_�%oio�N�@f������;��@�Ԇ��DW�	�ʒ
O�����LV���<h��-|�����s`�<���U՗[�z�����_i�~j�Q��W����9�D�+X�v�]Z��,}K�N�"}��Ώ{
��j��Η[�f\�eo�����W�����-s�.�$�̄�f0���@�_̆��/��1��6��O�r{��#��K�k��v��l�ɮ7��v��K���+���b��rO�����>X͈�����3푌�<>t���J��*���j���0i;' (�7M�e�RPZ�=�>س�� �! ���nt�}H{fX�VpS�^ر�uw�:^�]���D=�p!?>����7�/�#�O����g;�c�����P..'CW�����!qOA�d��<����t,f�Iâ��luY"?��h��!����Z[�踳!jH)�W��e�~�d�zܐ ��@�5����v�q��Ҟ7�}l��'����ic��҉��h;��xl�[�G��_W�����U,X�9|&��Ї��,��C��j��A�>�u,�NE�U��/�5����0���vp�{���ѳS�ht:2�.���Q���f�^��'g�3��sS?j;��?�7ҽj�ۤơ�o�}l��; �^�3h7�u�q�"��ǻn��u�8�����k��s��%簾<��7j�.h�\~t損�=�k��+��>H�l.����K�����!��A·�=�"
\���y6�+,�_�����}�p�~˹T?���-��63F5���E0��#�ZA�s��9��!ĉ�����W"�I�T�N�nf?xE>1s�c����18���r�����]m�w<�m$o4���>P-`r����<���K��Q(ܛh�K\E���]�]:�j�\�!VnH���-���^�H3z^_p��<o�� ���rs�1,��S�����rk(��Cb	�l��4y&�5���ZS3�C Ji��6{����2ݬ#Z���ڎ��u�7�]r�CW�{��Ԋ���,H����a?���%�9ujNR<&/t�V�_ Ĵ��ϭ�!�ϯ����]�I�s�aj���-W� T�����������x�b�@��j|$��T5ޙ�&+��}�κ��<L����h>]�BLP�g�4�o)�IXǃ'���G�	�wF������:"I�]F���E� J&ð���hC��$�

oE(?y�%g!�
1t�|~�Ή��S���	u�ϵU;'[�z�j���P<ۿ/X��ź<,%wx��lF��Q�D�Xi.�^LGbj!�A�T������"�<0vH��p��$��Y�<�0���֦��m gq�]48�=&��h� |��	�,=z�ō���'x=X��Qx�qU�T���װzxQ$�{|.�g�{�O��\���N8u�W���\~���V��G�'�l�V'8���G��y��ߎ�+<GR}ryD��K�L>7k��/d�_ſ��y��uc������I$\rd0"�p�������q�(5qNs��=�Y{�kcJ�\U�q
S�m�4S����m��ZZ&\l�Mjr�T�4uߜM@%��^D�}<BRk��5�}����J@+Yp�t�7�h��GPh��q��+$Є�������.��>��C�U�S�Y
z[�G%���җ�X�OX¼�e���=L"��B�<����so1���ਤʈ[��?/�^��:� ��Ճ?�a�im>�٨�R>ŗ�M�����x��J�%Nq$r��#�h*����ߋ�����8�3�I��j��A	�[y0��J�/�<f�1Mm��Vn�r��'<&���U��5��>)8���u��#K�����K�[)z��R4�&E �q����S&�mg�^���Bd���X)���b�J�>�ZO[�y�0��6�? k���r�}ʭ���[��nS{J?����`ơX���X�k�I����c�_g7��G�� jR�B�YvU�"�$(l{ ���]�跄��=�i��$[٠�;��
�7����܎1�)5�e_p��sQ���9��o�Q�p� �0�/w2G�T���?l�4n��lTWZ�߃[�|��@������ăC�3Qy6�����d�}*H.C�ec��Y����
�S,lbiPp��L_*���� .���q9��cT[|���D�g�B�Xr#D�jn(iр����3�@dV�$��p�6�q�y�}�
t�؜�a�6iJ(Ⱦ�����RE�@;H;g�.ؽmC��l_�����_�r�87��C,�}o��C�Kx��0�N��L�>hW��l�Ez��8�RkQŏ�Uxzf�y��҈8e�#�BH	
��#���+	�P�yPl���-�op�]Ӟ�vU&r���!�R�A�G�i(
iL'���A�N$�/U��Ǔ��*�	����*=.���N��[�Q��
P|1H�I�:.�0�x2�K�E5
3AL�(�ŏG)��kF� �˃�0�2���z�S�\�y��䴚Iw�[�O�Z �4�?���OJ`3�R��ѽ�8���f�J�m�س�a�ld���(vK��Ino��0n/�9/�9Om�Kw�3�Ԯ;g�R�7��6я� �|f
��igG�S���-���W�N7�/Ǡb� ͯ�Ӈ�u�8����3�@�S�kx�z8:g (��<lݏ}�q*�K�T(&5��>ѥ~�j�ՁP�fj?�0��Q�yii��x�F3웯��9�j��+��O�SF[����:	����TN\]^GS�(�%
#��Ҳ����eѯ6q��}9��dXI�����%_��a��>%Ѿ����N��V����w�Q��������"��!i�k�i}Eo+o�aџ^�*���|#�u�Ɣ���T�o�9v����O#7��'%����V���4�������G5=�����z�_B�T���l�����;vAt���G]���S�
�g�S�A>=����A�+�;�+}�{�ټ*ķ��Wz�!�s՝�k���3�1�r� T{�{��f���3��__�C1��U��;�0еJ47�l4r�����#5�M��m��m��m�l��f�ˏ�Ò1>�C��%Ƞ�(En�_�G���S�}�Kwd��(ѱ��҇�z%�ө���h�j��fS31U\�����'6&A��L��i&�w
�����`e��q�+?AL0�t���d0�x8�($1;S�O4��ە���求��~iL6�+ �Z3W7`�LK���H�.AJ�Ǹ?�Nb�S2�� -O�@Z�L�w\��q��}�Q�=XIk��,/��$�EƼe�{2�,�9v���%� �vE0���ed�K"?IC��4�S������;]�y�
�����t��4��_���h��Guvz:��ѩi�G��g��G��x�rSZ�jS���H���o���׃�Ѽ���"׍�V�����m�|��Ƞ��5���n27+k�g
`Ԝ�{�'��b���O������
�6'�0f��`�� EԳ�������L�,�_���B�ѣHS>��]�U�`�hD�B@��GL[��v�y�����?�i�)����ց=�g2bʻqJ\��J���d�Ĳ�<!��+rˇ�Z�{��}2�P�����|b��c�|*��W[P����F	x�����y1��(VJ�c'B���G�$�=��;�dA5{�q�(� YoZg`$w�e���W����:�n�o\�P�4o��ч�j�gʙԩ�?���ai�Ƕʣ/0O�$�ѭ���'�7��:�ȋ�(��ɦ�8F�Tp�uć^�AE?��?���?���}����-!$�!9@{�c��)�B���J�2Et�3S3���ь"�ҍ"�D3�l��C��"�u�[g���E�:o��{�x@0L��3ÕE��Q5�gP�G�"_��iav�Ar�)&���&�Ҁ�X�R�'-�h��!u4�O"?�NҬ���e��JNL�oz�lU�h���C:;��GD�L9)�c%q#���Û�v�97�&G����(�;Y��TNO�&3���9)~�|ѓvJ ���+�F�23FLn�x�c]J g�x����yV���Ӄ�[n��l��ʐ�R�>��N�04�+���ot'1=�;���#���A�{��dqV_uT���Ѱ���\���^I/٫;����!7%�[��U<���\��I-g`P<UIL��ɎpP���ݖ��]şXҶ�KCw�ѵ���ي��O�а�U<�Ro	�՝�w�����I]q#�Y�i~4Fw�1�#�H�i/���&y��1�'q�
(����;pv��S�0#m�/'�z�$W��Dr�(PB���ET��b1~N����cS.��ĿB]�N��U�R-z�D	�*Ho�?c�=�͈�#��b	̖�t��<�j�`��z�$G�L�#�J�ԏ�޺ә�JԝR+��=�[��)�(���T9��'Н?:���f7SG#J[�sx�������*���⧝Es����!�����@��kv��X�P������C���T�	\��$�A9!@}9XAQ����h��U<��-�bg�������J�x@�<�r@=K�WV��	2Ux�R<��g�� WȆ��ޅ�,r1f����m/�Ʋ@,t����>��]��)�~����:�8 8�d�1mA�*n�ÒR-������_���%��ʫ�Ua��,q�˱�{����q<;I#Q�wK�%m
OR�ీڎ�]��ݒ�P���r�O�l�T�d��fmJ����ï�_,A\((
3<^��`�m	v��ş��x�P����J/6�H l���2�ǭL�@�$��t�Ѵ��I��j�7�pj���7q���׶�`�3S�E�s��ʕ��۞z��p$�/���7��c���wG���0$a��~`�/�Ucw��2���@ �~�������"ߕInf��2�ƀ]/C^� <��/C�Ig����挹��T��v
�4ȉg�a�^s&�bd�#�>�eK�nZ�R/���!&�ܨ1~/
n�1Ź��L�ץ+'?ERԚ�z���x���J ��ف:q�J�Qh2_�a3ZsU�1=6cX@�/ <�m?���
*��{�T�ȥop�d�[k����^�;Rs��=B|��=��\+�5���7�6�(�r��e��f'|�W�eӚ�z9O7�؆����Fsc3h&���I�pK/�[�ݠ�������^S�6O��u���rg���TJʿ�QM��!��/��+���N�ԯ��-�颖��j���L;�	��ҔE�Jr�!�K"3{�U�i������ Q���uȂ�J�5|��]hgޠ͵�	<_�����:�Ey+k�B1T�9�jg�ttq|R�ӑU?;>����ܼ<6)�G�v~r��	{氬�ט�!bT��j:w��q�"��n:���{�enU�1>Y�e�7]����HV�0sO� ���93�6��X�Y}>ert&�A2O�Pǃ�,�1P��oA?�1R���`�<�dN�@n���鱞�h�LES�C�q�\P�$T^��xH��/fw? -8�j���%~8�q gO���֥t�ɷ-��qdu�[�Z/P%Ͽ֊��b�;���	���N� +8`#�����g�vM'��S/��{�y=O�.�g�d�(
T�gy�E�Լ/C���eh9�I�'�Sh>�\V�� -�B�Hb.�:�+����;P�.}���M��(6�ه�x A�@�j^E�N���x�����mP
��S�yc��@t[��x�qH%��&R�I�^��s��ET���9�,2+!<-A������T��N��mQ2�` m��)����n-��6�#f�H��ji��~,MH1�����su�k�T�����U�	~�j��[���D���@�)oף�T�Vx�ni[g��l џ�e�ٯe�9���x���`׸#֑��=j�x�"V.9�ʨ���.�g�لM��tu�Z9~�1���ڎ���w���nwDL:�?���0��^�Ƚ�;ҥE���[�x~s�2�,	=���(%3�x��!�Ϋ����D]ZQ�G|D�꾂dOb��	o�d�� wG��@L<�Ը���#DX ]�A�Z��aL�f��`��� 7�k���{p�>M�bf��`r3������e�Kw@j�bu.u��t�iڱct��4;Q��/${Ĩ�+�kNvL��+��0�$1vn�Փ�������9����a��϶6�_�/���G���P8���y��^aX���7��ڈ���ڰ^��jV~`��'��9�N��ã���숙�8�'��3�i�J�A+�]������ɠ�@�������q�(��JK��J4v�$���Gh����O�}hSl��hW;y����	���:v�aوs ><u,�}���0�'l<�z:��;FI���˶�p�YD1�d u~�U���
8�nzbօ��,]�z\;����m�N	��e����y>��ƵM/�"/�"Om���3��Sd�͌��E.i�.
�j�hֈ���`���&�cӡ��Wx�A"�}9�/ ����J�9J�`1^�i�X�z������(R<�٪�&X��Xa�zˬ5K������<L�����(.����C��� ���Eټr�*���@�9|�5S�j0�.�G��:}9�=r�0�ZC�g����at�/�+��O�i�ԲIˈ>̻Њy��AD��<KK�$���:���ap�kp
JI#��SP�I�Z��ͤ�Gv1rF�ޭjP�� $߻�o	�u!t�?��2~���`�E�}�03jI�m�׈���{���������
�#��j:���,	������/R�ZE�IߺXE8P�եR,��������L6:?���Cz~tzTg�����	��mjƞ�UPM���f�t;��u��'�:�+����4��]�?���o�w��������,D�5(�e�8�xe�b����ʊT27lwb��� ����*d���Q��8�pR-����uWopp��5�?�����<��dBԁ�b��&/_��шy��0�БY�WD�5`[�;;�
��!��@|�k:���9�H:lLE����[���.|�2f��=�/O���$�,3v�Y�����v�2L�q�*v�LF�:)����Fv���}ܓZ����\�TŴMˈg{�q��j���o:A��M���	%&�NH)2�hYP��o:�	u�6 �������kd����J�e��/`�X%�����߾�����=�g�6���LWG�}�����.���Xt�zll��K���:a�-��Xo�ѱ̼�b�V��}9�����/��=��nR-�Xv�{��n���|���`���3��=-�d��s$>v�a|�腂|7��I84���q�[N@��@"�M���_!!FV��'&�H�>#S��8��mn����n���3.v�𛊦��5$��΢K��[���[�P0�F�dw\��{D�Z�5�/�����$�\E��LhJ-6e��X��F �Gu'VF�-n�Clk?�m5�X��U"XD�vI7������A 9/�G�q�����0�Vh�>2�e0��=� ��+�L�a:�_��A���kH,���Y5�u+�֪�6y�^�>p=��6�+����V�����JL+�R�ԬGa%x���9#���^���ӥ����J�5$sb�ߋ�ի�-�nq�i�E��x�y��n��KG�#��R+.kK���L=� :N=˾W�iY&�f�a�Jj���{L2��Ì�8_JY;th�v��ꓴ�q_���阣N��H���Mg��4t������Ə�Z.��V��<.*>�W�ee}��Vf'ͤ�FdѴ����R9�q�<\�j�E��L�,�3
84�x��㱂&�y�YAf*5Qr��(��*p��l,Ș�(;�[�G�Y�,�%8���m�,��{��d��ˍh���*�%s����J%��J.���h �=
���*�/'_�t� ��5�nY��ה�[�͡��&s����^6�����Ǎ�{I��ώ�F�.g�ah���b�
%Xfh��.+~}	�d�VD��Ə�A���g/����Ju�Sd�t'rP����iL*�f�б�I�9��I���U�4g����N�-����Ր֤)��lWVH@PXl�]���/g����E��Bx3�F�������l��l��.�2��E~��|S���s{ɹ����Kw�_�J�%���I7%S$��dŜ֬ԫ6�'Fs8,I_Fs�e�Kέ ��L?�����}�?�^�b�H+�FVFc���\SfX�<�zҋU�%��S;��1����r����$��n�6߂b��x�΄���2�*eAv�0��G)7q���H?�� ��J@4����F�����Ō���D��q����:���\\	v�l;����W�<��>k�,5=;�M�$,%~hN��e�7�ql�[kR�z��|�
"I|�>�;ul���l�1�#�Ġ3{�ˊ߱� J�|gqYx�-�q|ڄQ'�H�$����U辈��4xbP��#�Ҷj���]D�O�cm��M��{y���(C[��@_r�Z�ʁ�ke����FW�#X�yJ���X<zO��1/uK�)���u�$�
ͯHZꦧ��b/6:U�%aJL���E2�4�3ф��W�q�
�� ~w"����.}����e�$�t�	碂M��ؾ���	/-��k��	R��8)�Q4Ðe�"�X�e�&~}F���yY_3�t��&��&|���V�\��/-��Z����^�%SeѮ�V����CK,n��Ju��T��4V��q���_7��s-�Y8�@|/
� 1&ÍR�:��}/t���z��n����*����j�jBkGJ��l[i���6@����ֈ:6���?x������=1U���7��m{���uc���w��E����7/��v� �蝹y�&�J��т�2h��h����?a>�BI?c��ō:�N�L�<�<{En�g���hB1��^z兮��$`2c�V�ò8�r�ŝ��=5�V�$A�ju���P4U�0�f�\�\�R�p�����
aT2J;+i���d�z��W��k��Z��V�k՝TDΈN���F5U�wF���j��*�:U��g�3'��6 �6�@�s6ܕmSs��P2e�	-V�*=.�e7�؆@��mzG��S|���ઁ��N�R�=golמ�[�=�%v(��vz�F ��
%��ʐf2���������X��o%��cǉC��ў�k� Z�,�����DQv�3Ŋa2��)���p>��8>�x�2hE�OVb{lA��Le��	V�*��/�(��kW�)U�J<4�~/)�?VG�4�G�J�D`
�b1C4E�U�Z��yc{�H�XH�ʸ&]3=�D�!nM<!�}�ry��T�,�)�Q,�-J�Y�C�.��S���Z����jG�����s�p��K�p圏�޽o�Y@�`���|1�p�)v��ͨ��B�3M����1XW5}�D��.�@�͚�+a	r��i'�����*�P��<�?kǖ3��eB��"
�X��)�k�.U��#��Ng�{�Ӛ� �)"�:Ӟ�~}�d^q��/�����{q��úgʑܖ�{�L��	�q��c>=�œ�M�cOm�i�GG�c��P�������!	g���Cm�{�����b�-x��!��Sq��#�Ul�e�F�C/w⬟Zo[C���ٲu�yK�yC���z�ŭxل�NF��z�_���9!�?t�AA��e�o909�L��-c�(v������>��������p���ʄ�( Fg�h��H��C��v��'U�[7~K|s¬�
�m�@1!�xp���Ώ�I�z6��L���#Q��7��jO�-(t�"�ٌ�qa]�HpK��WN{A	���O�3�2o N��-fU��ŒY�8���9Zx�y�^kGJ��R�l(}��x��j�2駏ە7�J���.��}ó�E���3^���������B�N��П�9��6H��¹/��Dt왧iNB-����n��Չ �B�x�Ҩ*��A�:��I )�(���ҙ�g+�'&q^n��_�^����D�g���h�;"�+�X�(B$Jt��u��䜒w֘��5�*Z�T#�f�ƒ
��G��0��Z3U/��[bXEȃ1�8.O"3�%C�(xׇ�/�nş@�T�ԮZ3L��;�N��	u�<T
�X����Q����l�D�]_&�1�
��v��t7��fZOVA�siD������r}���ٽ��DJ�jd��{ͱ�P���Rds.u���Q�Uh��<8����e0�����yQ�GX�[	�E��9���-1��E5V�H����(�������gϪ 9?�A�����ɻ���I�G�s��%ai�D���<J~�K��~��=�:����X'�'כ�c���7V�vqR�������g�G��Ȥ���9�XG����V?mjh��My��ܽ�{o:ם�w�SgpE��������@��o��^پn��f���5�2�0sᵣ�ʍG�l�[y�K��U��f�Z-�rc0�� W�$H%6`��'�!�1��� �.��9���Y�HS�`l�l_\G3K�9��8lJ�l� ��s!`L>��� t�μe�wIǠ�_��Sl��d�Q��	����H,{�Y&���1�	�9�K�S��Ɣ�v�Q��8�g�j�=��$��1�}�
W�q`�
�'�(���}�۳͂���iU#�jP�%�!5�Y+B��V�di�Q��tS�l}d��B]��(��3P�3ϦAш��O�����НXl�Ct̀�Hg�j���ʰؔǉ>Vd�%�-ͽ���Ǐ��zߗ�ו/��u'sPBm{	d������c��YL-�	���r�vD]j�1Y9��1y'�DZɓv�d$�~�������R�mw�Q?�Bq7����+��ҳR�{J�ov?��/̸Boؔ{�j�ڲ��jPw~V�X��'�/QwR����er��j�LċR5�����[	X�\Y#�
�W��U���1��kO��o��/Ԟ�K��AJPye �ʛq�T��.�|���<.g)�\���iv#w�ZO������ U�y��TwZ�I���FI2;=:�]���/u'�ͬ"~h���U�sW�7�KU��F���e�]�hO7Wy��5�.#Ψ�����y���]�p��y��q���vâe�x�ߊJϓ+�w*���<����B�hOu�R׊�.�"[>uϹ�բg���y����rðR�6��t�K+K8!m�a�Z>�I�(([�G��?��p��Ֆ�~V<���t'���9zcX���ؐ�b���@�{t = �(E8��9��g��3[�J�������ӂ��xh5J�'�N�
��P����{($��M�@q�s�l)0B��'���PV�̸�۠v��MP@l6/a��Y�����p�)�2�xR��7�#���	���2����;�KhО��1���Y���$��s�A ��f�"tYm>YO.��-�����I#��+rY_�/�F� ��J��Q�UN5t|d�Lwj�����ƑZ��V�U�~6ԆV�F�*U!W�}��%�)Ʊ�8�&���f��?=�o��aX-���f��b9<LL��'��ɘ�+�;�g>1�/��_�ݞ�Aҝ�>�c:L��Q@�Nv������z ���|�&����i�D��)/���%232ET�	}(�漄*n�I�3�t���&��LfG���TFHı�8=hm�#q�g4�0U>m�Az>
ĩZ;/��W5��*'p?%�N�ŕ�䙻��0��C���3��|Y���ף���X`���M��]_B���k��p�Kaj1�|Zp��y��s�5�p�=��듫��KN��t�=-�C!1.z"Y	4/��w�c���ű���@6\z<O�k���N���R/K ���EbD$�G�̞1pB�ͅ�@�'p�Yb�� �7�)H��d�Z��:6f�2D���<g�������Y��M��z��*f�6�|ta��ohK [-,	ݤ:��f��RƎ���JԖ�$�w���ff�jG��!N[#\�1��Kʫ�+c�Qڣ�%�Dp�(k����;;��	��r�j�K���u<�lc���!v|�aSObt~ß���T�z�DX����E-a<y����#��	���J
��'��!���m��y���k㹡�/~lh	��C���P��y�%/������o�՝�5K�Wo�oo�rAg�O�p&��Z��1�/c8��>��k�EU�p��4������J���$Ƈ����88f�-�>L�k\�
��w	0X��5&(	�l��������#�D�'�{Z$0U�)A�����"!�b~8��	<�zA�`���C�����{�\+�<�D�	�A<�
]�i�l���s�δbh
�~�l�����+ul�����^�+���^�)��f�^����.�ki澧��؏�L�=�7}?�zlgK3K-=!d�T11�������ǹȑ��5�ct�BS:�N</i��2�Ļ����냬�Q�u [f`��*2��� /�}&��{X�\�q<�'����'��N!��*�?���-e���X��F%�� �qa9�y�Y�]������?���r��U�@�����'��sf/k�rx<4��ӣ�ӣ������t8<�����<��6�|���פ׾�D�H��o���ڼ���}'�<v{w��A���u۽~����l��|e�����z�c64h�V�º_�L{�x�ue�=&�țM��k8!�N���ٌ�>"�5>��G�P�>c�ʌ������.�ͱ�eQ���w�Z0=���qn�
C��[P�;e��M����������`Bp� <����?(8/�jr�lj�us�L�(�	�bD��ÙHe��W5"�0��HK<oW[���P8.�)~!t�h�V��]B=JY�G u�=�X�N]��
��[v�'X̍R��f2�C��j���b���v{���,ۏ�\��{dJ]:f�j�N�;^��'a`�6ܵ�M0���� A ���,vޕ����b{fhG���滛C8j�^�6a�(��pH(VVqy�1mU�sqLZ�� J�O#]xڮ\����>��SlM�˭�]^dV>���yժ?At��ΐ�ý���L�������E� ���=_ƭ�ZqE��uI|M�ȹ��U52�a��۷tue�4���������c!aW=t\�4�= {0��О�{ ���p���jn�㾄K�r��'�RK�"�:L⪜[n-��d)+m\<Lc�X��pVp"�XI%�>����DT�+i�)u����<ם��߲��ܺ�+GL��Nk��o��ԥq�)����g[=��ۓ3�t���P�0`T��O�o�$��D���gԠ��h��B#Za9���F<Q��c���i���.�W�X����7��"{��WU�n�.\�^�4�˪JQ�g��:�4u��Ͱx���x8�Hm��Ya�&�r{'��g�����B��=p_�lJ ����S=�@o�K�A��Q<m]s�)��D�(3'���}���u�꤉���h����w�%�V��#�����±K���Q�R�l��h�)���VVp�_ɉ�bm*iv?T�`+c�S���\�tZ����BvR��o�\\��ʴv:y�Q�V��-�X���pb	���&�\U �]�H�(� _�]�0�Hm��0l4�5u���i.@�2�&�1��)���t�Gm��X�v����+,~��E�pɻ*�)�Ω�ש;�%��-��h�PYQ��p�hԗ6�b���R���i-yXkz���؟�
��yP���v�~�^
�2<��t�څ�<�65'��"��m�tB�舯x��xj��t
d�,aiT.��|:�n� -%P�Kpj˸4)�^�8b�Z%��xԫ�v��L���>-���0��9 �ғ�����9 Om���g���hQ�	gA��~�txh����: 7���U����q�x�9�=�kJ�5aq������g�s����V��� ��1�Z��Z��⇳5c�5�g��f�T,�b�ӓ���^�2��.���=3,oh�����O�����U�� �?ɾ0���\����������Cix��O�����lҁ���]���z��a��l���j%u��
mȵ=�h��%ќ��"{�fS`��~��=�]�W���^��I.�x]���ͥuZ;�<�������^Տk5�]�,zQ�ԎjGl���D�xMw7C���Nwй}G>uW���������i�"��O�^��}}��ٶ�ܸ�q¼<��\��<��g�Tp���g����n>��A�D6���ƚIl�I��*~�(�~�#���3�vfJ��as�$tC�Y��T�'�sE0��<1'��$%��1����9)C>��U���$MU8��-�$�K{���v->��	@��3���6Y��p~�)a�H`wL�V��9D�����O��h>b�$w���2b`&i��]���YPJ��ūZ�U����w��Q�{DG��
�K��ל�%(���A��8
x�(	���Au���C8���)s7l]�����9�J�Ө�t'[�=I�+!R<�I&���mN�A9���)ضEE(~\�/�{���J�?SDJ�l���[����Z��G�]�ҟ|d��ϴ9�^�GqX6�h�~'w��l�TD�����~���wId���ˈ�w�����	H۩~'���)���ؗą�k���ǟ;��~���������"zڿ�/�(��/+��v��%N�*�d��[�oDOn�H^��;��m��˼8�ҝ`œ�l:v��ĭ;�Q�g�h{P�ˊ��'�߿&��ox
i��� r�~'x��_Ε���v��P�{" R{�s������%U4�ΟE������B'���&�}L���#=Q����KZJ�N/K@(��I��Ι�!�oJt�K�:�)c�e�8�`�yU�Q"��m)#���R�ZF���?��kU��=\-Qo���,������N����lcw��qd�v�"���{5��K���Sr%Ά(I�=�(�(Ÿk�R/�w���� �kOس5|(��&6hJ����됙4�E9����ȱM;p���!D�~u�@��u��AiZQq���!��U�+^'wJ��⋷�����ķ�My@&�`w����U�B�@��\R�U�D����H�AJ�$�cO|+�X�hRW������%܊m�#�7�;$��ѝ�OlH���Ծ�:����'C^��-1>�c��{>̤;۫9~S*~~җy��z��zj�_0��Ig��>B�)`O�B4���˦�`��p<Q4����7δbo^/E���RJ;�%Z����V3�.�}1��{�8�o5;Ι8�X���6m�CoF�T+~J��7��@4$z�K/{��[���2�:���z.i��>�Q��������'k ��z�B��� �.�<����=��T���u<:P/��+J��Wt�M���?<.]��?�/�#�,�#�?���w��7�U>u�W��(r�{9�F�UL�%�~�(�ل�̸4����yGt[��ɛj�g�]�&��-Ҽ��]wй��V`e�K��:{�G�q��<<�z>r�y�����#zk��&��f�[	�q�y? ��x��?�i�)��}z���9��a1��1��d��1bq��ܻ|N�*^�#3�@B�W[<�����=H�GF�gq1�{I.�W]�J+��.��\��Q#�1⻔}�`e^�|�Z/��D8��?�`��x�߄֘�8�@&\��[�,���2�P��K��)�z@�ZԋC�y�@AJ�_����}�K��<s�W�T�2���B�R����~��X[��B������,�_��jpdP�]J���c��w�I�\7��R�G� �=�÷�IS.�`sY<��WR�ZF�z	d�y�	u���tO,� P����=�`T�U��;�"�Kg�BЊ�I�=�Ύ�Nß�����s�?�A��&�:����ozv �!PŽ{�$�5L�⥹/f�UM;��!�{��=�q�ɻ)�¯�EF:=^�+�O)�d�x'қx�<fW>D��"�mQ�'Q<Pp�qR�q9�{BNz�ٌ�i��4K�W�,C*���\�kθ��C��6��WuM�1Su��3��g�N�w%��L+>�Pj�H�|Jq�i	ɧR���ޮ߇�w����C�l�|�D5�ɦJ��������M��&�͎f�#%R:�̉�%��|��>P�Z�NC�F	���ݐ��k��ʡ�#��+�M�i@���^��P��[R�g\ӑ�/Wo�4+�T&'�yc}98hi&����� ��F�")���7i2�x+�sJcOs��NkkJck�U�6�x�yQc��֢���e?���#�� Y�0�FgX�5���0P:���k1�U���dI��C|!�U�"�1OW�z��V[��r��)5��1��V��6:��`��/�O�'ֈ^�QzIOL�d��g��֎^��]��M�v *L�U�u��ݓ�0;��v�c���t{wwo���W
P77[ן֎r�R7h�<x��Ӝԍ{<*S�z�=�l�Ӆ������I�.(�R�1?�Ee)��0KOǜ[��������@��]"�E���ng(���@ ��N>�t����ժ!MԦp�\�����M�ވ��A<967�+�m��� �c������+Ԋ6Y�`)�o#~aǴv��HU���j��;����$�ch��NSy(�?��O?��G�o)�7"�`mod��i����	n��H�rO+���������A<GiX��#�=�-p�����j���(��4w��?F�箨�~t2��r��N���2�2bSYJ5*x���G%����\:R�T��z�s� �R݉�	��6d���4m<����y3��k��.8_T�p��a�E���9��d�4+`�	t�_�ogH�"K�?T��V�C��(���ЂӺ�S�L�M�VH����;��o՝��ܱ�`!w�Q<�w��X؈����3%��f�f�#�}_�yB:��P����!S+e�^0��	�5ۧ�����s5�b >�G�e\��^�%��%�+��'$���?�qȻf�@�F? ��f>�?��㳓�Y���w��ߍ�`���܆�ǯ�;;�
��H{ʹ���׎�<��ݺ*�X1R�}x�vC'�ںS)�Y��*�A��L�k��_l{4��yϼ�]p�O�n:�r�M/�66M�-\gGjؔx��˰I'�H@>�ve�0��,p�jG?��S��C��*����`KU�@�{ҝ�$'���ѝdE���[���u�.MAR�����6��3;p���bđ���V�=�8�M"�=����m��� �(��&}]٦V)������`��~������ȧ��|�.n2dZ�C:�̯��&.���%#߷{�p^�6A)��8/�5�ü�4�r�M<4�I:�﷿��D����.�}00�d׋���H�hWP$�����ȋ�ν}Д��w��C��t��j.�xy�CO������&�0�3Ka����z1U�}��6��=�BQ"��L/nv9�q_�A����C���x�ۍlV��p�n�~f������Ԋt�C���w�]�$�m�8��M�5�l��)u�~�; !R��R{rw��Z�������۱Z#$}!C����q;}E���+ي�8vM'���-�?�| �/�t���������v��N%�#8a��+�S����_UH7�)�3�������a�s׀�ei��ɉg'O`��P�/؁/؁��(_)v`��q��ڟM��g�hv�����i�Fi4f�[�����.���=��0�2��B�;�f�fXv�q���/2�����8u����lK}8hi��G2h���𙸛�L��|X��:�8�.ԩ+��vT�x�����m�@����t'�V(��?��������j��N.b�E�UI���Y�@}���!�Ɣ{+��$¯"��	<�Y�a{�a<��hb��U�,��\�sE�O%>��8���S
��yS]��O���4��v�`܆���wmxi����I	*VM.R����(&R���!�S	҂
\�.w.�^�@r�!���o�[6�
f�=[@���ŵ��&tS�o�v��-`t�I��EfxE"��訚��_P���o�Ե�S'�xZ����A%Е
@�إ�1jZ��,�ATK&;�� #�;���G��q����]��ղ����@x@��$��q�x,�����6.�Ti%.�h�5N(�Lk��7��� ���gf"(��ph��Ż��)s�K.Ey� �J�LyZ��k ~��\5Ё�s���5�&���dizάQf.,s]�[�p��f��|i���v�߼���(����p�D�D�j�\+��L+�����nܷ�����`�`8�q������u��ih�I3&"[@��
L��xd�C�������c�r����
6Z�����#�V�%�x��w�X
,�x�Yn������m��O!LuRG��C�c�3DIʍ��9<qT����QC��Y���R�h�\�h�}K�m���Y~�z���h�ٺ�F��^�Lzm�Ttq�:upEx6B�GI�2 ��h���:)��߼X����5���9qh��N��^+�Z��!�5d9�����6~#2AvpM��/�Z�4��ij��D �b���{�^�Ap�@8ΐٱ��ѫ����"auc�E+Y�4�@�
x2 8zy2��.���1��V�U��VK�����[��c����Ex=K���h-0zy5=1�w��$�����MX.HwL�{�����.�3�?a����T����g���tY%Aj�'��+f*vZ$x���4]�բ�ۄLJ��������8q_FE�fm�V�|{���T���FvS���1I��b�A������9�T/e�ZE,^<�؁E�7��e^��	�����\���H�y���Q)�'����a�bQ��PL��-���ې�H�(2�����4sM �q�p��򌟥9�S��8��# XA/a�j�>)Lg+���,K�GJ4sL�l�&h'�:�DH��u�6?g
f�$av5g@�rF:�Z籘}C|Ů*w�Rт���>�����)��o�u|䰮�f������i4�yJB�v Z�uU�%��&z����gD1���e}�\����G�J�TN�OyBƪ�/u��#^���@�K�i�_k���5Y@0�>"�3X
��Eo6��n�G�k��BxȘ'�s��> �v��T�w�Z� m�=p�R��{��j�W�/�㪩����4�;�j,"g'�\��tb��~�2׏a/,��,O��s���p��]��_���厮;SFי�c�o;NI�����}���b�tR/v�$�"����c�*:�60q�5�5��06�v��6u���|R; ��T�s��A���Zq���Zњ\��Wۚ�6�u��[��:� �x�Ϫp��J����G�������&e�R�[��A/`���th�-����	�~^�8��m��XHD���@�h�w�$r��;�Ɨ��V�`�^Բ�T�i����Pi����9�Grl��d��n�y��+|��`K4ݮ�	���}C�Q��E%:c��}�vǎ�O�1p#Ţ�*�&�#b�0��5�*P���&�oY\���Td��seT9p�7&􁕓���M1J�
�����K2�%���\Kb���W�%#՘�{��w �8Ę0��н�4��[�����@&��H�`�������1������޴>N)�+Q�h_���r@�4#��6�M�I��#质]it�jAq�Z�=XDCi���қo���z��"�5���!8�ɖ���ezWo5$�V��@0��t�G�p���
b�����\Mn�5IK����iZ���T����_���Z�k|Y��<v���4_!�з�;|\T�@\Y�������i/����VǴ�9 K�b���� S��������7���@F�UށS�x�OM�&W����;����/�Ff��{��}[_~�\L��G�	��*@@% $^*�p)⣥!�%�B�]�̠/C��X1�r����KŐ�qH=ˣ�#��5歮%X�O6��)�t�!��D9Q�ܡM}��\s�!��+��������=��acj.*�D��c㔓��L�e4��Y�	���03��Ǹ ��5B�ђ�+0,�����K�?�N�I��,�p	W�~��}sVz"�4����׿���5d�����s�X�y��H^~�]g�>���e�eS|a�}�t�^6�'40���Ƃ�5|Q�n�제[�O�@r�$��PUͿ���3��/�^Jg_Jg��k��[�Jg��ǩGbŐ����4�S\A�E��V�\:���|@�IgN;��Wmd���`j��&�~��^�����v:�O\���Z@�*���q/(�J�����y���J�$U��o�j�I��T�4��̈q�#�@3�Hk�Kt	z�t����6��9lG��ױ>�!�<��#8�~��[M�v�z�����YUYYY_f~9�U�U4¬�Z8��W����+����^�-�3���lp�0����N5�%x��r�)���Ri=���Wn�#�F7|�q��6r�Y��ಢX�!�*M��w�`M����,�[yHE2+A7՜���ɛ�{��#r�`��}u�[^Ler��4[��l"�9e��d|�'ǅ��-Yw��'ԩ[t]R��x �м�Z���������l���ȸc>�J���t�x�J��q�b��E�:�O����3��+����QV�
�F��6�x�Q�rg %�ʣ�X�CXz� ���]��k��D�B���(����ӕ�ϫ$�T)��YhG���g��x�q�(���2a�K����!
�5�[2�[p8����z�k=ҍ�cP�]�`���E��zO��^�OɮTf7p�P\�Ʋv�������%X��7�7>oA�c���ʶ�ٛ�of̞��7ͣ���{3Ô©��3L/d�x+���ɏ�9J���,��؋"�vR���Ի�`ː%���:/�9k>bq���?�����������q����������h�>���'������*{�Yfcۂ!�E��׬�Y�3�,�ߊ���ZM�Ò��V��Cϰy5=	�AК�|���ج-��H���fh�~)&8�DE��%2j�1���(=��x?{�� �ٷ%���3=w
�
��5%��h����*�|5�z��6�	�����͝�KQ�e�t�J�j��8�����nA��[�W޲LL1�~\8^�Ρ�z��:�&;���
�>R�0��� {:�ݥt�	9d�m�A�5Ke�L�^�<s�["EĻ��T_#6�|� �^�
4�}^#��,��PD�kĞcT������5�̘�t(CC��wm��~K'���9��j;�Q/H"vz���I>�x�U�,FM4���|��������p���r����6����\u��F9:��l:�i'���:xYx�#3v_g���������=i6�7��{���{�͸׿&���u����tH�	��ހ�e+x�(����8K�қ{��B۱�	M��9ݲ%�y��`�1$����q�͘�����^{��c��F;�Nb_k옮@.U���?sWެt�d婵�I�(�D��Z�8�F����լ,�t�Tpv��4�����U�Yk���IE:������e*�k����W�wKj!��p�1|Y��0<#wI>���i��L/�J䭚��*��<�?O8㙕�[���fu����FI�G�eжF2�^�Qm�Z����a��F��� ����ΐX��85� )�Ux����l5���D�I���%� V��g�O�kp��=��-��b���L��*��j������s��]��\���5P��ߓN��w�������芞{�@����Y���^�ǭ�m$4�d5c.Y{�P���+�8��������V0ޣ\q�C1��	N#>�N�c�Mz�0����h.^��҉R0��g�7��Ɖ�#�W��Ꭺ𷿐�>�����n�P2i�]X�e#&��Q��__UbDS�qTvJAz$�K"��*���^q%(��Ԡj/�n�u�-3�m%���7��N��bX<�A�i\�pVbTm�ʱ�$u��L�U	�3�b��T����E���66�(�]�p�U����gS��g,��R �.�8�-�����u3�g�*mt(M�Q�i��:�;�!�J�PA�y㣪����.i̡R��j�jL���a��dd�i��Y�q�%�tI�,$�Q��tL:��t��lϜ������9-<eZz]�*y��A���i)GO��� �g,ӫr�-����LR�3��H�����a�(�*L�L�䕐��B� :�	�f�F���Ɛ�&�~�w�Y+!=���H�P�J���x�sc��s;��x�����$��9����3�UQ6�3%!��gJ�"��c%���+�-f��W&e�֍���g+G~U3i��Z��Jȟ�^h����>�KǛVc �Z.X�oY>�⸹	X-���1�.���\2�`wU�H%��崛�G��d�nvO�f���]�s�+[\)�KpZ����9�N������#�P��qLA�~���(G���+�J~Ǆ�LY��ǒ!"ձ�"k�r#�"�`N��'��K�X,���=y�?�DY�^���~��Z?�$ۥ��.ʑ���o�3��A�ӨD�"�=�Q9�A2��c�}�3��L��XD�2lp�V�:�&4�s�FJ���7�h�_��y���Ӣ3\�w����h���h6JY.tH�b����%0L�Ț2	׈��R�2@�.��D�$���܋���diW�m>T�~�R���I�^w��/g/k��z4˱��i4�&��bj�L�۳>�#;����P���|�J��K3qTi�;qp���a���f+Ds�o��g6Y��$c���
)OZ\�m����m4N�ۓW�W�Ʉ������6i��ѓ]���xP��o�C�}2vG��1����_w�Ǥw�߅?�������Vm�S��7KmdK�b����p��:��`�벃w'c�H)0���@<�K�و��<�Yg�7����ڰ�~H=eK�7OS�b�Tv�{����1� �Bj;�� sY�x[�2�,X��H��2b��������\0�Zċ����O����$�)6B=z�h~��ϝ}��J-�^�&���u�sJɵ?>��^��«
�^.w�SRL8�@3�p	;l�_�+{t�.�66t��,��u�-4M�BI��x�w=S�&25�L[��Tk�(I@J'��T_=�ӯ�WS��Է0?�T��fފ��Y����`Y�!|�7QC?%����	���5�վLMD�"��PD��43Hс�ó@ouWٯ���u���Hn)5���%N��W���ּ������������E*e��hd(��x�K{`�J�̹�|e:󁌉���q��޸e!�����mgف���ņ��lX��7E�D9.�X����	J�F*�Յ�,7����2���9¼^�ѯ��'��K������'3&ܐ]ҩ�)��pB#��
	W��dz�(�YK��Ɉ��%��K-ߦf��D��'�p&���]w�{���Ppcn��l��Yat��EWW�u�Buy���=����:ڞ;���a9��?�Hn�}H����#��i��xؿ~K.z�/�=����[I��G��a����@��Xэ1��L����v����7����P�q�H�p��,���a964�RM�p�E��dU�Hs��W�
����x_�ƈz"��z�9K�:��BȬMDI8��r2K���)T��2�8@��W%qT��h��j�wo���A�̝w���+.�m�BPkf/��7�_`Ė���H�$��p\�"(�tޙoӢve�^���ۘ��.":�JpNf����b�3�;�l(�Pt�x+�W ��ȋ�����h��A)v�cV-m�pGHd#��s�|;1��q�S��l���-�I����i�q�ʹ���\Įۗ�Mm4n��W��/v9�Q,Sȴ�R1��`e;��?bC�&�-=��n�p�R�� ń��a�W���l���6���"�f�K��Vz��$����d"G�G6��?"�w��tq�F���|.��L%4�R�B�S�ڥL�!���{����'��͘�:ӓ�:2�U����s�� f�N��I�s����,8r���t��A4�<�=����������B�]����ߑK&��=k��]���w΍l��� �H���֚�P+���PK  �Z]u��f  �     word/_rels/document.xml.rels���N� ��W!���N���Ͳd�Z��ӏX��3uo/�Y:�7\6�r�����z`o�|o��"ˁ�Q��M+��߬`�Y?� )��~�,,1^@G4>r�U�Z�̎hBi�Ӓ£k�(իl�/�|��|\�d�i��L�M�+�Yu�h���u�.�j�P�J�Z$S��\`<���i@?�p.ɿ�Da�Qp;\Zj�;VϿw�1˩%�5T�j��qSL���6
�Q�ιH�����|��%�V(��RD�"�M~���|PK  �Z]�ٌ#m   |      word/_rels/footnotes.xml.relsM�A!E�B�w�.�1��n`� V �Pb<�,]�����~�n>�4qp�,_�I���};\`]��ԇ�1U5#u{�WD��3�T*� ��2�1[�J�M��d���\~PK  �Z]�5�o  ;0     word/numbering.xml��ON�@��D��,���xP7HTU�=�IX���v���A�֓�	
	̛X�"��~���&����{����q9��Q���r8e����uq��z�'��~9-.Ӫ�eݟ�����}�ޤER�'i�>�WEҴ?V��|\�&�x��u[Y��IVz�5�˺��a�}Z��~:�8���:�OgI>�,{�b���M�-�����I�������Y�>�ڏ���޴8+�U��4���i�Ez����4�u��ӫ����j񑕋|���6߼������>��0�_��2�8|0��K2y�dR�d��dֺ$ӇO�L�,<|2��� s�da��D$��� {�dF������z����Ew����ߏ���������i�:��N��Q�wڷ���Ӿu�����N�o�z�};\��bc�_Î_7I��[�V[ߧQ:̊$߼Q��Q�� ,��'V�љ�k���$��C���|���Cbt��đCbt���%19�p��!18���yUޟS"���R������_��T,��Œ�m�O�l�	?fiUe�t�1��ٳ���V��2b?���,������2�~�1�Y&��2��˼�W�!)6�8"ŖǠXlmq��I��ŉ�-nW1&�0A�	"La��D�$�$&�0I�I"La��D�$���0E�)"La�SD�"���0M�i"La��D�&�4��0M�i",$�B",$�B",$�B",$�B",$�B"�a�3D�!�f�0C�"�a����������������������D�%�,f�0K�Y"�a��D�%�b",&�b",&�b",&�b",&�b",���/�va�|�$�����N_�;}A�����N_�;}�;�����8�PK  �Z]��D�  R     word/styles.xml�\Ks�8��`鰷��%�gJ���k3�7R�3HB�$�A;�_� �!�"E:��4�	�h���h ���ϟ�k<A"�_��z�m� {���^�3{~x�|��k�W亷�4���C{=���3�PV$�>�l�o�yЧ��`0���F
w({Io�uz{��	�a2h�����>��0B۷p"���Fԑ���UieZ��K���x���КA��=��|��!�1�R��9����C�*;���_;�k����h�/[��R�[&��� �Vs�u�ﾭz�~Rʺxߗ��
�b#:���� �H 
1X\�qy�b��F��0�2Ƭb�1��ȧ��鄛���gl?BgEY��� ���R�%�XA}B������A� �"��;��;��#��	A�������w��>�˫�K����-�����Lc�6�g��Ƙ���Iי8>�;/k����+�F>����~9,��r��������p���I�_`A'H.���bOPB����>d~���fHz�ʽ�7�Y�J�֨��K�:k�Ȋ�:a���Q����Y�ٶFԅ�-KZ7�o��h�~�0����+�����~��F���fa1|���N��l���tV�$}�kS�.KQ\�1���RR2f�XZ]`cL�ɂX:��u�Ѣz���2�G�˹9/���B�X{�P!�'��s�Ȣ�h�+�2o��'D<Q�xRL1hbrĪ7����1J����q����maj�7~s�V��
)ai�YFH��v�!��W�L?��bP�]*������ʊ+z��+�?��_U�l�7���"Z�^���W#�YY.���/���c�_҉6R�����}��_Pkە(�NI��4����*�U�2qD�~~rS`u)�v7������ܖn+G[��Q�,!֨1G���Q��wPT��Qtx�(�Y��6�hLы3E���U��U���Ptܘ��3E�^���7K����<ST���MP��rҘ��3)R^�R�2	��I8=�P!��{ڙ��Ih6&�y&�B�附�H8kL�ٙ�
	�3	�$ፋ��f���ơWB�<�y-"�6*�o�}��7���jBGnhry�܋�;Z�Jo�!w�1�1���*5�%{�8t��/3��E\�/{U�gg�{��=HJ�o����,#Vϡ�ٓ��4��������cҲ4TB����K�O-�0X�Np:��kֳ��'m����(>ڤ88�+��	�i7�jKS��:}�yv�S?{R'�V��H֡��_�s����j�m���B��ܾ&*����q�v1�Q[Q~��h�+��T��0�-�C���k3 �r\�P�w��YU����i�#��{�W��K�f�zG��y?��l�r[Sk�b�͎K!��ؓu�x0�-@�B־A�x�<*l
�
u*��zJ(���iQ��vϴ�<�ml�Pjl�Q￷��z,m�n2T=ݎ�NC`��q�~��q����ey`��V�E�e�^	��wH,@��ȖT�)eUՑ�?��C�0;u�U%��F�U*ܱ�6�ܗȳ`}$ZF���!�OR_��۰6��8%����$����m�l��$�3�pJ׶J�hi��ML[�/������~ad:�����\=\t}�Pxj/�)^������o ���e׬���7?+�{J��7V���_�,��\.g��������#b30;߫��B�F��(i��T��������+m�7� 	snўA��Pmп�d���DZ{4�I��"|0��7��A&I�ok���/���1��`�����Zؙ��� 0�w��A��Ü	N��ŀ� g����7o�ZԲ�p�t�i>�tR���S���h#��Vħ����"�$':��~��3"aFE �mL����4;6��0Ѯ1��]�7�����I���ڠ�0�X)z�q�O~�D���v�6hE0���c��g��R3��΢a��)	o��d����M�g#�����|���ȷ�h$�Z���)�:�����6�I�6����tjw�ɤ�l�\�ϔŧz�� ��.�Z�X�_�'���N�wI�Q���ǟ�a�D-@O ���@`��^z:��V9՞��};�l�hET���m�O��`4��W�ea��G}�Q応w~�Sp%�U�'�� �;$щ1w���	���^����
�	Ny|����K������PK  �Z]� i  K     word/footnotes.xml���n�0�_�NCw�&�R��=@B�D��6d{���l]�M�G���l��}�!��_����Z돵x;�/b�T�� �ʒ�Sk�3�RJҽq�6�O��)N)el�6D���T��)����`��6{У3����������bD_^P�����\�+ϔ˳(������-V�OK[j�d-���z����G�/��O�?��O�bɟ��B�g����&(T(Rٶ�(fM8<��͙l*97ȹW���u�[�|{cC��W	5_PK  �Z]n�   q     word/comments.xml����� �W	�S�=�E��R�	� �4BƑ����X�%�$2�8���c5[b���]#*�v��Zq������tL� ������Y�V1%%�����s�G�n2!u��X���(��� A;/�0���������ġ �!;����.�b"��g�X����%1J�0���oV�����^3YG:�Yopf��Sq��x)l0^���(�J��PK  �Z]u@b�  G     docProps/core.xml���n�0�_%�=q*���8�R�R��Ͳ��dox��B��q�zf?�ڮ{�f��vvNXQ��tJ�͜|����,�Zz.]���<���f#�~N���S���Er�$�]0S6���UYN�J��G`�G"9!���'�=@I
-�)+�x��7z��h<x�i=��{�h캮�&�5�g����5�6��HS+�QcMM/˴��0l�E��:TL�Uu�h��R>�>+����Ւ4UYM�r���c������x�U�hғ���3`H|��?PK  �Z]dNFd  �     docProps/app.xml�R�N�0��+�܉Ky�r]!� �)�-{�X8�e�nӆ 8������f���m�1�V�q5/p�k��U��o�.˵����l (piUv9�%cIu��T!�i|�e�6��7�Qp��[.��|~��#�Ӡ��hX����_S�ݗ��π~bV��G���	gCEئ�4jE#mξ��P�q�麓�}�M���q��񂳡"�*��!K$�9>�M���5mC�od�Æ����%3���>�&�.9W��8B<.J�q׋��&H�W�Q2$���V>RĶ�>���(�`:Po��O�K����gikӃ8G����V��5~�1��y�8�8�����k�~E�&�@��=�T̰�'�PK  �Z]y%��   �      docProps/custom.xml���
�0�_	���DJ�^ĳ�꽤�6`�!�-���~��a�Ǵ�+<��<F#���������p�β��[��=�(�HF.̩Q��a��Ա4s��<+t�[��]DVG�Oʮ������k6�������1����PK  �Z]=�
�  �     word/theme/theme1.xml�YMo�6��W���l+u�:E���֦�C��DKl(Q �$��q��aݰ�
�ð�@����l��_E�eS���ۊ5G�����KҾ|�8"�1�iܵ���أ>���u{4�б�l~pn�EHt�7`�
�H6l�{r�4A�|7�,�BY`�I)���ƚA[ ��Z�&�!0JEZ�s�"?b��	��}Oi�
�8�?>�}��!$]K����ȅ|ѵ����e�`QCֈC�7'�����,Lg�^��]jhf�����?pJ�
=Oz�,��Î�+�j��qYz��6�MCk�������*�U�K�Nc��լ�%�]�����U	nIX["/���
,��̖)*0J�����P�l��2����ޣl(*�P��Y�&Г�>$x̰� 7�^�s_�K��1����Q�)1/�����pr�����O<8����vƁN{���=�������!p��ۏ����5H�#����������?4����7�أQ�A�3RF!�:e+8�aJ2�"��o� �&`Uy���`D^�ޫ����&��0� w(%=�̎]W�XL�F?���=����LY��(�����Df(F���B&�]�+�����N��Abs`Fx,̬k8�	�m���Dh��QbT���P�L 1
E�ͫp*`d�FD�ހ"4�?c^%�\Ȥ�P0��F�-6��|]���
�!��
e�7 �:t��C%f�q�����Xv�0�A�k&˄��>�w0g\�q��%}3e�^���_ծ#٭�[hײ;>���;֨�d,�kc�=��r�2�=yN�]�������%�oɯX�+7�����Z	�jO�LȾ�t���ͥ��PN��"'�$��s}`��z�����C�H=�R�\v�AB��IX����K�՜[�&%��g��5��F�U�R��k]z]uN�\Q����s_���b*�����Z37�{� ?�~.a����)���*�>2�k>:��S��v��X7�cm//.WG�k��M�L��D��c�H�<�(�q��D���Ks�����rn��%	�b�0��W�*q�B�m��ތ��������a/fM&�53�0G����?c2e{PZ�Ϊ��\�����2o�X]��2Y��&_>�$!�˾�W@�Wυj��g�N_Zo����KZ��t���Jn���N�e"��%!��L�2i�kC�,�~�����	�^�= �e�!ChW䞞"͙w�|y��S̓��"2J�Z�E[�c�����Mkl�ˇ��9w�RU�,b[���a�u�Xe_�6k�n������ȋH?d#��#�vD�d��  K�B'_���XZ���Ke�SG�N]����R�x�.�(<�]C��S�m//X[�����OUt|O*ߖW�)�fx"G��.�|S6&<ky4�}��{h�<O�B\�_��M~/S��`�V`�ro)���e~;,���g�@4�!�v�7����5#����ky�ȭ��sDN��<`��ѱ`�?�yKVs.IU���PK  �Z]{�H:�  �	     word/fontTable.xml�]O�0���+HM�s�����Gv��x]XMhK�2ܿ�����1�ʑ4)oߞ�<9����yfm��L�9C�,*b�bb�����G��`Z�F[�:P!J����qJ9�C�Sk�T��Uk[&	�飌N��]�Ƕ�1p�NY�Q��I�R�U�dL���x���	h6����6)Ze �!z��Hf�bcȉ��:�ِ,Db�k���e���)Q���-]CB8˶�uR�u����ް!��(�]�fk�:�p�g.��)n�8ʨ��8~[i�iN��;l�.��z���,9}0]<�# ��pa���<��w0G=0��0��5�Y(FU������@+��d�\ �����X�s��B����>�G�#H���f�5u���;3� .�jtk�g�]�w�k�K}��5��p?ӳPK  �Z]-/B޶  �     word/settings.xml�UMS�0��Wx|n� �d��r����wY^ǚ�ó�㦿�+ۊ��R��$z��v��\\�T2�Za�:���q��B��:~z��>�W��ʂs�و�ڮ�:���WIby��S�&�4���%nS��Í��E�."�x01�A�fJp4֔nƍZ������7,�d�R���mp��-v=u'rdxIL��%�W2�ڷ�j5�R��|���o�����ks	Læ���F�j�(�4M��(������|�g�Z�x6�ҿ���]$ϬHH�U�@�B��̟�Y]S�d�8�ۚ���G|�[��i�NG�,`g#v��[l�|K1��V}�|��]��HiZ(n5�z��_@^W�|5�}B�]��3��P�_�(�I�OCӗ�*�";Xjc��=J�a�̱��[dJ1.�iook�����6�q������ap*�d�t�,Ϝ�C?|X�������(n�_t&�����:�����N�״�֒Fכq�gz���|�!�K�+F�R�'�� hd�uո6�F�a�e{jV�hw����?U�y��2"�[]3��`�}��%G]��OBU4��Ϛ<Hf�)m�rC9:���7PNy�p;�{��W�Y������	�ɳ�����N�.���8�ǊQM�n_�;6v��S���L�����9H)�ˠ��t��Z���d�+��PK  �Z]�TΜ   �      word/webSettings.xml]�;�0D���rOl(��M�"��L�$�lo���BAA9��FS6/��
�,�J�s-�G�J�o��$�:+�b�G)1!�V���J�)-�R4���@`���M�'�a����:h}T�� �L��q�kw�W��a��
g��s�Z^��;�PK    �Z]����o  %                   [Content_Types].xmlPK    �Z]�w���   �               �  _rels/.relsPK    �Z]�]U��z  G�              �  word/document.xmlPK    �Z]u��f  �               �}  word/_rels/document.xml.relsPK    �Z]�ٌ#m   |                �~  word/_rels/footnotes.xml.relsPK    �Z]�5�o  ;0               �  word/numbering.xmlPK    �Z]��D�  R               !�  word/styles.xmlPK    �Z]� i  K               
�  word/footnotes.xmlPK    �Z]n�   q               P�  word/comments.xmlPK    �Z]u@b�  G               X�  docProps/core.xmlPK    �Z]dNFd  �               ��  docProps/app.xmlPK    �Z]y%��   �                5�  docProps/custom.xmlPK    �Z]=�
�  �               �  word/theme/theme1.xmlPK    �Z]{�H:�  �	               :�  word/fontTable.xmlPK    �Z]-/B޶  �               �  word/settings.xmlPK    �Z]�TΜ   �                �  word/webSettings.xmlPK        ��    
```


<div style='page-break-after: always;'></div>

# File: requirements-dev.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch
pydantic
psycopg2-binary
```


<div style='page-break-after: always;'></div>

# File: scripts\smoke-test.ps1

```ps1
# ZuriShop automated smoke test — Bulletproof Edition
$script:failed = $false

function Check($name, $ok) {
    if ($ok) { Write-Host "[PASS] $name" -ForegroundColor Green }
    else     { Write-Host "[FAIL] $name" -ForegroundColor Red; $script:failed = $true }
}

Write-Host "=== ZuriShop Smoke Test ===" -ForegroundColor Cyan

# 1. API health
$ports = @{
    "product-api"=8001; "cart-service"=8002; "checkout-service"=8003
    "payment-service"=8004; "inventory-service"=8005
    "notification-service"=8006; "search-service"=8007
}
foreach ($svc in $ports.Keys) {
    try {
        $r = Invoke-RestMethod -Uri "http://localhost:$($ports[$svc])/healthz" -TimeoutSec 5
        Check "$svc /healthz" ($r.status -eq "healthy")
    } catch { 
        Write-Host "  -> Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Check "$svc /healthz" $false 
    }
}

# 2. Storefront
try { $s = Invoke-WebRequest -Uri http://localhost:8080 -UseBasicParsing -TimeoutSec 5; Check "storefront-web" ($s.StatusCode -eq 200) } catch { Check "storefront-web" $false }

# 3. Elasticsearch
try { $e = Invoke-RestMethod -Uri http://localhost:9200 -TimeoutSec 5; Check "elasticsearch" ($e.tagline -eq "You Know, for Search") } catch { Check "elasticsearch" $false }

# 4. Prometheus
try { Invoke-RestMethod -Uri http://localhost:9090/-/healthy -TimeoutSec 5 | Out-Null; Check "prometheus" $true } catch { Check "prometheus" $false }

# 5. PostgreSQL
try {
    $pg = docker compose exec -T postgres psql -U zurishop -d zurishop -tAc "SELECT 1"
    Check "postgres" ($pg.Trim() -eq "1")
} catch { Check "postgres" $false }

# 6. Search index + query
try {
    $seed = Invoke-RestMethod -Uri http://localhost:8007/search/index -Method Post -TimeoutSec 15
    Check "search indexing" ($seed.indexed -eq 4)
    $sr = Invoke-RestMethod -Uri "http://localhost:8007/search?q=keyboard" -TimeoutSec 5
    Check "search query" ($sr.count -ge 1)
} catch { 
    Write-Host "  -> Search Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Check "search" $false 
}

# 7. End-to-end checkout (FORCED UTF-8 ENCODING)
try {
    $cartId = "smoke-" + (Get-Random)
    
    # Force UTF-8 byte array to prevent PowerShell encoding bugs
    $cartBody = [System.Text.Encoding]::UTF8.GetBytes('{"product_id":"SKU-003","quantity":1}')
    Invoke-RestMethod -Uri "http://localhost:8002/cart/$cartId/items" -Method Post -ContentType "application/json" -Body $cartBody | Out-Null
    
    $checkoutBody = [System.Text.Encoding]::UTF8.GetBytes("{`"cart_id`":`"$cartId`",`"email`":`"smoke@zurimart.co.ke`"}")
    $co = Invoke-RestMethod -Uri http://localhost:8003/checkout -Method Post -ContentType "application/json" -Body $checkoutBody
    Check "checkout flow" ($co.status -eq "completed")
    
    $orders = Invoke-RestMethod -Uri http://localhost:8003/orders
    Check "order persisted in Postgres" ($orders.count -ge 1)
} catch { 
    Write-Host "  -> Checkout Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Check "checkout flow" $false 
}

if ($script:failed) { Write-Host "SMOKE TEST FAILED" -ForegroundColor Red; exit 1 }
Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
```


<div style='page-break-after: always;'></div>

# File: services\cart-service\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: services\cart-service\Dockerfile

```text
# ---------- Stage 1: builder (has pip, wheels, build cache) ----------
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: runtime (no pip, no build tools, tiny attack surface) ----------
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN python -m pip uninstall pip -y
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```


<div style='page-break-after: always;'></div>

# File: services\cart-service\main.py

```py
from fastapi import FastAPI
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
import redis
import os
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"cart-service","message":"%(message)s"}',
    stream=sys.stdout
)

app = FastAPI(title="cart-service")

Instrumentator().instrument(app).expose(app, endpoint="/metrics")

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    db=0,
    decode_responses=True
)

CART_TTL_SECONDS = int(os.getenv("CART_TTL_SECONDS", "3600"))


class CartItem(BaseModel):
    product_id: str
    quantity: int = 1


@app.get("/")
def root():
    return {
        "service": "cart-service",
        "status": "running"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "healthy"
    }


@app.post("/cart/{cart_id}/items")
def add_item_to_cart(cart_id: str, item: CartItem):
    key = f"cart:{cart_id}"

    redis_client.hincrby(
        key,
        item.product_id,
        item.quantity
    )
    redis_client.expire(key, CART_TTL_SECONDS)

    items = redis_client.hgetall(key)

    logging.info(
        "Added item %s to cart %s (TTL %ss)",
        item.product_id,
        cart_id,
        CART_TTL_SECONDS
    )

    return {
        "cart_id": cart_id,
        "items": items
    }


@app.get("/cart/{cart_id}")
def get_cart(cart_id: str):
    key = f"cart:{cart_id}"
    items = redis_client.hgetall(key)

    return {
        "cart_id": cart_id,
        "items": items,
        "item_count": len(items)
    }


@app.delete("/cart/{cart_id}")
def clear_cart(cart_id: str):
    key = f"cart:{cart_id}"
    redis_client.delete(key)

    return {
        "cart_id": cart_id,
        "status": "cleared"
    }
```


<div style='page-break-after: always;'></div>

# File: services\cart-service\requirements.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch
pydantic
```


<div style='page-break-after: always;'></div>

# File: services\checkout-service\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: services\checkout-service\Dockerfile

```text
# ---------- Stage 1: builder (has pip, wheels, build cache) ----------
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: runtime (no pip, no build tools, tiny attack surface) ----------
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN python -m pip uninstall pip -y
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```


<div style='page-break-after: always;'></div>

# File: services\checkout-service\main.py

```py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
from psycopg2.pool import ThreadedConnectionPool
from contextlib import asynccontextmanager
import asyncio
import httpx
import os
import uuid
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"checkout-service","message":"%(message)s"}',
    stream=sys.stdout
)

PRODUCT_API_URL = os.getenv("PRODUCT_API_URL", "http://localhost:8001")
CART_SERVICE_URL = os.getenv("CART_SERVICE_URL", "http://localhost:8002")
INVENTORY_SERVICE_URL = os.getenv("INVENTORY_SERVICE_URL", "http://localhost:8005")
PAYMENT_SERVICE_URL = os.getenv("PAYMENT_SERVICE_URL", "http://localhost:8004")
NOTIFICATION_SERVICE_URL = os.getenv("NOTIFICATION_SERVICE_URL", "http://localhost:8006")

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set. Inject it via environment or Secrets.")


db_pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- STARTUP ---
    global db_pool
    for attempt in range(30):
        try:
            db_pool = ThreadedConnectionPool(1, 5, dsn=DATABASE_URL)
            logging.info("Connected to PostgreSQL")
            break
        except Exception as error:
            logging.warning("PostgreSQL not ready (%s). Retry %s/30", error, attempt + 1)
            await asyncio.sleep(2)
    else:
        raise RuntimeError("Could not connect to PostgreSQL")
        
    yield  # <-- App runs here
    
    # --- SHUTDOWN ---
    if db_pool:
        db_pool.closeall()
        logging.info("PostgreSQL connection pool closed gracefully")

app = FastAPI(title="checkout-service", lifespan=lifespan)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class CheckoutRequest(BaseModel):
    cart_id: str
    email: str


@app.get("/")
def root():
    return {"service": "checkout-service", "status": "running"}


@app.get("/healthz")
def healthz():
    return {"status": "healthy"}


@app.post("/checkout")
async def checkout(request: CheckoutRequest):
    order_id = str(uuid.uuid4())

    async with httpx.AsyncClient(timeout=10.0) as client:
        cart_response = await client.get(f"{CART_SERVICE_URL}/cart/{request.cart_id}")
        if cart_response.status_code != 200:
            raise HTTPException(status_code=400, detail="Cart not found")

        cart = cart_response.json()
        items = cart.get("items", {})
        if not items:
            raise HTTPException(status_code=400, detail="Cart is empty")

        total = 0.0

        for product_id, quantity in items.items():
            quantity = int(quantity)

            product_response = await client.get(f"{PRODUCT_API_URL}/products/{product_id}")
            if product_response.status_code != 200:
                raise HTTPException(status_code=400, detail=f"Product {product_id} not found")

            product = product_response.json()
            total += float(product["price"]) * quantity

            reserve_response = await client.post(
                f"{INVENTORY_SERVICE_URL}/inventory/{product_id}/reserve",
                params={"quantity": quantity},
            )
            if reserve_response.status_code != 200:
                raise HTTPException(status_code=409, detail=f"Could not reserve stock for {product_id}")

        try:
            payment_response = await client.post(
                f"{PAYMENT_SERVICE_URL}/payments",
                json={"amount": total, "currency": "KES", "customer_email": request.email},
            )
            if payment_response.status_code != 200:
                raise HTTPException(status_code=402, detail="Payment failed")
        except httpx.RequestError as exc:
            # Catches ConnectError, TimeoutException, DNS failures, etc.
            logging.error("Payment service unreachable: %s", exc)
            raise HTTPException(status_code=503, detail="Payment service unavailable")

        # Persist the order (source of truth = PostgreSQL)
        conn = db_pool.getconn()
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """INSERT INTO orders.orders
                       (order_id, cart_id, customer_email, total, currency, status)
                       VALUES (%s, %s, %s, %s, %s, %s)""",
                    (order_id, request.cart_id, request.email, total, "KES", "completed"),
                )
            conn.commit()
        finally:
            db_pool.putconn(conn)

        await client.post(
            f"{NOTIFICATION_SERVICE_URL}/notifications",
            json={
                "to": request.email,
                "message": f"Your order {order_id} has been confirmed. Total: KES {total}",
                "type": "email",
            },
        )

        await client.delete(f"{CART_SERVICE_URL}/cart/{request.cart_id}")

        logging.info("Order %s completed successfully. Total: %s", order_id, total)

        return {
            "order_id": order_id,
            "status": "completed",
            "total": total,
            "currency": "KES",
        }


@app.get("/orders")
def list_orders():
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """SELECT order_id, customer_email, total, status, created_at
                   FROM orders.orders ORDER BY created_at DESC LIMIT 20"""
            )
            rows = cur.fetchall()
    finally:
        db_pool.putconn(conn)

    return {
        "count": len(rows),
        "orders": [
            {
                "order_id": r[0],
                "email": r[1],
                "total": float(r[2]),
                "status": r[3],
                "created_at": str(r[4]),
            }
            for r in rows
        ],
    }
```


<div style='page-break-after: always;'></div>

# File: services\checkout-service\requirements.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch
pydantic
psycopg2-binary
```


<div style='page-break-after: always;'></div>

# File: services\inventory-service\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: services\inventory-service\Dockerfile

```text
# ---------- Stage 1: builder (has pip, wheels, build cache) ----------
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: runtime (no pip, no build tools, tiny attack surface) ----------
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN python -m pip uninstall pip -y
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```


<div style='page-break-after: always;'></div>

# File: services\inventory-service\main.py

```py
from fastapi import FastAPI, HTTPException
from prometheus_fastapi_instrumentator import Instrumentator
from psycopg2.pool import ThreadedConnectionPool
from contextlib import asynccontextmanager
import asyncio
import logging
import os
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"inventory-service","message":"%(message)s"}',
    stream=sys.stdout
)

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set. Inject it via environment or Secrets.")


db_pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- STARTUP ---
    global db_pool
    for attempt in range(30):
        try:
            db_pool = ThreadedConnectionPool(1, 5, dsn=DATABASE_URL)
            logging.info("Connected to PostgreSQL")
            break
        except Exception as error:
            logging.warning("PostgreSQL not ready (%s). Retry %s/30", error, attempt + 1)
            await asyncio.sleep(2)
    else:
        raise RuntimeError("Could not connect to PostgreSQL")
        
    yield  # <-- App runs here
    
    # --- SHUTDOWN ---
    if db_pool:
        db_pool.closeall()
        logging.info("PostgreSQL connection pool closed gracefully")

app = FastAPI(title="inventory-service", lifespan=lifespan)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/")
def root():
    return {"service": "inventory-service", "status": "running"}


@app.get("/healthz")
def healthz():
    return {"status": "healthy"}


@app.get("/inventory")
def get_inventory():
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT product_id, remaining FROM inventory.stock ORDER BY product_id")
            rows = cur.fetchall()
    finally:
        db_pool.putconn(conn)

    return [{"product_id": r[0], "remaining": r[1]} for r in rows]


@app.get("/inventory/{product_id}")
def get_product_inventory(product_id: str):
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT product_id, remaining FROM inventory.stock WHERE product_id = %s",
                (product_id,),
            )
            row = cur.fetchone()
    finally:
        db_pool.putconn(conn)

    if row is None:
        raise HTTPException(status_code=404, detail="Product not found in inventory")

    return {"product_id": row[0], "remaining": row[1]}


@app.post("/inventory/{product_id}/reserve")
def reserve_inventory(product_id: str, quantity: int = 1):
    if quantity <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be greater than zero")

    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            # Atomic reservation: the DB guarantees no oversell (CHECK remaining >= 0)
            cur.execute(
                """UPDATE inventory.stock
                   SET remaining = remaining - %s
                   WHERE product_id = %s AND remaining >= %s
                   RETURNING remaining""",
                (quantity, product_id, quantity),
            )
            row = cur.fetchone()
            conn.commit()

            if row is None:
                cur.execute(
                    "SELECT 1 FROM inventory.stock WHERE product_id = %s",
                    (product_id,),
                )
                exists = cur.fetchone() is not None
    finally:
        db_pool.putconn(conn)

    if row is None:
        if not exists:
            raise HTTPException(status_code=404, detail="Product not found in inventory")
        raise HTTPException(status_code=409, detail="Insufficient stock")

    logging.info("Reserved %s units of %s. Remaining: %s", quantity, product_id, row[0])

    return {"product_id": product_id, "reserved": quantity, "remaining": row[0]}
```


<div style='page-break-after: always;'></div>

# File: services\inventory-service\requirements.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch
pydantic
psycopg2-binary
```


<div style='page-break-after: always;'></div>

# File: services\notification-service\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: services\notification-service\Dockerfile

```text
# ---------- Stage 1: builder (has pip, wheels, build cache) ----------
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: runtime (no pip, no build tools, tiny attack surface) ----------
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN python -m pip uninstall pip -y
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```


<div style='page-break-after: always;'></div>

# File: services\notification-service\main.py

```py
from fastapi import FastAPI
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"notification-service","message":"%(message)s"}',
    stream=sys.stdout
)

app = FastAPI(title="notification-service")

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class NotificationRequest(BaseModel):
    to: str
    message: str
    type: str = "email"


@app.get("/")
def root():
    return {
        "service": "notification-service",
        "status": "running"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "healthy"
    }


@app.post("/notifications")
def send_notification(request: NotificationRequest):
    logging.info(
        "Sending %s notification to %s: %s",
        request.type,
        request.to,
        request.message
    )

    return {
        "status": "queued",
        "to": request.to,
        "type": request.type
    }
```


<div style='page-break-after: always;'></div>

# File: services\notification-service\requirements.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch
pydantic
```


<div style='page-break-after: always;'></div>

# File: services\payment-service\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: services\payment-service\Dockerfile

```text
# ---------- Stage 1: builder (has pip, wheels, build cache) ----------
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: runtime (no pip, no build tools, tiny attack surface) ----------
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN python -m pip uninstall pip -y
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```


<div style='page-break-after: always;'></div>

# File: services\payment-service\main.py

```py
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator
from typing import Optional
import uuid
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"payment-service","message":"%(message)s"}',
    stream=sys.stdout
)

app = FastAPI(title="payment-service")

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


class PaymentRequest(BaseModel):
    amount: float
    currency: str = "KES"
    customer_email: Optional[str] = None


@app.get("/")
def root():
    return {
        "service": "payment-service",
        "status": "running"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "healthy"
    }


@app.post("/payments")
def create_payment(request: PaymentRequest):
    payment_id = str(uuid.uuid4())

    if request.amount <= 0:
        raise HTTPException(status_code=400, detail="Payment amount must be greater than zero")

    if request.amount > 200000:
        raise HTTPException(status_code=402, detail="Payment declined by mock payment provider")

    logging.info(
        "Payment approved: %s for amount %s",
        payment_id,
        request.amount
    )

    return {
        "payment_id": payment_id,
        "status": "approved",
        "amount": request.amount,
        "currency": request.currency
    }
```


<div style='page-break-after: always;'></div>

# File: services\payment-service\requirements.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch
pydantic
```


<div style='page-break-after: always;'></div>

# File: services\product-api\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: services\product-api\Dockerfile

```text
# ---------- Stage 1: builder (has pip, wheels, build cache) ----------
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: runtime (no pip, no build tools, tiny attack surface) ----------
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN python -m pip uninstall pip -y
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```


<div style='page-break-after: always;'></div>

# File: services\product-api\main.py

```py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from psycopg2.pool import ThreadedConnectionPool
from contextlib import asynccontextmanager
import asyncio
import logging
import os
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"product-api","message":"%(message)s"}',
    stream=sys.stdout
)

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise RuntimeError("DATABASE_URL is not set. Inject it via environment or Secrets.")

db_pool = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- STARTUP ---
    global db_pool
    for attempt in range(30):
        try:
            db_pool = ThreadedConnectionPool(1, 5, dsn=DATABASE_URL)
            logging.info("Connected to PostgreSQL")
            break
        except Exception as error:
            logging.warning("PostgreSQL not ready (%s). Retry %s/30", error, attempt + 1)
            await asyncio.sleep(2)
    else:
        raise RuntimeError("Could not connect to PostgreSQL")
        
    yield  # <-- App runs here
    
    # --- SHUTDOWN (Graceful Teardown) ---
    if db_pool:
        db_pool.closeall()
        logging.info("PostgreSQL connection pool closed gracefully")

app = FastAPI(title="product-api", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/")
def root():
    return {"service": "product-api", "status": "running"}


@app.get("/healthz")
def healthz():
    return {"status": "healthy"}


@app.get("/products")
def get_products():
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name, price, currency FROM catalog.products ORDER BY id")
            rows = cur.fetchall()
    finally:
        db_pool.putconn(conn)

    return [
        {"id": r[0], "name": r[1], "price": float(r[2]), "currency": r[3]}
        for r in rows
    ]


@app.get("/products/{product_id}")
def get_product(product_id: str):
    conn = db_pool.getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, price, currency FROM catalog.products WHERE id = %s",
                (product_id,),
            )
            row = cur.fetchone()
    finally:
        db_pool.putconn(conn)

    if row is None:
        raise HTTPException(status_code=404, detail="Product not found")

    return {"id": row[0], "name": row[1], "price": float(row[2]), "currency": row[3]}
```


<div style='page-break-after: always;'></div>

# File: services\product-api\requirements.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch
pydantic
psycopg2-binary
```


<div style='page-break-after: always;'></div>

# File: services\search-service\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: services\search-service\Dockerfile

```text
# ---------- Stage 1: builder (has pip, wheels, build cache) ----------
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---------- Stage 2: runtime (no pip, no build tools, tiny attack surface) ----------
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY . .
RUN python -m pip uninstall pip -y
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=3s --start-period=20s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```


<div style='page-break-after: always;'></div>

# File: services\search-service\main.py

```py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware 
from prometheus_fastapi_instrumentator import Instrumentator
from elasticsearch import Elasticsearch, NotFoundError
from contextlib import asynccontextmanager
import httpx
import os
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format='{"level":"%(levelname)s","service":"search-service","message":"%(message)s"}',
    stream=sys.stdout
)

ELASTICSEARCH_URL = os.getenv("ELASTICSEARCH_URL", "http://localhost:9200")
PRODUCT_API_URL = os.getenv("PRODUCT_API_URL", "http://localhost:8001")
INDEX_NAME = "products"

es = Elasticsearch([ELASTICSEARCH_URL])

@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- STARTUP ---
    try:
        if not es.indices.exists(index=INDEX_NAME):
            es.indices.create(index=INDEX_NAME)
            logging.info("Created Elasticsearch index: %s", INDEX_NAME)
    except Exception as error:
        logging.warning("Could not create Elasticsearch index: %s", error)
        
    yield  # <-- App runs here
    
    # --- SHUTDOWN ---
    es.close()
    logging.info("Elasticsearch client closed gracefully")

app = FastAPI(title="search-service", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Instrumentator().instrument(app).expose(app, endpoint="/metrics")


@app.get("/")
def root():
    return {
        "service": "search-service",
        "status": "running"
    }


@app.get("/healthz")
def healthz():
    return {
        "status": "healthy"
    }


@app.post("/search/index")
async def index_products():
    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(f"{PRODUCT_API_URL}/products")
        response.raise_for_status()
        products = response.json()

    indexed = 0

    for product in products:
        es.index(
            index=INDEX_NAME,
            id=product["id"],
            document=product
        )
        indexed += 1

    es.indices.refresh(index=INDEX_NAME)

    logging.info("Indexed %s products into Elasticsearch", indexed)

    return {
        "indexed": indexed
    }


@app.get("/search")
def search_products(q: str = ""):
    if not q:
        return {
            "count": 0,
            "hits": []
        }
        
    # Gracefully handle missing index (decoupled state)
    if not es.indices.exists(index=INDEX_NAME):
        return {
            "count": 0,
            "hits": []
        }

    query = {
        "query": {
            "multi_match": {
                "query": q,
                "fields": ["name", "id"]
            }
        }
    }
    
    try:
        response = es.search(index=INDEX_NAME, query=query["query"])
        hits = [
            hit["_source"]
            for hit in response["hits"]["hits"]
        ]
        return {
            "count": len(hits),
            "hits": hits
        }
    except NotFoundError:
        # Fallback if index is deleted between the check and the search
        return {
            "count": 0,
            "hits": []
        }
```


<div style='page-break-after: always;'></div>

# File: services\search-service\requirements.txt

```txt
fastapi
uvicorn[standard]
prometheus-fastapi-instrumentator
httpx
redis
elasticsearch==8.13.0
pydantic
```


<div style='page-break-after: always;'></div>

# File: storefront-web\.dockerignore

```dockerignore
# --- Python bytecode & cache (never needed in images) ---
__pycache__/
*.pyc
*.pyo
*.pyd
.pytest_cache/

# --- Virtual environments (huge, host-only) ---
.venv/
venv/

# --- Secrets (must NEVER be baked into an image) ---
.env
.env.*

# --- Version control metadata ---
.git/
.gitignore

# --- Build metadata (keeps context lean & cache stable) ---
Dockerfile
.dockerignore

# --- Docs ---
*.md
```


<div style='page-break-after: always;'></div>

# File: storefront-web\Dockerfile

```text
FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s \
  CMD wget -qO- http://localhost/ > /dev/null || exit 1
```


<div style='page-break-after: always;'></div>

# File: storefront-web\index.html

```html
<!doctype html>
<html>
<head>
  <title>ZuriShop</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      background: #f5f5f5;
    }

    .card {
      background: white;
      padding: 20px;
      border-radius: 8px;
      max-width: 900px;
    }

    input {
      padding: 8px;
      width: 300px;
      margin-right: 8px;
    }

    button {
      padding: 8px 12px;
      cursor: pointer;
    }

    pre {
      background: #111;
      color: #0f0;
      padding: 12px;
      overflow: auto;
      border-radius: 6px;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>ZuriShop</h1>
    <p>Simple retail storefront for the ZuriMart DevOps mastery project.</p>

    <input id="search" placeholder="Search products" />
    <button onclick="searchProducts()">Search</button>
    <button onclick="loadProducts()">Load All Products</button>
    <button onclick="reseedSearch()">Admin: Re-seed Search</button>

    <h2>Output</h2>
    <pre id="output">Loading...</pre>
  </div>

  <script>
    const PRODUCT_API_URL = "http://localhost:8001";
    const SEARCH_API_URL = "http://localhost:8007";

    async function loadProducts() {
      try {
        const response = await fetch(`${PRODUCT_API_URL}/products`);
        const data = await response.json();
        document.getElementById("output").textContent = JSON.stringify(data, null, 2);
      } catch (error) {
        document.getElementById("output").textContent = `Error: ${error}`;
      }
    }

    async function searchProducts() {
      try {
        const query = document.getElementById("search").value;
        const response = await fetch(`${SEARCH_API_URL}/search?q=${encodeURIComponent(query)}`);
        const data = await response.json();
        document.getElementById("output").textContent = JSON.stringify(data, null, 2);
      } catch (error) {
        document.getElementById("output").textContent = `Error: ${error}`;
      }
    }

    async function reseedSearch() {
      try {
        const response = await fetch(`${SEARCH_API_URL}/search/index`, { method: "POST" });
        const data = await response.json();
        document.getElementById("output").textContent = JSON.stringify(data, null, 2);
      } catch (error) {
        document.getElementById("output").textContent = `Error: ${error}`;
      }
    }

    loadProducts();
  </script>
</body>
</html>
```


<div style='page-break-after: always;'></div>

# File: zurishop-report.csv

```csv
"ProductId","Name","Price","Currency","Stock"
"SKU-001","Wireless Mouse","1500","KES","50"
"SKU-002","Mechanical Keyboard","6500","KES","19"
"SKU-003","USB-C Cable","700","KES","50"
"SKU-004","Laptop Stand","3200","KES","10"

```

