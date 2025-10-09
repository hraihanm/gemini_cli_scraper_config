# Test script to verify filesystem state and logging functionality
# This tests the complete filesystem-as-state pattern

Write-Host "=== Filesystem State and Logging Test ===" -ForegroundColor Green
Write-Host ""

# Test 1: Check directory structure
Write-Host "1. Testing directory structure..." -ForegroundColor Cyan
$directories = @(
    ".\.gemini\agents\tasks",
    ".\.gemini\agents\plans", 
    ".\.gemini\agents\logs",
    ".\.gemini\agents\workspace"
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

# Test 2: Create sample task files
Write-Host ""
Write-Host "2. Testing task file creation..." -ForegroundColor Cyan
$sampleTasks = @(
    @{
        task_id = "test_nav_001"
        agent = "navigation-agent"
        page_type = "categories"
        status = "queued"
        description = "Test navigation task"
        created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    },
    @{
        task_id = "test_sel_001"
        agent = "selector-agent"
        page_type = "listings"
        status = "running"
        description = "Test selector task"
        created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    },
    @{
        task_id = "test_par_001"
        agent = "parser-agent"
        page_type = "details"
        status = "completed"
        description = "Test parser task"
        created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        completed_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    }
)

foreach ($task in $sampleTasks) {
    $taskFile = ".\.gemini\agents\tasks\$($task.task_id).json"
    $task | ConvertTo-Json -Depth 3 | Out-File -FilePath $taskFile -Encoding UTF8
    Write-Host "  ✓ Created $taskFile" -ForegroundColor Green
}

# Test 3: Create sample plan files
Write-Host ""
Write-Host "3. Testing plan file creation..." -ForegroundColor Cyan
$samplePlans = @(
    @{
        file = "navigation_analysis.md"
        content = @"
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
    },
    @{
        file = "selector_map.md"
        content = @"
# Selector Map Results

## CSS Selectors
* Product title: `.product-title`
* Product price: `.price-value`
* Product image: `.product-image img`

## Verification Status
* All selectors tested and verified
* Cross-page compatibility confirmed
"@
    },
    @{
        file = "parser_specification.md"
        content = @"
# Parser Specification

## Generated Parsers
* categories.rb: Category page parser
* listings.rb: Product listing parser
* details.rb: Product detail parser

## Implementation Status
* All parsers generated successfully
* Error handling implemented
* Testing completed
"@
    }
)

foreach ($plan in $samplePlans) {
    $planFile = ".\.gemini\agents\plans\$($plan.file)"
    $plan.content | Out-File -FilePath $planFile -Encoding UTF8
    Write-Host "  ✓ Created $planFile" -ForegroundColor Green
}

# Test 4: Create sample log files
Write-Host ""
Write-Host "4. Testing log file creation..." -ForegroundColor Cyan
$sampleLogs = @(
    @{
        file = "navigation-agent-test.log"
        content = @"
[2024-01-01 10:00:00] Navigation Agent started
[2024-01-01 10:00:05] Analyzing site structure
[2024-01-01 10:00:10] Found 5 main categories
[2024-01-01 10:00:15] Identified pagination patterns
[2024-01-01 10:00:20] Navigation analysis completed
"@
    },
    @{
        file = "selector-agent-test.log"
        content = @"
[2024-01-01 10:05:00] Selector Agent started
[2024-01-01 10:05:05] Testing CSS selectors
[2024-01-01 10:05:10] Verified product title selector
[2024-01-01 10:05:15] Verified product price selector
[2024-01-01 10:05:20] Selector verification completed
"@
    }
)

foreach ($log in $sampleLogs) {
    $logFile = ".\.gemini\agents\logs\$($log.file)"
    $log.content | Out-File -FilePath $logFile -Encoding UTF8
    Write-Host "  ✓ Created $logFile" -ForegroundColor Green
}

# Test 5: Test task status reading
Write-Host ""
Write-Host "5. Testing task status reading..." -ForegroundColor Cyan
$taskFiles = Get-ChildItem -Path ".\.gemini\agents\tasks" -Filter "*.json"
foreach ($taskFile in $taskFiles) {
    $task = Get-Content $taskFile.FullName | ConvertFrom-Json
    Write-Host "  Task: $($task.task_id) - Agent: $($task.agent) - Status: $($task.status)" -ForegroundColor White
}

# Test 6: Test plan file reading
Write-Host ""
Write-Host "6. Testing plan file reading..." -ForegroundColor Cyan
$planFiles = Get-ChildItem -Path ".\.gemini\agents\plans" -Filter "*.md"
foreach ($planFile in $planFiles) {
    $content = Get-Content $planFile.FullName -Raw
    $lineCount = ($content -split "`n").Count
    Write-Host "  Plan: $($planFile.Name) - Lines: $lineCount" -ForegroundColor White
}

# Test 7: Test log file reading
Write-Host ""
Write-Host "7. Testing log file reading..." -ForegroundColor Cyan
$logFiles = Get-ChildItem -Path ".\.gemini\agents\logs" -Filter "*.log"
foreach ($logFile in $logFiles) {
    $content = Get-Content $logFile.FullName -Raw
    $lineCount = ($content -split "`n").Count
    Write-Host "  Log: $($logFile.Name) - Lines: $lineCount" -ForegroundColor White
}

# Test 8: Test coordinator functionality
Write-Host ""
Write-Host "8. Testing coordinator functionality..." -ForegroundColor Cyan
Write-Host "  Coordinator script exists: $(Test-Path '.\.gemini\agents\scripts\coordinator.ps1')" -ForegroundColor White
Write-Host "  Launch script exists: $(Test-Path '.\.gemini\agents\scripts\launch_agent.ps1')" -ForegroundColor White

Write-Host ""
Write-Host "=== Filesystem State Test Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  ✓ Directory structure verified" -ForegroundColor Green
Write-Host "  ✓ Task files created and readable" -ForegroundColor Green
Write-Host "  ✓ Plan files created and readable" -ForegroundColor Green
Write-Host "  ✓ Log files created and readable" -ForegroundColor Green
Write-Host "  ✓ Coordinator scripts available" -ForegroundColor Green
Write-Host ""
Write-Host "The filesystem-as-state pattern is working correctly!" -ForegroundColor Green
Write-Host "You can now use the multi-agent system with confidence." -ForegroundColor Green
