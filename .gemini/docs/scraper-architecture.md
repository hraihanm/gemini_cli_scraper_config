# Scraper Generator Architecture Specification

## Overview

This document defines the architecture for the Gemini CLI-based web scraper generator system for DataHen v3. The system uses an orchestrator pattern with specialized commands for navigation and detail parsing, designed for resumability and single-browser session constraints.

## Architecture Pattern

**Pattern**: Orchestrator + Specialized Commands
- **Master Orchestrator**: `/scrape-site` - Coordinates full scraper generation
- **Navigation Master**: `/create-navigation-parser` - Generates navigation parsers
- **Detail Master**: `/create-details-parser` - Generates detail parsers (existing, enhanced)

## State Management

### State Storage Location

**Decision**: Scraper-local state directory
```
generated_scraper/<scraper_name>/.scraper-state/
├── discovery-state.json      # Site structure discovery progress
├── navigation-selectors.json  # Discovered navigation selectors
├── detail-selectors.json      # Discovered detail selectors
├── phase-status.json          # Current phase, completed steps
└── browser-context.json       # Browser state for resumption
```

### State File Management

**Decision**: Configurable persistence with flag
- **Default**: Delete state files after successful completion
- **Flag**: `--keep-state` - Retain state files for debugging/iterations
- **Manual**: State files can be manually inspected/deleted

### Phase Status File Format

```json
{
  "scraper_name": "example_scraper",
  "version": "1.0.0",
  "created_at": "2025-01-XX...",
  "current_phase": "navigation_discovery",
  "completed_phases": ["site_discovery"],
  "keep_state": false,
  "phase_status": {
    "site_discovery": {
      "status": "completed",
      "completed_at": "2025-01-XX...",
      "discovered_patterns": ["hierarchical", "categories->listings->details"],
      "page_types_found": ["categories", "listings", "details"],
      "navigation_depth": 2,
      "site_structure": {
        "has_categories": true,
        "has_subcategories": true,
        "has_listings": true,
        "listing_pattern": "pagination"
      }
    },
    "navigation_discovery": {
      "status": "in_progress",
      "current_step": "analyzing_category_page",
      "checkpoints": {
        "categories_analyzed": true,
        "subcategories_analyzed": false,
        "listings_analyzed": false
      },
      "selector_plan": {}
    },
    "detail_discovery": {
      "status": "pending"
    },
    "assembly": {
      "status": "pending"
    }
  }
}
```

### Browser Context File Format

```json
{
  "last_url_visited": "https://example.com/categories",
  "last_phase": "navigation_discovery",
  "last_snapshot_refs": {
    "category_link": "e425",
    "next_page_button": "e612"
  },
  "session_metadata": {
    "started_at": "2025-01-XX...",
    "last_activity": "2025-01-XX..."
  }
}
```

## Command Specifications

### `/scrape-site` - Master Orchestrator

**Purpose**: End-to-end scraper generation coordinator

**Inputs**:
- `url=<site_url>` (REQUIRED) - Target website URL
- `name=<scraper_name>` (REQUIRED) - Scraper name
- `spec=<path>` (OPTIONAL) - Field specification CSV/JSON
- `collection=<name>` (OPTIONAL, default: "products") - Output collection name
- `out=<base_dir>` (OPTIONAL, default: "./generated_scraper") - Output directory
- `--keep-state` (FLAG) - Retain state files after completion
- `--resume` (FLAG) - Resume from existing state (checks phase-status.json)

**Phases**:

1. **Site Discovery**
   - Analyze home page structure
   - Detect navigation patterns
   - Identify page types (categories, listings, details)
   - Determine navigation depth
   - Output: `discovery-state.json`

2. **Navigation Generation** (calls `/create-navigation-parser`)
   - Pass: `scraper`, `discovery-state`, `browser-context`
   - Receive: Navigation parsers + `navigation-selectors.json`
   - Update: `phase-status.json`

3. **Detail Generation** (calls `/create-details-parser`)
   - Extract sample detail URLs from navigation discovery
   - Pass: `scraper`, `navigation-state`, `detail_url`, `spec`
   - Receive: `details.rb` + `detail-selectors.json`
   - Update: `phase-status.json`

