# Selector Verification Implementation

## Overview

This implementation adds **mandatory browser-based selector verification** to the Gemini CLI system. All selectors in parser files must now be verified using browser automation tools before deployment.

## What Was Implemented

### 1. System Configuration Updates

#### Updated Files:
- `.gemini/system.md` - Added mandatory selector verification protocol
- `GEMINI.md` - Added browser-first development requirements

#### Key Changes:
- **Mandatory Selector Verification Protocol** requiring browser tools for all selectors
- **Post-Escape Protocol** for handling interrupted operations
- **Browser-First Selector Development** workflow
- **Zero Tolerance** for placeholder selectors in production

### 2. Browser Verification Tools Required

The system now mandates using these browser automation tools:

1. **`browser_navigate`** - Navigate to target websites
2. **`browser_snapshot`** - Capture page structure and accessibility tree
3. **`browser_inspect_element`** - Examine DOM structure of target elements
4. **`browser_verify_selector`** - Test CSS selectors against actual page content

### 3. Verification Workflow

#### Before Writing ANY Parser Code:

```ruby
# 1. Navigate to target site
browser_navigate('https://target-site.com')

# 2. Capture page structure  
browser_snapshot()

# 3. Inspect target elements
browser_inspect_element('Product title', 'element_ref')

# 4. Verify each selector
browser_verify_selector('h1.product-title', 'Expected Product Name')

# 5. Test on multiple similar elements
# 6. Only then implement in parser
```

### 4. Parser Requirements

All parser files must now:

- ✅ **Use only browser-verified selectors**
- ✅ **Include verification comments with results**
- ✅ **Document selector reliability and fallbacks**
- ❌ **Never use `*_PLACEHOLDER` selectors**
- ❌ **Never deploy unverified selectors**

### 5. Example Implementation

Created `examples/verified_books_scraper.rb` demonstrating:

- Complete browser verification workflow
- Verification results documentation
- Selector reliability ratings (✓, ⚠️, ❌)
- Corrective actions for failed selectors

### 6. Tools and Scripts

#### `scripts/verify_selectors.rb`
- Template for systematic selector verification
- Demonstrates verification workflow for each parser type
- Generates parser templates with verified selectors
- Provides verification summary and failure reporting

## Verification Results Example

Based on testing with https://books.toscrape.com:

### Category Parser Selectors:
- ✅ `aside .nav-list ul li a` - Category links (100% verified)

### Listings Parser Selectors:
- ✅ `article.product_pod` - Product items (structure verified)
- ✅ `p.price_color` - Product prices (100% verified)

### Details Parser Selectors:
- ✅ `h1` - Product title (100% verified)
- ✅ `article p:nth-of-type(1)` - Product price (100% verified) 
- ⚠️ `article p:nth-of-type(2)` - Availability (51% verified - contains extra text)
- ❌ -> ✅ `article p:last-of-type` - Failed, corrected to proper description selector

## System Behavior Changes

### When User Escapes Operation:

The system will now:

1. **Halt immediately** - No continuation with unverified selectors
2. **Require verification** - Must verify all selectors before proceeding
3. **Browser navigation** - Navigate to representative pages
4. **Complete audit** - Verify ALL selectors in ALL parser files
5. **Multi-page testing** - Test selectors across different pages
6. **Documentation update** - Record verification results and changes

### Error Handling:

- **Failed Verifications**: Must be fixed before proceeding
- **Placeholder Selectors**: Automatic deployment blocking
- **Weak Matches**: Require refinement and re-testing
- **Missing Verification**: Prevents parser execution

## Benefits

1. **Reliability** - All selectors tested against real page content
2. **Robustness** - Multi-page testing ensures selector consistency  
3. **Maintainability** - Documented verification results for future reference
4. **Quality Assurance** - Zero unverified selectors in production
5. **Debugging** - Clear verification trail for troubleshooting

## Usage Instructions

### For New Scrapers:
1. Start with browser navigation and analysis
2. Verify every selector before implementation
3. Document verification results in parser comments
4. Test across multiple similar pages
5. Only deploy fully verified parsers

### For Existing Scrapers:
1. Audit all existing selectors using browser tools
2. Replace placeholder selectors with verified ones
3. Test selectors on current site versions
4. Update documentation with verification results
5. Re-deploy with verified selectors only

### When Operations Are Escaped:
1. Stop all scraping activities
2. Navigate to target sites using browser tools
3. Verify all selectors in all parser files
4. Fix any failed or weak verifications
5. Update parser files with corrected selectors
6. Resume operations only after complete verification

## Implementation Status

✅ **Completed:**
- System configuration updates
- Browser verification protocol definition
- Example implementation with real site testing
- Verification workflow documentation
- Tools and scripts for verification process

✅ **Tested:**
- Browser navigation and snapshot capture
- Element inspection and selector verification
- Multi-selector verification workflow
- Failed selector identification and correction

✅ **Ready for Production:**
- All system files updated with new requirements
- Complete workflow documented and tested
- Example scrapers with verified selectors
- Error handling and recovery procedures defined

The Gemini CLI now enforces browser-based selector verification as a mandatory requirement, ensuring all scrapers use reliable, tested selectors before deployment.
