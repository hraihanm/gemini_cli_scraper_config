# Gemini CLI Web Scraping Agent - Complete Project Documentation

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Design](#architecture--design)
3. [Gemini CLI Configuration](#gemini-cli-configuration)
4. [MCP Integration - Playwright MCP Mod](#mcp-integration---playwright-mcp-mod)
5. [Custom Commands System](#custom-commands-system)
6. [Workflow Pipeline](#workflow-pipeline)
7. [Technical Implementation](#technical-implementation)
8. [State Management](#state-management)
9. [Testing & Quality Assurance](#testing--quality-assurance)
10. [Best Practices & Guidelines](#best-practices--guidelines)
11. [Troubleshooting](#troubleshooting)

---

## Project Overview

### Purpose

This project is a **specialized AI agent system** built on **Google Gemini CLI** for automated web scraping development. It generates complete, production-ready web scrapers for e-commerce websites using the **DataHen V3** platform.

### Core Capabilities

- **Automated Scraper Generation**: End-to-end scraper creation from website URL to deployable code
- **Browser-First Discovery**: Uses Playwright MCP tools for intelligent selector discovery
- **Modular Architecture**: Independent, resumable commands that work across sessions
- **Field Specification System**: CSV-based field definition for precise data extraction
- **Automatic Testing**: Integrated parser testing using DataHen's `parser_tester` tool
- **Knowledge Preservation**: Human and AI-readable documentation of discoveries

### Technology Stack

- **AI Framework**: Google Gemini CLI (with custom system instructions)
- **Scraping Platform**: DataHen V3 (Ruby-based parsers)
- **Browser Automation**: Playwright MCP Mod (Custom Model Context Protocol server)
- **Configuration**: TOML files for custom commands, Markdown for instructions
- **State Management**: JSON files for machine-readable state, Markdown for knowledge

---

## Architecture & Design

### Two-Layer Configuration Architecture

The system uses a **layered configuration approach** inspired by firmware/OS separation:

#### 1. **SYSTEM.md** - The Firmware Layer

**Location**: `.gemini/system.md`

**Purpose**: Fundamental, non-negotiable operational rules for safe tool execution.

**Contains**:
- Tool usage protocols (absolute paths, file operations)
- Security and safety directives (destructive command checks)
- Workflow mechanics (Git operations, parser testing)
- Reserved variable definitions (DataHen-specific)
- Browser tool protocols (Playwright refs, selector verification)

**Key Principle**: These rules ensure safe, stable execution independent of the specific task.

#### 2. **GEMINI.md** - The Strategic Layer

**Location**: `GEMINI.md` (project root)

**Purpose**: High-level strategy, persona, and mission-specific context.

**Contains**:
- Agent persona (Senior E-commerce Scraping Engineer)
- Problem-solving methodology (PARSE framework)
- E-commerce-specific patterns and workflows
- Technology guidelines and best practices

**Key Principle**: Defines what the agent should do, while SYSTEM.md defines how to do it safely.

### Modular Design Principles

The system follows **five core principles**:

1. **Read State Files First**: Commands load existing state before starting work
2. **Write ALL Findings**: All discoveries written to files before completion
3. **Write Knowledge Files**: Both machine-readable (JSON) and human-readable (Markdown)
4. **Self-Contained**: Commands work independently, no conversation history needed
5. **Clear Completion**: Explicit reports of what's done and what's next

### Session Independence

**Key Feature**: Each command is **completely independent** and can run in separate Gemini CLI sessions.

**How it works**:
- State files (`.scraper-state/`) preserve all discoveries
- Knowledge files (`.md`) provide context for next phase
- Commands read state files, not conversation history
- Each command writes its findings before completion

**Benefits**:
- Resume work anytime, anywhere
- No context loss between sessions
- Parallel development possible
- Clear separation of concerns

---

## Gemini CLI Configuration

### System Instruction Override

The project uses Gemini CLI's **`GEMINI_SYSTEM_MD`** environment variable to override the default system prompt.

**How it works**:
- When `GEMINI_SYSTEM_MD=true`, Gemini CLI loads `.gemini/system.md`
- This completely replaces (not amends) the default system prompt
- Visual indicator: `|⌐■_■|` icon appears in CLI footer

**Why it's needed**:
- Default system prompt may conflict with custom instructions
- Provides complete control over agent behavior
- Enables specialized agent personas (e-commerce scraping expert)

### Context File Hierarchy

Gemini CLI loads context files in this order:

1. **Global Context**: `~/.gemini/GEMINI.md` (user-wide instructions)
2. **Project Context**: `<project-root>/GEMINI.md` (project-specific strategy)
3. **Subdirectory Context**: `<subdir>/GEMINI.md` (component-specific)

**Current Setup**:
- **SYSTEM.md**: `.gemini/system.md` (operational rules)
- **GEMINI.md**: `GEMINI.md` (strategic layer)

### Custom Slash Commands

**Location**: `.gemini/commands/*.toml`

**Purpose**: Reusable prompts for common workflows.

**Structure**:
```toml
description = "Short description shown in CLI"

prompt = """
Detailed instructions with {{args}} placeholder
"""
```

**Available Commands**:
- `/scrape-site` - Phase 1: Site discovery
- `/create-navigation-parser` - Phase 2: Navigation parsers
- `/create-details-parser` - Phase 3: Detail parser
- `/create-details-parser-standalone` - End-to-end detail parser (alternative)
- `/explore` - Browser exploration tool

---

## MCP Integration - Playwright MCP Mod

### Overview

The project uses a **custom Playwright MCP Mod** that extends the standard Playwright MCP server with specialized tools for web scraping development. This custom MCP server provides enhanced browser automation capabilities and DataHen parser testing integration.

### Installation

The Playwright MCP Mod is installed as an MCP server in your Gemini CLI configuration:

```json
{
  "mcpServers": {
    "playwright-mod": {
      "command": "npx",
      "args": ["path/to/playwright-mcp-mod"]
    }
  }
}
```

**Installation Steps**:
1. Clone the Playwright MCP Mod repository
2. Install dependencies: `npm install`
3. Build the project: `npm run build`
4. Configure in Gemini CLI MCP settings

### Key Custom Tools

#### 1. `browser_verify_selector` ✨

**Purpose**: Verifies that a CSS selector matches an element and contextually matches expected content.

**Key Features**:
- Semantic text similarity matching for text content
- Exact attribute matching for non-text attributes
- Batch verification support (multiple selectors at once)
- Detailed confidence scoring and explanations
- Special handling for semantic labels (name, title, label, heading)

**Usage**:
```javascript
browser_verify_selector({
  element: "Product name",
  selector: "#product-title",
  expected: "Expected Product Name",
  attribute: null  // Optional: "href", "data-id", etc.
})
```

**When to Use**:
- Verify text-based selectors (product names, prices, descriptions)
- Validate selector accuracy before using in parser code
- Test selectors across multiple pages for consistency

**Limitations**:
- **ONLY works for text-based fields** (names, prices, labels)
- **DOES NOT work** for image URLs, data attributes, or non-text content
- For non-text content, use `browser_evaluate()` instead

#### 2. `browser_inspect_element` ✨

**Purpose**: Reveals the real CSS selector and DOM tree details of an element.

**Key Features**:
- Extracts real CSS selectors from Playwright refs
- Batch inspection support (multiple elements at once)
- Detailed DOM structure information
- Human-readable element descriptions for permissions

**Usage**:
```javascript
browser_inspect_element({
  element: "Product title",
  ref: "e425",  // From browser_snapshot()
  batch: []  // Optional: additional elements to inspect
})
```

**When to Use**:
- **MANDATORY FIRST STEP** before using any selector in parser code
- Convert Playwright refs to real CSS selectors
- Understand DOM structure for complex elements
- Get selector for use in `browser_verify_selector`

**Critical Rule**: Always call `browser_inspect_element` before `browser_verify_selector` to get the real CSS selector (never use Playwright refs in selectors).

#### 3. `browser_view_html` ✨

**Purpose**: Get HTML content of the current page with configurable options.

**Key Features**:
- Configurable script inclusion/exclusion
- Advanced HTML sanitization (removes SVG and scripts)
- Token usage optimization (smart defaults)
- Direct HTML content return (no file saving)

**Usage**:
```javascript
browser_view_html({
  includeScripts: false,  // Default: false (reduces tokens)
  isSanitized: true       // Default: true (removes unnecessary content)
})
```

**When to Use**:
- **Last resort** when element-by-element inspection fails
- Need to understand overall HTML structure
- Batch selector discovery for multiple fields
- Complex nested structures hard to navigate

**Warning**: High token consumption - use strategically. Prefer `browser_inspect_element` + `browser_verify_selector` workflow first.

#### 4. `parser_tester` ✨

**Purpose**: Test DataHen parsers using Ruby parser_tester.rb script.

**Key Features**:
- Tests parsers with HTML files or live URLs
- Enforces mandatory testing workflow (HTML first, then URL)
- Comprehensive error handling and troubleshooting guidance
- Integration with browser tools for HTML download workflow
- Support for variable passing and context management

**Usage**:
```javascript
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/details.rb",
  html_file: "<path>/product-page.html",  // Recommended: HTML first
  url: "https://example.com/product/123",  // Only after HTML testing
  vars: '{"category_name":"Electronics","rank":1}',
  page_type: "details",
  quiet: false
})
```

**Testing Workflow**:
1. **MANDATORY**: Test with HTML files first (`html_file` parameter)
2. **OPTIONAL**: Test with live URLs only after successful HTML testing
3. **RECOMMENDED**: Use `auto_download: true` for seamless HTML capture

**Features**:
- File validation (scraper directory, config.yaml, parser files)
- Intelligent error analysis and troubleshooting
- Variable passing for context management
- Page type specification for proper validation

### Standard Playwright Tools

The custom MCP also provides all standard Playwright MCP tools:

**Core Automation**:
- `browser_navigate` - Navigate to URLs
- `browser_snapshot` - Capture accessibility tree
- `browser_click` - Click elements
- `browser_type` - Type text
- `browser_evaluate` - Execute JavaScript
- `browser_screenshot` - Take screenshots
- `browser_network_requests` - Monitor network activity

**Tab Management**:
- `browser_tab_list` - List open tabs
- `browser_tab_new` - Open new tab
- `browser_tab_select` - Switch tabs
- `browser_tab_close` - Close tabs

**Other Tools**:
- `browser_hover` - Hover over elements
- `browser_select_option` - Select dropdown options
- `browser_file_upload` - Upload files
- `browser_wait_for` - Wait for conditions
- `browser_close` - Close browser session

### Tool Selection Protocol

**For Text Fields** (names, prices, descriptions):
```
1. browser_snapshot() → Get element ref
2. browser_inspect_element('Element', 'ref') → Get real CSS selector
3. browser_verify_selector('Element', 'real_selector', 'expected') → Verify
```

**For Non-Text Fields** (images, data attributes):
```
1. browser_snapshot() → Get element ref
2. browser_inspect_element('Element', 'ref') → Get real CSS selector
3. browser_evaluate(() => document.querySelector('selector')?.src) → Extract
```

**For Complex Structures** (last resort):
```
1. browser_view_html({includeScripts: false, isSanitized: true}) → Get HTML
2. Analyze HTML structure manually
3. Extract selectors from HTML analysis
```

### Integration with Workflow

The Playwright MCP Mod tools are integrated throughout the scraping workflow:

1. **Site Discovery** (`/scrape-site`):
   - Uses `browser_navigate` to visit target site
   - Uses `browser_snapshot` to analyze structure
   - Uses `browser_inspect_element` to discover navigation patterns

2. **Navigation Parser Generation** (`/create-navigation-parser`):
   - Uses `browser_verify_selector` to validate category/listings selectors
   - Uses `browser_evaluate` to detect pagination patterns
   - Uses `browser_network_requests` to find API endpoints

3. **Detail Parser Generation** (`/create-details-parser`):
   - Uses `browser_inspect_element` to discover product field selectors
   - Uses `browser_verify_selector` to validate text fields
   - Uses `browser_evaluate` to extract image URLs and data attributes
   - Uses `parser_tester` to test generated parsers

### Important Notes

**Playwright Refs Warning**:
- **NEVER** use Playwright refs (e.g., `e62`, `e425`) in CSS selectors
- Refs are internal handles for Playwright tools only
- **ALWAYS** call `browser_inspect_element` first to get real CSS selector
- Real selectors work in Ruby parsers; refs do not

**Selector Verification Limitations**:
- `browser_verify_selector` **ONLY** works for text-based content
- For images, data attributes, or URLs, use `browser_evaluate()` instead
- Semantic matching works for text, not for arbitrary attribute values

**HTML View Usage**:
- `browser_view_html` is a **last resort** tool
- High token consumption - use strategically
- Prefer element-by-element inspection workflow first
- Use when multiple inspection attempts fail

---

## Custom Commands System

### Command Architecture

Each command follows a **standard structure**:

1. **Description**: Short, clear purpose statement
2. **Prompt**: Detailed instructions with placeholders
3. **Input Parsing**: Extract parameters from `{{args}}`
4. **State Loading**: Read existing state files
5. **Execution**: Perform discovery/generation
6. **State Writing**: Save all findings
7. **Completion Report**: Display summary and next steps

### Phase 1: `/scrape-site`

**Purpose**: Site discovery and scraper directory setup.

**What it does**:
- Navigates to target website
- Analyzes site structure (categories, subcategories, listings)
- Discovers sample URLs for each page type
- Parses field specification (if provided)
- Generates initial `seeder/seeder.rb` and `config.yaml`

**Key Outputs**:
- `discovery-state.json` - Machine-readable site structure
- `discovery-knowledge.md` - Human-readable analysis
- `field-spec.json` - Field specification (if provided)
- `phase-status.json` - Workflow progress tracking

**Example**:
```bash
/scrape-site url="https://naivas.online" name=naivas_online spec="spec_general_sample.csv"
```

### Phase 2: `/create-navigation-parser`

**Purpose**: Generate navigation parsers (categories → subcategories → listings).

**What it does**:
- Reads discovery knowledge from Phase 1
- Analyzes navigation pages using browser tools
- Discovers CSS selectors for navigation elements
- Generates Ruby parsers (`categories.rb`, `subcategories.rb`, `listings.rb`)
- Tests each parser automatically
- Updates `config.yaml` with navigation parsers

**Key Features**:
- Handles popups/cookies automatically
- Discovers pagination patterns (standard, infinite scroll, load more)
- Preserves navigation context (vars flow)
- Tests parsers before completion

**Example**:
```bash
/create-navigation-parser scraper=naivas_online
```

### Phase 3: `/create-details-parser`

**Purpose**: Generate product detail parser.

**What it does**:
- Reads navigation knowledge and field specification
- Analyzes product detail pages using browser tools
- Discovers CSS selectors for each field (guided by field-spec.json)
- Generates `parsers/details.rb` with navigation context
- Tests parser automatically
- Updates `config.yaml` with details parser and CSV exporter

**Key Features**:
- Field-guided discovery (only discovers fields in spec)
- Navigation context integration (category, breadcrumb, rank)
- Automatic CSV exporter generation
- Comprehensive testing

**Example**:
```bash
/create-details-parser scraper=naivas_online
```

### Standalone Alternative: `/create-details-parser-standalone`

**Purpose**: End-to-end detail parser generation without navigation context.

**Use Case**: When you have a direct product URL and want to generate a parser quickly.

**Difference**: Doesn't require navigation parsers, works independently.

---

## Workflow Pipeline

### Complete Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ Phase 1: Site Discovery                                     │
│ /scrape-site url="..." name=... spec="..."                  │
│                                                              │
│ • Navigate to site                                          │
│ • Analyze structure                                         │
│ • Discover sample URLs                                      │
│ • Parse field spec                                          │
│ • Generate seeder & config                                  │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 2: Navigation Parsers                                 │
│ /create-navigation-parser scraper=...                       │
│                                                              │
│ • Read discovery knowledge                                  │
│ • Discover category selectors                              │
│ • Discover subcategory selectors (if needed)               │
│ • Discover listings & pagination                           │
│ • Generate & test parsers                                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ Phase 3: Detail Parser                                      │
│ /create-details-parser scraper=...                         │
│                                                              │
│ • Read navigation knowledge                                │
│ • Read field specification                                 │
│ • Discover product field selectors                         │
│ • Generate & test detail parser                            │
│ • Generate CSV exporter                                    │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
            ✅ Scraper Complete
            Ready for Deployment
```

### Auto-Chaining Support

**Feature**: Commands can automatically chain to the next phase.

**How it works**:
- Add `auto_next=true` parameter to any command
- Command completes current phase
- Closes browser session
- Detects shell type
- Spawns new console window
- Executes next command automatically

**Example**:
```bash
/scrape-site url="https://naivas.online" name=naivas_online auto_next=true
# Automatically runs /create-navigation-parser after completion
```

**Benefits**:
- Fully automated pipeline execution
- No manual intervention needed
- Each phase runs in separate session

---

## Technical Implementation

### Browser-First Workflow

**Core Principle**: Use Playwright MCP Mod tools to discover selectors before writing parser code.

**Workflow**:
1. **Navigate**: `browser_navigate(url)` - Navigate to target page
2. **Handle Popups**: Check for cookies/notifications, dismiss if needed
3. **Snapshot**: `browser_snapshot()` - Capture accessibility tree with element refs
4. **Inspect**: `browser_inspect_element(element, ref)` - **MANDATORY FIRST STEP** - Get real CSS selector
5. **Verify**: `browser_verify_selector(element, real_selector, expected)` - For text fields only
6. **Evaluate**: `browser_evaluate()` - For non-text attributes (images, data-*, URLs)
7. **Document**: Save selectors to state files

**Critical Rule**: Always use `browser_inspect_element` first to convert Playwright refs to real CSS selectors. Never use refs (e.g., `e62`) directly in CSS selectors.

**Critical Rules**:
- **NEVER** use Playwright refs (e.g., `e62`) in CSS selectors
- **ALWAYS** call `browser_inspect_element` first to get real selectors
- **ONLY** use `browser_verify_selector` for text-based fields
- **USE** `browser_evaluate` for images, data attributes, URLs

### Selector Discovery Protocol

**For Text Fields** (names, prices, descriptions):
```
1. browser_snapshot() → Get element ref (e.g., "Product name" [ref=e425])
2. browser_inspect_element('Product name', 'e425') → Get real CSS selector (e.g., '.product-title')
3. browser_verify_selector('Product name', '.product-title', 'Expected Product Name') → Verify
```

**For Non-Text Fields** (images, data attributes):
```
1. browser_snapshot() → Get element ref (e.g., "Product image" [ref=e123])
2. browser_inspect_element('Product image', 'e123') → Get real CSS selector (e.g., '.product-image img')
3. browser_evaluate(() => document.querySelector('.product-image img')?.src) → Extract URL
```

**Note**: `browser_verify_selector` ONLY works for text-based content. For images, data attributes, or URLs, always use `browser_evaluate()` instead.

### Popup Handling

**Mandatory**: After every `browser_navigate()`, check for and handle popups.

**Layered Approach**:
1. **Primary**: Use `browser_snapshot()` to detect popups in accessibility tree, then `browser_click()` with selector/ref
2. **Fallback**: If popup visible in screenshot but NOT in accessibility tree, use `browser_mouse_click_xy()` with coordinates

**Common Patterns**:
- Cookie banners: Click "Accept", "Accept All", "I Agree"
- Notifications: Click "Later", "Not Now", "Skip"
- Modals: Click close button (X), "Close", or overlay

**Tools Used**:
- `browser_screenshot()` - Visual inspection
- `browser_snapshot()` - Accessibility tree check
- `browser_click()` - Dismiss popups (selector-based, preferred)
- `browser_mouse_click_xy()` - Dismiss popups (coordinate-based, fallback when popup invisible to accessibility tree)

**Documentation**: See `.gemini/popup-handling-strategy.md` for complete strategy details.

### Field Specification System

**Purpose**: Define exactly which fields to extract from product pages.

**CSV Format**:
```csv
column_name,column_type,dev_notes
name,str,FIND
customer_price_lc,float,FIND - The listed price
has_discount,boolean,PROCESS - true if has discount
```

**Field Types**:
- `str` - String/text data
- `float` - Decimal numbers (prices)
- `boolean` - True/false values
- `int` - Whole numbers

**Extraction Methods**:
- **FIND**: Extract directly from page (requires selector discovery)
- **PROCESS**: Calculate from other data (computed fields)

**Storage**: Parsed and stored in `.scraper-state/field-spec.json` with discovered selectors.

### Ruby Parser Structure

**Reserved Variables** (DO NOT declare):
- `pages` - Pre-defined array for queuing pages
- `outputs` - Pre-defined array for extracted data
- `page` - Pre-defined hash with current page data
- `content` - Pre-defined string with HTML content

**Standard Pattern**:
```ruby
html = Nokogiri::HTML(content)  # content is pre-defined
vars = page['vars']              # page is pre-defined

# Extract fields using discovered selectors
name = html.at_css('.product-title')&.text&.strip

# Queue next pages (pages is pre-defined)
pages << {
  url: next_url,
  page_type: "details",
  vars: vars.merge({rank: idx + 1})
}

# Generate outputs (outputs is pre-defined)
outputs << {
  '_collection' => 'products',
  '_id' => product_id,
  'name' => name,
  # ... other fields
}

# Memory management (if needed)
save_pages if pages.count > 99
save_outputs if outputs.count > 99
```

### DataHen V3 Architecture

**Components**:
- **Seeder**: Initial page queue (`seeder/seeder.rb`)
- **Parsers**: Extract data and queue pages (`parsers/*.rb`)
- **Config**: YAML configuration (`config.yaml`)
- **Exporters**: Output data in various formats (CSV, JSON)

**Page Types**:
- `categories` - Category navigation pages
- `subcategories` - Subcategory pages
- `listings` - Product listing pages
- `details` - Product detail pages

**Variable Flow**:
```
Seeder → Categories → Subcategories → Listings → Details
         (base_url)   (category_name) (rank)     (all fields)
```

---

## State Management

### State File Structure

All state files stored in `.scraper-state/` directory:

```
.scraper-state/
├── phase-status.json          # Workflow progress
├── discovery-state.json       # Site structure (Phase 1)
├── discovery-knowledge.md     # Site analysis (Phase 1)
├── field-spec.json            # Field specification
├── navigation-selectors.json  # Navigation selectors (Phase 2)
├── navigation-knowledge.md    # Navigation docs (Phase 2)
├── detail-selectors.json      # Detail selectors (Phase 3)
├── detail-knowledge.md        # Detail docs (Phase 3)
└── browser-context.json       # Browser session state
```

### File Purposes

**JSON Files** (Machine-readable):
- `phase-status.json` - Tracks which phases are completed
- `discovery-state.json` - Site structure analysis
- `field-spec.json` - Field specification with selectors
- `navigation-selectors.json` - Navigation selector discoveries
- `detail-selectors.json` - Detail field selector discoveries
- `browser-context.json` - Last browser state

**Markdown Files** (Human-readable):
- `discovery-knowledge.md` - Site analysis documentation
- `navigation-knowledge.md` - Navigation parser documentation
- `detail-knowledge.md` - Detail parser documentation

### Reading State Files

**Critical**: Use `ReadManyFiles` (not `ReadFile`) for state files.

**Why**: State files are in `.gitignore`, so `ReadFile` fails.

**Pattern**:
```javascript
ReadManyFiles({
  patterns: [
    "generated_scraper/<scraper>/.scraper-state/phase-status.json",
    "generated_scraper/<scraper>/.scraper-state/discovery-state.json"
  ],
  target_directory: "<workspace_root>"
})
```

### Writing State Files

**Critical**: **ALL file writes MUST use ABSOLUTE PATHS**.

**Conversion Pattern**:
```
Relative: generated_scraper/<scraper>/.scraper-state/file.json
Absolute: <workspace_root>/generated_scraper/<scraper>/.scraper-state/file.json
Example: D:\DataHen\projects\gemini_cli_testbed\generated_scraper\naivas_online\.scraper-state\file.json
```

---

## Testing & Quality Assurance

### Automatic Parser Testing

**Tool**: `parser_tester` MCP tool (Playwright MCP Mod - DataHen integration)

**When**: Immediately after parser generation

**Modes**:
1. **Auto-Download** (Recommended): `auto_download: true` - Automatically downloads HTML from active browser tab
2. **HTML File**: `html_file: "<absolute_path>"` - Uses saved HTML file (MANDATORY for first test)
3. **Live URL**: `url: "<url>"` - Tests with live URL (ONLY after successful HTML testing)

**Example**:
```javascript
// Recommended: Auto-download from active browser tab
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/details.rb",
  page_type: "details",
  auto_download: true,  // Automatically downloads HTML from browser
  vars: '{"category_name":"Electronics","rank":1}',
  quiet: false
})

// Alternative: Use saved HTML file
parser_tester({
  scraper_dir: "<absolute_path>/generated_scraper/<scraper>",
  parser_path: "parsers/details.rb",
  html_file: "<absolute_path>/cache/product-page.html",
  vars: '{"category_name":"Electronics","rank":1}',
  quiet: false
})
```

**Features**:
- Comprehensive file validation (scraper directory, config.yaml, parser files)
- Intelligent error analysis and troubleshooting guidance
- Integration with browser tools for seamless HTML capture
- Support for variable passing and context management

### Testing Workflow

**For Each Parser**:
1. Generate parser code
2. Navigate to sample page (if not already there)
3. Handle popups if needed
4. Test with `parser_tester` (auto_download recommended)
5. Analyze results
6. Refine selectors if needed
7. Re-test until passing

### Quality Standards

**Selector Verification**:
- Each selector must pass `browser_verify_selector` with >90% match
- Test selectors on minimum 3 different pages
- Document verification results in parser comments

**Parser Requirements**:
- No reserved variable declarations (`pages = []`, `outputs = []`)
- Proper error handling with `rescue` clauses
- Memory management for large datasets (`save_pages`/`save_outputs`)
- Navigation context preservation (vars flow)

**Data Extraction**:
- Product name: >95% extraction rate
- Price information: Handle promotional pricing
- Images: Extract primary and secondary images
- Availability: Detect in-stock/out-of-stock status

---

## Best Practices & Guidelines

### Command Usage

1. **Always provide field spec**: Use `spec="spec_general_sample.csv"` for consistent extraction
2. **Test incrementally**: Each parser is tested automatically, but verify manually too
3. **Check state files**: Review `.scraper-state/` to understand discoveries
4. **Use resume capability**: If interrupted, use `resume-url` parameter
5. **Trust browser tools**: The browser-first workflow discovers reliable selectors

### Selector Discovery

1. **Always inspect first**: Use `browser_inspect_element` (Playwright MCP Mod) before verification
2. **Never use refs**: Playwright refs (e.g., `e62`) are NOT real DOM attributes - always convert to real CSS selectors
3. **Verify text fields**: Use `browser_verify_selector` (Playwright MCP Mod) for names, prices, descriptions
4. **Evaluate non-text**: Use `browser_evaluate` for images, data attributes (browser_verify_selector doesn't work for these)
5. **Test multiple pages**: Verify selectors work across different products
6. **Use HTML view sparingly**: `browser_view_html` (Playwright MCP Mod) is last resort due to high token usage

### Code Generation

1. **Never declare reserved variables**: `pages`, `outputs`, `page`, `content` are pre-defined
2. **Use absolute paths**: All file writes require absolute paths
3. **Include error handling**: Use `rescue` clauses for CSS operations
4. **Preserve context**: Pass vars through parser chain
5. **Memory management**: Use `save_pages`/`save_outputs` for large datasets

### State Management

1. **Read state first**: Always load existing state files before starting work
2. **Write everything**: Save all discoveries before completion
3. **Use ReadManyFiles**: For state files (ReadFile fails due to .gitignore)
4. **Absolute paths**: Convert relative paths to absolute before writing
5. **Document discoveries**: Write both JSON (machine) and Markdown (human) files

### Browser Automation

1. **Handle popups**: Check for cookies/notifications after every navigation
2. **Use snapshots**: `browser_snapshot()` to understand page structure
3. **Ignore console errors**: Focus on page content, not JavaScript errors
4. **Verify selectors**: Test selectors before using in parser code
5. **Document URLs**: Track all URLs accessed during discovery

---

## Troubleshooting

### Command Not Found

**Problem**: Custom command doesn't appear in Gemini CLI.

**Solutions**:
1. Check `.toml` file exists in `.gemini/commands/`
2. Verify TOML syntax (no unescaped backslashes)
3. Restart Gemini CLI to reload commands
4. Check file naming (must match command name)

### State Files Not Found

**Problem**: `ReadManyFiles` returns "ignored by project ignore files".

**Solutions**:
- This is **expected** - state files are in `.gitignore`
- The system handles this gracefully
- Missing files are normal for first run
- Use `ReadManyFiles` (not `ReadFile`) for state files

### Parser Testing Fails

**Problem**: `parser_tester` fails with errors.

**Solutions**:
1. Ensure `config.yaml` exists in scraper directory
2. Verify parser file exists and has valid Ruby syntax
3. Check that HTML file path is absolute (if using `html_file`)
4. Verify `scraper_dir` is absolute path
5. Check for reserved variable declarations (`pages = []`, etc.)

### Selector Verification Fails

**Problem**: `browser_verify_selector` returns low confidence.

**Solutions**:
1. Ensure you're using REAL CSS selector (not Playwright ref)
2. Call `browser_inspect_element` first to get real selector
3. Verify selector works with `browser_evaluate` first
4. Test on multiple pages to ensure consistency
5. Check for dynamic content (may need different approach)

### Auto-Chaining Fails

**Problem**: Next command doesn't execute automatically.

**Solutions**:
1. Verify `auto_next=true` parameter is provided
2. Check shell type detection (`.gemini/shell-info.json`)
3. Ensure Gemini CLI is in PATH
4. Check console window spawns correctly
5. Verify command syntax in spawned window

### Browser Popups Not Handled

**Problem**: Popups block page interaction.

**Solutions**:
1. Use `browser_screenshot()` to visually inspect
2. Use `browser_snapshot()` to check accessibility tree
3. Look for common selectors: `[id*="cookie"]`, `[class*="modal"]`
4. Try clicking "Accept", "Close", "Later" buttons
5. Use `browser_evaluate` to check for overlay elements

---

## Additional Resources

### Documentation Files

- **`.gemini/README.md`**: Command reference and quick start
- **`.gemini/FIELD-SPEC-SYSTEM.md`**: Field specification details
- **`.gemini/MODULAR-ARCHITECTURE.md`**: Architecture deep dive
- **`.gemini/RESUME-GUIDE.md`**: Resuming interrupted work
- **`.gemini/system.md`**: Operational rules (firmware layer)
- **`GEMINI.md`**: Strategic instructions (strategic layer)
- **`README - Playwright MCP Mod.md`**: Playwright MCP Mod documentation and tool reference

### Related Articles

The project includes articles about Gemini CLI customization:

- **`articles/article_3_system_instruction.md`**: System instruction override
- **`articles/article_4_structured_gemini.md`**: Structured approach to GEMINI.md
- **`articles/codelabs_10_gemini_md.md`**: Customizing with GEMINI.md
- **`articles/codelabs_11_custom_slash.md`**: Custom slash commands
- **`articles/cloud_custom_slash.md`**: Official custom commands guide

### External Resources

- **Gemini CLI**: https://github.com/google-gemini/gemini-cli
- **DataHen Platform**: https://datahen.com
- **Model Context Protocol**: https://modelcontextprotocol.io
- **Playwright**: https://playwright.dev
- **Playwright MCP Mod**: Custom MCP server (see `README - Playwright MCP Mod.md`)

---

## Conclusion

This project represents a **sophisticated AI agent system** for automated web scraping development. By combining:

- **Gemini CLI** for intelligent code generation
- **Custom commands** for specialized workflows
- **Browser automation** for selector discovery
- **State management** for resumability
- **Automatic testing** for quality assurance

It provides a **complete solution** for generating production-ready web scrapers with minimal manual intervention.

The **modular, session-independent architecture** ensures that work can be resumed, parallelized, and maintained across different development sessions, making it a robust and scalable solution for web scraping automation.

---

**Last Updated**: 2025-01-XX  
**Version**: 1.0.0  
**Maintainer**: DataHen Team
