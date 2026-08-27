<#
.SYNOPSIS
Adds groups that User1 has onto User2 (only the ones User2 doesn't already have).

.DESCRIPTION
Reads two usernames either directly from parameters or from a CSV file (default: users.csv
next to the script). Compares group membership of User1 and User2, then adds the groups
that only User1 has onto User2. Groups User2 already has are skipped.

.PARAMETER User1
The user whose groups will be copied FROM (source). (samAccountName)
.PARAMETER User2
The user that will receive the groups (target). (samAccountName)
.PARAMETER CsvFile
Path to a CSV file containing the usernames. Defaults to users.csv in the script directory.
    Columns: User1,User2
.PARAMETER WhatIf
Show what would be added without making changes.

.EXAMPLE
.\Add-ADGroupMembership.ps1 -User1 jdoe -User2 jsmith

.EXAMPLE
.\Add-ADGroupMembership.ps1 -WhatIf

.NOTES
Requires the ActiveDirectory PowerShell module.
#>
param(
    [string]$User1,
    [string]$User2,
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
if (-not $User1 -or -not $User2) {
    if (-not (Test-Path $CsvFile)) {
        Write-Error "CSV file not found: $CsvFile"
        return
    }
    $users = Import-Csv -Path $CsvFile
    if (-not $users -or -not $users[0].User1 -or -not $users[0].User2) {
        Write-Error "CSV must have a header row with columns 'User1' and 'User2' and at least one data row."
        return
    }
    $User1 = $users[0].User1
    $User2 = $users[0].User2
}

# Get all direct groups for each user via the memberOf attribute
$sourceGroups = @(Get-ADUser -Identity $User1 -Properties memberOf).memberOf |
    ForEach-Object { (Get-ADGroup -Identity $_ -ErrorAction SilentlyContinue).Name } |
    Where-Object { $_ }

$targetGroups = @(Get-ADUser -Identity $User2 -Properties memberOf).memberOf |
    ForEach-Object { (Get-ADGroup -Identity $_ -ErrorAction SilentlyContinue).Name } |
    Where-Object { $_ }

# Groups to add: in source but not already in target
$groupsToAdd = $sourceGroups | Where-Object { $targetGroups -notcontains $_ }

Write-Host "Source ($User1) groups: $($sourceGroups.Count)" -ForegroundColor Cyan
Write-Host "Target ($User2) groups: $($targetGroups.Count)" -ForegroundColor Cyan
Write-Host "Groups to add: $($groupsToAdd.Count)" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "`n=== [WhatIf] Would add to $User2 ===" -ForegroundColor Yellow
    $groupsToAdd | ForEach-Object { Write-Host "  $_" }
    return
}

# Add each missing group to the target user
$addedCount = 0
foreach ($group in $groupsToAdd) {
    try {
        Add-ADGroupMember -Identity $group -Members $User2 -ErrorAction Stop
        Write-Host "  Added $User2 to: $group" -ForegroundColor Green
        $addedCount++
    }
    catch {
        Write-Warning "  Failed to add $User2 to $group : $($_.Exception.Message)"
    }
}

Write-Host "`nDone. Added $addedCount of $($groupsToAdd.Count) groups to $User2." -ForegroundColor Cyan
