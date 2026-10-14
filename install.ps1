# pc-local — تثبيت بنقرة واحدة (Windows PowerShell)
# الاستخدام:
#   irm https://raw.githubusercontent.com/moha700m/home-ai/main/install.ps1 | iex
$ErrorActionPreference = "Stop"

$RepoOwner = if ($env:HOME_AI_OWNER) { $env:HOME_AI_OWNER } else { "moha700m" }
$RepoName  = if ($env:HOME_AI_REPO)  { $env:HOME_AI_REPO }  else { "home-ai" }
$InstallDir = if ($env:HOME_AI_DIR) { $env:HOME_AI_DIR } else { Join-Path $HOME "home-ai" }
$Port = if ($env:HOME_AI_PORT) { $env:HOME_AI_PORT } else { "3847" }
$Branch = if ($env:HOME_AI_BRANCH) { $env:HOME_AI_BRANCH } else { "main" }

function Info($m) { Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "OK  $m" -ForegroundColor Green }
function Fail($m) { Write-Host "ERR $m" -ForegroundColor Red; exit 1 }

Info "تثبيت pc-local (home-ai)"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Fail "ثبّت Git من https://git-scm.com ثم أعد المحاولة"
}
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Fail "ثبّت Node.js 22+ من https://nodejs.org ثم أعد المحاولة"
}
Ok "Node $(node -v)"

$Url = "https://github.com/$RepoOwner/$RepoName.git"
Info "استنساخ من GitHub: $Url"

if (Test-Path (Join-Path $InstallDir ".git")) {
  Info "المجلد موجود — تحديث..."
  git -C $InstallDir fetch --depth 1 origin $Branch
  git -C $InstallDir checkout $Branch
  git -C $InstallDir pull --ff-only origin $Branch
} else {
  $parent = Split-Path -Parent $InstallDir
  if ($parent -and -not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }
  git clone --branch $Branch --depth 1 $Url $InstallDir
}

if (-not (Test-Path (Join-Path $InstallDir "package.json"))) {
  Fail "ما لقيت package.json في $InstallDir"
}

Info "تثبيت الحزم (npm install)..."
Push-Location $InstallDir
try {
  npm install
  npx --yes "@cursor/bdk@0.2.24" validate --dir .
} finally {
  Pop-Location
}
Ok "تم التثبيت"

Write-Host ""
Write-Host "المجلد: $InstallDir" -ForegroundColor Green
Write-Host "تشغيل:"
Write-Host "  cd $InstallDir"
Write-Host "  npm run dev"
Write-Host "ثم افتح: http://127.0.0.1:$Port/playground"
Write-Host ""
Write-Host "للمحادثة بالذكاء الاصطناعي:"
Write-Host "  npx @cursor/bdk login"
