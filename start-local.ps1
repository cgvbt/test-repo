$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Get-Command py -ErrorAction SilentlyContinue
if ($python) { $exe = 'py'; $args = @('-3', (Join-Path $here 'server.py')) }
else {
  $python = Get-Command python -ErrorAction SilentlyContinue
  if (-not $python) { throw 'Python 3 is required. Install it from https://www.python.org/downloads/ and try again.' }
  $exe = 'python'; $args = @((Join-Path $here 'server.py'))
}
Write-Host 'FoodTrail is starting at http://127.0.0.1:8765' -ForegroundColor Green
Write-Host 'Keep this window open while using FoodTrail. Press Ctrl+C to stop.'
Start-Process 'http://127.0.0.1:8765'
& $exe @args
