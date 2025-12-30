# Issues Analysis & Recommendations

## Issue 1: browser-context.json Location

### Current State
- **File Location**: `.gemini/browser-context.json` (global, project-level)
- **Content**: Contains `last_scraper_name: "lulu_sa"` - mixing contexts from different scrapers
- **Problem**: Browser context should be per-scraper, not global

### Why This Is Wrong
1. **Multiple Scrapers**: If working on multiple scrapers, contexts get mixed
2. **Architecture Mismatch**: Architecture docs specify `.scraper-state/browser-context.json` (per-scraper)
3. **Resumability**: Each scraper needs its own browser state for proper resumption
4. **State Isolation**: Scraper state should be isolated in `.scraper-state/` directory

### Current Implementation
- Commands say "Save browser-context.json (USE ABSOLUTE PATH)" but don't specify exact path
- Path ambiguity leads to wrong location

### Recommendation
**Move to**: `generated_scraper/<scraper>/.scraper-state/browser-context.json`

**Benefits**:
- ✅ Per-scraper isolation
- ✅ Matches architecture specification
- ✅ Consistent with other state files
- ✅ Proper resumability per scraper

**Changes Needed**:
1. Update all three commands to specify exact path: `generated_scraper/<scraper>/.scraper-state/browser-context.json`
2. Update examples to show correct path
3. Add note about scraper-specific location

---

## Issue 2: Reserved Variables Declaration

### Current State
- Agent occasionally declares `pages = []` in parser code
- This breaks the parser because `pages` is a pre-defined reserved variable
- Issue is **occasional** - sometimes works, sometimes doesn't

### Why This Happens
1. **Not Emphasized Enough**: Reserved variables mentioned in system.md but not prominently in command prompts
2. **Assumption**: Agent may assume arrays need initialization
3. **Inconsistent**: Works sometimes (naivas.online) but fails other times (lulu_sa)
4. **Missing Validation**: No explicit check before writing parser code

### Reserved Variables (from system.md)
- `pages` - Pre-defined array, use `pages << {...}` directly
- `outputs` - Pre-defined array, use `outputs << {...}` directly
- `page` - Pre-defined hash, current page data
- `content` - Pre-defined string, HTML content

### What's Wrong
```ruby
# ❌ WRONG - Don't declare reserved variables
pages = []  # This breaks the parser!
categories.each do |category|
  pages << {...}
end
```

### What's Right
```ruby
# ✅ CORRECT - Use reserved variables directly
categories.each do |category|
  pages << {...}  # pages is already defined
end
```

### Recommendation
**Add Explicit Warnings in All Commands**:

1. **Before Parser Generation Section**:
   - Add prominent "🚨 FORBIDDEN: Reserved Variables" section
   - List all reserved variables
   - Show wrong vs. right examples
   - Add validation step before writing code

2. **In Parser Code Examples**:
   - Remove any `pages = []` declarations
   - Add comments: "# pages is pre-defined, don't declare it"
   - Show direct usage: `pages << {...}`

3. **Validation Step**:
   - Before writing parser code, scan for reserved variable declarations
   - If found, remove them before saving

**Changes Needed**:
1. Add "FORBIDDEN: Reserved Variables" section to all three commands
2. Update parser code examples to never show `pages = []` or `outputs = []`
3. Add validation step in parser generation sections
4. Emphasize in system.md (already there, but strengthen)

---

## Implementation Plan

### Phase 1: browser-context.json Fix
1. Update `scrape-site.toml`:
   - Change path to: `generated_scraper/<scraper>/.scraper-state/browser-context.json`
   - Update examples

2. Update `create-navigation-parser.toml`:
   - Change path to: `generated_scraper/<scraper>/.scraper-state/browser-context.json`
   - Update examples

3. Update `create-details-parser.toml`:
   - Change path to: `generated_scraper/<scraper>/.scraper-state/browser-context.json`
   - Update examples

### Phase 2: Reserved Variables Enforcement
1. Add "FORBIDDEN: Reserved Variables" section to all commands:
   - Before parser generation steps
   - Prominent warning with examples
   - Validation checklist

2. Update parser code examples:
   - Remove any `pages = []` or `outputs = []` declarations
   - Add comments explaining reserved variables
   - Show correct usage patterns

3. Add validation step:
   - Before writing parser code, check for reserved variable declarations
   - Remove if found

---

## Questions for Discussion

1. **browser-context.json**:
   - ✅ Move to `.scraper-state/` - Agreed?
   - Should we delete the global `.gemini/browser-context.json`?

2. **Reserved Variables**:
   - ✅ Add explicit warnings - Agreed?
   - Should we add a pre-generation validation step?
   - Should we add this to system.md more prominently?

3. **Implementation Priority**:
   - Which should be fixed first?
   - Should both be done together?

