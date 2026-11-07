# Free from @barakahraaz on Instagram. Not for sale.
# Reel skill setup checker for Windows. Claude runs this; the user never types it.
#   powershell -NoProfile -ExecutionPolicy Bypass -File .kit/setup.ps1 -Check
#   powershell -NoProfile -ExecutionPolicy Bypass -File .kit/setup.ps1 -Install <tool>
# Tools: git chrome ffmpeg node python python-packages obsidian playwright (all but playwright and python-packages install with winget).
param(
  [switch]$Check,
  [string]$Install = ''
)

function Refresh-Path {
  # winget changes the saved PATH, not the running one. Re-read it so a fresh install is seen at once.
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}
Refresh-Path

function Say($msg) { [Console]::Error.WriteLine($msg) }

function Has($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Has-Path($paths) {
  foreach ($p in $paths) { if ($p -and (Test-Path $p)) { return $true } }
  return $false
}

function Has-Chrome {
  Has-Path @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe")
}

function Has-Obsidian {
  Has-Path @(
    "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe",
    "$env:LOCALAPPDATA\Obsidian\Obsidian.exe",
    "$env:ProgramFiles\Obsidian\Obsidian.exe")
}

function Has-Python { return [bool](Python-Cmd) }

function Python-Cmd {
  # The first real Python, or $null. The Windows Store shim answers "python" but is not a real install; run it to be sure.
  foreach ($c in 'python', 'py') {
    if (Has $c) {
      & $c -c "import sys" 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) { return $c }
    }
  }
  return $null
}

function Has-Python-Packages {
  # numpy, scipy and pillow for the sound mix, motion blur and checks. No -I: a --user install lives in the user site folder.
  $py = Python-Cmd
  if (-not $py) { return $false }
  Push-Location $env:SystemRoot
  & $py -c "import numpy, scipy, PIL" 2>$null | Out-Null
  $ok = ($LASTEXITCODE -eq 0)
  Pop-Location
  return $ok
}

function Install-Python-Packages {
  $py = Python-Cmd
  if (-not $py) { Say 'Install python first.'; return 1 }
  Push-Location $env:SystemRoot
  $log = (& $py -m pip install --user numpy scipy pillow 2>&1 | Out-String)
  $code = $LASTEXITCODE
  # Only a PEP 668 "externally-managed-environment" refusal is retried past.
  if ($code -ne 0 -and $log -match 'externally-managed-environment') {
    & $py -m pip install --user --break-system-packages numpy scipy pillow | Out-Host
    $code = $LASTEXITCODE
  } elseif ($code -ne 0) {
    Say (($log -split "`n") | Select-Object -Last 5 | Out-String)
  }
  Pop-Location
  return $code
}

function Python3-Shim {
  # Kit scripts run in Git Bash and call python3. winget Python gives python and py only.
  # (Skipped when a real python3 already resolves; the Store stub counts as not resolving.)
  $dir = Join-Path $HOME 'bin'
  $shim = Join-Path $dir 'python3'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  [IO.File]::WriteAllText($shim, "#!/usr/bin/env bash`nexec python `"`$@`"`n")   # LF endings, no BOM
}

function Has-Python3-Shim {
  if (Test-Path (Join-Path $HOME 'bin\python3')) { return $true }
  $c = Get-Command python3 -ErrorAction SilentlyContinue
  return [bool]($c -and $c.Source -notlike '*WindowsApps*')
}

function Has-Git {
  # Claude Code on Windows runs through Git Bash, and the reel render script is bash.
  (Has git) -or (Has-Path @("$env:ProgramFiles\Git\bin\bash.exe", "$env:ProgramFiles\Git\usr\bin\bash.exe"))
}

function Has-Playwright {
  if (-not (Has npm)) { return $false }
  $root = (& npm root -g 2>$null)
  return [bool]($root -and (Test-Path (Join-Path $root 'playwright')))
}

function Run-Check {
  $n = 0
  if (-not (Has winget))                       { 'missing: winget';     $n++ }
  if (-not (Has-Git))                          { 'missing: git';        $n++ }
  if (-not (Has-Chrome))                       { 'missing: chrome';     $n++ }
  if (-not ((Has ffmpeg) -and (Has ffprobe)))  { 'missing: ffmpeg';     $n++ }
  if (-not (Has node))                         { 'missing: node';       $n++ }
  if (-not (Has-Python))                       { 'missing: python';     $n++ }
  elseif (-not (Has-Python3-Shim))             { Python3-Shim }
  if (-not (Has-Python-Packages))              { 'missing: python-packages'; $n++ }
  if (-not (Has-Playwright))                   { 'missing: playwright'; $n++ }
  if (-not (Has-Obsidian))                     { 'missing: obsidian';   $n++ }
  if ($n -eq 0) { 'all ready' }
}

function Run-Install($tool) {
  if ($tool -notin 'git','chrome','ffmpeg','node','python','python-packages','obsidian','playwright') {
    Say "Unknown tool: $tool"; return 2
  }
  if ($tool -eq 'python-packages') { return (Install-Python-Packages) }
  if ($tool -ne 'playwright' -and -not (Has winget)) {
    Say 'winget is missing. Update "App Installer" from the Microsoft Store, then try again.'
    return 1
  }
  $flags = '--silent', '--accept-package-agreements', '--accept-source-agreements'
  switch ($tool) {
    'git'        { winget install --id Git.Git -e @flags }
    'chrome'     { winget install --id Google.Chrome -e @flags }
    'ffmpeg'     { winget install --id Gyan.FFmpeg -e @flags }
    'node'       { winget install --id OpenJS.NodeJS.LTS -e @flags }
    'python'     { winget install --id Python.Python.3.14 -e @flags }
    'obsidian'   { winget install --id Obsidian.Obsidian -e @flags }
    'playwright' {
      Refresh-Path
      if (-not (Has npm)) { Say 'Install node first.'; return 1 }
      npm install -g playwright
    }
  }
  $code = $LASTEXITCODE
  Refresh-Path
  if ($tool -eq 'python' -and (Has-Python)) { Python3-Shim }
  # -1978335189 (0x8A15002B) means winget found it already installed. That is success.
  if ($code -eq -1978335189) { return 0 }
  return $code
}

if ($Check) { Run-Check; exit 0 }
if ($Install) { exit (Run-Install $Install) }
Say 'usage: setup.ps1 -Check | -Install <tool>'
exit 2
