#Requires -RunAsAdministrator

$TaskName = "RobocopyBackupMirror"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptFile = Join-Path $ScriptDir "robocopy_backup_mirror.ps1"

if (-not (Test-Path $ScriptFile)) {
    throw "Script file not found: $ScriptFile"
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
