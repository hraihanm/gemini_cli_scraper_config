# Start playwright-mcp-mod as background HTTP SSE server on port 3000
# Run this BEFORE launching `agent --yolo` in Cursor CLI
#
# Usage: pwsh -File scripts/start-playwright-mcp.ps1
# Stop:  Stop-Process -Name node -ErrorAction SilentlyContinue  (or close the window)

$NodeExe = "C:\nvm4w\nodejs\node.exe"
$CliJs   = "D:\DataHen\projects\playwright-mcp-mod\cli.js"
$Port    = 3000

# Kill any existing instance on port 3000
$existing = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Stopping existing process on port $Port..."
    $existing | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 500
}

Write-Host "Starting playwright-mcp-mod on http://localhost:$Port/sse ..."
$proc = Start-Process -FilePath $NodeExe `
    -ArgumentList "$CliJs --caps vision --port $Port" `
    -PassThru -WindowStyle Minimized

Write-Host "playwright-mcp-mod started (PID: $($proc.Id))"
Write-Host "SSE endpoint: http://localhost:$Port/sse"
Write-Host ""
Write-Host "Now run: agent --yolo"
