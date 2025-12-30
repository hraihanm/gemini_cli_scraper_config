# DMART/DLOC Scraper Boilerplate

This is an **optimized boilerplate template** for creating e-commerce scrapers using DataHen's platform. The boilerplate provides a complete structure with **comprehensive comments** and **PLACEHOLDER selectors** that need to be replaced with site-specific selectors discovered during the scraping process.

## ✨ Key Features

- **AI-Optimized**: Extensive comments explain DataHen v3 structure, variable flow, and patterns
- **Clear PLACEHOLDER Markers**: All placeholders are clearly marked with discovery instructions
- **Fixed Common Issues**: Price extraction, variable references, and output hash structure are correct
- **Comprehensive Documentation**: Each file includes header comments explaining purpose and usage
- **Helper Functions**: Reusable utilities for text, number, and boolean extraction

## Structure

```
dmart_dloc_boilerplate/
├── README.md              # This file - explains boilerplate structure
├── config.yaml            # Complete DataHen configuration (parsers, exporters)
├── .gitignore             # Git ignore patterns
├── seeder/
│   └── seeder.rb          # Initial page seeding (update URL and page_type)
├── parsers/
│   ├── categories.rb      # Category navigation parser (replace PLACEHOLDER selectors)
│   ├── subcategories.rb   # Subcategory navigation parser (replace PLACEHOLDER selectors)
│   ├── listings.rb        # Product listings parser (replace PLACEHOLDER selectors)
│   └── details.rb         # Product detail parser (replace PLACEHOLDER selectors)
└── lib/
    ├── headers.rb          # HTTP headers and base URL constants (update BASE_URL)
    ├── helpers.rb          # Helper functions for text/number/boolean extraction (no changes needed)
    └── regex.rb            # Helper module for measurement extraction (no changes needed)
```

## Key Concepts

### DataHen v3 Parser Structure

**CRITICAL**: DataHen parsers are TOP-LEVEL SCRIPTS, NOT FUNCTIONS.

- **Pre-defined Variables**: `content`, `page`, `pages`, `outputs` are available at script level
- **DO NOT declare**: `pages = []`, `outputs = []`, `page = {}`, `content = ""`
- **DO NOT wrap in functions**: DataHen executes parser files directly as scripts
- **Use directly**: `pages << {...}`, `outputs << {...}`, `html = Nokogiri::HTML(content)`

### PLACEHOLDER Replacement Pattern

All parser files contain `PLACEHOLDER` strings that must be replaced with discovered CSS selectors:

- **Pattern**: `html.at_css('PLACEHOLDER')` → `html.at_css('.discovered-selector')`
- **Pattern**: `html.css('PLACEHOLDER')` → `html.css('.discovered-selector')`
- **Pattern**: `name = "PLACEHOLDER"` → `name = html.at_css('.product-title')&.text&.strip`

**Discovery Instructions**: Each PLACEHOLDER includes comments explaining:
- What to discover (selector type, element type)
- Which browser tool to use (browser_inspect_element, browser_verify_selector, browser_evaluate)
- Example selectors for reference
- Site-specific notes where applicable

### Variable Flow

```
Seeder → Categories → Subcategories → Listings → Details
         (base_url)   (category_name) (rank)     (all fields)
```

Variables are passed via `vars` hash and merged at each stage:
- Categories parser receives: `base_url`
- Subcategories parser receives: `category_name`, `breadcrumb`
- Listings parser receives: `category_name`, `breadcrumb`, `page_number`
- Details parser receives: `category_name`, `breadcrumb`, `rank`, `page_number`

## Files to Update

### 1. `lib/headers.rb`
- **Update**: `URLs::BASE_URL` constant with site's base URL (replace `PLACEHOLDER_BASE_URL`)
- **Keep**: `ReqHeaders::MINIMAL_HEADERS` (usually no changes needed)
- **Comments**: Header explains purpose and usage

### 2. `seeder/seeder.rb`
- **Update**: `url:` with site's homepage URL (replace `PLACEHOLDER_HOMEPAGE_URL`)
- **Update**: `page_type:` based on site structure (replace `PLACEHOLDER_PAGE_TYPE` with "categories" or "listings")
- **Keep**: Headers reference and structure
- **Comments**: Explains DataHen v3 structure and reserved variables

### 3. `parsers/categories.rb`
- **Replace**: `html.css('PLACEHOLDER')` with category link selector
- **Replace**: `category.at_css('PLACEHOLDER')` with category name selector
- **Update**: Site-specific logic for determining next page_type (lines 50-52)
- **Keep**: Variable passing structure, save_pages calls
- **Comments**: Explains variable flow, DataHen v3 structure, and PLACEHOLDER replacement

