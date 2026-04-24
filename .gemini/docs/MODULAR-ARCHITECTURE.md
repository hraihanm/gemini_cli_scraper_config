# Modular Architecture - Session Independence

## Overview

All three commands (`/scrape-site`, `/create-navigation-parser`, `/create-details-parser`) are now **completely modular and session-independent**. Each command:

1. **Reads state files** (no conversation history needed)
2. **Performs work** (discovery, parser generation)
3. **Writes ALL findings** to knowledge files
4. **Completes independently** with clear next steps

## Session Independence

**Gemini CLI Limitation:**
- ❌ No built-in session-to-session context passing
- ✅ Each session is independent
- ✅ State must be written to files for persistence

**Our Solution:**
- ✅ All knowledge written to `.scraper-state/` files
- ✅ Each command reads state files at start
- ✅ Commands can run in different sessions
- ✅ No conversation history required

## Knowledge Files Structure

```
generated_scraper/<scraper>/.scraper-state/
├── discovery-state.json          # Site structure + `_notes` (human summary)
├── navigation-selectors.json     # Selectors + `_notes`
├── detail-selectors.json         # Selectors + `_notes`
├── menu-state.json               # DHero menu phase + `_notes` (when applicable)
├── phase-status.json             # Overall progress tracking
└── browser-context.json          # Browser session state
```

(Legacy `*-knowledge.md` files may still exist from older runs.)

## Command Flow

### Phase 1: Site Discovery (`/scrape-site`)

**Reads:** Nothing (starts fresh)

**Writes:**
- `discovery-state.json` - Site structure (JSON) including `_notes`
- `phase-status.json` - Marks site_discovery complete
- `browser-context.json` - Browser state

**Completes with:** "Next: `/create-navigation-parser scraper=<name>`"

### Phase 2: Navigation Parsers (`/create-navigation-parser`)

**Reads:**
- `discovery-state.json` - Site structure (and `_notes`)
- `phase-status.json` - Check if already done

**Writes:**
- `parsers/categories.rb` - Category parser
- `parsers/subcategories.rb` - Subcategory parser (if needed)
- `parsers/listings.rb` - Listings parser
- `navigation-selectors.json` - Selectors (JSON) including `_notes`
- `phase-status.json` - Marks navigation_discovery complete

**Completes with:** "Next: `/create-details-parser scraper=<name>`"

### Phase 3: Detail Parser (`/create-details-parser`)

**Reads:**
- `navigation-selectors.json` - Navigation selectors (and `_notes`)
- `discovery-state.json` - Site structure (and `_notes`)
- `phase-status.json` - Check if already done

**Writes:**
- `parsers/details.rb` - Detail parser
- `detail-selectors.json` - Selectors (JSON) including `_notes`
- `phase-status.json` - Marks detail_discovery complete

**Completes with:** "Scraper complete! Ready for testing."

## Notes format (`_notes` in JSON)

Each phase's primary JSON state file includes a **`_notes`** string (markdown). It should cover:

1. **Completion Status** - When completed, what phase
2. **Discoveries** - What was found, selectors discovered
3. **Why/How** - Reasoning behind selector choices
4. **Edge Cases** - Special handling discovered
5. **Vars Flow** - How data flows between parsers
6. **Next Steps** - What command to run next

**Example (`navigation-selectors.json` → `_notes`):**
```markdown
# Navigation Parser Knowledge - naivas_online

**Completed**: 2025-01-XX 15:30:00
**Phase**: Navigation Discovery

## Parsers Generated

### Categories Parser
- **Selector**: `.category-item a`
- **Why**: Main navigation menu uses this class
- **Verified**: Yes, tested on 3 pages
- **Edge Cases**: Some have subcategories

## Vars Flow
- Categories → Listings: `category_name`, `breadcrumb`
- Listings → Details: `rank`, `page_number`

## Next Steps
Run: `/create-details-parser scraper=naivas_online`
```

## Usage Examples

### Complete Workflow (3 Sessions)

**Session 1:**
```bash
/scrape-site url="https://naivas.online" name=naivas_online
# Writes: discovery-state.json (with _notes)
# Completes: "Next: /create-navigation-parser scraper=naivas_online"
```

**Session 2 (New Session):**
```bash
/create-navigation-parser scraper=naivas_online
# Reads: discovery-state.json
# Writes: navigation-selectors.json (with _notes), parsers/*.rb
# Completes: "Next: /create-details-parser scraper=naivas_online"
```

**Session 3 (New Session):**
```bash
/create-details-parser scraper=naivas_online
# Reads: navigation-selectors.json, discovery-state.json
# Writes: detail-selectors.json (with _notes), parsers/details.rb
# Completes: "Scraper complete!"
```

### Resume After Interruption

**If interrupted during navigation parser:**
```bash
/create-navigation-parser scraper=naivas_online
# Reads phase-status.json, sees "in_progress"
# Resumes from checkpoint
# Completes normally
```

## Benefits

1. **Session Independence** - Commands work across sessions
2. **Knowledge Preservation** - All findings saved to files
3. **Resumability** - Can resume from any checkpoint
4. **Modularity** - Each command is self-contained
5. **Documentation** - Knowledge files serve as documentation
6. **No Token Bloat** - Each session starts fresh, reads files

## File-Based Communication

**Between Sessions:**
- Session 1 writes → Files
- Session 2 reads → Files
- No conversation history needed

**Between Commands:**
- Command A writes → Knowledge files
- Command B reads → Knowledge files
- Commands can run in different sessions

## Critical Requirements

Each command MUST:

1. ✅ **Read state files first** - Check what's already done
2. ✅ **Write ALL findings** - Before completion
3. ✅ **Write knowledge files** - Both JSON and Markdown
4. ✅ **Update phase status** - Mark phase complete
5. ✅ **Display next steps** - Clear instructions for continuation

## Summary

**All three commands are now:**
- ✅ Completely modular
- ✅ Session-independent
- ✅ File-based communication
- ✅ Self-contained
- ✅ Resumable
- ✅ Well-documented

**No conversation history needed - everything in files!**

