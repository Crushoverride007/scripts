$settingsUrl = "https://raw.githubusercontent.com/Crushoverride007/docker-install-script/main/vscode-setup/settings-windows.json"
$settingsPath = "$env:APPDATA\Code\User\settings.json"
$settingsDir = Split-Path $settingsPath
if (-Not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}
Invoke-WebRequest -Uri $settingsUrl -OutFile $settingsPath
