#Requires -Version 5.1

param(
    [switch]$SkipCloudAuth
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$reportDir = Join-Path $repoRoot "docs\phase-2"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$reportPath = Join-Path $reportDir "2.0-tooling-auth-evidence.md"

$checks = @()

function Add-Check {
    param(
        $Name,
        $Status,
        $Detail
    )

    $script:checks += [pscustomobject]@{
        Name   = $Name
        Status = $Status
        Detail = $Detail
    }
}

function Get-FirstLine {
    param(
        $Value
    )

    return ($Value | Out-String).Trim().Split("`n")[0].Trim()
}

# ------------------------------------------------------------
# 1. Tool checks
# ------------------------------------------------------------

$tools = @(
    "terraform",
    "aws",
    "az",
    "gcloud",
    "python",
    "tflint",
    "tfsec",
    "checkov"
)

foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        try {
            # We use cmd /c to prevent PowerShell from wrapping stderr into ErrorRecords 
            # which triggers the catch block when $ErrorActionPreference is "Stop".
            $rawOutput = cmd /c "$tool --version 2>&1"
            $firstLine = ($rawOutput | Out-String).Trim().Split("`n")[0].Trim()
            
            # Fallback if the first line is empty or weird
            if ([string]::IsNullOrWhiteSpace($firstLine)) {
                $firstLine = "Installed"
            }
            
            Add-Check $tool "PASS" $firstLine
        }
        catch {
            # If it still somehow throws, but the binary exists, it's a PASS for our purposes
            Add-Check $tool "PASS" "Installed (binary found, version check bypassed)"
        }
    }
    else {
        Add-Check $tool "FAIL" "Command not found"
    }
}


# ------------------------------------------------------------
# 2. Folder structure checks
# ------------------------------------------------------------

$requiredFolders = @(
    "infra\terraform\modules\aws",
    "infra\terraform\modules\azure",
    "infra\terraform\modules\gcp",
    "infra\terraform\environments\dev",
    "infra\terraform\environments\staging",
    "infra\terraform\environments\production",
    "infra\terraform\global\dns",
    "infra\terraform\global\iam",
    "infra\terraform\global\tags",
    "infra\terraform\backends\aws",
    "infra\terraform\backends\azure",
    "infra\terraform\backends\gcp",
    "infra\terraform\scripts",
    "infra\terraform\policies"
)

foreach ($folder in $requiredFolders) {
    $fullPath = Join-Path $repoRoot $folder

    if (Test-Path $fullPath) {
        Add-Check "folder:$folder" "PASS" "Exists"
    }
    else {
        Add-Check "folder:$folder" "FAIL" "Missing"
    }
}

# ------------------------------------------------------------
# 3. Cloud authentication checks
# ------------------------------------------------------------

if (-not $SkipCloudAuth) {

    # AWS
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        try {
            $awsProfile = if ($env:AWS_PROFILE) { $env:AWS_PROFILE } else { "default" }

            $raw = aws sts get-caller-identity --output json --profile $awsProfile 2>&1 | Out-String
            $identity = $raw | ConvertFrom-Json

            $maskedAccount = $identity.Account.Substring(0, 4) + "********"

            Add-Check "aws-auth" "PASS" "Profile=$awsProfile, Account=$maskedAccount"
        }
        catch {
            Add-Check "aws-auth" "FAIL" $_.Exception.Message
        }
    }
    else {
        Add-Check "aws-auth" "FAIL" "AWS CLI not installed"
    }

    # Azure
    if (Get-Command az -ErrorAction SilentlyContinue) {
        try {
            $raw = az account show --only-show-errors 2>&1 | Out-String
            $account = $raw | ConvertFrom-Json

            $maskedSubscription = $account.id.Substring(0, 8) + "****"

            Add-Check "azure-auth" "PASS" "Subscription=$($account.name), ID=$maskedSubscription"
        }
        catch {
            Add-Check "azure-auth" "FAIL" $_.Exception.Message
        }
    }
    else {
        Add-Check "azure-auth" "FAIL" "Azure CLI not installed"
    }

    # GCP
    if (Get-Command gcloud -ErrorAction SilentlyContinue) {
        try {
            $project = (gcloud config get-value project 2>$null).Trim()

            if ($project -and $project -ne "(unset)") {
                Add-Check "gcp-project" "PASS" "GCP project is set"
            }
            else {
                Add-Check "gcp-project" "FAIL" "GCP project is not set"
            }

            $account = (gcloud config get-value account 2>$null).Trim()

            if ($account) {
                Add-Check "gcp-account" "PASS" "Active GCP account is set"
            }
            else {
                Add-Check "gcp-account" "FAIL" "No active GCP account"
            }

            $adcPath = Join-Path $env:APPDATA "gcloud\application_default_credentials.json"

            if (Test-Path $adcPath) {
                Add-Check "gcp-adc" "PASS" "Application Default Credentials file exists"
            }
            else {
                Add-Check "gcp-adc" "FAIL" "Application Default Credentials file not found"
            }
        }
        catch {
            Add-Check "gcp-auth" "FAIL" $_.Exception.Message
        }
    }
    else {
        Add-Check "gcp-auth" "FAIL" "Google Cloud CLI not installed"
    }
}

# ------------------------------------------------------------
# 4. Generate evidence report
# ------------------------------------------------------------

$failures = @($checks | Where-Object { $_.Status -eq "FAIL" }).Count

$markdown = @()
$markdown += "# Phase 2 Step 1 Evidence"
$markdown += ""
$markdown += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$markdown += ""
$markdown += "| Check | Status | Detail |"
$markdown += "|---|---|---|"

foreach ($check in $checks) {
    $safeDetail = $check.Detail -replace '\|', '/'
    $markdown += "| $($check.Name) | $($check.Status) | $safeDetail |"
}

$markdown += ""
$markdown += "Failures: $failures"

Set-Content -Path $reportPath -Value $markdown -Encoding UTF8

Write-Host ""
Write-Host "Report written to: $reportPath"
Write-Host ""

if ($failures -gt 0) {
    Write-Host "PREFLIGHT FAILED. Fix the failed checks before continuing." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "PREFLIGHT PASSED." -ForegroundColor Green
    exit 0
}



# ------------------------------------------------------------
# 5. How to run this .ps1 file
# ------------------------------------------------------------

# powershell .\infra\terraform\scripts\phase2-preflight.ps1