4. **Assembly & Validation**
   - Read all state files
   - Generate `config.yaml` from complete state
   - Generate `seeder/seeder.rb` (if not already created)
   - Run integration tests
   - Clean up state files (unless `--keep-state`)

**Resume Logic**:
```ruby
if --resume flag:
  load phase-status.json
  if current_phase exists:
    resume from current_phase
  else:
    start from beginning
else:
  start fresh (overwrite existing state)
```

---

### `/create-navigation-parser` - Navigation Master

**Purpose**: Generate comprehensive navigation parsers (categories, subcategories, listings)

**Inputs**:
- `scraper=<name>` (REQUIRED) - Scraper name (must exist)
- `resume-url=<url>` (OPTIONAL) - Resume browser from this URL
- `discovery-state=<path>` (OPTIONAL, default: `generated_scraper/<name>/.scraper-state/discovery-state.json`)
- `browser-context=<path>` (OPTIONAL) - Browser state file
- `--checkpoint` (FLAG) - Save checkpoint after each page type

**Outputs**:
- `parsers/categories.rb` - Category extraction parser
- `parsers/subcategories.rb` - Subcategory parser (if detected)
- `parsers/listings.rb` - Product listings parser
- `navigation-selectors.json` - Discovered selectors
- Updates `phase-status.json` checkpoints

**Process**:

1. **Load Context**
   ```ruby
   # Load discovery state
   discovery = load_json(discovery-state)
   
   # Resume browser if context provided
   if browser-context.exists? || resume-url:
     url = browser-context['last_url_visited'] || resume-url
     browser_navigate(url)
   else:
     # Start from discovery's category page
     browser_navigate(discovery['sample_category_url'])
   ```

2. **Comprehensive Parser Generation** (with checkpointing):
   - **Categories Parser** (if `has_categories: true`)
     - Analyze category page structure
     - Extract category links and patterns
     - Generate `parsers/categories.rb`
     - **Checkpoint**: Save progress → `phase-status.phase_status.navigation_discovery.checkpoints.categories_analyzed = true`
   
   - **Subcategories Parser** (if `has_subcategories: true`)
     - Analyze subcategory page structure
     - Extract subcategory navigation
     - Generate `parsers/subcategories.rb`
     - **Checkpoint**: Save progress
   
   - **Listings Parser** (if `has_listings: true`)
     - Analyze listings page structure
     - Extract product links, pagination patterns
     - Generate `parsers/listings.rb`
     - Extract sample detail URLs for detail master
     - **Checkpoint**: Save progress

3. **Selector Documentation**:
   ```json
   {
     "categories": {
       "category_link_selector": [".category-item a", ".nav-link"],
       "category_name_selectors": [".category-title", "h2"],
       "verified": true,
       "confidence": 0.95
     },
     "subcategories": {
       "subcategory_link_selector": [".subcategory a"],
       "verified": true
     },
     "listings": {
       "product_link_selector": [".product-item a", ".product-card a"],
       "pagination_next": [".next-page", "a[aria-label='Next']"],
       "pagination_pattern": "query_param",  // or "path", "infinite_scroll"
       "pagination_param": "page",
       "sample_detail_urls": ["https://example.com/p/123", "..."],
       "verified": true
     }
   }
   ```

**Error Recovery**:
- If failure occurs:
  - Read `phase-status.json`
  - Identify last successful checkpoint
  - Resume from that checkpoint
  - Don't re-analyze completed page types

---

### `/create-details-parser` - Detail Master (Enhanced)

**Purpose**: Generate product detail parser with navigation context awareness

**Inputs**:
- `scraper=<name>` (REQUIRED) - Scraper name
- `url=<detail_url>` (REQUIRED unless resume-url provided)
- `resume-url=<url>` (OPTIONAL) - Resume browser from this URL
- `navigation-state=<path>` (OPTIONAL) - Navigation selectors context
- `spec=<path>` (OPTIONAL) - Field specification CSV/JSON
- `collection=<name>` (OPTIONAL) - Output collection name
- `html=<path>` (OPTIONAL) - Local HTML file for testing

