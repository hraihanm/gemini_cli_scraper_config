# AIConfig Multi-Agent Launcher
# This script launches interactive agents for AIConfig parser generation

param(
    [Parameter(Mandatory=$false)]
    [string]$PageType = "all",
    
    [Parameter(Mandatory=$false)]
    [string]$ScraperName = "pns-hk-scraper",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetUrl = "https://www.pns.hk/en/"
)

Write-Host "=== AIConfig Multi-Agent Launcher ===" -ForegroundColor Cyan
Write-Host "Scraper: $ScraperName" -ForegroundColor Yellow
Write-Host "Page Type: $PageType" -ForegroundColor Yellow
Write-Host "Target URL: $TargetUrl" -ForegroundColor Yellow
Write-Host ""

# Create necessary directories
$directories = @(
    ".\.gemini\agents\tasks",
    ".\.gemini\agents\plans", 
    ".\.gemini\agents\logs",
    ".\.gemini\agents\workspace\generated_scraper\$ScraperName\parsers",
    ".\.gemini\agents\workspace\generated_scraper\$ScraperName\seeder",
    ".\.gemini\agents\workspace\generated_scraper\$ScraperName\finisher"
)

foreach ($dir in $directories) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force
        Write-Host "Created directory: $dir" -ForegroundColor Green
    }
}

# Function to launch an agent
function Launch-Agent {
    param(
        [string]$Agent,
        [string]$PageType,
        [string]$TaskId,
        [string]$TargetUrl,
        [string]$Description
    )
    
    Write-Host "Launching $Agent for $PageType..." -ForegroundColor Yellow
    
    # Create task file
    $taskFile = ".\.gemini\agents\tasks\$TaskId.json"
    $taskData = @{
        task_id = $TaskId
        agent = $Agent
        page_type = $PageType
        status = "queued"
        process_id = $null
        started_at = $null
        target_url = $TargetUrl
        description = $Description
        created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        aiconfig_fields = @()
        dependencies = @()
    } | ConvertTo-Json -Depth 3
    
    $taskData | Out-File -FilePath $taskFile -Encoding UTF8
    
    # Create agent launch script
    $agentScript = ".\.gemini\agents\scripts\agent_$TaskId.ps1"
    $scriptContent = @"
# Agent Task Assignment
Write-Host "=== $Agent - Task ID: $TaskId ===" -ForegroundColor Cyan
Write-Host "Page Type: $PageType" -ForegroundColor Yellow
Write-Host "Target URL: $TargetUrl" -ForegroundColor Yellow
Write-Host "Description: $Description" -ForegroundColor Yellow
Write-Host ""
Write-Host "Your task is to work on the $PageType page type for the $ScraperName scraper." -ForegroundColor Green
Write-Host "Use browser tools to analyze the site and complete your task." -ForegroundColor Green
Write-Host "Save your results to .gemini/agents/plans/ directory." -ForegroundColor Green
Write-Host ""

# Launch Gemini CLI with agent extension
& gemini -e $Agent -i
"@
    
    $scriptContent | Out-File -FilePath $agentScript -Encoding UTF8
    
    # Launch the agent in a new PowerShell window
    Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-File", $agentScript -WindowStyle Normal
    
    Write-Host "Agent launched in new window. Task ID: $TaskId" -ForegroundColor Green
    Write-Host "Monitor progress in .gemini/agents/tasks/$TaskId.json" -ForegroundColor Blue
    Write-Host ""
}

# Launch agents based on page type
if ($PageType -eq "all" -or $PageType -eq "categories") {
    Launch-Agent -Agent "navigation-agent" -PageType "categories" -TaskId "nav_categories_001" -TargetUrl $TargetUrl -Description "Analyze website structure for PNS HK categories page based on aiconfig.yaml configuration"
    Start-Sleep -Seconds 2
}

