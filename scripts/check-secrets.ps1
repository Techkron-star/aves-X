# Scans tracked files for API keys, tokens and private keys.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-secrets.ps1
$ErrorActionPreference = "Stop"

$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$gitCandidates = @(
  "C:\Program Files\Git\cmd\git.exe",
  "git"
)
$git = $gitCandidates | Where-Object {
  if ($_ -eq "git") { $null -ne (Get-Command git -ErrorAction SilentlyContinue) }
  else { Test-Path $_ }
} | Select-Object -First 1
if (!$git) { throw "git no encontrado" }

$patterns = @(
  "AIza[0-9A-Za-z_-]{30,}",                       # Google API key
  "sk-[A-Za-z0-9]{20,}",                          # OpenAI / OpenRouter style
  "gh[pousr]_[A-Za-z0-9]{20,}",                   # GitHub tokens
  "github_pat_[A-Za-z0-9_]{20,}",                 # GitHub fine-grained PAT
  "xox[baprs]-[A-Za-z0-9-]{10,}",                 # Slack
  "AKIA[0-9A-Z]{16}",                             # AWS access key id
  "-----BEGIN [A-Z ]*PRIVATE KEY-----"            # private keys
)

$failed = $false
foreach ($pattern in $patterns) {
  $out = & $git -C $repo grep -n -I -E $pattern -- . ":(exclude)*.lock"
  if ($LASTEXITCODE -eq 0 -and $out) {
    $failed = $true
    "SECRET PATTERN FOUND: $pattern"
    $out | ForEach-Object { "  $_" }
  }
}

# Files that must never be tracked
$forbidden = & $git -C $repo ls-files | Where-Object {
  $_ -match '(^|/)(\.env(\..*)?|.*\.(jks|keystore|p12|pem|key|p8|asc)|google-services\.json|GoogleService-Info\.plist|key\.properties|local\.properties)$'
}
if ($forbidden) {
  $failed = $true
  "FORBIDDEN FILES TRACKED:"
  $forbidden | ForEach-Object { "  $_" }
}

if ($failed) {
  "SECRETS CHECK: FAILED"
  exit 1
}
"SECRETS CHECK: OK (no keys, tokens or signing material in tracked files)"
exit 0
