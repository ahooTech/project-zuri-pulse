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