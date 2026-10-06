# robocopy_backup

PowerShell scripts for mirroring a user profile to a network share with Robocopy, and for scheduling the backup to run automatically every night.

## Scripts

### `robocopy_backup_mirror.ps1`

Mirrors `C:\Users\Bryan` to `\\192.168.88.10\Bryan\kudubackup` using `robocopy /MIR`.

- Excludes hidden/system files, dotfiles/dotfolders, `AppData`, `node_modules`, and `MicrosoftEdgeBackups`.
- Skips junction points (`/XJD`) to avoid infinite loops.
- Retries up to 5 times with a 15 second wait, using 32 threads (`/MT:32`).
- Writes a timestamped log file (`yyyyMMdd_HH_mm_backup.log`) next to the script.
- Reports an error if Robocopy's exit code indicates failure (8 or higher).

Additional backup jobs can be added by extending the `$Jobs` array at the top of the script.

### `schedule_backup_1am.ps1`

Registers a Windows Scheduled Task (`RobocopyBackupMirror`) that runs `robocopy_backup_mirror.ps1` daily at 1:00 AM.

- Must be run as Administrator (`#Requires -RunAsAdministrator`).
- Prompts for the password of the account the task will run as, since a UNC network destination requires a password-based logon (not S4U) to carry network credentials when running unattended.
- Runs with the highest privileges and a 4-hour execution time limit.

## Usage

1. Edit `$Jobs` in `robocopy_backup_mirror.ps1` to set your desired source/destination pairs.
2. Run `robocopy_backup_mirror.ps1` manually to test the backup.
3. Run `schedule_backup_1am.ps1` as Administrator once to register the nightly scheduled task.

## Logs

Each run produces a timestamped `*_backup.log` file alongside the scripts. These are excluded from version control via `.gitignore`.
