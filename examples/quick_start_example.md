# Quick Start Example

## 📋 Complete Example: Creating a Naivas Scraper

### Step 1: Create CSV Specification

Create `naivas_spec.csv`:
```csv
column_name,column_type,dev_notes
competitor_product_id,str,FIND - Find the product SKU or use URL identifier
name,str,FIND - Product title/name
brand,str,FIND - Brand name if available
category,str,FIND - Main category from breadcrumb
sub_category,str,FIND - Subcategories joined with >
customer_price_lc,float,FIND - Current selling price in KES
base_price_lc,float,FIND - Original price if discounted
has_discount,boolean,PROCESS - true if base_price > customer_price
discount_percentage,float,PROCESS - Calculate percentage discount
description,str,FIND - Product description
img_url,str,FIND - Main product image URL
sku,str,FIND - Product SKU code
url,str,PROCESS - Current page URL
is_available,boolean,FIND - Product availability status
```

### Step 2: Set Environment
```bash
# PowerShell
$env:GEMINI_SYSTEM_MD = "true"

# Bash/Zsh  
export GEMINI_SYSTEM_MD=true
```

### Step 3: Run the Command

**Option A: Simple Command**
```bash
gemini "Create a complete DataHen V3 scraper for https://naivas.online using @naivas_spec.csv. Store: Naivas Supermarket, Country: KE, Currency: KES, Location: Nairobi"
```

**Option B: Detailed Command**
```bash
gemini "Create a complete DataHen V3 scraper for the following:

Target URL: https://naivas.online
Store Name: Naivas Supermarket
Country: KE
Currency: KES
Location: Nairobi
Competitor Type: supermarket

Use the field specification from @naivas_spec.csv

Please analyze the site structure using Playwright MCP tools, identify category patterns, understand product listings and details pages, then generate the complete production-ready scraper with proper error handling and CSV export configuration."
```

### Step 4: What You'll Get

The AI will generate a complete scraper structure:

```
naivas_scraper/
├── lib/
│   ├── headers.rb          # HTTP headers configuration
│   └── autorefetch.rb      # Error handling utilities
├── seeder/
│   └── seeder.rb           # Seeds the main category page
├── parsers/
│   ├── category.rb         # Extracts category links
│   ├── listings.rb         # Gets product URLs + pagination
│   └── details.rb          # Extracts all product data
├── config.yaml             # Complete DataHen configuration
└── .gitignore              # Git ignore file
```

### Step 5: Test Locally

```bash
# Test seeder
hen seeder try naivas seeder/seeder.rb

# Test category parser
hen parser try naivas parsers/category.rb https://naivas.online

# Test listings parser  
hen parser try naivas parsers/listings.rb https://naivas.online/category/electronics

# Test details parser
hen parser try naivas parsers/details.rb https://naivas.online/product/example
```

### Step 6: Deploy to DataHen

```bash
# Initialize git repository
git init .
git add .
git commit -m "Initial Naivas scraper"

# Push to your repository
git remote add origin https://github.com/yourusername/naivas-scraper.git
git push -u origin main

# Create scraper on DataHen
hen scraper create naivas https://github.com/yourusername/naivas-scraper.git

# Deploy and start
hen scraper deploy naivas
hen scraper start naivas

# Monitor progress
hen scraper stats naivas
```

## 🎯 Expected Results

The scraper will:
- ✅ Extract all categories from the main page
- ✅ Navigate through product listings with pagination
- ✅ Extract all fields specified in your CSV
- ✅ Handle errors gracefully with autorefetch
- ✅ Export data in both JSON and CSV formats
- ✅ Include proper data validation and type conversion

## 📊 Sample Output Data

```json
{
  "competitor_product_id": "12345",
  "name": "Organic Apple Juice 1L",
  "brand": "Organic Valley",
  "category": "Beverages",
  "sub_category": "Juices > Fruit Juices",
  "customer_price_lc": 250.0,
  "base_price_lc": 300.0,
  "has_discount": true,
  "discount_percentage": 16.67,
  "description": "Pure organic apple juice with no added sugar",
  "img_url": "https://naivas.online/images/products/apple-juice.jpg",
  "sku": "NAI-12345",
  "url": "https://naivas.online/product/organic-apple-juice-1l",
  "is_available": true
}
```

This example demonstrates the complete workflow from CSV specification to deployed scraper!
