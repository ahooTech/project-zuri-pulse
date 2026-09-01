#Requires -Version 5.1

param(
    [switch]$SkipApply
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$tfRoot = Join-Path $repoRoot "infra\terraform"
$backendsRoot = Join-Path $tfRoot "backends"
$reportDir = Join-Path $repoRoot "docs\phase-2"
New-Item -ItemType Directory -Force -Path $reportDir | Out-Null
$reportPath = Join-Path $reportDir "2.1-state-backend-evidence.md"

function Invoke-Native {
    param(
        [string]$Command,
        [string[]]$Arguments
    )

    Write-Host "$Command $($Arguments -join ' ')" -ForegroundColor DarkCyan
    & $Command @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "$Command failed with exit code $LASTEXITCODE"
    }
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Text
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

if (-not $env:AWS_PROFILE) {
    $env:AWS_PROFILE = "zuri-platform"
}

foreach ($tool in @("terraform", "aws", "az", "gcloud")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool is not installed."
    }
}

try {
    $null = aws sts get-caller-identity --output json --profile $env:AWS_PROFILE | ConvertFrom-Json
}
catch {
    throw "AWS authentication failed for profile $($env:AWS_PROFILE)."
}

try {
    $null = az account show --only-show-errors | ConvertFrom-Json
}
catch {
    throw "Azure authentication failed. Run az login and ensure a subscription is selected."
}

$gcpProject = (gcloud config get-value project 2>$null).Trim()

if (-not $gcpProject -or $gcpProject -eq "(unset)") {
    throw "GCP project is not set. Run: gcloud config set project <PROJECT_ID>"
}

$awsRegion = "us-east-1"
$azureLocation = "eastus"
$gcpRegion = "us-central1"
$gcpBucketLocation = "US"

if (-not $SkipApply) {

    Write-Host "Bootstrapping AWS state backend..." -ForegroundColor Cyan
    $awsBootstrap = Join-Path $tfRoot "bootstrap\aws"
    Push-Location $awsBootstrap
    Invoke-Native terraform @("init", "-input=false")
    Invoke-Native terraform @("apply", "-input=false", "-auto-approve", "-var=aws_region=$awsRegion")
    Pop-Location

    Write-Host "Bootstrapping Azure state backend..." -ForegroundColor Cyan
    $azureBootstrap = Join-Path $tfRoot "bootstrap\azure"
    Push-Location $azureBootstrap
    Invoke-Native terraform @("init", "-input=false")
    Invoke-Native terraform @("apply", "-input=false", "-auto-approve", "-var=azure_location=$azureLocation")
    Pop-Location

    Write-Host "Bootstrapping GCP state backend..." -ForegroundColor Cyan
    $gcpBootstrap = Join-Path $tfRoot "bootstrap\gcp"
    Push-Location $gcpBootstrap
    Invoke-Native terraform @("init", "-input=false")
    Invoke-Native terraform @("apply", "-input=false", "-auto-approve", "-var=gcp_project_id=$gcpProject", "-var=gcp_region=$gcpRegion", "-var=gcp_bucket_location=$gcpBucketLocation")
    Pop-Location
}

Write-Host "Reading bootstrap outputs..." -ForegroundColor Cyan

Push-Location (Join-Path $tfRoot "bootstrap\aws")
$awsBucket = (terraform output -raw s3_bucket_name).Trim()
$awsLock = (terraform output -raw dynamodb_lock_table).Trim()
Pop-Location

Push-Location (Join-Path $tfRoot "bootstrap\azure")
$azureResourceGroup = (terraform output -raw resource_group_name).Trim()
$azureStorageAccount = (terraform output -raw storage_account_name).Trim()
$azureContainer = (terraform output -raw container_name).Trim()
Pop-Location

Push-Location (Join-Path $tfRoot "bootstrap\gcp")
$gcpBucket = (terraform output -raw state_bucket_name).Trim()
Pop-Location

foreach ($cloud in @("aws", "azure", "gcp")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $backendsRoot $cloud) | Out-Null
}

$environments = @("dev", "staging", "production")
$layers = @("networking", "security", "kubernetes", "databases", "monitoring")

Write-Host "Generating backend configuration files..." -ForegroundColor Cyan

