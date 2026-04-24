# Gemini CLI Scraper Generator - Custom Commands

A modular, session-independent scraper generation system for DataHen v3. This system uses three specialized commands to generate complete web scrapers with navigation parsers, detail parsers, and proper configuration.

## Command naming (current)

- **Preferred (generic):** `/scrape`, `/navigation-parser`, `/details-parser`, `/api-scrape`, `/api-navigation-parser`, `/api-details-parser`, `/restaurant-details-parser`, `/menu-parser` — select project via `project=` and `profiles/*.toml`.
- **Deprecated thin aliases:** `/dmart-*`, `/dhero-*`, and `/dmart-api-*` keep old slash names but only inject shared shards and point at the same workflows as the generic commands (fixed `project=`).
- **Deprecated command files location:** `.gemini/commands/depracated/`
- **Changelog:** [docs/workflows/CHANGELOG.md](../docs/workflows/CHANGELOG.md)

## 🚀 Quick Start

```bash
# Step 1: Site discovery and setup
/scrape url="https://naivas.online" name=naivas_online spec="spec_general_sample.csv"

# Step 2: Generate navigation parsers
/navigation-parser scraper=naivas_online

# Step 3: Generate detail parser
/details-parser scraper=naivas_online
```

## 📋 Commands Overview

### 1. `/scrape` - Site Discovery & Setup (generic)

**Purpose**: Analyzes website structure, discovers navigation patterns, and sets up the scraper directory.

**What it does**:
- Navigates to the target website
- Analyzes site structure (categories, subcategories, listings, details)
- Discovers sample URLs for each page type
- Parses field specification (if provided)
- Generates initial `seeder/seeder.rb` and `config.yaml`

**Usage**:
```bash
/scrape url="https://example.com" name=my_scraper spec="spec_general_sample.csv"
```

**Parameters**:
- `url=<site_url>` (REQUIRED) - Target website URL
- `name=<scraper_name>` (REQUIRED) - Scraper name/slug
- `spec=<path-to-CSV>` (OPTIONAL) - Field specification file
- `out=<base_dir>` (OPTIONAL) - Output directory (default: `./generated_scraper`)

**Outputs**:
- `generated_scraper/<scraper>/seeder/seeder.rb`
- `generated_scraper/<scraper>/config.yaml` (initial)
- `generated_scraper/<scraper>/.scraper-state/discovery-state.json` (includes `_notes`)
- `generated_scraper/<scraper>/.scraper-state/field-spec.json` (if spec provided)
- `generated_scraper/<scraper>/.scraper-state/phase-status.json`

**Next Step**: Run `/navigation-parser`

---

### 2. `/navigation-parser` - Navigation Parsers (generic)

**Purpose**: Generates navigation parsers (categories, subcategories, listings) that discover and queue product pages.

**What it does**:
- Reads discovery knowledge from Phase 1
- Analyzes category/subcategory/listings pages using browser tools
- Discovers CSS selectors for navigation elements
- Generates `parsers/categories.rb`, `parsers/subcategories.rb` (if needed), `parsers/listings.rb`
- Tests each parser with `parser_tester` MCP tool
- Updates `config.yaml` with navigation parsers

**Usage**:
```bash
/navigation-parser scraper=naivas_online
```

**Parameters**:
- `scraper=<scraper_name>` (REQUIRED) - Scraper name (must exist from Phase 1)
- `resume-url=<url>` (OPTIONAL) - Resume browser from this URL
- `out=<base_dir>` (OPTIONAL) - Output directory (default: `./generated_scraper`)

**Outputs**:
- `generated_scraper/<scraper>/parsers/categories.rb` ✅ (tested)
- `generated_scraper/<scraper>/parsers/subcategories.rb` ✅ (tested, if applicable)
- `generated_scraper/<scraper>/parsers/listings.rb` ✅ (tested)
- `generated_scraper/<scraper>/config.yaml` (updated with navigation parsers)
- `generated_scraper/<scraper>/.scraper-state/navigation-selectors.json` (includes `_notes`)

**Next Step**: Run `/details-parser`

---

### 3. `/details-parser` - Detail Parser (generic)

**Purpose**: Generates the product detail parser that extracts product data from individual product pages.

**What it does**:
- Reads navigation knowledge and field specification
- Analyzes product detail pages using browser tools
- Discovers CSS selectors for each field (guided by field-spec.json if available)
- Generates `parsers/details.rb` with proper navigation context
- Tests parser with `parser_tester` MCP tool
- Updates `config.yaml` with details parser and CSV exporter fields

**Usage**:
```bash
/details-parser scraper=naivas_online
```

