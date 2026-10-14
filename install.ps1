# pc-local one-click installer (Windows PowerShell 5.1+ / PowerShell 7+)
# Prefer this (more reliable than irm|iex):
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr -UseBasicParsing https://raw.githubusercontent.com/moha700m/home-ai/main/install.ps1 -OutFile $env:TEMP\home-ai-install.ps1; & $env:TEMP\home-ai-install.ps1"
# Or double-click install.cmd after cloning.

$ErrorActionPreference = 'Continue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$RepoOwner = if ($env:HOME_AI_OWNER) { $env:HOME_AI_OWNER } else { 'moha700m' }
$RepoName  = if ($env:HOME_AI_REPO)  { $env:HOME_AI_REPO }  else { 'home-ai' }
$HomeDir   = if ($env:USERPROFILE) { $env:USERPROFILE } elseif ($HOME) { $HOME } else { $env:HOMEDRIVE + $env:HOMEPATH }
$InstallDir = if ($env:HOME_AI_DIR) { $env:HOME_AI_DIR } else { Join-Path $HomeDir 'home-ai' }
$Port = if ($env:HOME_AI_PORT) { $env:HOME_AI_PORT } else { '3847' }
$Branch = if ($env:HOME_AI_BRANCH) { $env:HOME_AI_BRANCH } else { 'main' }

function Info([string]$m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok([string]$m)   { Write-Host "OK  $m" -ForegroundColor Green }
function Warn([string]$m) { Write-Host "!!  $m" -ForegroundColor Yellow }
function Fail([string]$m) { Write-Host "ERR $m" -ForegroundColor Red; exit 1 }

function Test-Cmd([string]$name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Invoke-Native([string]$File, [string[]]$ArgList, [string]$WorkDir) {
  Info ("Running: {0} {1}" -f $File, ($ArgList -join ' '))
  $p = @{
    FilePath = $File
    ArgumentList = $ArgList
    NoNewWindow = $true
    Wait = $true
    PassThru = $true
  }
  if ($WorkDir) { $p.WorkingDirectory = $WorkDir }
  $proc = Start-Process @p
  if ($proc.ExitCode -ne 0) {
    Fail ("Command failed ({0}): {1} {2}" -f $proc.ExitCode, $File, ($ArgList -join ' '))
  }
}

Info 'Installing pc-local (home-ai)'

if (-not (Test-Cmd 'git')) {
  Fail 'Git not found. Install from https://git-scm.com then reopen PowerShell.'
}
if (-not (Test-Cmd 'node')) {
  Fail 'Node.js not found. Install Node 22+ from https://nodejs.org then reopen PowerShell.'
}
if (-not (Test-Cmd 'npm')) {
  Fail 'npm not found. Reinstall Node.js from https://nodejs.org (include npm).'
}

$nodeVer = (& node -v 2>$null)
if (-not $nodeVer) { Fail 'Could not read node version.' }
Ok ("Node {0}" -f $nodeVer)

$major = 0
try { $major = [int](($nodeVer -replace '^v','').Split('.')[0]) } catch {}
if ($major -lt 22) {
  Warn ("Node 22+ recommended (found {0})" -f $nodeVer)
}

$Url = "https://github.com/$RepoOwner/$RepoName.git"
Info ("Clone from GitHub: {0}" -f $Url)

$gitDir = Join-Path $InstallDir '.git'
if (Test-Path $gitDir) {
  Info 'Folder exists - updating...'
  Invoke-Native 'git' @('-C', $InstallDir, 'fetch', '--depth', '1', 'origin', $Branch) $null
  Invoke-Native 'git' @('-C', $InstallDir, 'checkout', $Branch) $null
  # pull may fail on shallow clones; ignore non-zero by retrying fetch+reset
  & git -C $InstallDir pull --ff-only origin $Branch 2>$null | Out-Null
} else {
  $parent = Split-Path -Parent $InstallDir
  if ($parent -and -not (Test-Path $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
  }
  if (Test-Path $InstallDir) {
    Warn ("Removing incomplete folder: {0}" -f $InstallDir)
    Remove-Item -Recurse -Force $InstallDir
  }
  Invoke-Native 'git' @('clone', '--branch', $Branch, '--depth', '1', $Url, $InstallDir) $null
}

$pkg = Join-Path $InstallDir 'package.json'
if (-not (Test-Path $pkg)) {
  Fail ("package.json missing in {0}" -f $InstallDir)
}

Info 'npm install...'
Invoke-Native 'npm' @('install') $InstallDir

Info 'Validating agent...'
# Older npm may not support npx --yes; try both
$npxOk = $false
Push-Location $InstallDir
try {
  & npx --yes "@cursor/bdk@0.2.24" validate --dir . 2>$null
  if ($LASTEXITCODE -eq 0) { $npxOk = $true }
  if (-not $npxOk) {
    & npx "@cursor/bdk@0.2.24" validate --dir .
    if ($LASTEXITCODE -ne 0) { Fail 'bdk validate failed' }
  }
} finally {
  Pop-Location
}

Ok 'Install complete'
Write-Host ''
Write-Host ("Folder: {0}" -f $InstallDir) -ForegroundColor Green
Write-Host 'Run:'
Write-Host ("  cd `"$InstallDir`"")
Write-Host '  npm run dev'
Write-Host ("Open: http://127.0.0.1:{0}/playground" -f $Port)
Write-Host ''
Write-Host 'For AI chat (once):'
Write-Host '  npx @cursor/bdk login'
Write-Host ''

if ($env:HOME_AI_START -eq '1') {
  Info ("Starting server on port {0}..." -f $Port)
  Set-Location $InstallDir
  & npx --yes "@cursor/bdk@0.2.24" serve --dir . --mode single --dev --port $Port
}
