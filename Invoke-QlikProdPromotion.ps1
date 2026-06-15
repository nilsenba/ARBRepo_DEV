param(
    [Parameter(Mandatory = $true)][string]$JiraKey,
    [Parameter(Mandatory = $true)][string]$RepoFullName,
    [Parameter(Mandatory = $true)][string]$SourceBranch,
    [Parameter(Mandatory = $true)][string]$SourceSha,
    [Parameter(Mandatory = $true)][string]$MainSha,
    [Parameter(Mandatory = $false)][string]$ProdSpaceName = "",
    [Parameter(Mandatory = $false)][bool]$DryRun = $false
)

$ErrorActionPreference = "Stop"

function Get-ArtifactPath {
    $qvf = Get-ChildItem -Path "." -Recurse -Filter "*.qvf" | Select-Object -First 1
    if (-not $qvf) {
        throw "No QVF artifact found in checked-out repository."
    }
    return $qvf.FullName
}

function Get-BaseSpaceName {
    param(
        [string]$RepositoryFullName,
        [string]$ExplicitSpaceName
    )

    if (-not [string]::IsNullOrWhiteSpace($ExplicitSpaceName)) {
        return $ExplicitSpaceName
    }

    $repoName = ($RepositoryFullName -split "/")[-1]
    return ($repoName -replace "-", " ")
}

function Invoke-QlikApi {
    param(
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Path,
        [object]$Body = $null
    )

    $tenant = $env:QLIK_PROD_TENANT_URL.TrimEnd("/")
    $headers = @{
        Authorization = "Bearer $env:QLIK_PROD_API_KEY"
        Accept = "application/json"
    }
    $uri = "$tenant$Path"

    if ($null -eq $Body) {
        return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers
    }

    return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body ($Body | ConvertTo-Json -Depth 10) -ContentType "application/json"
}

$artifactPath = Get-ArtifactPath
$resolvedProdSpaceName = Get-BaseSpaceName -RepositoryFullName $RepoFullName -ExplicitSpaceName $ProdSpaceName

Write-Host "Promotion identity:"
Write-Host "  Jira key: $JiraKey"
Write-Host "  Source branch: $SourceBranch"
Write-Host "  Source SHA: $SourceSha"
Write-Host "  Main SHA: $MainSha"
Write-Host "  Production space: $resolvedProdSpaceName"
Write-Host "  Artifact: $artifactPath"
Write-Host "  Dry run: $DryRun"

if ($DryRun) {
    Write-Host "Dry run enabled. Skipping Qlik Production API writes."
    return
}

# Build note:
# Replace the placeholder section below with the exact Qlik import/reload/publish API calls
# used by your tenant standard. Keep the script idempotent: repeated runs for the same
# Jira key should update/republish the same production app rather than creating duplicates.

Write-Host "TODO: Query Qlik Production tenant for target space '$resolvedProdSpaceName'."
Write-Host "TODO: Import artifact into production shared/staging space."
Write-Host "TODO: Reload app and validate expected app object."
Write-Host "TODO: Publish or republish to managed production space."

throw "Qlik production API implementation is intentionally stubbed until target space/app mapping is confirmed."

