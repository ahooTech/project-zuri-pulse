#Requires -Version 5.1

param(
    [string]$AwsRegion = "us-east-1",
    [string]$AzureLocation = "eastus",
    [string]$GcpRegion = "us-central1",
    [string]$GcpBucketLocation = "US",

    # Skips the interactive YES prompt
    [switch]$Force,

    # Automatically runs bootstrap-state.ps1 after destroy
    [switch]$Recreate,

    # Keeps local generated backend .hcl files and validation folder
    [switch]$SkipLocalCleanup,

    # Removes local bootstrap terraform.tfstate files after successful destroy
    [switch]$RemoveLocalState
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$tfRoot = Join-Path $repoRoot "infra\terraform"
$bootstrapRoot = Join-Path $tfRoot "bootstrap"
$scriptsRoot = Join-Path $tfRoot "scripts"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Text
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

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

function Set-ForceDestroy {
    param(
        [string]$Path,
        [string]$ResourcePattern
    )

    $original = [System.IO.File]::ReadAllText($Path)
    $modified = $original

    if ($modified -match 'force_destroy\s*=\s*false') {
        $modified = [regex]::Replace(
            $modified,
            'force_destroy\s*=\s*false',
            'force_destroy = true'
        )
    }
    elseif ($modified -notmatch 'force_destroy\s*=\s*true') {
        $modified = [regex]::Replace(
            $modified,
            $ResourcePattern,
            '$1' + "`r`n  force_destroy = true"
        )
    }

    if ($modified -notmatch 'force_destroy\s*=\s*true') {
        throw "Could not set force_destroy = true in $Path"
    }

    Write-Utf8NoBom -Path $Path -Text $modified

    return $original
}

# ------------------------------------------------------------
# Tool checks
# ------------------------------------------------------------

foreach ($tool in @("terraform", "aws", "az", "gcloud")) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool is not installed or not available in PATH."
    }
}

if (-not $env:AWS_PROFILE) {
    $env:AWS_PROFILE = "zuri-platform"
}

# ------------------------------------------------------------
# Cloud auth checks
# ------------------------------------------------------------

Write-Host "Checking cloud authentication..." -ForegroundColor Cyan

$null = & aws sts get-caller-identity --output json --profile $env:AWS_PROFILE | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "AWS authentication failed for profile $($env:AWS_PROFILE)."
}

$null = & az account show --only-show-errors | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Azure authentication failed. Run az login and ensure a subscription is selected."
}

$gcpProject = (gcloud config get-value project 2>$null).Trim()
if (-not $gcpProject -or $gcpProject -eq "(unset)") {
    throw "GCP project is not set. Run: gcloud config set project <PROJECT_ID>"
}

# ------------------------------------------------------------
# Confirmation
# ------------------------------------------------------------

if (-not $Force) {
    Write-Host ""
    Write-Host "WARNING: This will destroy the ZuriMart Phase 2 Terraform state backends." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This will delete:" -ForegroundColor Yellow
    Write-Host "  - AWS S3 state bucket"
    Write-Host "  - AWS DynamoDB lock table"
    Write-Host "  - Azure resource group, storage account, and tfstate container"
    Write-Host "  - GCP GCS state bucket"
    Write-Host ""
    Write-Host "Do NOT run this if you already have real Terraform state stored in these backends." -ForegroundColor Red
    Write-Host ""

    $confirmation = Read-Host "Type YES to continue"

    if ($confirmation -ne "YES") {
        throw "Destroy aborted by user."
    }
}

# ------------------------------------------------------------
# Backup local bootstrap state files
# ------------------------------------------------------------

$backupRoot = Join-Path $bootstrapRoot "state-backup"
$timestamp = Get-Date -Format "yyyy-MM-dd-HH-mm-ss"
$backupPath = Join-Path $backupRoot $timestamp

New-Item -ItemType Directory -Force -Path $backupPath | Out-Null

foreach ($cloud in @("aws", "azure", "gcp")) {
    $stateFile = Join-Path $bootstrapRoot "$cloud\terraform.tfstate"
    $stateBackupFile = Join-Path $backupPath "$cloud.terraform.tfstate"

    if (Test-Path $stateFile) {
        Copy-Item -Path $stateFile -Destination $stateBackupFile -Force
        Write-Host "Backed up $cloud state to $stateBackupFile" -ForegroundColor DarkGreen
    }

    $stateBackup = Join-Path $bootstrapRoot "$cloud\terraform.tfstate.backup"
    $stateBackupCopy = Join-Path $backupPath "$cloud.terraform.tfstate.backup"

    if (Test-Path $stateBackup) {
        Copy-Item -Path $stateBackup -Destination $stateBackupCopy -Force
        Write-Host "Backed up $cloud state backup to $stateBackupCopy" -ForegroundColor DarkGreen
    }
}

# ------------------------------------------------------------
# Destroy AWS state backend
# ------------------------------------------------------------

Write-Host ""
Write-Host "Destroying AWS state backend..." -ForegroundColor Cyan

$awsDir = Join-Path $bootstrapRoot "aws"
$awsMain = Join-Path $awsDir "main.tf"

$originalAwsMain = Set-ForceDestroy `
    -Path $awsMain `
    -ResourcePattern '(?m)(resource\s+"aws_s3_bucket"\s+"terraform_state"\s*\{)'

try {
    Invoke-Native terraform @("-chdir=$awsDir", "init", "-input=false")
    Invoke-Native terraform @("-chdir=$awsDir", "apply", "-input=false", "-auto-approve", "-var=aws_region=$AwsRegion")
    Invoke-Native terraform @("-chdir=$awsDir", "destroy", "-input=false", "-auto-approve", "-var=aws_region=$AwsRegion")

    Write-Utf8NoBom -Path $awsMain -Text $originalAwsMain
    Write-Host "AWS state backend destroyed." -ForegroundColor Green
}
catch {
    Write-Host "AWS destroy failed. $awsMain may still contain force_destroy = true." -ForegroundColor Red
    throw
}

