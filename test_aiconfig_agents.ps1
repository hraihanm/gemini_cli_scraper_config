# Test script for AIConfig Multi-Agent System
# This script demonstrates the system by launching a single agent

Write-Host "=== AIConfig Multi-Agent Test ===" -ForegroundColor Cyan
Write-Host "Testing single agent launch for PNS HK listings page" -ForegroundColor Yellow
Write-Host ""

# Create test task
$taskId = "test_listings_001"
$taskFile = ".\.gemini\agents\tasks\$taskId.json"

# Ensure directories exist
$directories = @(
    ".\.gemini\agents\tasks",
    ".\.gemini\agents\plans",
    ".\.gemini\agents\logs"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Create test task file
$taskData = @{
    task_id = $taskId
    agent = "selector-agent"
    page_type = "listings"
    status = "queued"
    process_id = $null
    started_at = $null
    target_url = "https://www.pns.hk/en/grocery/lc/04040000"
    description = "Test: Create CSS selectors for PNS HK listings page based on aiconfig.yaml"
    created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    aiconfig_fields = @("competitor_product_id", "name", "brand", "category", "customer_price_lc")
} | ConvertTo-Json -Depth 3

$taskData | Out-File -FilePath $taskFile -Encoding UTF8
Write-Host "Created test task file: $taskFile" -ForegroundColor Green

# Create agent launch script
$agentScript = ".\.gemini\agents\scripts\test_agent.ps1"
$scriptContent = @"
# Test Agent Task Assignment
Write-Host "=== SELECTOR AGENT - Test Task ===" -ForegroundColor Cyan
Write-Host "Task ID: $taskId" -ForegroundColor Yellow
Write-Host "Page Type: listings" -ForegroundColor Yellow
Write-Host "Target URL: https://www.pns.hk/en/grocery/lc/04040000" -ForegroundColor Yellow
Write-Host ""
Write-Host "Your task is to create CSS selectors for PNS HK listings page." -ForegroundColor Green
Write-Host "Required fields: competitor_product_id, name, brand, category, customer_price_lc" -ForegroundColor Green
Write-Host "Use browser tools to verify all selectors with >90% accuracy." -ForegroundColor Green
Write-Host "Save results to .gemini/agents/plans/selector_map.md" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to launch Gemini CLI with selector-agent extension..." -ForegroundColor Yellow
Read-Host

# Launch Gemini CLI with agent extension
& gemini -e selector-agent -i
"@

$scriptContent | Out-File -FilePath $agentScript -Encoding UTF8
Write-Host "Created agent script: $agentScript" -ForegroundColor Green

Write-Host ""
Write-Host "=== Ready to Launch Test Agent ===" -ForegroundColor Cyan
Write-Host "Task file: $taskFile" -ForegroundColor Blue
Write-Host "Agent script: $agentScript" -ForegroundColor Blue
Write-Host ""
Write-Host "To launch the test agent, run:" -ForegroundColor Yellow
Write-Host "Start-Process -FilePath 'powershell' -ArgumentList '-NoExit', '-File', '$agentScript'" -ForegroundColor White
Write-Host ""
Write-Host "Or manually run: gemini -e selector-agent -i" -ForegroundColor Yellow
Write-Host ""

# Ask if user wants to launch
$launch = Read-Host "Do you want to launch the test agent now? (y/n)"
if ($launch -eq "y" -or $launch -eq "Y") {
    Write-Host "Launching test agent..." -ForegroundColor Yellow
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-File", $agentScript -WindowStyle Normal
    Write-Host "Test agent launched in new window!" -ForegroundColor Green
} else {
    Write-Host "Test agent ready to launch manually." -ForegroundColor Blue
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host "Monitor the agent in the new window." -ForegroundColor Blue
Write-Host "Check task status in: $taskFile" -ForegroundColor Blue
