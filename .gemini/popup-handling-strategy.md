# Popup Handling Strategy - Coordinate-Based Clicking Fallback

**Created**: 2024-12-19  
**Status**: Active Implementation  
**Purpose**: Handle popups/cookies/notifications that are invisible to accessibility tree but visible in screenshots

---

## Problem Statement

Some websites implement popups (cookie banners, notifications, modals) that are:
- **Visible** in screenshots (visual rendering)
- **Invisible** to `browser_snapshot()` (accessibility tree)
- **Blocking** page interaction until dismissed

This creates a challenge: we can see the popup visually but cannot interact with it using standard selector-based clicking because it doesn't appear in the accessibility tree.

---

## Solution: Layered Popup Handling Approach

### Primary Approach: Selector-Based Clicking (Preferred)

**When to use**: Popup appears in `browser_snapshot()` accessibility tree

**Workflow**:
1. `browser_navigate(url)`
2. `browser_snapshot()` → Check for popup elements
3. If popup found: `browser_click(element, ref)` or `browser_click(element, selector)`
4. `browser_snapshot()` → Verify popup dismissed

**Advantages**:
- Most reliable method
- Works across viewport sizes
- Survives responsive design changes
- Standard Playwright MCP tool (no special capabilities needed)

### Fallback Approach: Coordinate-Based Clicking

**When to use**: Popup visible in screenshot BUT NOT in `browser_snapshot()` accessibility tree

**Workflow**:
1. `browser_navigate(url)`
2. `browser_screenshot()` → Visual inspection
3. `browser_snapshot()` → Check accessibility tree
4. If popup visible in screenshot BUT NOT in snapshot:
   - Analyze screenshot (AI vision) to identify button location
   - Extract coordinates (x, y) from button center region
   - `browser_mouse_click_xy("Accept button", x, y)` → Click by coordinates
5. `browser_snapshot()` → Verify popup dismissed

**Tool Requirements**:
- `browser_mouse_click_xy` requires `--caps=vision` capability flag
- Available in Playwright MCP Mod (opt-in capability)

**Advantages**:
- Works when accessibility tree fails
- Handles visually-rendered but DOM-hidden popups
- Last resort when selector-based approach fails

**Disadvantages**:
- Viewport-dependent (coordinates change with window size)
- Fragile (responsive design can break coordinates)
- Less reliable than selector-based clicking
- Requires vision capability flag

---

## Implementation Details

### Coordinate Extraction Guidelines

**Button Location Analysis**:
- Look for common button patterns:
  - "Accept", "Accept All", "I Agree" (cookie banners)
  - "Later", "Not Now", "Skip" (notifications)
  - Close button (X) typically top-right corner
  - Overlay backgrounds (click to dismiss)

**Coordinate Selection**:
- **Click center** of button region, not edge
- Account for button padding/margins
- Prefer center coordinates over corner coordinates
- Coordinates are viewport-relative (not page-relative)