**Enhancements**:
- Reads `navigation-selectors.json` to understand page flow
- Incorporates navigation context into parser (vars flow)
- Uses sample URLs from navigation discovery if not provided
- Maintains consistency with navigation parsers

**Outputs**:
- `parsers/details.rb` - Enhanced with navigation context
- `detail-selectors.json` - Product field selectors
- Updates `phase-status.json` to mark detail_discovery complete

**Process**:

1. **Load Navigation Context**:
   ```ruby
   navigation_state = load_json(navigation-state || default_path)
   # Understand vars flow: categories → listings → details
   # Ensure detail parser receives correct vars from listings parser
   ```

2. **Browser Navigation**:
   - Use `resume-url` if provided
   - Else use `url` parameter
   - Else use sample URL from `navigation-selectors.json`

3. **Selector Discovery** (same as current implementation)

4. **Parser Generation** (enhanced):
   ```ruby
   # Include navigation context in comments
   # This parser receives vars from listings parser:
   # - category_name, breadcrumb, rank, page_number
   
   vars = page['vars']
   
   outputs << {
     '_collection' => collection_name,
     '_id' => sku || competitor_product_id || hash(name + url),
     # ... product fields ...
     'category_name' => vars['category_name'],  # From navigation
     'breadcrumb' => vars['breadcrumb'],        # From navigation
     'rank_in_listing' => vars['rank'],          # From listings
     # ...
   }
   ```

---

## Browser Session Management

### Single Session Constraint

**Constraint**: Playwright MCP can only access one browser session at a time.

### Session Handoff Pattern

1. **Orchestrator Manages Session**:
   - Starts browser session in Phase 1
   - Maintains session throughout all phases
   - Passes browser state via `browser-context.json`

2. **Sub-commands Receive Context**:
   ```ruby
   # Option 1: State file (source of truth)
   browser_context = load_json('.scraper-state/browser-context.json')
   if browser_context['last_url_visited']:
     browser_navigate(browser_context['last_url_visited'])
   
   # Option 2: Command parameter (override)
   if resume-url:
     browser_navigate(resume-url)  # Override state file
   ```

3. **Sequential Execution**:
   - No parallel navigation needed
   - Orchestrator waits for each command to complete
   - Browser session persists between commands

### Browser Context Updates

Each command updates `browser-context.json`:
```json
{
  "last_url_visited": "<current_url>",
  "last_phase": "<current_phase>",
  "last_activity": "<timestamp>"
}
```

---

## Config.yaml Generation (Phase 4)

**Decision**: Orchestrator generates fresh config from state files

### Config Generation Process

1. **Read State Files**:
   - `discovery-state.json` → site structure
   - `navigation-selectors.json` → page types discovered
   - `detail-selectors.json` → detail parser info

2. **Determine Page Types**:
   ```ruby
   page_types = []
   page_types << "categories" if discovery['has_categories']
   page_types << "subcategories" if discovery['has_subcategories']
   page_types << "listings" if discovery['has_listings']
   page_types << "details" if detail_selectors.exists?
   ```

3. **Generate config.yaml**:
   ```yaml
   seeder:
     file: ./seeder/seeder.rb
     disabled: false
   
   parsers:
     - page_type: categories
       file: ./parsers/categories.rb
       disabled: false
     - page_type: subcategories
       file: ./parsers/subcategories.rb
       disabled: false
     - page_type: listings
       file: ./parsers/listings.rb
       disabled: false
     - page_type: details
       file: ./parsers/details.rb
       disabled: false
   
   exporters:
     - exporter_name: products_json
       exporter_type: json
       collection: products
       write_mode: pretty_array
       start_on_job_done: true
   ```

4. **Generate Seeder** (if not exists):
   - Read from `discovery-state.json` → initial URLs
   - Create `seeder/seeder.rb` with proper page types

---

## Error Recovery & Checkpointing

### Checkpoint Strategy

