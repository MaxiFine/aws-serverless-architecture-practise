Param(
  [switch] $Local,
  [switch] $AutoApprove,
  [switch] $Destroy,
  [switch] $SkipBucketCheck
)

# PowerShell wrapper that invokes the Bash deploy script.
# Ensures users on Windows can run the same flow via Git Bash or WSL.

$ErrorActionPreference = 'Stop'

function Find-Bash {
  $bash = (Get-Command bash -ErrorAction SilentlyContinue).Path
  if (-not $bash) {
    $gitBash = Join-Path ${env:ProgramFiles} 'Git\bin\bash.exe'
    if (Test-Path $gitBash) { return $gitBash }
  }
  return $bash
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BashExe = Find-Bash
if (-not $BashExe) {
  Write-Error "Bash not found. Please install Git for Windows (Git Bash) or run this from WSL."
}

# Build argument list for the bash script
$argsList = @()
if ($Local) { $argsList += '--local' }
if ($AutoApprove) { $argsList += '--auto-approve' }
if ($Destroy) { $argsList += '--destroy' }
if ($SkipBucketCheck) { $argsList += '--skip-bucket-check' }

$joinedArgs = $argsList -join ' '

Write-Host "[+] Using Bash at: $BashExe"
Write-Host "[+] Running deploy.sh from: $ScriptDir"

# Execute bash with login shell context (-l) to ensure PATH is set up
& $BashExe -lc "cd '$ScriptDir' && chmod +x ./deploy.sh && ./deploy.sh $joinedArgs"
