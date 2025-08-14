# DataHen Scraper Creator - PowerShell Script
# Usage: .\new_scraper.ps1 -Url "https://store.com" -SpecFile "spec.csv" -StoreName "Store Name"

param(
    [Parameter(Mandatory=$true, HelpMessage="Target website URL")]
    [string]$Url,
    
    [Parameter(Mandatory=$true, HelpMessage="CSV specification file path")]
    [string]$SpecFile,
    
    [Parameter(HelpMessage="Store/competitor name")]
    [string]$StoreName = "",
    
    [Parameter(HelpMessage="Country code (e.g., US, KE, UK)")]
    [string]$Country = "US",
    
    [Parameter(HelpMessage="Currency code (e.g., USD, KES, GBP)")]
    [string]$Currency = "USD",
    
    [Parameter(HelpMessage="Competitor type (e.g., supermarket, pharmacy, electronics)")]
    [string]$CompetitorType = "ecommerce",
    
    [Parameter(HelpMessage="Store location/city")]
    [string]$Location = "",
    
    [Parameter(HelpMessage="Additional requirements or notes")]
    [string]$Notes = ""
)

# Check if Gemini CLI is available
if (-not (Get-Command "gemini" -ErrorAction SilentlyContinue)) {
    Write-Error "Gemini CLI not found. Please install Gemini CLI first."
    exit 1
}

# Check if spec file exists
if (-not (Test-Path $SpecFile)) {
    Write-Error "Specification file '$SpecFile' not found."
    exit 1
}

# Check if specialized configuration is active
Write-Host "🔍 Checking Gemini CLI configuration..." -ForegroundColor Yellow
$testResult = gemini "test" 2>&1
if ($testResult -notmatch '\|⌐■_■\|') {
    Write-Warning "Specialized scraping configuration may not be active."
    Write-Host "To activate, run: `$env:GEMINI_SYSTEM_MD = 'true'" -ForegroundColor Cyan
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        exit 0
    }
}

Write-Host "🕷️ DataHen Scraper Creator" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "Target URL: $Url" -ForegroundColor White
Write-Host "Spec File: $SpecFile" -ForegroundColor White
Write-Host "Store: $StoreName" -ForegroundColor White
Write-Host "Country: $Country" -ForegroundColor White
Write-Host "Currency: $Currency" -ForegroundColor White
Write-Host ""

# Build the prompt
$prompt = @"
Create a complete DataHen V3 scraper for the following e-commerce site:

🎯 TARGET DETAILS:
- URL: $Url
- Store Name: $StoreName
- Country: $Country
- Currency: $Currency
- Competitor Type: $CompetitorType
$(if ($Location) { "- Location: $Location" })

📋 REQUIREMENTS:
- Use the field specification from @$SpecFile
- Analyze the site structure using Playwright MCP tools
- Extract category navigation patterns  
- Understand product listings and pagination
- Map product detail fields to CSS selectors
- Generate production-ready scraper with error handling

$(if ($Notes) { "📝 ADDITIONAL NOTES:`n$Notes`n" })

Please create the complete scraper structure with:
1. Library modules (headers, autorefetch)
2. Seeder for main page
3. Category parser for navigation
4. Listings parser with pagination
5. Details parser with all CSV fields
6. Complete config.yaml with CSV export
7. Proper error handling and data validation

Start by analyzing the site structure, then generate all necessary files.
"@

Write-Host "🚀 Creating scraper..." -ForegroundColor Yellow
Write-Host ""

# Execute the command
try {
    gemini $prompt
    Write-Host ""
    Write-Host "✅ Scraper generation completed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🧪 NEXT STEPS:" -ForegroundColor Cyan
    Write-Host "1. Review the generated files"
    Write-Host "2. Test locally with DataHen CLI:"
    Write-Host "   hen seeder try scraper_name seeder/seeder.rb"
    Write-Host "   hen parser try scraper_name parsers/category.rb $Url"
    Write-Host "3. Initialize git repository and deploy to DataHen"
    Write-Host ""
}
catch {
    Write-Error "Failed to create scraper: $_"
    exit 1
}
"@