**Parameters**:
- `scraper=<scraper_name>` (REQUIRED) - Scraper name (must exist from Phase 2)
- `url=<details_page_url>` (OPTIONAL) - Specific product page URL (uses sample from navigation if not provided)
- `spec=<path-to-CSV>` (OPTIONAL) - Field specification (if not provided in Phase 1)
- `collection=<collection_name>` (OPTIONAL) - Output collection name (default: `products`)
- `resume-url=<url>` (OPTIONAL) - Resume browser from this URL
- `out=<base_dir>` (OPTIONAL) - Output directory (default: `./generated_scraper`)

**Outputs**:
- `generated_scraper/<scraper>/parsers/details.rb` ✅ (tested)
- `generated_scraper/<scraper>/config.yaml` (updated with details parser + CSV exporter)
- `generated_scraper/<scraper>/.scraper-state/field-spec.json` (updated with discovered selectors)
- `generated_scraper/<scraper>/.scraper-state/detail-selectors.json` (includes `_notes`)

**Completion**: Scraper is now complete and ready for deployment!

---

## 📊 Field Specification System

### What is Field Specification?

Field specification defines exactly which fields to extract from product pages. It's provided as a CSV file with this format:

```csv
column_name,column_type,dev_notes
competitor_product_id,str,FIND - Find the product-id if possible or else use sku or barcode
name,str,FIND
customer_price_lc,float,FIND - The listed price of the product
has_discount,boolean,PROCESS - true if it has discount
```

### Field Types

- **`str`**: String/text data
- **`float`**: Decimal numbers (prices, percentages)
- **`boolean`**: True/false values
- **`int`**: Whole numbers

### Extraction Methods

- **`FIND`**: Extract directly from page elements (requires selector discovery)
- **`PROCESS`**: Calculate/derive from other data (computed fields like `has_discount`)

### How Field Spec is Used

1. **Phase 1** (`/scrape`): Parses CSV → stores in `.scraper-state/field-spec.json`
2. **Phase 3** (`/details-parser`): 
   - Uses field-spec.json to guide selector discovery
   - Only discovers fields marked as "FIND"
   - Generates parser code extracting only specified fields
   - Generates CSV exporter configuration matching field spec

### Example Field Spec File

See `spec_general_sample.csv` for a complete example with all common e-commerce fields.

---

## 🔄 Complete Workflow Examples

### Example 1: Full Pipeline with Field Spec (Recommended)

```bash
# Phase 1: Site discovery with field specification
/scrape url="https://naivas.online" name=naivas_online spec="spec_general_sample.csv"

# Phase 2: Generate navigation parsers
/navigation-parser scraper=naivas_online

# Phase 3: Generate detail parser (uses field-spec.json from Phase 1)
/details-parser scraper=naivas_online
```

**Result**: Complete scraper with all parsers tested and config.yaml ready for deployment.

### Example 2: Without Field Spec (Common Fields)

```bash
# Phase 1: Site discovery (no spec - will use common fields)
/scrape url="https://example.com" name=my_store

# Phase 2: Generate navigation parsers
/navigation-parser scraper=my_store

# Phase 3: Generate detail parser (discovers common fields)
/details-parser scraper=my_store
```

**Result**: Scraper with common fields (name, price, brand, description, etc.)

### Example 3: Provide Spec Later

```bash
# Phase 1: Site discovery (no spec)
/scrape url="https://shop.com" name=shop

# Phase 2: Generate navigation parsers
/navigation-parser scraper=shop

# Phase 3: Provide spec now (overrides common fields)
/details-parser scraper=shop spec="spec_general_sample.csv"
```

**Result**: Scraper with custom field specification applied in Phase 3.

---

## 📁 Generated File Structure

After running all three commands, you'll have:

```
generated_scraper/
└── <scraper_name>/
    ├── config.yaml              # Complete config with all parsers + exporters
    ├── seeder/
    │   └── seeder.rb           # Initial page seeding
    ├── parsers/
    │   ├── categories.rb       # Category navigation parser
    │   ├── subcategories.rb    # Subcategory parser (if applicable)
    │   ├── listings.rb         # Product listings parser
    │   └── details.rb         # Product detail parser
    └── .scraper-state/         # State files (for resumability)
        ├── discovery-state.json          # includes _notes
        ├── field-spec.json
        ├── navigation-selectors.json     # includes _notes
        ├── detail-selectors.json         # includes _notes
        ├── phase-status.json
        └── browser-context.json
```

---

## 🔧 State Management & Resumability

### State Files Location

All state files are stored in `.scraper-state/` directory:

- **`discovery-state.json`**: Site structure analysis + human-readable `_notes` (from Phase 1)
- **`field-spec.json`**: Field specification with discovered selectors
- **`navigation-selectors.json`**: Navigation selector discoveries + `_notes`
- **`detail-selectors.json`**: Detail field selector discoveries + `_notes`
- **`phase-status.json`**: Workflow progress tracking
- **`browser-context.json`**: Browser session state

### Resuming Work

If a command is interrupted, you can resume:

