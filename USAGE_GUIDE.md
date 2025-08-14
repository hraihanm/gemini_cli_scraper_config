# Web Scraping Expert - Usage Guide

## 🚀 Quick Start

### Minimal Requirements
You need just two things:
1. **Main page URL** (e.g., `https://store.com`)
2. **CSV specification file** (column_name, column_type, dev_notes)

## 📋 Usage Options

### Option 1: Simple Prompt Template (Recommended)

Create a file called `scraper_request_template.md`:

```markdown
# Scraper Request

**Target URL:** [PASTE_URL_HERE]

**CSV Specification:** @[CSV_FILE_NAME]

**Additional Requirements:**
- Store name: [STORE_NAME]
- Country/Location: [COUNTRY] 
- Currency: [CURRENCY_CODE]
- Any special notes: [NOTES]

Please create a complete DataHen V3 scraper for this site.
```

**Usage:**
1. Copy the template
2. Fill in the placeholders
3. Attach your CSV spec file
4. Run: `gemini "$(cat scraper_request_template.md)"`

### Option 2: Direct Command (Fastest)

```bash
gemini "Create a complete scraper for https://example-store.com using the field specification in @spec.csv. Store name: Example Store, Country: US, Currency: USD"
```

### Option 3: Interactive Mode

```bash
gemini "I need to create a scraper. Let me provide the URL and specification."
```

Then provide:
- Target URL
- CSV specification file
- Store details

## 🎯 Detailed Workflow

### Step 1: Prepare Your CSV Specification

Your CSV should have these columns:
```csv
column_name,column_type,dev_notes
competitor_product_id,str,FIND - Find the product-id if possible or else use sku
name,str,FIND
brand,str,FIND
category,str,FIND - Search for category breadcrumb and get the first
customer_price_lc,float,FIND - The listed price of the product
has_discount,boolean,PROCESS - true if it has discount
```

**Field Types:**
- `str`: String/text data
- `float`: Decimal numbers (prices, percentages)
- `boolean`: True/false values
- `int`: Whole numbers

**Dev Notes:**
- `FIND`: Extract directly from page elements
- `PROCESS`: Calculate/derive from other data

### Step 2: Run the Command

**Example with all details:**
```bash
gemini "Create a DataHen V3 scraper for https://naivas.online with the following details:

Target URL: https://naivas.online
Store Name: Naivas
Location: Nairobi, Kenya  
Country: KE
Currency: KES
Competitor Type: supermarket

Use the field specification from @product_spec.csv

Please analyze the site structure, create all necessary parsers, and generate the complete scraper configuration."
```

### Step 3: What You'll Get

The AI will automatically:

1. **🔍 Analyze the site** using Playwright MCP tools
2. **📂 Extract categories** and understand navigation
3. **🛍️ Map product fields** to CSS selectors
4. **⚙️ Generate complete scraper** with:
   - `seeder/seeder.rb`
   - `parsers/category.rb`
   - `parsers/listings.rb` 
   - `parsers/details.rb`
   - `lib/headers.rb`
   - `lib/autorefetch.rb`
   - `config.yaml` with CSV export configuration
   - `.gitignore`

## 🎮 Advanced Usage Options

### Option A: Custom Slash Command (Recommended)

Create a custom command in your shell profile:

**PowerShell (`$PROFILE`):**
```powershell
function New-Scraper {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$SpecFile,
        
        [string]$StoreName = "",
        [string]$Country = "US",
        [string]$Currency = "USD",
        [string]$CompetitorType = "ecommerce"
    )
    
    $prompt = @"
Create a complete DataHen V3 scraper for the following:

Target URL: $Url
Store Name: $StoreName
Country: $Country
Currency: $Currency
Competitor Type: $CompetitorType

Use the field specification from @$SpecFile

Please analyze the site structure using Playwright MCP tools, extract categories and product patterns, and generate the complete production-ready scraper with proper error handling.
"@
    
    gemini $prompt
}
```

**Usage:**
```powershell
New-Scraper -Url "https://store.com" -SpecFile "spec.csv" -StoreName "Example Store" -Country "KE" -Currency "KES"
```

