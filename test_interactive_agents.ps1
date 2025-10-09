# Test script for interactive agent launching
# This demonstrates the difference between -p and -i modes

Write-Host "=== Interactive Agent Testing ===" -ForegroundColor Green
Write-Host ""

Write-Host "Testing Interactive Mode vs Non-Interactive Mode..." -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Interactive Mode (RECOMMENDED):" -ForegroundColor Cyan
Write-Host "   Command: gemini -e navigation-agent -i `"You are the navigation-agent...`""
Write-Host "   Benefits:"
Write-Host "   - You can see what the agent is doing in real-time"
Write-Host "   - You can intervene if something goes wrong"
Write-Host "   - You can guide the agent if needed"
Write-Host "   - You can stop/restart the agent"
Write-Host ""

Write-Host "2. Non-Interactive Mode (NOT RECOMMENDED):" -ForegroundColor Red
Write-Host "   Command: gemini -e navigation-agent -p `"You are the navigation-agent...`""
Write-Host "   Problems:"
Write-Host "   - Runs once and exits"
Write-Host "   - You can't see what's happening"
Write-Host "   - You can't intervene if there are issues"
Write-Host "   - No real-time monitoring"
Write-Host ""

Write-Host "=== Testing Interactive Agent Launch ===" -ForegroundColor Green
Write-Host ""

# Test launching a single agent in interactive mode
Write-Host "Launching Navigation Agent in interactive mode..." -ForegroundColor Yellow
Write-Host "This will open a new PowerShell window where you can interact with the agent."
Write-Host ""

$scriptPath = Join-Path (Split-Path $MyInvocation.MyCommand.Definition) ".gemini\agents\scripts\launch_agent.ps1"

# Launch Navigation Agent
& $scriptPath -Agent "navigation-agent" -PageType "categories" -TaskId "test_nav_001" -TargetUrl "https://www.pns.hk/en/" -Description "Test interactive navigation agent for PNS HK categories page"

Write-Host ""
Write-Host "=== Interactive Agent Launched ===" -ForegroundColor Green
Write-Host "Check the new PowerShell window to see the agent working interactively."
Write-Host "You can now:"
Write-Host "- See what the agent is doing in real-time"
Write-Host "- Intervene if needed"
Write-Host "- Guide the agent if required"
Write-Host "- Stop/restart the agent if necessary"
Write-Host ""
Write-Host "To launch more agents, use:" -ForegroundColor Yellow
Write-Host "  /aiconfig:start all pns-hk-scraper"
Write-Host "  /aiconfig:start analyze categories pns-hk-scraper"
Write-Host "  /aiconfig:start selectors listings pns-hk-scraper"
Write-Host "  /aiconfig:start parser details pns-hk-scraper"