# ------------------------------------------------------------
# Destroy Azure state backend
# ------------------------------------------------------------

Write-Host ""
Write-Host "Destroying Azure state backend..." -ForegroundColor Cyan

$azureDir = Join-Path $bootstrapRoot "azure"

try {
    Invoke-Native terraform @("-chdir=$azureDir", "init", "-input=false")
    Invoke-Native terraform @("-chdir=$azureDir", "destroy", "-input=false", "-auto-approve", "-var=azure_location=$AzureLocation")

    Write-Host "Azure state backend destroyed." -ForegroundColor Green
}
catch {
    Write-Host "Azure destroy failed." -ForegroundColor Red
    throw
}

# ------------------------------------------------------------
# Destroy GCP state backend
# ------------------------------------------------------------

Write-Host ""
Write-Host "Destroying GCP state backend..." -ForegroundColor Cyan

$gcpDir = Join-Path $bootstrapRoot "gcp"
$gcpMain = Join-Path $gcpDir "main.tf"

$originalGcpMain = Set-ForceDestroy `
    -Path $gcpMain `
    -ResourcePattern '(?m)(resource\s+"google_storage_bucket"\s+"terraform_state"\s*\{)'

try {
    Invoke-Native terraform @("-chdir=$gcpDir", "init", "-input=false")

    Invoke-Native terraform @(
        "-chdir=$gcpDir",
        "apply",
        "-input=false",
        "-auto-approve",
        "-var=gcp_project_id=$gcpProject",
        "-var=gcp_region=$GcpRegion",
        "-var=gcp_bucket_location=$GcpBucketLocation"
    )

    Invoke-Native terraform @(
        "-chdir=$gcpDir",
        "destroy",
        "-input=false",
        "-auto-approve",
        "-var=gcp_project_id=$gcpProject",
        "-var=gcp_region=$GcpRegion",
        "-var=gcp_bucket_location=$GcpBucketLocation"
    )

    Write-Utf8NoBom -Path $gcpMain -Text $originalGcpMain
    Write-Host "GCP state backend destroyed." -ForegroundColor Green
}
catch {
    Write-Host "GCP destroy failed. $gcpMain may still contain force_destroy = true." -ForegroundColor Red
    throw
}

# ------------------------------------------------------------
# Clean locally generated backend files
# ------------------------------------------------------------

if (-not $SkipLocalCleanup) {
    Write-Host ""
    Write-Host "Cleaning locally generated backend files..." -ForegroundColor Cyan

    Remove-Item -Recurse -Force (Join-Path $scriptsRoot "backend-validation") -ErrorAction SilentlyContinue

    Remove-Item -Force (Join-Path $tfRoot "backends\aws\*.hcl") -ErrorAction SilentlyContinue
    Remove-Item -Force (Join-Path $tfRoot "backends\azure\*.hcl") -ErrorAction SilentlyContinue
    Remove-Item -Force (Join-Path $tfRoot "backends\gcp\*.hcl") -ErrorAction SilentlyContinue

    Write-Host "Local backend files cleaned." -ForegroundColor Green
}

# ------------------------------------------------------------
# Optional: remove local bootstrap state files
# ------------------------------------------------------------

if ($RemoveLocalState) {
    Write-Host ""
    Write-Host "Removing local bootstrap state files..." -ForegroundColor Cyan

    foreach ($cloud in @("aws", "azure", "gcp")) {
        Remove-Item -Force (Join-Path $bootstrapRoot "$cloud\terraform.tfstate") -ErrorAction SilentlyContinue
        Remove-Item -Force (Join-Path $bootstrapRoot "$cloud\terraform.tfstate.backup") -ErrorAction SilentlyContinue
    }

    Write-Host "Local bootstrap state files removed." -ForegroundColor Green
}

# ------------------------------------------------------------
# Optional recreate
# ------------------------------------------------------------

Write-Host ""
Write-Host "STATE BACKEND DESTROY COMPLETE." -ForegroundColor Green

if ($Recreate) {
    Write-Host ""
    Write-Host "Recreating state backends using bootstrap-state.ps1..." -ForegroundColor Cyan

    & (Join-Path $scriptsRoot "bootstrap-state.ps1")
}
else {
    Write-Host ""
    Write-Host "To recreate the state backends, run:" -ForegroundColor Cyan
    Write-Host "powershell .\infra\terraform\scripts\bootstrap-state.ps1"
}




# ------------------------------------------------------------
# 1. How to run this .ps1 file
# ------------------------------------------------------------


# powershell .\infra\terraform\scripts\destroy-state.ps1 -> then type YES

#  powershell .\infra\terraform\scripts\destroy-state.ps1 -Force  -> no need to type yes

# powershell .\infra\terraform\scripts\destroy-state.ps1 -Force -Recreate -> destroy and immediately recreate


# powershell .\infra\terraform\scripts\destroy-state.ps1 -Force -RemoveLocalState  -> If you want a completely fresh local Terraform state after destroy, run this


# powershell .\infra\terraform\scripts\bootstrap-state.ps1  -> recreate later




# Verify AWS
# aws s3 ls --profile zuri-platform
# aws dynamodb list-tables --profile zuri-platform --output table

# Verify AZURE
# az group list --query "[?contains(name, 'zuri-platform-tfstate')].name" --output table

# Verify GCP
# gcloud storage buckets list --filter="name~tfstate"




