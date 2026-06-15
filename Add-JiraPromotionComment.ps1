param(
    [Parameter(Mandatory = $true)][string]$JiraKey,
    [Parameter(Mandatory = $true)][string]$RepoFullName,
    [Parameter(Mandatory = $true)][string]$SourceBranch,
    [Parameter(Mandatory = $true)][string]$SourceSha,
    [Parameter(Mandatory = $true)][string]$MainSha,
    [Parameter(Mandatory = $false)][string]$ProdSpaceName = "",
    [Parameter(Mandatory = $true)][string]$Status,
    [Parameter(Mandatory = $true)][string]$RunUrl,
    [Parameter(Mandatory = $false)][bool]$DryRun = $false
)

$ErrorActionPreference = "Stop"

$bodyText = @"
Qlik production promotion completed with status: $Status

Repository: $RepoFullName
Production space: $ProdSpaceName
Source branch: $SourceBranch
Source SHA: $SourceSha
Main SHA: $MainSha
Workflow run: $RunUrl
"@

Write-Host "Jira comment payload:"
Write-Host $bodyText
Write-Host "Dry run: $DryRun"

if ($DryRun) {
    Write-Host "Dry run enabled. Skipping Jira comment write."
    return
}

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$env:JIRA_EMAIL`:$env:JIRA_API_TOKEN"))
$headers = @{
    Authorization = "Basic $auth"
    Accept = "application/json"
    "Content-Type" = "application/json"
}

$body = @{
    body = @{
        type = "doc"
        version = 1
        content = @(
            @{
                type = "paragraph"
                content = @(
                    @{
                        type = "text"
                        text = $bodyText
                    }
                )
            }
        )
    }
}

$uri = "$($env:JIRA_BASE_URL.TrimEnd('/'))/rest/api/3/issue/$JiraKey/comment"
Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body ($body | ConvertTo-Json -Depth 10)

Write-Host "Added Jira comment to $JiraKey"

