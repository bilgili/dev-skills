# Idempotent TLA+ toolchain installer (Windows PowerShell).
# Installs: JDK 11+ (winget/choco), tla2tools.jar, tlc.cmd / sany.cmd wrappers.
# Safe to re-run.
$ErrorActionPreference = 'Stop'
$Jar    = Join-Path $HOME 'tools\tla2tools.jar'
$Bin    = Join-Path $HOME '.local\bin'
$JarUrl = 'https://github.com/tlaplus/tlaplus/releases/latest/download/tla2tools.jar'

Write-Host '== TLA+ toolchain setup =='

# 1. JDK 11+.
$hasJava = $false
try { java -version *> $null; $hasJava = ($LASTEXITCODE -eq 0) } catch { $hasJava = $false }
if ($hasJava) {
  Write-Host '[ok] java present'
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
  Write-Host '[..] installing Temurin JDK via winget'
  winget install --id EclipseAdoptium.Temurin.21.JDK -e --accept-source-agreements --accept-package-agreements
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
  Write-Host '[..] installing Temurin JDK via choco'
  choco install -y temurin
} else {
  Write-Error '[!!] no java, no winget/choco. Install a JDK 11+: https://adoptium.net/'
}

# 2. tla2tools.jar.
if (Test-Path $Jar) {
  Write-Host "[ok] jar present: $Jar"
} else {
  Write-Host '[..] downloading tla2tools.jar'
  New-Item -ItemType Directory -Force -Path (Split-Path $Jar) | Out-Null
  Invoke-WebRequest -Uri $JarUrl -OutFile $Jar
  Write-Host "[ok] jar downloaded: $Jar"
}

# 3. Wrappers (.cmd so they run from any shell).
New-Item -ItemType Directory -Force -Path $Bin | Out-Null
$tlc  = Join-Path $Bin 'tlc.cmd'
$sany = Join-Path $Bin 'sany.cmd'
if (-not (Test-Path $tlc)) {
  '@echo off' , 'java -XX:+UseParallelGC -cp "%USERPROFILE%\tools\tla2tools.jar" tlc2.TLC %*' |
    Set-Content -Encoding ascii $tlc
  Write-Host "[ok] wrote $tlc"
} else { Write-Host "[ok] wrapper present: $tlc" }
if (-not (Test-Path $sany)) {
  '@echo off' , 'java -cp "%USERPROFILE%\tools\tla2tools.jar" tla2sany.SANY %*' |
    Set-Content -Encoding ascii $sany
  Write-Host "[ok] wrote $sany"
} else { Write-Host "[ok] wrapper present: $sany" }

# 4. PATH sanity.
if (($env:PATH -split ';') -notcontains $Bin) {
  Write-Host "[!!] $Bin not on PATH. Add it (User env), e.g.:"
  Write-Host "     setx PATH `"$Bin;%PATH%`""
}
Write-Host '== done. verify: tlc -help =='
