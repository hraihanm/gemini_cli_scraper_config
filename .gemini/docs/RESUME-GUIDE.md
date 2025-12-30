# Quick Resume Guide - Token Limit Recovery

## Current Situation

You hit the token limit while working on price selectors for `naivas_online` scraper.

## What We Know (From Context)

**Completed:**
- ✅ Customer price selector found: `p.my-0.leading-none.flex.flex-col.md\:flex-row.pb-0 > span.font-bold.text-naivas-green`
- ✅ Base price logic understood: If no discount, `base_price = customer_price`

**In Progress:**
- 🔄 Finding base_price selector for discounted products
- Current product: Rina Vegetable Oil 5L
- Current URL: https://naivas.online/rina-vegetable-oil-5l

**Next Steps:**
1. Navigate to discounted product (Rina Vegetable Oil 5L or find another with visible discount)
2. Inspect price elements to find strikethrough/base price selector
3. Update details.rb parser with discovered base_price selector

## How to Resume

### Option 1: Manual Resume (Quick)

**In New Session, Provide This:**

```
I'm working on naivas_online scraper detail parser.

Completed:
- Customer price selector: p.my-0.leading-none.flex.flex-col.md\:flex-row.pb-0 > span.font-bold.text-naivas-green
- Base price logic: If no discount, base_price = customer_price

Current task:
Finding base_price selector for discounted products. Need to analyze a product with discount.

Next steps:
1. Navigate to https://naivas.online/rina-vegetable-oil-5l (or find discounted product)
2. Inspect price elements to find strikethrough/base price selector
3. Update parsers/details.rb with base_price selector

Continue from here.
```

### Option 2: Use Resume Command

**First:** Create summary (if command exists):
```
/create-summary scraper=naivas_online
```

**Then in new session:**
```
/resume-work scraper=naivas_online
```

### Option 3: Direct Continue

**Navigate and Continue:**

1. Navigate to discounted product:
   ```
   Navigate to https://naivas.online/rina-vegetable-oil-5l
   ```

2. Inspect price elements:
   ```
   Use browser_snapshot and browser_inspect_element to find base_price selector
   ```

3. Update parser:
   ```
   Update parsers/details.rb with the discovered base_price selector
   ```

## File Locations

- Scraper: `generated_scraper/naivas_online/`
- Detail parser: `generated_scraper/naivas_online/parsers/details.rb`
- **State directory**: `generated_scraper/naivas_online/.scraper-state/`
  - `detail-selectors.json` - Discovered selectors (CHECK THIS FIRST)
  - `phase-status.json` - Completed phases
  - `navigation-selectors.json` - Navigation selectors (if exists)
  - `session-progress.json` - Session resume info (if created)
  - `browser-context.json` - Browser state

## Tips for Future Sessions

1. **Save Selectors Immediately:** After discovering a selector, it's already saved to `detail-selectors.json` - check that file first
2. **Check Generated Files:** Look at `parsers/details.rb` to see current state
3. **Use State Files:** Check `.scraper-state/` directory for progress tracking
4. **Create Summaries:** Before hitting limits, create summary with `/create-summary`

## Resume Pattern for Price Selectors

```ruby
# Current state in details.rb:
customer_price = text_of(html.at_css('p.my-0.leading-none.flex.flex-col.md\\:flex-row.pb-0 > span.font-bold.text-naivas-green'))

# Need to find base_price selector
# Logic: base_price = base_price_element || customer_price

# Steps:
# 1. Find product with discount (Rina Vegetable Oil 5L)
# 2. Inspect strikethrough price element
# 3. Get selector (likely: p.text-naivas-red or similar)
# 4. Update parser
```

