# AESIR Red installer for Windows (EXPERIMENTAL).
#
#   irm https://raw.githubusercontent.com/MarcReinl/aesir-red-dist/main/install.ps1 | iex
#
# Downloads a bundled-runtime archive (an official Node runtime plus the whole
# installed plugin closure), verifies its checksum, extracts it under
# %LOCALAPPDATA%\aesir\versions\<version>, puts `aesir` on PATH, checks that
# the launcher starts, and installs PowerShell 7 through winget when it is
# missing, since the shell tool runs commands through it. The sandbox on
# Windows requires native compatibility verification before support is claimed.
#
# Environment:
#   AESIR_VERSION                  release to install (default: the one below)
#   AESIR_ROOT                     install root (default: %LOCALAPPDATA%\aesir)
#   AESIR_INSTALL_SYSTEM_PACKAGES  set to 0 to never run winget; the installer
#                                  then only reports what is missing
#
# Experimental: no CI job has ever booted this terminal on real Windows. The
# Windows build leg runs the batch boot smoke only; the interactive terminal,
# its ConPTY backend and its key handling are unproven here.
$ErrorActionPreference = 'Stop'

$Version = if ($env:AESIR_VERSION) { $env:AESIR_VERSION } else { '0.1.5-rc.2' }
$Repo = if ($env:AESIR_REPO) { $env:AESIR_REPO } else { 'MarcReinl/aesir-red-dist' }
$Root = if ($env:AESIR_ROOT) { $env:AESIR_ROOT } else { Join-Path $env:LOCALAPPDATA 'aesir' }
$InstallSystemPackages = $env:AESIR_INSTALL_SYSTEM_PACKAGES -ne '0'

function Write-Note([string] $Text) { Write-Host "  $Text" }
function Write-Warn([string] $Text) { Write-Host "aesir install: WARNING: $Text" -ForegroundColor Yellow }

Write-Host ''
Write-Host '  AESIR Red for Windows is EXPERIMENTAL.' -ForegroundColor Yellow
Write-Host '  The interactive terminal has never been verified on Windows by CI.' -ForegroundColor Yellow
Write-Host '  Windows and Linux compatibility require platform validation.' -ForegroundColor Yellow
Write-Host ''

if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') {
  throw "aesir install: only x64 Windows is published (this machine reports $env:PROCESSOR_ARCHITECTURE)."
}

# tar.exe is bsdtar, present since Windows 10 1803. Expand-Archive is avoided
# deliberately: it stamps Mark-of-the-Web onto every extracted file, so
# SmartScreen then challenges the bundled node.exe, and it is far slower across
# a closure this size.
if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
  throw 'aesir install: tar.exe is required (Windows 10 1803 or newer).'
}

$Filename = "aesir-$Version-win32-x64.zip"
$Base = "https://github.com/$Repo/releases/download/aesir-v$Version"
$Destination = Join-Path (Join-Path $Root 'versions') $Version
$Pending = Join-Path (Join-Path $Root 'versions') ('.install-' + [System.Guid]::NewGuid().ToString('N'))
$Payload = Join-Path $Pending 'payload'
$Previous = Join-Path $Pending 'previous'
$Temp = Join-Path ([System.IO.Path]::GetTempPath()) ("aesir-" + [System.Guid]::NewGuid().ToString('N'))

New-Item -ItemType Directory -Path $Temp -Force | Out-Null
try {
  Write-Host "aesir install: $Filename"
  $Archive = Join-Path $Temp $Filename
  $Sums = Join-Path $Temp 'SHA256SUMS'
  Invoke-WebRequest -Uri "$Base/$Filename" -OutFile $Archive -UseBasicParsing
  Invoke-WebRequest -Uri "$Base/SHA256SUMS" -OutFile $Sums -UseBasicParsing

  $Expected = (Get-Content $Sums | ForEach-Object {
      $parts = $_ -split '\s+', 2
      if ($parts.Length -eq 2 -and $parts[1].TrimStart('*') -eq $Filename) { $parts[0] }
    } | Select-Object -First 1)
  if (-not $Expected) { throw "aesir install: $Filename is absent from SHA256SUMS." }
  $Actual = (Get-FileHash -Algorithm SHA256 -Path $Archive).Hash.ToLowerInvariant()
  if ($Actual -ne $Expected.ToLowerInvariant()) {
    throw "aesir install: checksum mismatch for $Filename (expected $Expected, got $Actual)."
  }
  Unblock-File -Path $Archive

  New-Item -ItemType Directory -Path $Payload -Force | Out-Null
  & tar.exe -xf $Archive -C $Payload --strip-components=1
  if ($LASTEXITCODE -ne 0) { throw "aesir install: extraction failed with exit $LASTEXITCODE." }

  $NodeExe = Join-Path (Join-Path $Payload 'node') 'node.exe'
  $Launcher = Join-Path $Payload 'aesir-launch.mjs'
  $Installed = & $NodeExe $Launcher --version 2>&1
  if ($LASTEXITCODE -ne 0 -or ($Installed -join "`n").Trim() -ne $Version) {
    throw "aesir install: replacement launcher did not report $Version; the installed version is unchanged.`n  $Installed"
  }
  if (Test-Path $Destination) { Move-Item $Destination $Previous }
  Move-Item $Payload $Destination
}
finally {
  if ((Test-Path $Previous) -and -not (Test-Path $Destination)) {
    Move-Item $Previous $Destination
  }
  if (Test-Path $Pending) { Remove-Item -Recurse -Force $Pending }
  Remove-Item -Recurse -Force $Temp -ErrorAction SilentlyContinue
}

