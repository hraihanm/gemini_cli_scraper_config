# Session Resumability Solution

## Problem Statement

When working on scraper generation, AI conversations can accumulate:
- Browser snapshots (high token usage)
- HTML analysis results
- Multiple selector discovery attempts
- Trial and error iterations

This can exceed token limits (137k tokens > 131k max), causing work to be lost.

## Current Infrastructure

**What Exists:**
- Scraper state files (`.scraper-state/`) - track generated scraper progress
- Phase status tracking - which parsers have been generated
- Selector files (navigation-selectors.json, detail-selectors.json)

**What's Missing:**
- Session state tracking - what the AI was doing when interrupted
- Progress summaries - what's been discovered/completed
- Resume instructions - how to continue in a new session

## Proposed Solution Architecture

### 1. Session Progress File

Create `generated_scraper/<scraper_name>/.scraper-state/session-progress.json`:

```json
{
  "session_id": "2025-01-XX-14-30-22",
  "scraper_name": "naivas_online",
  "current_task": "detail_parser_price_selectors",
  "started_at": "2025-01-XX 14:30:22",
  "last_activity": "2025-01-XX 15:45:10",
  
  "completed_discoveries": {
    "customer_price": {
      "status": "completed",
      "selector": "p.my-0.leading-none.flex.flex-col.md\\:flex-row.pb-0 > span.font-bold.text-naivas-green",
      "verified": true,
      "notes": "Customer price span inside p tag"
    },
    "base_price": {
      "status": "in_progress",
      "discovered_selectors": [],
      "current_hypothesis": "If no discount, base_price = customer_price. Need to find product with discount to verify selector."
    }
  },
  
  "current_url": "https://naivas.online/rina-vegetable-oil-5l",
  "current_product": "Rina Vegetable Oil 5L",
  "next_steps": [
    "Navigate to product with discount",
    "Inspect price elements",
    "Find base_price selector",
    "Update details.rb parser"
  ],
  
  "browser_context": {
    "last_url": "https://naivas.online/rina-vegetable-oil-5l",
    "last_snapshot_refs": {}
  },
  
  "discoveries_summary": "Customer price selector found: p > span.font-bold.text-naivas-green. Base price selector needs verification on discounted product.",
  
  "resume_instructions": "Navigate to https://naivas.online/rina-vegetable-oil-5l (or another discounted product), inspect price elements to find base_price selector pattern."
}
```

### 2. Progressive Checkpointing

**During Active Work:**

1. **After Each Selector Discovery:**
   - Immediately save selector to session-progress.json
   - Write to detail-selectors.json
   - Summarize: "Found customer_price selector: p > span.text-naivas-green"
   - Purge detailed browser snapshots from context

2. **After Each Product Analysis:**
   - Save product URL and findings
   - Update next_steps list
   - Clear browser HTML from context (keep only selectors)

3. **Before Complex Operations:**
   - If approaching token limit, save checkpoint
   - Generate resume instructions
   - Summarize current state

### 3. Resume Pattern

**When Starting New Session:**

User: "I hit token limit. Resume from session-state."

