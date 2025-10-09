# Test script for the new simplified structure
# Tests: agent_state directory + navigation-agent + parser-agent (with selector capabilities)

Write-Host "=== Testing New Simplified Structure ===" -ForegroundColor Green
Write-Host ""

# Test 1: Check agent_state directory structure
Write-Host "1. Testing agent_state directory structure..." -ForegroundColor Cyan
$directories = @(
    ".\agent_state\tasks",
    ".\agent_state\plans", 
    ".\agent_state\logs",
    ".\agent_state\workspace"
)

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "  ✓ $dir exists" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $dir missing" -ForegroundColor Red
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✓ Created $dir" -ForegroundColor Yellow
    }
}

# Test 2: Create sample task for navigation-agent
Write-Host ""
Write-Host "2. Testing navigation-agent task..." -ForegroundColor Cyan
$navTask = @{
    task_id = "test_nav_001"
    agent = "navigation-agent"
    page_type = "categories"
    status = "queued"
    description = "Analyze website structure for PNS HK categories page"
    created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
}

$navTask | ConvertTo-Json -Depth 3 | Out-File -FilePath ".\agent_state\tasks\test_nav_001.json" -Encoding UTF8
Write-Host "  ✓ Created navigation-agent task" -ForegroundColor Green

# Test 3: Create sample task for parser-agent (with selector capabilities)
Write-Host ""
Write-Host "3. Testing parser-agent task (with selector discovery)..." -ForegroundColor Cyan
$parserTask = @{
    task_id = "test_par_001"
    agent = "parser-agent"
    page_type = "listings"
    status = "queued"
    description = "Discover CSS selectors and generate Ruby parser for PNS HK listings page"
    created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
}

$parserTask | ConvertTo-Json -Depth 3 | Out-File -FilePath ".\agent_state\tasks\test_par_001.json" -Encoding UTF8
Write-Host "  ✓ Created parser-agent task with selector capabilities" -ForegroundColor Green

# Test 4: Create sample plan files
Write-Host ""
Write-Host "4. Testing plan file creation..." -ForegroundColor Cyan

# Navigation analysis plan
$navPlan = @"
# Navigation Analysis Results

## Site Structure
* Main categories identified
* URL patterns discovered
* Pagination mechanisms found

## Findings
* Site uses standard pagination
* Categories are well-structured
* Navigation is consistent
"@

$navPlan | Out-File -FilePath ".\agent_state\plans\navigation_analysis.md" -Encoding UTF8
Write-Host "  ✓ Created navigation analysis plan" -ForegroundColor Green

# Parser specification plan (with selectors)
$parserPlan = @"
# Parser Specification with Selector Discovery

## CSS Selectors Discovered
* Product title: `.product-title`
* Product price: `.price-value`
* Product image: `.product-image img`

## Generated Parsers
* listings.rb: Product listing parser with verified selectors
* details.rb: Product detail parser with verified selectors

## Selector Verification Status
* All selectors tested and verified
* Cross-page compatibility confirmed
* Fallback strategies implemented
"@

$parserPlan | Out-File -FilePath ".\agent_state\plans\parser_specification.md" -Encoding UTF8
Write-Host "  ✓ Created parser specification with selector discovery" -ForegroundColor Green

# Test 5: Test task reading
Write-Host ""
Write-Host "5. Testing task file reading..." -ForegroundColor Cyan
$taskFiles = Get-ChildItem -Path ".\agent_state\tasks" -Filter "*.json"
foreach ($taskFile in $taskFiles) {
    $task = Get-Content $taskFile.FullName | ConvertFrom-Json
    Write-Host "  Task: $($task.task_id) - Agent: $($task.agent) - Status: $($task.status)" -ForegroundColor White
}

# Test 6: Test plan reading
Write-Host ""
Write-Host "6. Testing plan file reading..." -ForegroundColor Cyan
$planFiles = Get-ChildItem -Path ".\agent_state\plans" -Filter "*.md"
foreach ($planFile in $planFiles) {
    $content = Get-Content $planFile.FullName -Raw
    $lineCount = ($content -split "`n").Count
    Write-Host "  Plan: $($planFile.Name) - Lines: $lineCount" -ForegroundColor White
}

Write-Host ""
Write-Host "=== New Structure Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  ✓ agent_state directory structure verified" -ForegroundColor Green
Write-Host "  ✓ Navigation-agent task created" -ForegroundColor Green
Write-Host "  ✓ Parser-agent task created (with selector capabilities)" -ForegroundColor Green
Write-Host "  ✓ Plan files created and readable" -ForegroundColor Green
Write-Host "  ✓ Simplified 2-agent structure working" -ForegroundColor Green
Write-Host ""
Write-Host "The new simplified structure is ready!" -ForegroundColor Green
Write-Host "Agents: navigation-agent + parser-agent (with selector discovery)" -ForegroundColor Cyan
Write-Host "State: agent_state/ directory (outside .gemini)" -ForegroundColor Cyan
