$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\frontend"
if (!(Test-Path "package.json")) { throw "frontend/package.json missing." }
npm install
if (!(Test-Path ".env.local")) { Copy-Item ".env.local.example" ".env.local" }
Write-Host "Frontend environment ready."