$BinDir = Join-Path $Root 'bin'
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
foreach ($shim in @('aesir.cmd', 'aesir.ps1')) {
  # Installed wrappers live outside the archive, so their relative targets include the version directory.
  $Source = Get-Content -Raw (Join-Path (Join-Path $Destination 'bin') $shim)
  $Source = $Source.Replace('..\node', "..\versions\$Version\node").Replace('..\aesir-launch.mjs', "..\versions\$Version\aesir-launch.mjs")
  [System.IO.File]::WriteAllText((Join-Path $BinDir $shim), $Source, [System.Text.UTF8Encoding]::new($false))
}

# Read the RAW user PATH. Reading $env:Path would merge the machine value in and
# then write the merged result back to user scope; expanding a REG_EXPAND_SZ
# PATH would freeze %USERPROFILE%-style entries into literals. setx is never
# used: it silently truncates at 1024 characters.
$EnvKey = Get-Item 'HKCU:\Environment'
$RawPath = $EnvKey.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
if (($RawPath -split ';') -notcontains $BinDir) {
  $Kind = if ($RawPath -like '*%*') { 'ExpandString' } else { 'String' }
  $Updated = if ([string]::IsNullOrEmpty($RawPath)) { $BinDir } else { "$RawPath;$BinDir" }
  Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $Updated -Type $Kind
  Write-Note "Added $BinDir to your user PATH, which new terminals read."
}

# A process reads the registry PATH once, when it starts, so any terminal opened
# earlier keeps its old value, including the one running this installer, and
# including every terminal opened since an earlier install wrote the entry. That
# is why the note above is not enough on its own: an upgrade finds the entry
# already present, says nothing, and leaves `aesir` unresolvable in the very
# session that just installed it. This script runs inside the user's shell, so
# it can put the directory on the live PATH and make the command work now.
if (($env:Path -split ';') -notcontains $BinDir) {
  $env:Path = "$BinDir;$env:Path"
  Write-Note 'Added it to this terminal too, so aesir works here right away.'
}

# The shell tool runs commands through PowerShell 7 (pwsh) and falls back to
# Windows PowerShell 5.1, which writes the OEM code page and garbles non-ASCII
# tool output. Installing pwsh here is what keeps that a non-event for the user.
function Test-Pwsh {
  if (Get-Command pwsh -ErrorAction SilentlyContinue) { return $true }
  return Test-Path (Join-Path (Join-Path $env:ProgramFiles 'PowerShell') '7\pwsh.exe')
}
$PwshState = 'PowerShell 7 (pwsh) is installed.'
if (-not (Test-Pwsh)) {
  if (-not $InstallSystemPackages) {
    $PwshState = 'PowerShell 7 (pwsh) is missing and AESIR_INSTALL_SYSTEM_PACKAGES=0 forbids installing it.'
  }
  elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host 'aesir install: PowerShell 7 is not installed; installing it with winget (a UAC prompt may appear).'
    & winget install --id Microsoft.PowerShell --exact --source winget --silent --accept-package-agreements --accept-source-agreements | Out-Null
    $PwshState = if (Test-Pwsh) { 'PowerShell 7 (pwsh) was installed now.' } else { 'PowerShell 7 (pwsh) could not be installed; tool output falls back to Windows PowerShell 5.1.' }
  }
  else {
    $PwshState = 'PowerShell 7 (pwsh) is missing and winget is unavailable; install it from https://aka.ms/powershell to keep non-ASCII tool output intact.'
  }
}

Write-Host ''
Write-Host "AESIR Red $Version is installed. Start it with:  aesir"
Write-Host ''
Write-Note 'Run aesir from PowerShell or Windows Terminal, not cmd.exe: a .cmd shim makes'
Write-Note '  cmd.exe ask "Terminate batch job (Y/N)?" after every Ctrl+C.'
Write-Note 'A model API key is required; the terminal opens a provider setup on first launch.'
Write-Note "Settings and sessions live in $env:USERPROFILE\.aesir\home."
Write-Note $PwshState
Write-Note 'Native Windows sandbox and interactive terminal behavior require platform validation.'
