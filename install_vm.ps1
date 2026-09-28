# =============================================================================
#  install_vm.ps1 - Windows one-liner launcher for install_vm.sh
#
#  From ANY Windows shell (cmd, PowerShell 5 or 7, Windows Terminal):
#    powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.ps1 | iex"
#
#  With flags (the same line works in cmd and PowerShell):
#    powershell -ExecutionPolicy Bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/install_vm.ps1))) --server --name web1"
#
#  If Git for Windows is missing it offers to install it with winget.
#
#  From a clone:   .\install_vm.ps1 --server
#
#  Why this exists: in PowerShell "curl" is an alias for Invoke-WebRequest and
#  "bash" is the WSL launcher, so "curl ... | bash" does not work. This finds
#  Git Bash and runs the real script with it. Run it as your normal user - not
#  as Administrator; Vagrant must run as you.
#
#  Honours the same LAB_REPO / LAB_REF environment variables as the script.
# =============================================================================

function Invoke-LabScript {
  param([string]$Name, [string[]]$Arguments)

  $repo = if ($env:LAB_REPO) { $env:LAB_REPO } else { 'Crushoverride007/scripts' }
  $ref  = if ($env:LAB_REF)  { $env:LAB_REF }  else { 'main' }

  # ---- find a real bash (Git for Windows), never the WSL stub --------------
  $candidates = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe",
    'C:\msys64\usr\bin\bash.exe'
  )
  $git = Get-Command git.exe -ErrorAction SilentlyContinue
  if ($git) {
    # ...\Git\cmd\git.exe -> ...\Git\bin\bash.exe
    $candidates += Join-Path (Split-Path (Split-Path $git.Source)) 'bin\bash.exe'
  }
  $bash = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if (-not $bash -and (Get-Command winget.exe -ErrorAction SilentlyContinue) -and [Environment]::UserInteractive) {
    # No Git Bash yet: offer to install it rather than just failing.
    Write-Host ''
    Write-Host '  Git for Windows is needed (it provides the bash these scripts run in).'
    $answer = Read-Host '  Install it now with winget? [Y/n]'
    if ($answer -eq '' -or $answer -match '^(y|yes)$') {
      winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
      $bash = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    }
  }
  if (-not $bash) {
    Write-Host ''
    Write-Host '  x No Git Bash found. Install Git for Windows, then run this again:' -ForegroundColor Red
    Write-Host '      https://git-scm.com/download/win'
    Write-Host '      (or: winget install --id Git.Git -e)'
    Write-Host ''
    $global:LASTEXITCODE = 1
    return
  }

  # ---- the script: next to this file (a clone), or downloaded --------------
  $tmp = $null
  $local = if ($PSCommandPath) { Join-Path (Split-Path $PSCommandPath) $Name } else { $null }
  if ($local -and (Test-Path $local)) {
    $script = $local
  } else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    $url = "https://raw.githubusercontent.com/$repo/$ref/$Name"
    try {
      $body = (Invoke-WebRequest -UseBasicParsing -Uri $url).Content
    } catch {
      Write-Host "  x could not download $url" -ForegroundColor Red
      Write-Host "    $($_.Exception.Message)"
      $global:LASTEXITCODE = 1
      return
    }
    if ($body -is [byte[]]) { $body = [Text.Encoding]::UTF8.GetString($body) }
    # bash chokes on CR, so write it with LF only and without a BOM
    $tmp = Join-Path $env:TEMP ("$Name." + [guid]::NewGuid().ToString('N') + '.sh')
    [IO.File]::WriteAllText($tmp, ($body -replace "`r", ''), (New-Object Text.UTF8Encoding $false))
    $script = $tmp
  }

  try {
    & $bash $script @Arguments
  } finally {
    if ($tmp) { Remove-Item -Force $tmp -ErrorAction SilentlyContinue }
  }
  # No "exit" here: under "irm | iex" it would close the user's PowerShell.
}

# "irm | iex" cannot pass arguments, so LAB_ARGS can carry them instead:
#   $env:LAB_ARGS='--server --name web1'; irm .../install_vm.ps1 | iex
$labArgs = @($args)
if ($labArgs.Count -eq 0 -and $env:LAB_ARGS) {
  $labArgs = @($env:LAB_ARGS -split '\s+' | Where-Object { $_ })
}
Invoke-LabScript -Name 'install_vm.sh' -Arguments $labArgs
