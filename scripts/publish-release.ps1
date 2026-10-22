param(
  [Parameter(Mandatory = $true)][string]$RunId,
  [Parameter(Mandatory = $true)][string]$Tag,
  [string]$Title = "Aves-X $Tag - Nebula Engine v1",
  [string]$BodyFile = "release_body.md",
  [string]$Commit = "",
  [switch]$Replace
)

$ErrorActionPreference = "Stop"

$repo = "Techkron-star/aves-X"
$tokenPath = Join-Path $env:USERPROFILE ".config\opencode\github-token"

if (!(Test-Path $tokenPath)) { throw "No existe el token en $tokenPath" }
$token = (Get-Content $tokenPath -Raw).Trim()
if (!$token) { throw "El token esta vacio" }

$headers = @{
  Authorization          = "Bearer $token"
  "User-Agent"           = "aves-x-auditor"
  Accept                 = "application/vnd.github+json"
  "X-GitHub-Api-Version" = "2022-11-28"
}
$api = "https://api.github.com/repos/$repo"

if (!(Test-Path $BodyFile)) { throw "No existe el archivo de notas: $BodyFile" }
$body = Get-Content $BodyFile -Raw

# ---------------------------------------------------------------- artifact ---
"Buscando el artefacto aves-x-libre-apks del run $RunId..."
$artifacts = Invoke-RestMethod -Uri "$api/actions/runs/$RunId/artifacts" -Headers $headers
$artifact = $artifacts.artifacts | Where-Object { $_.name -eq "aves-x-libre-apks" } | Select-Object -First 1
if (!$artifact) { throw "El run $RunId no tiene el artefacto aves-x-libre-apks" }
"Artefacto: $($artifact.id) ($([math]::Round($artifact.size_in_bytes / 1MB, 1)) MB)"

$tmp = Join-Path $env:TEMP "aves-x-release-$RunId"
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
New-Item -ItemType Directory -Path $tmp | Out-Null
$zip = Join-Path $tmp "apks.zip"

"Descargando artefacto..."
Invoke-WebRequest -Uri $artifact.archive_download_url -Headers $headers -OutFile $zip
Expand-Archive -Path $zip -DestinationPath (Join-Path $tmp "apks") -Force
$apks = Get-ChildItem (Join-Path $tmp "apks") -Recurse -Filter "*.apk"
if ($apks.Count -eq 0) { throw "El artefacto no contiene APKs" }
$apks | ForEach-Object { "APK: $($_.Name) ($([math]::Round($_.Length / 1MB, 1)) MB)" }

# ------------------------------------------------------------- existing rel ---
$existing = $null
try {
  $existing = Invoke-RestMethod -Uri "$api/releases/tags/$Tag" -Headers $headers
} catch {
  $existing = $null
}

if ($existing) {
  if (!$Replace) {
    throw "Ya existe una release para $Tag. Usa -Replace para recrearla."
  }
  "Eliminando la release existente $($existing.id)..."
  Invoke-RestMethod -Method Delete -Uri "$api/releases/$($existing.id)" -Headers $headers | Out-Null
}

# move/remove the tag so the release points at the APK commit
try {
  $ref = Invoke-RestMethod -Uri "$api/git/ref/tags/$Tag" -Headers $headers
  "Borrando el tag existente $Tag ($($ref.object.sha))..."
  Invoke-RestMethod -Method Delete -Uri "$api/git/refs/tags/$Tag" -Headers $headers | Out-Null
} catch {
  # tag does not exist: the release API will create it
}

# ---------------------------------------------------------------- release ----
$payload = @{
  tag_name         = $Tag
  name             = $Title
  body             = $body
  draft            = $false
  prerelease       = $false
  make_latest      = "true"
}
if ($Commit) { $payload["target_commitish"] = $Commit }

"Creando la release $Tag..."
$release = Invoke-RestMethod -Method Post -Uri "$api/releases" -Headers $headers -Body ($payload | ConvertTo-Json) -ContentType "application/json"
"Release: $($release.html_url)"

# ----------------------------------------------------------------- upload ----
$uploadBase = $release.upload_url -replace '\{.*\}$', ''
foreach ($apk in $apks) {
  $uri = "$uploadBase?name=$([uri]::EscapeDataString($apk.Name))"
  "Subiendo $($apk.Name)..."
  Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -InFile $apk.FullName -ContentType "application/vnd.android.package-archive" | Out-Null
}

Remove-Item $tmp -Recurse -Force
"RELEASE OK: $($release.html_url)"