**Retry Strategy**:
- If coordinate click fails, retry with slight offset (±5px)
- Maximum 2 coordinate-click attempts per popup
- If both attempts fail, log error and continue (don't block workflow)

### Verification Protocol

**After Any Popup Dismissal**:
1. Always call `browser_snapshot()` to verify popup dismissed
2. Check that page content is now accessible
3. Verify no blocking overlays remain

**Failure Handling**:
- If popup persists after coordinate click:
  - Log failure in discovery-knowledge.md
  - Document coordinates attempted
  - Continue workflow (don't block)
  - Note for manual intervention if needed

---

## Logging and Documentation

### When Coordinate Clicks Are Used

**Documentation Requirements**:
- Log in appropriate knowledge file:
  - `discovery-knowledge.md` (for site discovery phase)
  - `navigation-knowledge.md` (for navigation parser phase)
  - `detail-knowledge.md` (for detail parser phase)

**Information to Log**:
```markdown
## Popup Handling - Coordinate-Based Click

**Date**: <timestamp>
**URL**: <page_url>
**Popup Type**: Cookie banner / Notification / Modal
**Button Text**: "Accept" / "Later" / etc.
**Coordinates Used**: (x, y)
**Viewport Size**: <width>x<height>
**Result**: Success / Failed (with retry attempts)
**Notes**: Any relevant observations
```

### Example Log Entry

```markdown
## Popup Handling - Coordinate-Based Click

**Date**: 2024-12-19 14:30:00
**URL**: https://example.com/products
**Popup Type**: Cookie banner
**Button Text**: "Accept All Cookies"
**Coordinates Used**: (960, 850)
**Viewport Size**: 1920x1080
**Result**: Success (first attempt)
**Notes**: Cookie banner was visible in screenshot but not in accessibility tree. 
Coordinate click successfully dismissed popup. Button was centered in bottom banner.
```

---

## Tool Reference

### Playwright MCP Mod Tools Used

**Standard Tools** (always available):
- `browser_navigate(url)` - Navigate to page
- `browser_screenshot()` - Capture visual state
- `browser_snapshot()` - Get accessibility tree
- `browser_click(element, ref)` - Click by element reference
- `browser_click(element, selector)` - Click by CSS selector

**Coordinate-Based Tools** (requires `--caps=vision`):
- `browser_mouse_click_xy(element, x, y)` - Click at coordinates
- `browser_mouse_move_xy(element, x, y)` - Move mouse to coordinates
- `browser_mouse_drag_xy(element, startX, startY, endX, endY)` - Drag between coordinates

**Tool Availability**:
- Coordinate-based tools are opt-in via `--caps=vision` flag
- Check Playwright MCP Mod configuration for vision capability
- Standard tools work without special capabilities

---

## Best Practices

### Priority Order

1. **Always try selector-based approach first**
   - More reliable
   - Survives responsive design changes
   - Standard tool usage

2. **Use coordinate-based as last resort**
   - Only when popup invisible to accessibility tree
   - Document when used
   - Verify dismissal after click

3. **Never block workflow**
   - If coordinate click fails twice, log and continue
   - Don't halt scraper generation for popup issues
   - Note for manual intervention if critical

### Quality Gates

- **Maximum attempts**: 2 coordinate-click attempts per popup
- **Verification required**: Always verify popup dismissal after click
- **Documentation required**: Log coordinate clicks in knowledge files
- **Failure tolerance**: Continue workflow even if popup persists

### Testing Considerations

- Test on different viewport sizes if possible
- Document viewport size when using coordinates
- Retry with offset if first attempt fails
- Verify popup dismissal before proceeding

---

## Integration Points

### Command Files Updated

All scraper generation commands now include enhanced popup handling:

- **`/scrape-site`**: Site discovery phase popup handling + **documents successful strategy in discovery-state.json**
- **`/create-navigation-parser`**: Navigation parser phase popup handling (categories, subcategories, listings) + **reads popup_handling from discovery-state.json**
- **`/create-details-parser`**: Detail parser phase popup handling + **reads popup_handling from discovery-state.json**
- **`/create-details-parser-standalone`**: Standalone detail parser popup handling

### Workflow Integration

**Popup handling occurs**:
- After every `browser_navigate()` call
- Before page analysis begins
- Before selector discovery starts
- Before parser testing

**Verification occurs**:
- After popup dismissal (selector-based or coordinate-based)
- Before proceeding to next step
- Ensures page is ready for interaction

### Discovery State Integration

**Site Discovery Phase** (`/scrape-site`):
- Discovers and documents successful popup handling strategy
- Stores in `discovery-state.json` under `popup_handling` section:
  - `successful_selectors`: Array of working selectors/refs
  - `coordinate_clicks`: Array of working coordinates (if used)
  - `handling_method`: "selector_based" | "coordinate_based" | "none"

**Later Phases** (`/create-navigation-parser`, `/create-details-parser`):
- **Read** `popup_handling` from `discovery-state.json`
- **Try documented strategy first** before discovering new approach
- **Reuse** successful selectors/coordinates from site discovery
- **Fallback** to discovery if documented strategy fails

**Benefits**:
- Consistent popup handling across all phases
- Faster execution (reuse known working strategy)
- Reduced discovery overhead in later phases
- Better reliability (proven working approach)

---

## Troubleshooting

### Common Issues

**Issue**: Coordinate click doesn't dismiss popup
- **Solution**: Retry with ±5px offset
- **Solution**: Verify viewport size matches expected
- **Solution**: Check if popup moved or changed

**Issue**: Popup reappears after dismissal
- **Solution**: May need to handle multiple popups
- **Solution**: Check for multiple overlay layers
- **Solution**: Verify dismissal with snapshot

**Issue**: Coordinates work on one viewport but not another
- **Solution**: Document viewport size in logs
- **Solution**: Prefer selector-based approach when possible
- **Solution**: Consider responsive design variations

### Debugging Tips

- Always take screenshot before coordinate click (for debugging)
- Log exact coordinates used (for reproducibility)
- Document viewport size (for context)
- Note button appearance (for pattern recognition)

---

## Future Enhancements

### Potential Improvements

1. **Pattern Recognition**: Learn common popup patterns and button locations
2. **Viewport Normalization**: Normalize coordinates across viewport sizes
3. **Retry Strategies**: Smarter retry with multiple coordinate offsets
4. **Popup Detection**: Better detection of popup presence/absence
5. **Selector Discovery**: Attempt to discover selectors even for invisible popups

### Research Areas

- DOM manipulation to make popups accessible
- JavaScript execution to dismiss popups programmatically
- Network request interception for popup-related API calls
- Cookie/localStorage manipulation to prevent popup display

---

## References

- **Playwright MCP Mod**: `README - Playwright MCP Mod.md`
- **Project Documentation**: `PROJECT_DOCUMENTATION.md`
- **Command Files**: `.gemini/commands/*.toml`
- **System Instructions**: `.gemini/system.md`

---

## Changelog

**2024-12-19**: Initial implementation
- Added coordinate-based clicking fallback
- Updated all command files with enhanced popup handling
- Created comprehensive documentation

---

## Status

✅ **Active**: This strategy is actively implemented in all scraper generation commands  
✅ **Tested**: Coordinate-based clicking works when accessibility tree fails  
✅ **Documented**: Full documentation in this file and command files  
✅ **Logged**: Coordinate clicks are documented in knowledge files
