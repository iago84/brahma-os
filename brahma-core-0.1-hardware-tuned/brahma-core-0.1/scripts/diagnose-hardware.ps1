$ErrorActionPreference = "Continue"
Write-Host "`n=== BRAHMA HARDWARE DIAGNOSTICS ===" -ForegroundColor Cyan

Get-CimInstance Win32_OperatingSystem |
  Select-Object Caption, Version, BuildNumber,
    @{Name="RAM_Total_GB";Expression={[math]::Round($_.TotalVisibleMemorySize/1MB,1)}},
    @{Name="RAM_Free_GB";Expression={[math]::Round($_.FreePhysicalMemory/1MB,1)}} |
  Format-List

Get-CimInstance Win32_Processor |
  Select-Object Name, NumberOfCores, NumberOfLogicalProcessors |
  Format-List

Get-CimInstance Win32_VideoController |
  Select-Object Name, AdapterRAM, DriverVersion |
  Format-List

Get-PSDrive -PSProvider FileSystem |
  Select-Object Name,
    @{Name="Free_GB";Expression={[math]::Round($_.Free/1GB,1)}},
    @{Name="Used_GB";Expression={[math]::Round($_.Used/1GB,1)}} |
  Format-Table -AutoSize

Write-Host "`n=== NVIDIA ===" -ForegroundColor Cyan
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
  nvidia-smi
} else {
  Write-Host "nvidia-smi not found. Check NVIDIA driver installation."
}

Write-Host "`n=== OLLAMA ===" -ForegroundColor Cyan
if (Get-Command ollama -ErrorAction SilentlyContinue) {
  ollama --version
  ollama list
  try { Invoke-RestMethod http://127.0.0.1:11434/api/tags | ConvertTo-Json -Depth 4 }
  catch { Write-Host "Ollama API is not responding. Start the Ollama application." }
} else {
  Write-Host "Ollama CLI not found."
}
