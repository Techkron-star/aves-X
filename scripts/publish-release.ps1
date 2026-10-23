param(
  [Parameter(Mandatory = $true)][string]$RunId,
  [Parameter(Mandatory = $true)][string]$Tag,
  [string]$Title = "Aves-X Beta 0.5",
  [string]$BodyFile = "release_body.md",
  [string]$Commit = ""
)

$ErrorActionPreference = "Stop"

$repo = "Techkron-star/aves-X"
if ($Tag -notmatch '^aves-x-v') {
  throw "El tag debe empezar por aves-x-v para no activar flujos del Aves original."
}

$token = $env:GH_TOKEN
if (!$token) { throw "Define GH_TOKEN con un token que tenga permiso para publicar releases." }

$headers = @{
  Authorization          = "Bearer $token"
  "User-Agent"           = "aves-x-release"
  Accept                 = "application/vnd.github+json"
  "X-GitHub-Api-Version" = "2022-11-28"
}
$api = "https://api.github.com/repos/$repo"

if (!(Test-Path $BodyFile)) { throw "No existe el archivo de notas: $BodyFile" }
$body = Get-Content $BodyFile -Raw

# Download the Aves-X libre APK artifact from a successful Actions run.
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

# Never delete or overwrite tags and releases automatically.
try {
  $existing = Invoke-RestMethod -Uri "$api/releases/tags/$Tag" -Headers $headers
  if ($existing) { throw "Ya existe la release para $Tag; no se sobrescribe automáticamente." }
} catch {
  if ($_.Exception.Message -match "no se sobrescribe automáticamente") { throw }
  # A 404 means there is no release for this tag yet.
}

$prerelease = [bool]($Tag -match '(?i)(alpha|beta|rc)')
$payload = @{
  tag_name   = $Tag
  name       = $Title
  body       = $body
  draft      = $false
  prerelease = $prerelease
  make_latest = -not $prerelease
}
if ($Commit) { $payload["target_commitish"] = $Commit }

"Creando la release $Tag..."
$release = Invoke-RestMethod -Method Post -Uri "$api/releases" -Headers $headers -Body ($payload | ConvertTo-Json) -ContentType "application/json"
"Release: $($release.html_url)"

$uploadBase = $release.upload_url -replace '\{.*\}$', ''
foreach ($apk in $apks) {
  $uri = "$uploadBase?name=$([uri]::EscapeDataString($apk.Name))"
  "Subiendo $($apk.Name)..."
  Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -InFile $apk.FullName -ContentType "application/vnd.android.package-archive" | Out-Null
}

Remove-Item $tmp -Recurse -Force
"RELEASE OK: $($release.html_url)"
