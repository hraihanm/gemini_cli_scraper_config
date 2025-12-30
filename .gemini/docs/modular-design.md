# Modular Command Design - Session Independence

## Core Principle

**Each command is completely independent** - it reads state files, performs work, writes ALL findings, and completes. No conversation history needed.

## State Files as Communication Channel

**Between Sessions:**
- Session 1: Writes findings to `.scraper-state/` files
- Session 2: Reads `.scraper-state/` files, continues work
- No conversation history needed - everything in files

**Between Commands:**
- Command A: Writes completion report
- Command B: Reads completion report, starts work
- Commands can run in different sessions

## Knowledge Files Structure

Each command writes comprehensive knowledge files before completion:

```
generated_scraper/<scraper>/.scraper-state/
├── discovery-state.json          # Site structure (from scrape-site)
├── discovery-knowledge.md         # Human-readable summary
├── navigation-selectors.json     # Selectors (from create-navigation-parser)
├── navigation-knowledge.md       # What was discovered, why, how
├── detail-selectors.json         # Selectors (from create-details-parser)
├── detail-knowledge.md           # Field discoveries, edge cases, notes
├── phase-status.json             # Overall progress
└── browser-context.json          # Browser state
```

## Command Completion Pattern

**Before ANY command completes:**

1. **Write Selector/State Files** (JSON - machine readable)
2. **Write Knowledge Files** (Markdown - human readable + AI readable)
3. **Write Completion Report** (What was done, what's next)
4. **Update Phase Status** (Mark phase complete)

**Knowledge File Format:**
```markdown
# Navigation Parser Knowledge - naivas_online

## Completed: [Date/Time]

## Discoveries

### Categories Parser
- **Selector Found**: `.category-item a`
- **Why This Selector**: Main navigation menu uses this class
- **Verified**: Yes, tested on 3 category pages
- **Edge Cases**: Some categories have subcategories (handled in subcategories parser)
- **Notes**: Categories page has 12 main categories

### Listings Parser
- **Selector Found**: `.product-card a`
- **Pagination Pattern**: Query parameter `?page=2`
- **Products Per Page**: 24
- **Verified**: Yes, tested pagination through 3 pages
- **Edge Cases**: Last page has fewer products (handled with conditional)

## Vars Flow
- Categories → Listings: `category_name`, `breadcrumb`
- Listings → Details: `category_name`, `breadcrumb`, `rank`, `page_number`

## Next Steps for Detail Parser
- Use sample URLs from `sample_detail_urls` array
- Expect vars: `category_name`, `breadcrumb`, `rank`, `page_number`
- Product ID extraction: Use SKU from `data-product-id` attribute
```

## Command Independence Rules

1. **Read State Files First** - Never assume conversation context
2. **Write All Findings** - Before completion, write everything discovered
3. **Idempotent** - Can run multiple times safely (checks state first)
4. **Self-Contained** - All needed info in state files
5. **Clear Completion** - Write what's done, what's next, how to continue

## Example: Modular Flow

**Session 1:**
```
/scrape-site url="https://naivas.online" name=naivas_online
→ Writes: discovery-state.json, discovery-knowledge.md
→ Completes: "Site discovery complete. Next: /create-navigation-parser scraper=naivas_online"
```

**Session 2 (New Session):**
```
/create-navigation-parser scraper=naivas_online
→ Reads: discovery-state.json, discovery-knowledge.md
→ Writes: navigation-selectors.json, navigation-knowledge.md
→ Completes: "Navigation parsers complete. Next: /create-details-parser scraper=naivas_online"
```

**Session 3 (New Session):**
```
/create-details-parser scraper=naivas_online
→ Reads: navigation-selectors.json, navigation-knowledge.md, discovery-knowledge.md
→ Writes: detail-selectors.json, detail-knowledge.md
→ Completes: "Detail parser complete. Scraper ready for testing."
```

**No conversation history needed - everything in files!**

