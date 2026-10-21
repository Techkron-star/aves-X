param(
  [string]$Ref = "develop",
  [int]$WorkflowId = 385000599,
  [int]$TimeoutMinutes = 25,
  [int]$PollSeconds = 15,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repo = "Techkron-star/aves-X"
$tokenPath = Join-Path $env:USERPROFILE ".config\opencode\github-token"

if (!(Test-Path $tokenPath)) {
  throw "No existe el token en $tokenPath"
}

$token = (Get-Content $tokenPath -Raw).Trim()
if (!$token) {
  throw "El token está vacío"
}

$headers = @{
  Authorization = "Bearer $token"
  "User-Agent" = "aves-x-auditor"
  Accept = "application/vnd.github+json"
}
$api = "https://api.github.com/repos/$repo"

if ($DryRun) {
  "DRY RUN: repo=$repo workflow=$WorkflowId ref=$Ref"
  $runs = Invoke-RestMethod -Uri "$api/actions/runs?per_page=1" -Headers $headers
  if ($runs.workflow_runs.Count -gt 0) {
    $last = $runs.workflow_runs[0]
    "Último run: $($last.id) | $($last.name) | $($last.status) | $($last.conclusion)"
  } else {
    "No hay runs todavía."
  }
  exit 0
}

$before = 0
$latest = Invoke-RestMethod -Uri "$api/actions/runs?per_page=1" -Headers $headers
if ($latest.workflow_runs.Count -gt 0) {
  $before = [int64]$latest.workflow_runs[0].id
}

$body = @{ ref = $Ref } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$api/actions/workflows/$WorkflowId/dispatches" -Headers $headers -Body $body -ContentType "application/json" | Out-Null
"Build lanzada para $Ref. Esperando el run..."

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
$run = $null

while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds 5
  $runs = Invoke-RestMethod -Uri "$api/actions/runs?per_page=10" -Headers $headers
  $run = $runs.workflow_runs | Where-Object {
    $_.workflow_id -eq $WorkflowId -and [int64]$_.id -gt $before -and $_.head_branch -eq $Ref
  } | Select-Object -First 1
  if ($run) { break }
}

if (!$run) {
  throw "No apareció ningún run nuevo en $TimeoutMinutes minutos."
}

"RUN: $($run.id) | $($run.html_url)"

while ($run.status -ne "completed" -and (Get-Date) -lt $deadline) {
  Start-Sleep -Seconds $PollSeconds
  $run = Invoke-RestMethod -Uri "$api/actions/runs/$($run.id)" -Headers $headers
  "STATUS: $($run.status)"
}

if ($run.status -ne "completed") {
  throw "Timeout esperando el run $($run.id)."
}

"CONCLUSION: $($run.conclusion)"

$failed = $false
$jobs = Invoke-RestMethod -Uri "$api/actions/runs/$($run.id)/jobs" -Headers $headers
foreach ($j in $jobs.jobs) {
  "JOB: $($j.name) => $($j.conclusion)"
  if ($j.conclusion -ne "success") {
    $failed = $true
    try {
      $ann = Invoke-RestMethod -Uri "$api/check-runs/$($j.id)/annotations" -Headers $headers
      if ($ann.Count -eq 0) {
        "  (sin anotaciones)"
      } else {
        foreach ($a in $ann) {
          "  [$($a.annotation_level)] $($a.title): $($a.message)"
        }
      }
    } catch {
      "  no se pudieron leer las anotaciones: $($_.Exception.Message)"
    }
  }
}

if ($failed -or $run.conclusion -ne "success") {
  exit 1
}

"BUILD OK"
exit 0
