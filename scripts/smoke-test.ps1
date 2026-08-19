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