AI should:
1. Load latest session-progress.json
2. Read resume_instructions
3. Continue from where left off
4. Reference completed_discoveries (don't re-discover)

### 4. Focused Commands for Long Tasks

Create granular commands for detail parser work:

- `/discover-selector` - Focused command to find ONE selector
- `/verify-selectors` - Test multiple selectors
- `/update-parser` - Update parser file with discovered selectors

Each command is independent, small scope, resumable.

## Implementation Strategy

### Option A: Session State File (Recommended)

**How It Works:**
1. Commands automatically create/update `generated_scraper/<scraper>/.scraper-state/session-progress.json`
2. After each discovery, save immediately
3. On token limit hit, user can say "resume" → AI loads progress file
4. New session continues with full context from progress file

**Pros:**
- Automatic checkpointing
- Preserves all discoveries
- Clear resume path
- Works with any command

**Cons:**
- Requires commands to actively save progress
- Need to design progress file schema

### Option B: Manual Summary + Resume Instructions

**How It Works:**
1. Before hitting limit, AI generates resume instructions
2. User copies summary
3. In new session, user provides summary
4. AI continues from summary

**Pros:**
- Simple, no infrastructure needed
- User control over what to remember

**Cons:**
- Manual process
- Can lose details
- User must remember to ask for summary

### Option C: Hybrid Approach (Best Solution)

**Combine Both:**

1. **Automatic Session State File:**
   - Commands save discoveries immediately to progress file
   - Creates checkpoint after each major step

2. **Manual Resume Command:**
   - `/resume` command that loads latest progress
   - `/summary` command that generates human-readable summary
   - User can choose: auto-resume or manual resume with summary

3. **Progressive Summarization:**
   - After each discovery, summarize briefly
   - Keep detailed info in progress file
   - Keep only summaries in conversation context

## Quick Fix for Current Situation

**Right Now - For Your Price Selector Issue:**

You can resume manually:

1. **Check existing state files:**
   ```
   generated_scraper/naivas_online/.scraper-state/detail-selectors.json
   generated_scraper/naivas_online/.scraper-state/phase-status.json
   ```

2. **Manual Summary:**
   ```
   # Current Progress - Naivas Online Detail Parser
   
   ## Completed
   - Customer price selector found: `p.my-0.leading-none.flex.flex-col.md\:flex-row.pb-0 > span.font-bold.text-naivas-green`
   - Base price logic: If no discount, base_price = customer_price
   
   ## In Progress
   - Need to find base_price selector for discounted products
   - Currently analyzing: Rina Vegetable Oil 5L (https://naivas.online/rina-vegetable-oil-5l)
   - Need to check product with discount to verify base_price selector pattern
   
   ## Next Steps
   1. Navigate to discounted product (Rina Vegetable Oil or find another)
   2. Inspect price elements to find strikethrough/base price selector
   3. Update details.rb with base_price selector
   ```

3. **In New Session:**
   ```
   I'm working on naivas_online scraper. Current progress:
   - Customer price selector: p.my-0.leading-none... > span.font-bold.text-naivas-green
   - Need to find base_price selector by analyzing discounted product
   - Next: Navigate to https://naivas.online/rina-vegetable-oil-5l and inspect prices
   ```

## Recommended Implementation

**Phase 1: Immediate (Quick Fix)**
- Manual resume pattern (Option B)
- Users manually summarize when hitting limits
- Commands don't need changes

**Phase 2: Short-term (Enhanced)**
- Add `/summary` command to generate resume instructions
- Commands save selectors immediately to detail-selectors.json
- Add session-progress.json tracking

**Phase 3: Long-term (Full Solution)**
- Automatic checkpointing in all commands
- `/resume` command that auto-loads progress
- Progressive summarization to prevent token bloat

## Proposed Commands

### `/summary` - Generate Resume Instructions

Generates a concise summary of current work that can be used to resume.

**Usage:**
```
/summary scraper=naivas_online
```

**Output:**
```
Current Progress Summary:
- Scraper: naivas_online
- Phase: Detail Parser Development
- Completed: Customer price selector found
- In Progress: Base price selector discovery
- Current URL: https://naivas.online/rina-vegetable-oil-5l
- Next Steps: [1] Navigate to discounted product, [2] Find base_price selector

To resume: Provide this summary to continue where you left off.
```

### `/resume` - Auto-resume from Progress

Loads session-progress.json and continues work.

**Usage:**
```
/resume scraper=naivas_online
```

**Implementation:**
1. Find latest session-progress.json
2. Load completed_discoveries
3. Continue from next_steps
4. Don't re-do completed work

## Best Practices for Token Management

1. **Save Immediately:** After discovering a selector, save it to file immediately
2. **Summarize Frequently:** After each product/selector, create brief summary
3. **Purge HTML:** Don't keep full HTML in context - keep only selectors
4. **Use Files:** Save detailed findings to files, not conversation context
5. **Checkpoint Often:** Before complex operations, save progress

## Example: How It Would Work

**Session 1 (Before Limit):**
```
User: /create-details-parser scraper=naivas_online url=...

AI: Discovering selectors...
[Browser navigation, snapshots, HTML analysis]
Found customer_price: p > span.text-naivas-green
Saving to detail-selectors.json...
[More analysis...]
Token limit approaching - saving checkpoint...
```

**Session 2 (After Resume):**
```
User: /resume scraper=naivas_online

AI: Loading session progress...
Found previous work:
- Customer price selector: ✓ completed
- Base price selector: ⏳ in progress
- Current URL: https://naivas.online/rina-vegetable-oil-5l
Continuing from base price discovery...
[Navigates to product, continues analysis]
```

This provides full resumability across sessions!

