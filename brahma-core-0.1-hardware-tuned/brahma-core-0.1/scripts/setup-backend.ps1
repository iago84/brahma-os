$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\backend"
py -3.12 -m venv .venv
& .\.venv\Scripts\python.exe -m pip install --upgrade pip
& .\.venv\Scripts\python.exe -m pip install -e ".[dev,knowledge]"
if (!(Test-Path ".env")) { Copy-Item ".env.example" ".env" }
Write-Host "Backend environment ready."
