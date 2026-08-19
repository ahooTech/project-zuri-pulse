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