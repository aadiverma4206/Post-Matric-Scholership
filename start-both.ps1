# PowerShell script to start both Scholarship.Api and Scholarship.Web reliably
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Starting Scholarship Management System (Govt. Portal AY 2025-26)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

# Ensure any previous processes on 5001 or 5002 are stopped
$ports = @(5001, 5002)
foreach ($port in $ports) {
    $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($connections) {
        $pids = $connections | Select-Object -ExpandProperty OwningProcess -Unique
        foreach ($p in $pids) {
            Write-Host "Stopping existing process PID $p on port $port..." -ForegroundColor Yellow
            Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
        }
    }
}

Start-Sleep -Milliseconds 500

Write-Host "`n[1/2] Starting Scholarship.Api backend on http://localhost:5001..." -ForegroundColor Cyan
$apiProcess = Start-Process -FilePath "dotnet" -ArgumentList "run --project `"$PSScriptRoot\Scholarship.Api\Scholarship.Api.csproj`" --launch-profile http" -PassThru -NoNewWindow

try {
    Write-Host "Waiting 3 seconds for API to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3

    Write-Host "`n[2/2] Starting Scholarship.Web frontend on http://localhost:5002..." -ForegroundColor Cyan
    Write-Host "Opening http://localhost:5002 in your browser..." -ForegroundColor Green
    Start-Process "http://localhost:5002"

    dotnet run --project "$PSScriptRoot\Scholarship.Web\Scholarship.Web.csproj" --launch-profile http
}
finally {
    if ($apiProcess -and !$apiProcess.HasExited) {
        Write-Host "`nStopping Scholarship.Api backend process..." -ForegroundColor Yellow
        Stop-Process -Id $apiProcess.Id -Force -ErrorAction SilentlyContinue
    }
}
