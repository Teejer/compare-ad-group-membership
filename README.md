# Compare-ADGroupMembership

Compares the group membership of two Active Directory users and shows the difference between them.

## Scripts

Two scripts are included, both reading from the same `users.csv` file:

- **Compare-ADGroupMembership.ps1** — lists the group differences between the two users.
- **Add-ADGroupMembership.ps1** — copies the groups User1 has onto User2 (only the ones User2 doesn't already have).

## What Compare does

Given two usernames, the script:

- Lists groups that are **only** in User1
- Lists groups that are **only** in User2
- Lists groups that are **shared** between both users
- Exports the full comparison to a CSV file

## What Add does

Given two usernames, the script:

- Finds the groups User1 has that User2 does **not** already have
- Adds those groups to User2
- Reports which groups were added / skipped
- Supports `-WhatIf` to preview without making changes

## Requirements

- Windows machine joined to / with access to the Active Directory domain
- `ActiveDirectory` PowerShell module (part of RSAT)

## Usage

```powershell
# Both scripts use users.csv by default (User1,User2 columns)
.\Compare-ADGroupMembership.ps1
.\Add-ADGroupMembership.ps1

# Or pass the users directly
.\Compare-ADGroupMembership.ps1 -User1 jdoe -User2 jsmith
.\Add-ADGroupMembership.ps1 -User1 jdoe -User2 jsmith

# Preview the Add script without making changes
.\Add-ADGroupMembership.ps1 -WhatIf
```

### Input CSV format

Both scripts look for `users.csv` next to the script file, with a header row and one data row. The columns are the same for both scripts:

```csv
User1,User2
jdoe,jsmith
```

- For **Compare**: `User1` and `User2` are compared.
- For **Add**: `User1`'s groups are copied onto `User2`.

### Output CSV (Compare only)

The result CSV (default `Compare-Groups.csv`) has these columns:

| GroupName | InUser1 | InUser2 | Difference |
|-----------|---------|---------|------------|
| GroupA     | True    | False   | Only jdoe  |
| GroupB     | True    | True    | Shared     |

## Parameters

### Compare-ADGroupMembership.ps1

| Parameter  | Description                                                        | Default               |
|------------|--------------------------------------------------------------------|-----------------------|
| `User1`    | First username (samAccountName)                                    | -                     |
| `User2`    | Second username (samAccountName)                                   | -                     |
| `CsvFile`  | CSV file containing the two users                                  | `users.csv`           |
| `OutputPath` | Path for the result CSV                                           | `Compare-Groups.csv` in the script directory |

### Add-ADGroupMembership.ps1

| Parameter | Description                                                         | Default    |
|-----------|---------------------------------------------------------------------|------------|
| `User1`   | Source user whose groups are copied (samAccountName)                | -          |
| `User2`   | Target user that receives the groups (samAccountName)               | -          |
| `CsvFile` | CSV file containing the two users                                   | `users.csv` |
| `WhatIf`  | Preview the additions without making changes                        | off        |

