# Master Agent Coordinator Script
# This script keeps the master agent alive and coordinates with subagents

param(
    [string]$ScraperName = "pns-hk-scraper",
    [int]$CheckInterval = 30,  # Check every 30 seconds
    [int]$MaxWaitTime = 3600   # Maximum wait time: 1 hour
)

Write-Host "=== Master Agent Coordinator ===" -ForegroundColor Green
Write-Host "Scraper: $ScraperName" -ForegroundColor Cyan
Write-Host "Check Interval: $CheckInterval seconds" -ForegroundColor Cyan
Write-Host "Max Wait Time: $MaxWaitTime seconds" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$tasksDir = ".\agent_state\tasks"
$plansDir = ".\agent_state\plans"
$logsDir = ".\agent_state\logs"

# Ensure directories exist
if (!(Test-Path $tasksDir)) { New-Item -ItemType Directory -Path $tasksDir -Force }
if (!(Test-Path $plansDir)) { New-Item -ItemType Directory -Path $plansDir -Force }
if (!(Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force }

function Get-TaskStatus {
    $tasks = Get-ChildItem -Path $tasksDir -Filter "*.json" | ForEach-Object {
        $content = Get-Content $_.FullName | ConvertFrom-Json
        [PSCustomObject]@{
            TaskId = $content.task_id
            Agent = $content.agent
            Status = $content.status
            PageType = $content.page_type
            CreatedAt = $content.created_at
            StartedAt = $content.started_at
            CompletedAt = $content.completed_at
        }
    }
    return $tasks
}

function Show-Status {
    $tasks = Get-TaskStatus
    Write-Host "=== Task Status ===" -ForegroundColor Yellow
    foreach ($task in $tasks) {
        $statusColor = switch ($task.Status) {
            "queued" { "Yellow" }
            "running" { "Green" }
            "completed" { "Cyan" }
            "failed" { "Red" }
            default { "White" }
        }
        Write-Host "  $($task.TaskId) - $($task.Agent) - $($task.PageType) - $($task.Status)" -ForegroundColor $statusColor
    }
    Write-Host ""
}

function Check-AllTasksComplete {
    $tasks = Get-TaskStatus
    $incompleteTasks = $tasks | Where-Object { $_.Status -ne "completed" -and $_.Status -ne "failed" }
    return $incompleteTasks.Count -eq 0
}

function Show-Results {
    Write-Host "=== Generated Results ===" -ForegroundColor Yellow
    
    # Check for navigation results
    $navResults = Get-ChildItem -Path $plansDir -Filter "*navigation*" -ErrorAction SilentlyContinue
    if ($navResults) {
        Write-Host "  Navigation Agent Results:" -ForegroundColor Green
        foreach ($result in $navResults) {
            Write-Host "    - $($result.Name)" -ForegroundColor White
        }
    }
    
    # Check for selector results
    $selResults = Get-ChildItem -Path $plansDir -Filter "*selector*" -ErrorAction SilentlyContinue
    if ($selResults) {
        Write-Host "  Selector Agent Results:" -ForegroundColor Green
        foreach ($result in $selResults) {
            Write-Host "    - $($result.Name)" -ForegroundColor White
        }
    }
    
    # Check for parser results
    $parResults = Get-ChildItem -Path $plansDir -Filter "*parser*" -ErrorAction SilentlyContinue
    if ($parResults) {
        Write-Host "  Parser Agent Results:" -ForegroundColor Green
        foreach ($result in $parResults) {
            Write-Host "    - $($result.Name)" -ForegroundColor White
        }
    }
    
    # Check for generated scraper files
    $scraperDir = ".\agent_state\workspace\generated_scraper\$ScraperName"
    if (Test-Path $scraperDir) {
        Write-Host "  Generated Scraper Files:" -ForegroundColor Green
        $scraperFiles = Get-ChildItem -Path $scraperDir -Recurse -ErrorAction SilentlyContinue
        foreach ($file in $scraperFiles) {
            Write-Host "    - $($file.FullName.Replace((Get-Location).Path, '.'))" -ForegroundColor White
        }
    }
    
    Write-Host ""
}

# Main coordination loop
Write-Host "Starting coordination loop..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop coordination and exit." -ForegroundColor Yellow
Write-Host ""

while ($true) {
    $elapsed = (Get-Date) - $startTime
    
    # Check if we've exceeded max wait time
    if ($elapsed.TotalSeconds -gt $MaxWaitTime) {
        Write-Host "Maximum wait time exceeded. Stopping coordination." -ForegroundColor Red
        break
    }
    
    # Show current status
    Show-Status
    Show-Results
    
    # Check if all tasks are complete
    if (Check-AllTasksComplete) {
        Write-Host "All tasks completed! Coordination finished." -ForegroundColor Green
        Show-Results
        break
    }
    
    # Wait before next check
    Write-Host "Waiting $CheckInterval seconds before next check..." -ForegroundColor Gray
    Write-Host "Elapsed time: $([math]::Round($elapsed.TotalMinutes, 1)) minutes" -ForegroundColor Gray
    Write-Host "----------------------------------------" -ForegroundColor Gray
    Start-Sleep -Seconds $CheckInterval
}

Write-Host ""
Write-Host "=== Coordination Complete ===" -ForegroundColor Green
Write-Host "Total coordination time: $([math]::Round($elapsed.TotalMinutes, 1)) minutes" -ForegroundColor Cyan
