<#
.SYNOPSIS
Compares group membership of two Active Directory users and exports to CSV.

.DESCRIPTION
Reads two usernames either directly from parameters or from a CSV file (default: users.csv
next to the script). Compares the group membership of both users and outputs the groups
that are only in User1, only in User2, and shared. Results are exported to a CSV file.

.PARAMETER User1
First username (samAccountName). Optional if using -CsvFile.
.PARAMETER User2
Second username (samAccountName). Optional if using -CsvFile.
.PARAMETER CsvFile
Path to a CSV file containing the usernames. Defaults to users.csv in the script directory.
.PARAMETER OutputPath
Optional path for the result CSV. Defaults to Compare-Groups.csv in current directory.

.EXAMPLE
.\Compare-ADGroupMembership.ps1
# Uses users.csv by default

.EXAMPLE
.\Compare-ADGroupMembership.ps1 -User1 jdoe -User2 jsmith

.NOTES
Requires the ActiveDirectory PowerShell module.
#>
param(
    [string]$User1,
    [string]$User2,
    [string]$CsvFile,
    [string]$OutputPath
)

# Robustly resolve the script's directory. $PSScriptRoot is empty when the script
# is run interactively or invoked in some module/dot-sourcing contexts.
function Get-ScriptDirectory {
    if ($PSScriptRoot) { return $PSScriptRoot }
    $path = $MyInvocation.MyCommand.Path
    if ($path) { return (Split-Path -Parent $path) }
    return (Get-Location).Path
}

# Defaults (resolved here so pathing is robust)
if (-not $CsvFile)    { $CsvFile = Join-Path (Get-ScriptDirectory) "users.csv" }
if (-not $OutputPath) { $OutputPath = Join-Path (Get-ScriptDirectory) "Compare-Groups.csv" }

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

# Get all direct groups for each user. Get-ADPrincipalGroupMembership is unreliable
# (often returns only the primary group), so use the memberOf attribute instead.
$groups1 = @(Get-ADUser -Identity $User1 -Properties memberOf).memberOf |
    ForEach-Object { (Get-ADGroup -Identity $_ -ErrorAction SilentlyContinue).Name }
$groups2 = @(Get-ADUser -Identity $User2 -Properties memberOf).memberOf |
    ForEach-Object { (Get-ADGroup -Identity $_ -ErrorAction SilentlyContinue).Name }

# Remove any empty names
$groups1 = $groups1 | Where-Object { $_ }
$groups2 = $groups2 | Where-Object { $_ }

# Compute differences (case-insensitive)
$onlyIn1 = $groups1 | Where-Object { $groups2 -notcontains $_ }
$onlyIn2 = $groups2 | Where-Object { $groups1 -notcontains $_ }
$inBoth  = $groups1 | Where-Object { $groups2 -contains $_ }

# Build a result table for CSV
$results = @()
foreach ($g in ($groups1 + $groups2 | Select-Object -Unique)) {
    $results += [PSCustomObject]@{
        GroupName  = $g
        InUser1    = ($groups1 -contains $g)
        InUser2    = ($groups2 -contains $g)
        Difference = if ($groups1 -contains $g -and $groups2 -contains $g) { "Shared" }
                    elseif ($groups1 -contains $g) { "Only $User1" }
                    else { "Only $User2" }
    }
}

# Export to CSV
$results | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "CSV exported to: $OutputPath" -ForegroundColor Cyan

# Display results
$onlyIn1Count = ($onlyIn1 | Measure-Object).Count
$onlyIn2Count = ($onlyIn2 | Measure-Object).Count
$inBothCount  = ($inBoth  | Measure-Object).Count

Write-Host "`n=== Groups only in $User1 ($onlyIn1Count) ===" -ForegroundColor Yellow
$onlyIn1 | ForEach-Object { Write-Host "  $_" }

Write-Host "`n=== Groups only in $User2 ($onlyIn2Count) ===" -ForegroundColor Yellow
$onlyIn2 | ForEach-Object { Write-Host "  $_" }

Write-Host "`n=== Shared groups ($inBothCount) ===" -ForegroundColor Green
$inBoth | ForEach-Object { Write-Host "  $_" }
