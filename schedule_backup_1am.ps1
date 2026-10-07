#Requires -RunAsAdministrator

$TaskName = "RobocopyBackup"
$LegacyTaskName = "RobocopyBackupMirror"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$Options = @{
    "1" = "robocopy_backup_mirror.ps1"
    "2" = "robocopy_backup_nodelete.ps1"
}

Write-Host "Which backup should run nightly at 1:00 AM?"
Write-Host ""
Write-Host "  1) Mirror   - Keeps the destination an exact copy of the source."
Write-Host "                Files deleted on the source are DELETED from the destination."
Write-Host "  2) Nodelete - Copies new and changed files only. Nothing is ever deleted"
Write-Host "                from the destination, and newer destination files are kept."
Write-Host ""

do {
    $Choice = (Read-Host "Enter 1 or 2").Trim()
} until ($Options.ContainsKey($Choice))

$ScriptFile = Join-Path $ScriptDir $Options[$Choice]

if (-not (Test-Path $ScriptFile)) {
    throw "Script file not found: $ScriptFile"
}

# Only one backup task should exist, since both scripts write to the same
# destination. Remove the task registered by older versions of this script.
if (Get-ScheduledTask -TaskName $LegacyTaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $LegacyTaskName -Confirm:$false
    Write-Host "Removed old scheduled task '$LegacyTaskName'."
}

$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptFile`"" -WorkingDirectory $ScriptDir
$Trigger = New-ScheduledTaskTrigger -Daily -At 1:00AM
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -ExecutionTimeLimit (New-TimeSpan -Hours 4)

# Destination is a UNC network share, so the task needs a password-based
# logon (not S4U) to have network credentials when it runs unattended.
$Credential = Get-Credential -UserName "$env:USERDOMAIN\$env:USERNAME" -Message "Enter the password for the account that will run the backup task"

Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings `
    -User $Credential.UserName -Password $Credential.GetNetworkCredential().Password -RunLevel Highest -Force

Write-Host "Scheduled task '$TaskName' created to run '$ScriptFile' daily at 1:00 AM."
