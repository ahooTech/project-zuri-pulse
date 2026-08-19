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