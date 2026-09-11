[CmdletBinding()]
param(
    [switch]$ApplyConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") {
    throw "This installer is intentionally Windows-only."
}
if ([string]::IsNullOrWhiteSpace($env:APPDATA)) {
    throw "APPDATA is not set; Herdr's Windows config directory cannot be resolved safely."
}

$herdrConfigRoot = Join-Path $env:APPDATA "herdr"
$targetScriptRoot = Join-Path $herdrConfigRoot "custom"
New-Item -ItemType Directory -Force -Path $targetScriptRoot | Out-Null

$scripts = @(
    "Herdr.Common.ps1",
    "Rename-HerdrAgent.ps1",
    "Fork-HerdrAgent.ps1",
    "Move-HerdrPane.ps1",
    "Show-HerdrPromptHistory.ps1"
)

foreach ($script in $scripts) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $script) -Destination $targetScriptRoot -Force
}

Write-Host "Installed Windows helpers in $targetScriptRoot" -ForegroundColor Green

if ($ApplyConfig) {
    $configPath = Join-Path $herdrConfigRoot "config.toml"
    if (Test-Path -LiteralPath $configPath) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$configPath.before-windows-custom-$stamp"
        Copy-Item -LiteralPath $configPath -Destination $backupPath -Force
        Write-Host "Backed up the existing config to $backupPath"
    }
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "config.windows.toml") -Destination $configPath -Force
    Write-Host "Installed the Windows config at $configPath" -ForegroundColor Green
    Write-Host "Run: herdr server reload-config"
} else {
    Write-Host "The existing Herdr config was not changed."
    Write-Host "After reviewing config.windows.toml, rerun with -ApplyConfig to install it."
}
