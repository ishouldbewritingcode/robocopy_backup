$Jobs = @(
    @{ Source = "C:\Users\Bryan"; Dest = "\\192.168.88.10\Bryan\kudubackup" }
)

$LogFile = Join-Path $PSScriptRoot "$(Get-Date -Format 'yyyyMMdd_HH_mm')_backup_nodelete.log"
$CommonArgs = @("/E", "/XO", "/XA:SH", "/XD", "AppData", ".*", "node_modules", "MicrosoftEdgeBackups", "/XJD", "/R:5", "/W:15", "/MT:32", "/V", "/NP")

$First = $true
foreach ($Job in $Jobs) {
    $LogArg = if ($First) { "/LOG:$LogFile" } else { "/LOG+:$LogFile" }
    $First = $false

    robocopy $Job.Source $Job.Dest @CommonArgs $LogArg

    # Robocopy exit codes 0-7 are success/informational; 8+ indicate failure.
    if ($LASTEXITCODE -ge 8) {
        Write-Error "Robocopy failed for $($Job.Source) -> $($Job.Dest) (exit code $LASTEXITCODE)"
    }
}
