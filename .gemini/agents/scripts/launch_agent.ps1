# PowerShell script to launch interactive Gemini CLI agents
# Usage: .\launch_agent.ps1 -Agent "navigation-agent" -PageType "categories" -TaskId "nav_001"

param(
    [Parameter(Mandatory=$true)]
    [string]$Agent,
    
    [Parameter(Mandatory=$true)]
    [string]$PageType,
    
    [Parameter(Mandatory=$true)]
    [string]$TaskId,
    
    [string]$TargetUrl = "",
    [string]$Description = ""
)

# Create task directory if it doesn't exist
$taskDir = ".\agent_state\tasks"
if (!(Test-Path $taskDir)) {
    New-Item -ItemType Directory -Path $taskDir -Force
}

# Create task file
$taskFile = "$taskDir\$TaskId.json"
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
} | ConvertTo-Json -Depth 3

$taskData | Out-File -FilePath $taskFile -Encoding UTF8

Write-Host "Created task file: $taskFile" -ForegroundColor Green

# Launch interactive Gemini CLI process
Write-Host "Launching interactive $Agent for $PageType..." -ForegroundColor Yellow

# Launch the agent directly in a new PowerShell window
$agentPrompt = "You are the $Agent. Your Task ID is $TaskId. Your task is to: $Description. Page Type: $PageType. Target URL: $TargetUrl. Use browser tools to analyze the site and complete your task. Save your results to agent_state/plans/ directory."

# Create a command that will run in the new PowerShell window
$command = "Write-Host 'You are the $Agent. Your Task ID is $TaskId.' -ForegroundColor Cyan; Write-Host 'Your task is to: $Description' -ForegroundColor Cyan; Write-Host 'Page Type: $PageType' -ForegroundColor Cyan; Write-Host 'Target URL: $TargetUrl' -ForegroundColor Cyan; Write-Host ''; Write-Host 'Use browser tools to analyze the site and complete your task.' -ForegroundColor Yellow; Write-Host 'Save your results to agent_state/plans/ directory.' -ForegroundColor Yellow; Write-Host ''; Write-Host 'YOLO MODE ENABLED - All tool calls will be auto-approved' -ForegroundColor Red; Write-Host ''; gemini -e $Agent -i `"$agentPrompt`" -y"

# Launch the agent in a new PowerShell window
Start-Process -FilePath "powershell" -ArgumentList "-NoExit", "-Command", $command -WindowStyle Normal

Write-Host "Agent launched in new window. Task ID: $TaskId" -ForegroundColor Green
Write-Host "Monitor progress in .gemini/agents/tasks/$TaskId.json" -ForegroundColor Blue