```bash
# Resume from where you left off
/navigation-parser scraper=naivas_online resume-url="https://naivas.online/categories"
/details-parser scraper=naivas_online resume-url="https://naivas.online/product/123"
```

The system automatically checks `phase-status.json` to determine what's already completed.

---

## 🧪 Testing

Each parser is automatically tested after generation using the `parser_tester` MCP tool:

- **Categories Parser**: Tests category link extraction
- **Subcategories Parser**: Tests subcategory link extraction
- **Listings Parser**: Tests product link extraction and pagination
- **Details Parser**: Tests product field extraction

All tests use downloaded HTML files for reliable offline testing.

---

## 📝 Field Specification Details

### CSV Format

Your CSV file should have these columns:

```csv
column_name,column_type,dev_notes
```

**Example**:
```csv
column_name,column_type,dev_notes
name,str,FIND
customer_price_lc,float,FIND - The listed price of the product
has_discount,boolean,PROCESS - true if it has discount
```

### Field Spec Storage

The parsed field spec is stored in `.scraper-state/field-spec.json`:

```json
{
  "source_file": "spec_general_sample.csv",
  "parsed_at": "2025-11-06T16:00:00Z",
  "fields": [
    {
      "name": "name",
      "type": "str",
      "extraction_method": "FIND",
      "notes": "...",
      "selectors": [".product-title", "h1"],
      "verified": true,
      "confidence": 0.95
    }
  ]
}
```

---

## 🎯 Key Features

### ✅ Modular Design

- Each command is **completely independent**
- No conversation history needed between commands
- All context passed via state files

### ✅ Session Independence

- Commands work across different Gemini CLI sessions
- State files preserve all findings
- Can resume work anytime

### ✅ Automatic Testing

- All parsers tested immediately after generation
- Uses `parser_tester` MCP tool
- Validates selector accuracy and data extraction

### ✅ Field Specification Support

- Define exact fields to extract via CSV
- Guides selector discovery (only discover needed fields)
- Auto-generates CSV exporter configuration

### ✅ Browser-First Workflow

- Uses Playwright MCP tools for selector discovery
- `browser_inspect_element` for real CSS selectors
- `browser_verify_selector` for text fields
- `browser_evaluate` for non-text attributes

---

## 🚨 Important Notes

### Absolute Paths Required

**CRITICAL**: All file write operations MUST use absolute paths. The system automatically converts relative paths, but ensure you're aware of this requirement.

### Reading state files (Gemini CLI)

Use the **`read_file`** tool with **absolute paths** (or paths relative to cwd) for `.scraper-state/` files.

This repo sets **`.gemini/settings.json`** → `context.fileFiltering.respectGitIgnore` and `respectGeminiIgnore` to **`false`**, so paths under `generated_scraper/` remain readable by the agent. Do **not** use Cursor-only names like `ReadManyFiles` / `ReadFile` / `WriteFile` in Gemini CLI prompts.

### Playwright Refs Warning

**NEVER** use Playwright refs (like `e62`, `e425`) in CSS selectors. Always use `browser_inspect_element` first to get real CSS selectors before calling `browser_verify_selector`.

---

## 📚 Additional Documentation

- **Field Specification System**: See `.gemini/FIELD-SPEC-SYSTEM.md`
- **Modular Architecture**: See `.gemini/MODULAR-ARCHITECTURE.md`
- **Resume Guide**: See `.gemini/RESUME-GUIDE.md`

---

## 🐛 Troubleshooting

### Command Not Found

If a command doesn't appear in Gemini CLI:
1. Check that the `.toml` file exists in `.gemini/commands/`
2. Verify TOML syntax is valid (no unescaped backslashes)
3. Restart Gemini CLI to reload commands

### State Files Not Found

If `read_file` fails on a state path:
- Missing files are normal on first run — continue the workflow.
- If the tool reports the path is ignored, confirm `.gemini/settings.json` keeps `respectGitIgnore` / `respectGeminiIgnore` false for this project, or copy state to a non-ignored path.

### Parser Testing Fails

If `parser_tester` fails:
1. Ensure `config.yaml` exists in scraper directory
2. Verify parser file exists and has valid Ruby syntax
3. Check that HTML file path is absolute (if using `html_file` parameter)

---

## 💡 Tips

1. **Always provide field spec**: Use `spec="spec_general_sample.csv"` for consistent field extraction
2. **Test incrementally**: Each parser is tested automatically, but you can test manually too
3. **Check state files**: Look in `.scraper-state/` to see what was discovered
4. **Resume capability**: If interrupted, use `resume-url` parameter to continue
5. **Browser tools**: The system uses browser-first workflow - trust the selector discoveries

---

## 📞 Support

For issues or questions:
1. Check `.scraper-state/` files for discovery results
2. Review `_notes` fields in state JSON files for detailed documentation
3. Check `phase-status.json` for workflow progress

---

**Happy Scraping! 🕷️**




