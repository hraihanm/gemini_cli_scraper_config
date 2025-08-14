#!/bin/bash
# DataHen Scraper Creator - Bash Script
# Usage: ./new_scraper.sh "https://store.com" "spec.csv" "Store Name" "US" "USD"

set -e

# Function to display usage
usage() {
    echo "🕷️ DataHen Scraper Creator"
    echo "Usage: $0 <url> <spec_file> [store_name] [country] [currency] [competitor_type] [location]"
    echo ""
    echo "Parameters:"
    echo "  url              Target website URL (required)"
    echo "  spec_file        CSV specification file path (required)"
    echo "  store_name       Store/competitor name (optional)"
    echo "  country          Country code, e.g., US, KE, UK (default: US)"
    echo "  currency         Currency code, e.g., USD, KES, GBP (default: USD)"
    echo "  competitor_type  Type, e.g., supermarket, pharmacy (default: ecommerce)"
    echo "  location         Store location/city (optional)"
    echo ""
    echo "Examples:"
    echo "  $0 \"https://store.com\" \"spec.csv\""
    echo "  $0 \"https://naivas.online\" \"naivas_spec.csv\" \"Naivas\" \"KE\" \"KES\" \"supermarket\" \"Nairobi\""
    exit 1
}

# Check minimum required arguments
if [ $# -lt 2 ]; then
    usage
fi

# Parse arguments
URL="$1"
SPEC_FILE="$2"
STORE_NAME="${3:-}"
COUNTRY="${4:-US}"
CURRENCY="${5:-USD}"
COMPETITOR_TYPE="${6:-ecommerce}"
LOCATION="${7:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Check if Gemini CLI is available
if ! command -v gemini &> /dev/null; then
    echo -e "${RED}❌ Gemini CLI not found. Please install Gemini CLI first.${NC}"
    exit 1
fi

# Check if spec file exists
if [ ! -f "$SPEC_FILE" ]; then
    echo -e "${RED}❌ Specification file '$SPEC_FILE' not found.${NC}"
    exit 1
fi

# Check if specialized configuration is active
echo -e "${YELLOW}🔍 Checking Gemini CLI configuration...${NC}"
if ! gemini "test" 2>&1 | grep -q "|⌐■_■|"; then
    echo -e "${YELLOW}⚠️ Specialized scraping configuration may not be active.${NC}"
    echo -e "${CYAN}To activate, run: export GEMINI_SYSTEM_MD=true${NC}"
    echo -n "Continue anyway? (y/N): "
    read -r continue
    if [[ ! "$continue" =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

echo -e "${GREEN}🕷️ DataHen Scraper Creator${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "${WHITE}Target URL: $URL${NC}"
echo -e "${WHITE}Spec File: $SPEC_FILE${NC}"
echo -e "${WHITE}Store: $STORE_NAME${NC}"
echo -e "${WHITE}Country: $COUNTRY${NC}"
echo -e "${WHITE}Currency: $CURRENCY${NC}"
echo ""

# Build the prompt
PROMPT="Create a complete DataHen V3 scraper for the following e-commerce site:

🎯 TARGET DETAILS:
- URL: $URL
- Store Name: $STORE_NAME
- Country: $COUNTRY
- Currency: $CURRENCY
- Competitor Type: $COMPETITOR_TYPE"

if [ -n "$LOCATION" ]; then
    PROMPT="$PROMPT
- Location: $LOCATION"
fi

PROMPT="$PROMPT

📋 REQUIREMENTS:
- Use the field specification from @$SPEC_FILE
- Analyze the site structure using Playwright MCP tools
- Extract category navigation patterns  
- Understand product listings and pagination
- Map product detail fields to CSS selectors
- Generate production-ready scraper with error handling

Please create the complete scraper structure with:
1. Library modules (headers, autorefetch)
2. Seeder for main page
3. Category parser for navigation
4. Listings parser with pagination
5. Details parser with all CSV fields
6. Complete config.yaml with CSV export
7. Proper error handling and data validation

Start by analyzing the site structure, then generate all necessary files."

echo -e "${YELLOW}🚀 Creating scraper...${NC}"
echo ""

# Execute the command
if gemini "$PROMPT"; then
    echo ""
    echo -e "${GREEN}✅ Scraper generation completed!${NC}"
    echo ""
    echo -e "${CYAN}🧪 NEXT STEPS:${NC}"
    echo "1. Review the generated files"
    echo "2. Test locally with DataHen CLI:"
    echo "   hen seeder try scraper_name seeder/seeder.rb"
    echo "   hen parser try scraper_name parsers/category.rb $URL"
    echo "3. Initialize git repository and deploy to DataHen"
    echo ""
else
    echo -e "${RED}❌ Failed to create scraper${NC}"
    exit 1
fi