foreach ($environment in $environments) {
    foreach ($layer in $layers) {

        $awsBackendPath = Join-Path $backendsRoot "aws\$environment-$layer.hcl"
        $awsContent = @(
            "bucket         = `"$awsBucket`"",
            "key            = `"zuri-platform/$environment/$layer/terraform.tfstate`"",
            "region         = `"$awsRegion`"",
            "use_lockfile   = true",
            "encrypt        = true"
        ) -join "`n"
        Write-Utf8NoBom -Path $awsBackendPath -Text $awsContent

        $azureBackendPath = Join-Path $backendsRoot "azure\$environment-$layer.hcl"
        $azureContent = @(
            "resource_group_name  = `"$azureResourceGroup`"",
            "storage_account_name = `"$azureStorageAccount`"",
            "container_name       = `"$azureContainer`"",
            "key                  = `"zuri-platform/$environment/$layer/terraform.tfstate`""
        ) -join "`n"
        Write-Utf8NoBom -Path $azureBackendPath -Text $azureContent

        $gcpBackendPath = Join-Path $backendsRoot "gcp\$environment-$layer.hcl"
        $gcpContent = @(
            "bucket = `"$gcpBucket`"",
            "prefix = `"zuri-platform/$environment/$layer`""
        ) -join "`n"
        Write-Utf8NoBom -Path $gcpBackendPath -Text $gcpContent
    }
}

Write-Host "Validating backends using empty Terraform roots..." -ForegroundColor Cyan

$validationRoot = Join-Path $tfRoot "scripts\backend-validation"

$validationTargets = @(
    @{
        Cloud       = "aws"
        BackendFile = Join-Path $backendsRoot "aws\dev-networking.hcl"
        Content     = @("terraform {", '  backend "s3" {}', "}") -join "`n"
    },
    @{
        Cloud       = "azure"
        BackendFile = Join-Path $backendsRoot "azure\dev-networking.hcl"
        Content     = @("terraform {", '  backend "azurerm" {}', "}") -join "`n"
    },
    @{
        Cloud       = "gcp"
        BackendFile = Join-Path $backendsRoot "gcp\dev-networking.hcl"
        Content     = @("terraform {", '  backend "gcs" {}', "}") -join "`n"
    }
)

foreach ($target in $validationTargets) {
    $validationPath = Join-Path $validationRoot $target.Cloud
    New-Item -ItemType Directory -Force -Path $validationPath | Out-Null

    Remove-Item -Recurse -Force (Join-Path $validationPath ".terraform") -ErrorAction SilentlyContinue
    Remove-Item -Force (Join-Path $validationPath "terraform.tfstate") -ErrorAction SilentlyContinue
    Remove-Item -Force (Join-Path $validationPath "terraform.tfstate.backup") -ErrorAction SilentlyContinue

    $mainTfPath = Join-Path $validationPath "main.tf"
    Write-Utf8NoBom -Path $mainTfPath -Text $target.Content

    Push-Location $validationPath
    Invoke-Native terraform @("init", "-input=false", "-reconfigure", "-backend-config=$($target.BackendFile)")
    Pop-Location
}

$backendFileCount = (Get-ChildItem -Path $backendsRoot -Recurse -Filter *.hcl).Count

$markdown = @()
$markdown += "# Phase 2 Step 2 Evidence"
$markdown += ""
$markdown += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$markdown += ""
$markdown += "## Remote State Resources"
$markdown += ""
$markdown += "| Cloud | Item | Value |"
$markdown += "|---|---|---|"
$markdown += "| AWS | State bucket | $awsBucket |"
$markdown += "| AWS | Lock table | $awsLock |"
$markdown += "| AWS | Region | $awsRegion |"
$markdown += "| Azure | Resource group | $azureResourceGroup |"
$markdown += "| Azure | Storage account | $azureStorageAccount |"
$markdown += "| Azure | Container | $azureContainer |"
$markdown += "| GCP | State bucket | $gcpBucket |"
$markdown += "| GCP | Project | $gcpProject |"
$markdown += ""
$markdown += "## Backend Files"
$markdown += ""
$markdown += "Generated backend files: $backendFileCount"
$markdown += ""
$markdown += "Expected backend files: 45"
$markdown += ""

if ($backendFileCount -eq 45) {
    $markdown += "Backend generation status: PASS"
}
else {
    $markdown += "Backend generation status: FAIL"
}

Set-Content -Path $reportPath -Value $markdown -Encoding UTF8

Write-Host ""
Write-Host "Report written to: $reportPath" -ForegroundColor Green
Write-Host ""
Write-Host "BOOTSTRAP COMPLETE." -ForegroundColor Green



# ------------------------------------------------------------
# 1. How to run this .ps1 file
# ------------------------------------------------------------


# Verify generated backend files
# Get-ChildItem infra\terraform\backends -Recurse -Filter *.hcl | Measure-Object

# Verify AWS Resources
# aws s3 ls --profile zuri-platform
# aws dynamodb list-tables --profile zuri-platform --output table

# Verify AZURE
# az storage account list --query "[?contains(name, 'zuripulsetf')].{name:name, resourceGroup:resourceGroup}" --output table
# az storage container list --account-name <YOUR_STORAGE_ACCOUNT_NAME> --output table


# Verify GCP
# gcloud storage buckets list --filter="name~tfstate"

# Delete the old broken validation folder
# PS C:\project-zuri-pulse> Remove-Item -Recurse -Force infra\terraform\scripts\backend-validation -ErrorAction SilentlyContinue

# When your AWS, Azure, and GCP state resources already exist, you can skip applying them again:
# PS C:\project-zuri-pulse> powershell .\infra\terraform\scripts\bootstrap-state.ps1 -SkipApply

# PS C:\project-zuri-pulse> powershell .\infra\terraform\scripts\bootstrap-state.ps1