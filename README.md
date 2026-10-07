# robocopy_backup

PowerShell scripts for backing up a user profile to a network share with Robocopy, and for scheduling the backup to run automatically every night.

There are two backup variants:

| Script | Deleted on source | Changed on source | Newer on destination |
| --- | --- | --- | --- |
| `robocopy_backup_mirror.ps1` | Deleted from destination | Overwrites destination | Overwritten by source |
| `robocopy_backup_nodelete.ps1` | Kept on destination | Overwrites destination | Kept (not overwritten) |

## Scripts

Both backup scripts share the same base settings:

- Exclude hidden/system files, dotfiles/dotfolders, `AppData`, `node_modules`, and `MicrosoftEdgeBackups`.
- Skip junction points (`/XJD`) to avoid infinite loops.
- Retry up to 5 times with a 15 second wait, using 32 threads (`/MT:32`).
- Report an error if Robocopy's exit code indicates failure (8 or higher).

Additional backup jobs can be added by extending the `$Jobs` array at the top of either script.

### `robocopy_backup_mirror.ps1`

Mirrors `C:\Users\Bryan` to `\\192.168.88.10\Bryan\kudubackup` using `robocopy /MIR`.

- The destination is kept as an exact copy of the source: files and folders deleted on the source are **deleted from the destination**.
- Writes a timestamped log file (`yyyyMMdd_HH_mm_backup.log`) next to the script.

### `robocopy_backup_nodelete.ps1`

Copies `C:\Users\Bryan` to `\\192.168.88.10\Bryan\kudubackup` without ever deleting anything on the destination. It uses `/E` (copy all subfolders, including empty ones) and `/XO` instead of `/MIR`.

- **Deletions are not propagated.** Files and folders deleted on the source stay on the destination, so you can still recover them from the backup.
- **Newer destination files are protected.** `/XO` skips any source file that is older than the copy already on the destination, so a newer file on the destination is never overwritten.
- **Changed files are still overwritten.** When a source file is newer than the destination copy, it replaces it. Only the latest version is kept; previous versions aren't saved.
- **Renames and moves leave copies behind.** A renamed or moved file is copied to its new path, and the old copy stays at the old path, so the backup grows over time.
- **Restored old files may not be backed up.** `/XO` compares last-modified times only. If you restore an older version of a file on the source (for example, from an archive or "Restore previous versions"), it keeps its old timestamp and won't replace the newer copy on the destination.
- Writes a timestamped log file (`yyyyMMdd_HH_mm_backup_nodelete.log`) next to the script.

> **Note:** By default, both scripts write to the same destination. Running the mirror script there removes everything the nodelete script kept. Use only one of them per destination, or point them at different destinations.

### `schedule_backup_1am.ps1`

Registers a Windows Scheduled Task (`RobocopyBackup`) that runs a backup script daily at 1:00 AM.

- Asks whether to schedule the mirror or the nodelete script, with a short description of each.
- Only one backup task is kept. Running the script again replaces the existing task, so you can switch variants at any time. It also removes the `RobocopyBackupMirror` task created by earlier versions of this script.
- Must be run as Administrator (`#Requires -RunAsAdministrator`).
- Prompts for the password of the account the task will run as, since a UNC network destination requires a password-based logon (not S4U) to carry network credentials when running unattended.
- Runs with the highest privileges and a 4-hour execution time limit.

## Usage

1. Choose a variant (mirror or nodelete) and edit `$Jobs` in that script to set your desired source/destination pairs.
2. Run the script manually to test the backup.
3. Run `schedule_backup_1am.ps1` as Administrator once and choose your variant to register the nightly scheduled task.

## Logs

Each run produces a timestamped log file alongside the scripts: `*_backup.log` for the mirror script and `*_backup_nodelete.log` for the nodelete script. These are excluded from version control via `.gitignore`.