**Decision**: Resume from last successful page type

### Checkpoint Points

1. **After Categories Parser Generated**
   ```json
   "checkpoints": {
     "categories_analyzed": true,
     "categories_parser_generated": true,
     "last_category_url": "https://example.com/categories"
   }
   ```

2. **After Subcategories Parser Generated**
   ```json
   "checkpoints": {
     "subcategories_analyzed": true,
     "subcategories_parser_generated": true
   }
   ```

3. **After Listings Parser Generated**
   ```json
   "checkpoints": {
     "listings_analyzed": true,
     "listings_parser_generated": true,
     "sample_detail_urls": ["https://example.com/p/123"]
   }
   ```

### Resume Logic

```ruby
# If resuming navigation discovery
if phase_status['navigation_discovery']['checkpoints']['listings_analyzed']:
  # Already completed, skip to detail generation
  skip_to_phase("detail_discovery")
elsif phase_status['navigation_discovery']['checkpoints']['subcategories_analyzed']:
  # Resume from listings
  resume_url = phase_status['navigation_discovery']['checkpoints']['last_listings_url']
  generate_listings_parser(resume_url)
elsif phase_status['navigation_discovery']['checkpoints']['categories_analyzed']:
  # Resume from subcategories
  resume_url = phase_status['navigation_discovery']['checkpoints']['last_subcategory_url']
  generate_subcategories_parser(resume_url)
else:
  # Start from beginning
  start_from_categories()
```

---

## File Structure

### Generated Scraper Structure

```
generated_scraper/<scraper_name>/
├── config.yaml                    # Generated in Phase 4
├── seeder/
│   └── seeder.rb                  # Generated in Phase 4 or earlier
├── parsers/
│   ├── categories.rb               # From Navigation Master
│   ├── subcategories.rb           # From Navigation Master (if needed)
│   ├── listings.rb                 # From Navigation Master
│   └── details.rb                  # From Detail Master
└── .scraper-state/                 # State directory (deleted on success)
    ├── discovery-state.json
    ├── navigation-selectors.json
    ├── detail-selectors.json
    ├── phase-status.json
    └── browser-context.json
```

---

## Implementation Checklist

### Phase 1: Navigation Master (`/create-navigation-parser`)

- [ ] Command file created: `.gemini/commands/create-navigation-parser.toml`
- [ ] State file reading logic
- [ ] Browser resume logic (state file + parameter)
- [ ] Categories parser generation
- [ ] Subcategories parser generation (conditional)
- [ ] Listings parser generation
- [ ] Pagination detection (query param, path, infinite scroll)
- [ ] Checkpoint saving after each page type
- [ ] Error recovery from checkpoints
- [ ] `navigation-selectors.json` output
- [ ] `phase-status.json` updates

### Phase 2: Enhanced Detail Master

- [ ] Enhance existing `/create-details-parser`
- [ ] Add `navigation-state` parameter support
- [ ] Load navigation context
- [ ] Incorporate vars flow from navigation
- [ ] Update `phase-status.json` on completion

### Phase 3: Master Orchestrator (`/scrape-site`)

- [ ] Command file created: `.gemini/commands/scrape-site.toml`
- [ ] Site discovery phase (Phase 1)
- [ ] Call Navigation Master (Phase 2)
- [ ] Call Detail Master (Phase 3)
- [ ] Config.yaml generation (Phase 4)
- [ ] Seeder generation (Phase 4)
- [ ] Integration testing
- [ ] State cleanup (`--keep-state` flag)
- [ ] Resume logic (`--resume` flag)

### Phase 4: Testing & Validation

- [ ] Test full workflow end-to-end
- [ ] Test resume functionality
- [ ] Test error recovery from checkpoints
- [ ] Test state file persistence
- [ ] Validate generated parsers with `parser_tester`

---

## Next Steps

1. **Implement Navigation Master** (`/create-navigation-parser.toml`)
2. **Enhance Detail Master** (add navigation context support)
3. **Implement Orchestrator** (`/scrape-site.toml`)
4. **Test with real sites**
5. **Iterate based on feedback**

