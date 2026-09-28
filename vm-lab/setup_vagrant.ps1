# =============================================================================
#  setup_vagrant.ps1 - install Vagrant + a hypervisor setup on Windows
#
#  From any Windows shell (cmd, PowerShell 5 or 7), as your NORMAL user:
#    powershell -ExecutionPolicy Bypass -c "irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/vm-lab/setup_vagrant.ps1 | iex"
#
#  With flags:
#    powershell -ExecutionPolicy Bypass -c "& ([scriptblock]::Create((irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/vm-lab/setup_vagrant.ps1))) --provider virtualbox -y"
#
#  Installs what is missing, asking before each install:
#    - Git for Windows       (winget)  - the lab scripts run in its bash
#    - Vagrant               (winget)
#    - VMware:     the Vagrant VMware Utility (HashiCorp release, checksum
#                  verified) + the vagrant-vmware-desktop plugin
#    - VirtualBox: VirtualBox itself (winget)
#  Windows asks for administrator approval (UAC) for each installer.
#
#  It can NOT install VMware Workstation: that needs a Broadcom account. It is
#  free for personal use; install it by hand and re-run this.
#
#  FLAGS
#    --provider NAME   vmware_desktop | virtualbox
#                      (default: VMware if installed, else VirtualBox)
#    -y, --yes         install without asking
# =============================================================================

