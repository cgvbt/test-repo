$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$vendor = Join-Path $here 'vendor'
$fonts = Join-Path $here 'fonts'
New-Item -ItemType Directory -Force -Path $vendor,$fonts | Out-Null

function Download-File([string]$Url,[string]$Path) {
  Write-Host "Downloading $([IO.Path]::GetFileName($Path)) ..."
  Invoke-WebRequest -Uri $Url -OutFile $Path -UseBasicParsing
}

# These libraries are open source and stored locally so the map renderer itself works offline.
Download-File 'https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.js' (Join-Path $vendor 'maplibre-gl.js')
Download-File 'https://unpkg.com/maplibre-gl@5.6.1/dist/maplibre-gl.css' (Join-Path $vendor 'maplibre-gl.css')
Download-File 'https://unpkg.com/pmtiles@4.3.0/dist/pmtiles.js' (Join-Path $vendor 'pmtiles.js')

# Get the PMTiles CLI from its latest GitHub release.
$release = Invoke-RestMethod -Uri 'https://api.github.com/repos/protomaps/go-pmtiles/releases/latest' -Headers @{ 'User-Agent'='FoodTrail-Offline-Setup' }
$asset = $release.assets | Where-Object { $_.name -match '(?i)windows.*amd64.*\.zip$|amd64.*windows.*\.zip$' } | Select-Object -First 1
if (-not $asset) { $asset = $release.assets | Where-Object { $_.name -match '(?i)windows.*\.zip$' } | Select-Object -First 1 }
if (-not $asset) { throw 'Could not find the Windows PMTiles CLI ZIP in the latest release.' }
$cliZip = Join-Path $env:TEMP 'foodtrail-pmtiles.zip'
$cliDir = Join-Path $env:TEMP 'foodtrail-pmtiles-cli'
Download-File $asset.browser_download_url $cliZip
if (Test-Path $cliDir) { Remove-Item $cliDir -Recurse -Force }
Expand-Archive -Path $cliZip -DestinationPath $cliDir -Force
$pmtiles = Get-ChildItem $cliDir -Filter 'pmtiles.exe' -Recurse | Select-Object -First 1
if (-not $pmtiles) { throw 'pmtiles.exe was not found in the downloaded CLI archive.' }

# Extract the Philippines from Protomaps' openly licensed OSM-derived daily basemap.
# Bounding box: west,south,east,north. Max zoom 15 gives detailed city streets while
# keeping the national archive much smaller than the full planet dataset.
$outMap = Join-Path $here 'philippines.pmtiles'
if (-not (Test-Path $outMap)) {
  $made = $false
  for ($days = 0; $days -le 6; $days++) {
    $date = (Get-Date).Date.AddDays(-$days).ToString('yyyyMMdd')
    $source = "https://build.protomaps.com/$date.pmtiles"
    Write-Host "Preparing Philippines offline map from build $date (this can take a while)..."
    & $pmtiles.FullName extract $source $outMap '--bbox=116,4,127.5,22.5' '--maxzoom=15'
    if ($LASTEXITCODE -eq 0 -and (Test-Path $outMap) -and (Get-Item $outMap).Length -gt 1000000) { $made = $true; break }
    if (Test-Path $outMap) { Remove-Item $outMap -Force }
    Write-Warning "Build $date unavailable or extraction failed; trying previous day's build."
  }
  if (-not $made) { throw 'Could not create the offline Philippines map. Check your internet connection and retry setup.' }
} else { Write-Host 'philippines.pmtiles already exists; keeping the existing map archive.' }

# Download a small set of Latin glyph ranges for local labels. Any missing glyph range
# only affects uncommon characters; the map itself remains offline.
foreach ($range in @('0-255','256-511','512-767','768-1023')) {
  $fontDir = Join-Path $fonts 'Open Sans Regular'
  New-Item -ItemType Directory -Force -Path $fontDir | Out-Null
  $fontPath = Join-Path $fontDir ($range + '.pbf')
  if (-not (Test-Path $fontPath)) {
    try { Download-File ("https://fonts.openmaptiles.org/Open%20Sans%20Regular/$range.pbf") $fontPath }
    catch { Write-Warning "Could not download font range $range; map labels may be incomplete." }
  }
}
Write-Host ''
Write-Host 'Offline map setup complete.' -ForegroundColor Green
Write-Host 'Next, run .\start-local.ps1 and open FoodTrail at http://127.0.0.1:8765.'
Write-Host 'After setup, map tiles are served from philippines.pmtiles on your own computer; no public tile server is used.'