### 4. `parsers/subcategories.rb`
- **Replace**: `html.css('PLACEHOLDER')` with subcategory link selector
- **Keep**: Variable passing structure, breadcrumb logic
- **Comments**: Explains variable flow and when this parser is used

### 5. `parsers/listings.rb`
- **Replace**: `html.css('PLACEHOLDER')` with product link selector
- **Update**: Pagination logic (choose ONE strategy from commented options)
  - Strategy 1: Next Button (most common - uncomment and update selector)
  - Strategy 2: Query Parameter Pattern (?page=2)
  - Strategy 3: Path Pattern (/page/2)
  - Strategy 4: Count-Based Calculation (if product count displayed)
- **Keep**: Variable passing structure, rank tracking
- **Comments**: Explains all pagination strategies with examples

### 6. `parsers/details.rb`
- **Replace**: ALL `PLACEHOLDER` strings with discovered selectors
- **Fixed**: Price extraction logic (customer_price_lc, base_price_lc properly defined)
- **Fixed**: Variable references (all variables defined before use)
- **Fixed**: Missing helper function calls (text_of, number_from, boolean_from)
- **Ensure**: Output hash matches config.yaml exporter fields exactly
- **Update**: Site-specific values (competitor_name, country_iso, language, currency_code_lc)
- **Keep**: Helper function calls, MeasurementExtractor usage, output structure
- **Comments**: Comprehensive comments for each field extraction with discovery instructions

### 7. `lib/helpers.rb`
- **No changes needed** - generic helper functions work for most sites
- **Functions**: `text_of()`, `number_from()`, `boolean_from()`
- **Comments**: Explains usage and examples

### 8. `config.yaml`
- **Usually no changes needed** - already configured with all parsers and exporter
- **Verify**: Parser file paths are correct
- **Verify**: Exporter fields match output hash in details.rb

## Common Patterns

### Selector Discovery
1. Use browser tools to discover real CSS selectors
2. Replace PLACEHOLDER with discovered selector
3. Test with parser_tester MCP tool
4. Verify output matches expected structure

### Price Extraction (Using Helper Functions)
```ruby
# Extract price text first
customer_price_text = html.at_css('.price-selector')&.text&.strip

# Convert to number using helper (removes currency symbols, commas)
customer_price_lc = number_from(customer_price_text)

# Base price (if discounted)
base_price_text_element = html.at_css('.original-price-selector')
base_price_text = text_of(base_price_text_element)
base_price_lc = base_price_text ? number_from(base_price_text) : customer_price_lc
```

### URL Handling
```ruby
# Always handle relative URLs
product_url = product_link['href']
product_url = URI.join(base_url, product_url).to_s unless product_url.start_with?('http')
```

### Variable Passing
```ruby
# Always merge vars to preserve context
vars: vars.merge({
  new_field: value,
  existing_field: vars['existing_field']  # Preserve from previous stage
})
```

## Testing

After replacing PLACEHOLDERs, test each parser:
```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/details.rb",
  page_type: "details",
  auto_download: true,
  vars: '{"category_name":"Test","breadcrumb":"Test","rank":1}',
  quiet: false
})
```

## Notes

- **All PLACEHOLDER strings must be replaced** before deployment
- **Output hash in details.rb must match config.yaml exporter fields** exactly (field names are case-sensitive)
- **Preserve helper function calls** and existing structure
- **Test each parser** after editing using parser_tester MCP tool
- **Use absolute paths** when writing files
- **Read file comments** - they explain DataHen v3 structure, variable flow, and patterns
- **Follow discovery instructions** in comments for each PLACEHOLDER

## Improvements in This Version

### ✨ Enhanced Comments
- Comprehensive header comments in all files explaining purpose and structure
- Inline comments for each PLACEHOLDER explaining what to discover
- Comments explaining DataHen v3 structure and reserved variables
- Comments explaining variable flow between parsers

### 🐛 Fixed Issues
- **details.rb**: Fixed price extraction (customer_price_lc, base_price_lc properly defined)
- **details.rb**: Fixed variable references (all variables defined before use)
- **details.rb**: Fixed missing helper function calls
- **details.rb**: Fixed undefined variable references (add_to_cart_button, etc.)
- **listings.rb**: Improved pagination strategies with clear examples
- **All files**: Added proper require statements and fixed structure

### 📝 Better PLACEHOLDER Markers
- Clear PLACEHOLDER strings with discovery instructions
- Examples provided for each PLACEHOLDER
- Site-specific notes where applicable
- Browser tool recommendations for discovery

