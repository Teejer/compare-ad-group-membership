# Compare-ADGroupMembership

Compares the group membership of two Active Directory users and shows the difference between them.

## What it does

Given two usernames, the script:

- Lists groups that are **only** in User1
- Lists groups that are **only** in User2
- Lists groups that are **shared** between both users
- Exports the full comparison to a CSV file

## Requirements

- Windows machine joined to / with access to the Active Directory domain
- `ActiveDirectory` PowerShell module (part of RSAT)

## Usage

```powershell
# Uses users.csv by default
.\Compare-ADGroupMembership.ps1

# Specify a different CSV
.\Compare-ADGroupMembership.ps1 -CsvFile "C:\path\to\users.csv"

# Or pass the users directly
.\Compare-ADGroupMembership.ps1 -User1 jdoe -User2 jsmith
```

### Input CSV format

By default the script looks for `users.csv` next to the script file, with a header row and one data row:

```csv
User1,User2
jdoe,jsmith
```

### Output CSV

The result CSV (default `Compare-Groups.csv`) has these columns:

| GroupName | InUser1 | InUser2 | Difference |
|-----------|---------|---------|------------|
| GroupA     | True    | False   | Only jdoe  |
| GroupB     | True    | True    | Shared     |

## Parameters

| Parameter  | Description                                                        | Default               |
|------------|--------------------------------------------------------------------|-----------------------|
| `User1`    | First username (samAccountName)                                    | -                     |
| `User2`    | Second username (samAccountName)                                   | -                     |
| `CsvFile`  | CSV file containing the two users                                  | `users.csv`           |
| `OutputPath` | Path for the result CSV                                           | `Compare-Groups.csv`  |