if ($PageType -eq "all" -or $PageType -eq "subcategories") {
    Launch-Agent -Agent "navigation-agent" -PageType "subcategories" -TaskId "nav_subcategories_001" -TargetUrl "https://www.pns.hk/en/foodBeverages" -Description "Analyze website structure for PNS HK subcategories page based on aiconfig.yaml configuration"
    Start-Sleep -Seconds 2
}

if ($PageType -eq "all" -or $PageType -eq "listings") {
    Launch-Agent -Agent "navigation-agent" -PageType "listings" -TaskId "nav_listings_001" -TargetUrl "https://www.pns.hk/en/grocery/lc/04040000" -Description "Analyze website structure for PNS HK listings page based on aiconfig.yaml configuration"
    Start-Sleep -Seconds 2
}

# Launch Selector Agents
if ($PageType -eq "all" -or $PageType -eq "categories") {
    Launch-Agent -Agent "selector-agent" -PageType "categories" -TaskId "sel_categories_001" -TargetUrl $TargetUrl -Description "Create CSS selectors for PNS HK categories page based on aiconfig.yaml fields: category_name, category_url"
    Start-Sleep -Seconds 2
}

if ($PageType -eq "all" -or $PageType -eq "subcategories") {
    Launch-Agent -Agent "selector-agent" -PageType "subcategories" -TaskId "sel_subcategories_001" -TargetUrl "https://www.pns.hk/en/foodBeverages" -Description "Create CSS selectors for PNS HK subcategories page based on aiconfig.yaml fields: subcategory_name, subcategory_url"
    Start-Sleep -Seconds 2
}

if ($PageType -eq "all" -or $PageType -eq "listings") {
    Launch-Agent -Agent "selector-agent" -PageType "listings" -TaskId "sel_listings_001" -TargetUrl "https://www.pns.hk/en/grocery/lc/04040000" -Description "Create CSS selectors for PNS HK listings page based on aiconfig.yaml fields: competitor_product_id, name, brand, category, customer_price_lc, base_price_lc, has_discount, discount_percentage, img_url, sku, url, is_available, etc."
    Start-Sleep -Seconds 2
}

# Launch Parser Agents
if ($PageType -eq "all" -or $PageType -eq "categories") {
    Launch-Agent -Agent "parser-agent" -PageType "categories" -TaskId "par_categories_001" -TargetUrl $TargetUrl -Description "Generate Ruby parser for PNS HK categories page matching aiconfig.yaml configuration with fields: category_name, category_url"
    Start-Sleep -Seconds 2
}

if ($PageType -eq "all" -or $PageType -eq "subcategories") {
    Launch-Agent -Agent "parser-agent" -PageType "subcategories" -TaskId "par_subcategories_001" -TargetUrl "https://www.pns.hk/en/foodBeverages" -Description "Generate Ruby parser for PNS HK subcategories page matching aiconfig.yaml configuration with fields: subcategory_name, subcategory_url"
    Start-Sleep -Seconds 2
}

if ($PageType -eq "all" -or $PageType -eq "listings") {
    Launch-Agent -Agent "parser-agent" -PageType "listings" -TaskId "par_listings_001" -TargetUrl "https://www.pns.hk/en/grocery/lc/04040000" -Description "Generate Ruby parser for PNS HK listings page matching aiconfig.yaml configuration with all 25+ configured fields"
    Start-Sleep -Seconds 2
}

Write-Host "=== All Agents Launched ===" -ForegroundColor Cyan
Write-Host "Monitor progress in .gemini/agents/tasks/ directory" -ForegroundColor Blue
Write-Host "View results in .gemini/agents/plans/ directory" -ForegroundColor Blue
Write-Host "Generated scrapers in .gemini/agents/workspace/generated_scraper/ directory" -ForegroundColor Blue
Write-Host ""
Write-Host "Use /aiconfig:monitor:status to check agent status" -ForegroundColor Yellow
Write-Host "Use /aiconfig:monitor:logs [agent] to view agent logs" -ForegroundColor Yellow