function Invoke-SetupVagrant {
  param([string[]]$Arguments)

  $provider = ''
  $assumeYes = $false
  for ($i = 0; $i -lt $Arguments.Count; $i++) {
    switch ($Arguments[$i]) {
      '--provider' { $i++; $provider = $Arguments[$i] }
      { $_ -in '-y', '--yes' } { $assumeYes = $true }
      { $_ -in '-h', '--help' } {
        Write-Host 'setup_vagrant.ps1 [--provider vmware_desktop|virtualbox] [-y]'
        return
      }
      default { Write-Host "  x unknown flag: $($Arguments[$i])" -ForegroundColor Red; return }
    }
  }
  if ($provider -and $provider -notin 'vmware_desktop', 'virtualbox') {
    Write-Host "  x provider must be vmware_desktop or virtualbox on Windows (got '$provider')" -ForegroundColor Red
    return
  }

  function Say($m)  { Write-Host "==> $m" -ForegroundColor White }
  function Ok($m)   { Write-Host "  + $m" -ForegroundColor Green }
  function Warn($m) { Write-Host "  ! $m" -ForegroundColor Yellow }
  function Confirm-Step($q) {
    if ($assumeYes) { return $true }
    $a = Read-Host "  $q [Y/n]"
    return ($a -eq '' -or $a -match '^(y|yes)$')
  }
  function Refresh-Path {
    # Pick up PATH changes from installers without opening a new window.
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'User')
  }

  [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
  $needReboot = $false

  if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    Warn 'winget is not available. Install "App Installer" from the Microsoft Store, then re-run.'
    return
  }

  # ---- 1. Git for Windows -------------------------------------------------
  Say 'Git for Windows'
  $gitBash = @("$env:ProgramFiles\Git\bin\bash.exe", "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe") |
             Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($gitBash) { Ok "found ($gitBash)" }
  elseif (Confirm-Step 'Git for Windows is not installed (the lab scripts need its bash). Install it?') {
    winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
    Ok 'Git for Windows installed'
  }

  # ---- 2. Vagrant ---------------------------------------------------------
  Say 'Vagrant'
  $vagrant = @((Get-Command vagrant.exe -ErrorAction SilentlyContinue).Source,
               "$env:ProgramFiles\Vagrant\bin\vagrant.exe") |
             Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
  if ($vagrant) {
    Ok (& $vagrant --version | Select-Object -First 1)
  } elseif (Confirm-Step 'Vagrant is not installed. Install it?') {
    winget install --id Hashicorp.Vagrant -e --source winget --accept-package-agreements --accept-source-agreements
    Refresh-Path
    $vagrant = "$env:ProgramFiles\Vagrant\bin\vagrant.exe"
    if (-not (Test-Path $vagrant)) { Warn 'Vagrant did not install - see the winget output above.'; return }
    Ok 'Vagrant installed'
    $needReboot = $true
  } else {
    Warn 'Vagrant is required. https://developer.hashicorp.com/vagrant/install'
    return
  }
  $plugins = (& $vagrant plugin list 2>$null) -join "`n"

  # ---- 3. provider --------------------------------------------------------
  $vmwareExe = @("${env:ProgramFiles(x86)}\VMware\VMware Workstation\vmware.exe",
                 "$env:ProgramFiles\VMware\VMware Workstation\vmware.exe") |
               Where-Object { Test-Path $_ } | Select-Object -First 1
  $vboxExe = "$env:ProgramFiles\Oracle\VirtualBox\VBoxManage.exe"
  if (-not $provider) {
    if ($vmwareExe) { $provider = 'vmware_desktop' } else { $provider = 'virtualbox' }
  }
  Say "provider: $provider"

  if ($provider -eq 'vmware_desktop') {
    if ($vmwareExe) { Ok 'VMware Workstation found' }
    else {
      Warn 'VMware Workstation is not installed, and this script cannot install it (it needs'
      Warn 'a Broadcom account). It is free for personal use:'
      Warn '  https://www.vmware.com/products/desktop-hypervisor'
      Warn 'Or re-run with --provider virtualbox to use VirtualBox instead.'
    }

    # The plugin talks to this background service; without it nothing works.
    $svc = Get-Service -Name VagrantVMware -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') { Ok 'Vagrant VMware Utility running' }
    elseif (Confirm-Step 'Install the Vagrant VMware Utility (needed by the VMware plugin)?') {
      $ver  = (Invoke-RestMethod 'https://checkpoint-api.hashicorp.com/v1/check/vagrant-vmware-utility').current_version
      $file = "vagrant-vmware-utility_${ver}_windows_amd64.msi"
      $base = "https://releases.hashicorp.com/vagrant-vmware-utility/$ver"
      $msi  = Join-Path $env:TEMP $file
      Invoke-WebRequest -UseBasicParsing "$base/$file" -OutFile $msi
      # Verify against HashiCorp's published checksums before running it.
      $sums = (Invoke-WebRequest -UseBasicParsing "$base/vagrant-vmware-utility_${ver}_SHA256SUMS").Content
      if ($sums -is [byte[]]) { $sums = [Text.Encoding]::UTF8.GetString($sums) }
      $want = ($sums -split "`n" | Where-Object { $_ -match [regex]::Escape($file) }) -replace '\s.*$', ''
      $got  = (Get-FileHash $msi -Algorithm SHA256).Hash.ToLower()
      if (-not $want -or $got -ne $want.Trim().ToLower()) {
        Warn "checksum mismatch for $file - not installing it"
        Remove-Item $msi -Force
        return
      }
      Start-Process msiexec.exe -ArgumentList '/i', "`"$msi`"", '/passive', '/norestart' -Verb RunAs -Wait
      Remove-Item $msi -Force -ErrorAction SilentlyContinue
      Ok "Vagrant VMware Utility $ver installed"
    }

    if ($plugins -match '(?m)^vagrant-vmware-desktop ') { Ok 'vagrant-vmware-desktop plugin installed' }
    elseif (Confirm-Step 'Install the vagrant-vmware-desktop plugin?') {
      & $vagrant plugin install vagrant-vmware-desktop
      if ($LASTEXITCODE -eq 0) { Ok 'vagrant-vmware-desktop plugin installed' }
      else { Warn 'plugin install failed - after a reboot run: vagrant plugin install vagrant-vmware-desktop' }
    }
  } else {
    if (Test-Path $vboxExe) { Ok ('VirtualBox ' + (& $vboxExe --version)) }
    elseif (Confirm-Step 'VirtualBox is not installed. Install it?') {
      winget install --id Oracle.VirtualBox -e --source winget --accept-package-agreements --accept-source-agreements
      Ok 'VirtualBox installed'
    }
  }

  Write-Host ''
  Write-Host 'Done.' -ForegroundColor Green
  if ($needReboot) { Warn 'Vagrant was just installed: restart Windows before using it.' }
  Write-Host '  Build a lab with:'
  Write-Host "  powershell -ExecutionPolicy Bypass -c `"irm https://raw.githubusercontent.com/Crushoverride007/scripts/main/vm-lab/install_lab.ps1 | iex`""
  Write-Host ''
  # No "exit": under "irm | iex" it would close the user's PowerShell window.
}

Invoke-SetupVagrant -Arguments @($args)
