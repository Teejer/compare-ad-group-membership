<#
.SYNOPSIS
Adds groups that User1 has onto User2 (only the ones User2 doesn't already have).

.DESCRIPTION
Reads two usernames either directly from parameters or from a CSV file (default: users.csv
next to the script). Compares group membership of User1 and User2, then adds the groups
that only User1 has onto User2. Groups User2 already has are skipped.

.PARAMETER SourceUser
The user whose groups will be copied FROM. (samAccountName)
.PARAMETER TargetUser
The user that will receive the groups. (samAccountName)
.PARAMETER CsvFile
Path to a CSV file containing the usernames. Defaults to users.csv in the script directory.
    Columns: SourceUser,TargetUser
.PARAMETER WhatIf
Show what would be added without making changes.

.EXAMPLE
.\Add-ADGroupMembership.ps1 -SourceUser jdoe -TargetUser jsmith

.EXAMPLE
.\Add-ADGroupMembership.ps1 -WhatIf

.NOTES
Requires the ActiveDirectory PowerShell module.
#>
param(
    [string]$SourceUser,
    [string]$TargetUser,
    [string]$CsvFile,
    [switch]$WhatIf
)

# Robustly resolve the script's directory.
function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    $path = $MyInvocation.MyCommand.Path
    if ($path) { return (Split-Path -Parent $path) }
    return (Get-Location).Path
}

# Default
if (-not $CsvFile) { $CsvFile = Join-Path (Get-ScriptDirectory) "users.csv" }

# If users not given directly, read from the CSV file
if (-not $SourceUser -or -not $TargetUser) {
    if (-not (Test-Path $CsvFile)) {
        Write-Error "CSV file not found: $CsvFile"
        return
    }
    $users = Import-Csv -Path $CsvFile
    if (-not $users -or -not $users[0].SourceUser -or -not $users[0].TargetUser) {
        Write-Error "CSV must have a header row with columns 'SourceUser' and 'TargetUser' and at least one data row."
        return
    }
    $SourceUser = $users[0].SourceUser
    $TargetUser = $users[0].TargetUser
}

# Get all direct groups for each user via the memberOf attribute
$sourceGroups = @(Get-ADUser -Identity $SourceUser -Properties memberOf).memberOf |
    ForEach-Object { (Get-ADGroup -Identity $_ -ErrorAction SilentlyContinue).Name } |
    Where-Object { $_ }

$targetGroups = @(Get-ADUser -Identity $TargetUser -Properties memberOf).memberOf |
    ForEach-Object { (Get-ADGroup -Identity $_ -ErrorAction SilentlyContinue).Name } |
    Where-Object { $_ }

# Groups to add: in source but not already in target
$groupsToAdd = $sourceGroups | Where-Object { $targetGroups -notcontains $_ }

Write-Host "Source ($SourceUser) groups: $($sourceGroups.Count)" -ForegroundColor Cyan
Write-Host "Target ($TargetUser) groups: $($targetGroups.Count)" -ForegroundColor Cyan
Write-Host "Groups to add: $($groupsToAdd.Count)" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "`n=== [WhatIf] Would add to $TargetUser ===" -ForegroundColor Yellow
    $groupsToAdd | ForEach-Object { Write-Host "  $_" }
    return
}

# Add each missing group to the target user
$addedCount = 0
foreach ($group in $groupsToAdd) {
    try {
        Add-ADGroupMember -Identity $group -Members $TargetUser -ErrorAction Stop
        Write-Host "  Added $TargetUser to: $group" -ForegroundColor Green
        $addedCount++
    }
    catch {
        Write-Warning "  Failed to add $TargetUser to $group : $($_.Exception.Message)"
    }
}

Write-Host "`nDone. Added $addedCount of $($groupsToAdd.Count) groups to $TargetUser." -ForegroundColor Cyan
