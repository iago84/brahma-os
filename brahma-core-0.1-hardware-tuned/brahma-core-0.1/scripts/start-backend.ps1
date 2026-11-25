$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\..\backend"
if (!(Test-Path ".venv\Scripts\Activate.ps1")) { throw "Run setup-backend.ps1 first." }
. .\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