**Bash/Zsh (`~/.bashrc` or `~/.zshrc`):**
```bash
new-scraper() {
    local url="$1"
    local spec_file="$2"
    local store_name="${3:-Example Store}"
    local country="${4:-US}"
    local currency="${5:-USD}"
    local competitor_type="${6:-ecommerce}"
    
    gemini "Create a complete DataHen V3 scraper for the following:

Target URL: $url
Store Name: $store_name
Country: $country
Currency: $currency
Competitor Type: $competitor_type

Use the field specification from @$spec_file

Please analyze the site structure using Playwright MCP tools, extract categories and product patterns, and generate the complete production-ready scraper with proper error handling."
}
```

**Usage:**
```bash
new-scraper "https://store.com" "spec.csv" "Example Store" "KE" "KES"
```

### Option B: Configuration File Approach

Create `scraper_config.yaml`:
```yaml
target_url: "https://example-store.com"
spec_file: "product_spec.csv"
store_details:
  name: "Example Store"
  country: "US"
  currency: "USD"
  competitor_type: "supermarket"
  location: "New York"
additional_notes: |
  - Focus on organic products
  - Include nutrition information if available
  - Handle multiple product variants
```

**Usage:**
```bash
gemini "Create a scraper based on the configuration in @scraper_config.yaml and specification in @product_spec.csv"
```

### Option C: Interactive Script

Create `create_scraper.ps1`:
```powershell
# Interactive Scraper Creator
Write-Host "🕷️ DataHen Scraper Creator" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

$url = Read-Host "Enter target URL"
$specFile = Read-Host "Enter CSV specification file path"
$storeName = Read-Host "Enter store name"
$country = Read-Host "Enter country code (e.g., US, KE)"
$currency = Read-Host "Enter currency code (e.g., USD, KES)"

Write-Host "`n🚀 Creating scraper..." -ForegroundColor Yellow

$prompt = @"
Create a complete DataHen V3 scraper for:

Target URL: $url
Store Name: $storeName  
Country: $country
Currency: $currency

Use the field specification from @$specFile

Please analyze the site structure, create all parsers, and generate the complete scraper configuration.
"@

gemini $prompt
```

**Usage:**
```powershell
.\create_scraper.ps1
```

## 🎯 Best Practices

### 1. Prepare Your Environment
```bash
# Set the specialized system prompt
$env:GEMINI_SYSTEM_MD = "true"  # PowerShell
export GEMINI_SYSTEM_MD=true   # Bash/Zsh

# Verify the configuration is active (look for |⌐■_■| icon)
gemini "Test the scraping configuration"
```

### 2. CSV Specification Tips
- **Be specific in dev_notes**: "FIND - Product title in h1.product-name"
- **Include fallback strategies**: "FIND - Price in .price or .cost"
- **Specify data processing**: "PROCESS - Calculate from base_price and customer_price"

### 3. Iterative Development
```bash
# Start with basic analysis
gemini "Analyze the structure of https://store.com and identify category patterns"

# Then request the full scraper
gemini "Now create the complete scraper using @spec.csv"
```

## 🔧 Troubleshooting

### Common Issues

**1. Site requires authentication:**
```bash
gemini "The site https://store.com requires login. Help me handle authentication in the scraper."
```

**2. Complex JavaScript rendering:**
```bash
gemini "The site uses heavy JavaScript. Optimize the scraper for dynamic content loading."
```

**3. Anti-bot protection:**
```bash
gemini "The site has bot protection. Implement appropriate delays and headers."
```

## 📊 Example Complete Usage

```bash
# 1. Set environment
export GEMINI_SYSTEM_MD=true

# 2. Create specification file (product_spec.csv)
# competitor_product_id,str,FIND - Product SKU or ID
# name,str,FIND - Product title
# brand,str,FIND - Brand name
# customer_price_lc,float,FIND - Current selling price
# has_discount,boolean,PROCESS - Check if discounted

# 3. Run scraper creation
gemini "Create a complete DataHen V3 scraper for:

Target URL: https://naivas.online
Store Name: Naivas Supermarket
Country: KE
Currency: KES
Location: Nairobi
Competitor Type: supermarket

Use the field specification from @product_spec.csv

Please analyze the site structure using Playwright MCP tools and generate the complete production-ready scraper."

# 4. Test the generated scraper locally
hen seeder try naivas seeder/seeder.rb
hen parser try naivas parsers/category.rb https://naivas.online
```

This approach gives you maximum flexibility while maintaining the power of the specialized configuration!
