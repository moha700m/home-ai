# Tiny bootstrap for Windows (ASCII-only, safe for irm | iex)
# Downloads install.ps1 to TEMP then runs it.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
$uri = 'https://raw.githubusercontent.com/moha700m/home-ai/main/install.ps1'
$dst = Join-Path $env:TEMP 'home-ai-install.ps1'
Write-Host "==> Downloading installer..." -ForegroundColor Cyan
Invoke-WebRequest -UseBasicParsing -Uri $uri -OutFile $dst
Write-Host "==> Running $dst" -ForegroundColor Cyan
& powershell -NoProfile -ExecutionPolicy Bypass -File $dst
exit $LASTEXITCODE
