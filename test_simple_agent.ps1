# Simple test script to launch an agent
# This tests the basic agent launching functionality

Write-Host "=== Simple Agent Launch Test ===" -ForegroundColor Green
Write-Host ""

Write-Host "Testing direct agent launch..." -ForegroundColor Yellow

# Test launching Navigation Agent directly
Write-Host "Launching Navigation Agent..." -ForegroundColor Cyan

$agentPrompt = "You are the navigation-agent. Your Task ID is test_001. Your task is to: Test navigation agent functionality. Page Type: categories. Target URL: https://www.pns.hk/en/. Use browser tools to analyze the site and complete your task. Save your results to .gemini/agents/plans/ directory."

$command = "Write-Host 'You are the navigation-agent. Your Task ID is test_001.' -ForegroundColor Cyan; Write-Host 'Your task is to: Test navigation agent functionality' -ForegroundColor Cyan; Write-Host 'Page Type: categories' -ForegroundColor Cyan; Write-Host 'Target URL: https://www.pns.hk/en/' -ForegroundColor Cyan; Write-Host ''; Write-Host 'Use browser tools to analyze the site and complete your task.' -ForegroundColor Yellow; Write-Host 'Save your results to .gemini/agents/plans/ directory.' -ForegroundColor Yellow; Write-Host ''; gemini -e navigation-agent -i `"$agentPrompt`""

# Launch the agent in a new PowerShell window
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", $command -WindowStyle Normal

Write-Host "Agent should now be launching in a new PowerShell window..." -ForegroundColor Green
Write-Host "If you see a new PowerShell window open, the test is successful!" -ForegroundColor Green
