# Field Specification System

## Overview

The field specification system allows you to define exactly which fields to extract from product detail pages using a CSV file format. This ensures consistency across scrapers and guides the AI to discover only the fields you need.

## Field Specification Format

### CSV Format (spec_general_sample.csv)

```csv
column_name,column_type,dev_notes
competitor_product_id,str,FIND - Find the product-id if possible or else use sku or barcode
name,str,FIND
brand,str,FIND
category,str,FIND - Search for category breadcrumb and get the first of it
sub_category,str,"FIND - Include the rest of the subcategories ""subcat 1 > subcat 2 > …"""
customer_price_lc,float,FIND - The listed price of the product
base_price_lc,float,"FIND - If it has no discount, then it is the same as customer_price_lc"
has_discount,boolean,PROCESS - true if it has discount
discount_percentage,float,PROCESS - process from customer_price_lc and base_price_lc
description,str,FIND
img_url,str,FIND
sku,str,FIND
url,str,PROCESS
is_available,boolean,FIND
```

### Field Types

- **`str`**: String/text data
- **`float`**: Decimal numbers (prices, percentages)
- **`boolean`**: True/false values
- **`int`**: Whole numbers

### Extraction Methods

- **`FIND`**: Extract directly from page elements (requires selector discovery)
- **`PROCESS`**: Calculate/derive from other data (computed fields)

## Storage in `.scraper-state`

### File: `field-spec.json`

```json
{
  "source_file": "spec_general_sample.csv",
  "parsed_at": "2025-11-06T16:00:00Z",
  "fields": [
    {
      "name": "competitor_product_id",
      "type": "str",
      "extraction_method": "FIND",
      "notes": "Find the product-id if possible or else use sku or barcode",
      "selectors": [".product-id", "[data-product-id]"],
      "verified": true,
      "confidence": 0.95,
      "extraction_notes": "Product ID found in data-product-id attribute"
    },
    {
      "name": "has_discount",
      "type": "boolean",
      "extraction_method": "PROCESS",
      "notes": "true if it has discount",
      "computation": "customer_price_lc < base_price_lc",
      "verified": true
    }
  ]
}
```

### Field Structure

**FIND Fields:**
- `name`: Field name (snake_case)
- `type`: Data type (str, float, boolean, int)
- `extraction_method`: "FIND"
- `notes`: Original notes from CSV
- `selectors`: Array of discovered CSS selectors (added during discovery)
- `verified`: Boolean (true after browser verification)
- `confidence`: Float (0.0-1.0)
- `extraction_notes`: Additional notes about selector discovery

**PROCESS Fields:**
- `name`: Field name (snake_case)
- `type`: Data type (str, float, boolean, int)
- `extraction_method`: "PROCESS"
- `notes`: Original notes from CSV
- `computation`: Computation logic (e.g., "customer_price_lc < base_price_lc")
- `verified`: Boolean (true after implementation)

## Workflow Integration

### Phase 1: `/scrape-site`

**Input:**
```bash
/scrape-site url="https://naivas.online" name=naivas_online spec="spec_general_sample.csv"
```

**Process:**
1. Parse CSV file (`spec_general_sample.csv`)
2. Extract field definitions (name, type, extraction_method, notes)
3. Create `field-spec.json` structure
4. Save to `.scraper-state/field-spec.json`

**Output:**
- `field-spec.json` with parsed field definitions (no selectors yet)

### Phase 2: `/create-navigation-parser`

**No changes** - Navigation parsers don't use field spec

### Phase 3: `/create-details-parser`

**Input:**
```bash
/create-details-parser scraper=naivas_online
# OR if spec wasn't provided in Phase 1:
/create-details-parser scraper=naivas_online spec="spec_general_sample.csv"
```

**Process:**
1. Load `field-spec.json` (from Phase 1 or parse if spec parameter provided)
2. For each FIND field:
   - Discover CSS selectors using browser tools
   - Verify selectors work
   - Update `field-spec.json` with discovered selectors
3. For each PROCESS field:
   - Document computation logic
   - Update `field-spec.json` with computation
4. Generate `parsers/details.rb`:
   - Extract only fields from `field-spec.json`
   - Use discovered selectors for FIND fields
   - Implement computation for PROCESS fields
5. Generate `config.yaml` exporter:
   - Create CSV exporter with fields from `field-spec.json`

**Output:**
- Updated `field-spec.json` with discovered selectors
- `parsers/details.rb` extracting only specified fields
- `config.yaml` with CSV exporter matching field spec

## Usage Examples

### Example 1: With Field Spec (Recommended)

```bash
# Phase 1: Parse and store field spec
/scrape-site url="https://naivas.online" name=naivas_online spec="spec_general_sample.csv"

# Phase 2: Generate navigation parsers
/create-navigation-parser scraper=naivas_online

# Phase 3: Generate detail parser (uses field-spec.json from Phase 1)
/create-details-parser scraper=naivas_online
```

### Example 2: Spec Provided Later

```bash
# Phase 1: Without spec (will discover common fields)
/scrape-site url="https://naivas.online" name=naivas_online

# Phase 2: Generate navigation parsers
/create-navigation-parser scraper=naivas_online

# Phase 3: Provide spec now (overrides common fields)
/create-details-parser scraper=naivas_online spec="spec_general_sample.csv"
```

### Example 3: No Spec (Fallback Mode)

```bash
# Phase 1: Without spec
/scrape-site url="https://naivas.online" name=naivas_online

# Phase 2: Generate navigation parsers
/create-navigation-parser scraper=naivas_online

# Phase 3: No spec provided (discovers common fields)
/create-details-parser scraper=naivas_online
```

## Benefits

1. **Consistency**: All scrapers use the same field definitions
2. **Efficiency**: Only discover fields you need (saves tokens)
3. **Documentation**: Field spec documents what fields are extracted
4. **Config Generation**: Automatically generates CSV exporter fields
5. **Resumability**: Field spec persists in `.scraper-state/` for later reference

## Field Spec Lifecycle

1. **Parse** (scrape-site): CSV → field-spec.json (no selectors)
2. **Discover** (create-details-parser): Browser tools → selectors added to field-spec.json
3. **Generate** (create-details-parser): field-spec.json → parser code + config.yaml exporter
4. **Store** (persistent): field-spec.json remains in `.scraper-state/` for reference

## File Locations

- **Input**: `spec_general_sample.csv` (project root or provided path)
- **Storage**: `generated_scraper/<scraper>/.scraper-state/field-spec.json`
- **Usage**: Referenced by `create-details-parser` for field discovery and parser generation

