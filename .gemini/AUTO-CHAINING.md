# Auto-Chaining Feature

## Overview

The scraper generation commands now support automatic chaining to the next phase using the `auto_next=true` parameter. This allows you to run the entire scraper generation pipeline with a single command.

## How It Works

### Command Flow

```
/scrape-site url="..." name=scraper auto_next=true
  ↓ (auto-executes)
/create-navigation-parser scraper=scraper auto_next=true
  ↓ (auto-executes)
/create-details-parser scraper=scraper
  ↓ (complete)
```

### Implementation

When `auto_next=true` is provided:
1. Command completes its work
2. Displays completion summary
3. **CLOSE BROWSER**: Calls `browser_close()` MCP tool to close browser session
   - Required because browser session is tied to current console
   - New console cannot access existing browser (would spawn about:blank tabs)
4. **Spawn NEW console window** and execute next command:
   - Windows: Uses Windows Terminal (`wt`) or PowerShell for better color support
   - Linux/Mac: Uses `xterm` or `gnome-terminal`
5. The next command runs in a new Gemini CLI session but reads state files

### Parameters

**All commands support**:
- `auto_next=true|false` (OPTIONAL, default: false)
  - If `true`: Automatically execute next command after completion
  - If `false` or not provided: Display "Next Command" message and wait for user

## Usage Examples

### Full Auto-Chained Pipeline

```bash
# Start with auto-chaining enabled
/scrape-site url="https://naivas.online" name=naivas_online spec="spec_general_sample.csv" auto_next=true
```

This will:
1. ✅ Run site discovery
2. ✅ Auto-execute `/create-navigation-parser scraper=naivas_online auto_next=true`
3. ✅ Auto-execute `/create-details-parser scraper=naivas_online`
4. ✅ Complete entire scraper generation

### Manual Step-by-Step (Default)

```bash
# Step 1: Site discovery (no auto_next)
/scrape-site url="https://naivas.online" name=naivas_online spec="spec_general_sample.csv"

# Step 2: Navigation parsers (no auto_next)
/create-navigation-parser scraper=naivas_online

# Step 3: Detail parser
/create-details-parser scraper=naivas_online
```

### Partial Auto-Chaining

```bash
# Auto-chain from site discovery to navigation, but stop before details
/scrape-site url="https://naivas.online" name=naivas_online auto_next=true

# Then manually run details parser
/create-details-parser scraper=naivas_online
```

## Technical Details

### Execution Method

The auto-chaining spawns a **NEW console/terminal window** for each phase:

**CRITICAL: Browser Closing**
- **MUST close browser** before spawning new console using `browser_close()` MCP tool
- Browser session is tied to the current console
- New console cannot access existing browser session (will spawn about:blank tabs)
- Close browser first, then spawn new console

**Windows** (preferred order for color support):
```bash
# Option 1: Windows Terminal (wt) - BEST color support, preserves Gemini CLI formatting
wt -d . gemini -y "/create-navigation-parser scraper=<scraper>"

# Option 2: PowerShell - Good color support, better than CMD
start powershell -NoExit -Command "gemini -y '/create-navigation-parser scraper=<scraper>'"

# Option 3: CMD - Basic (fallback, less colorful)
start cmd /k "gemini -y \"/create-navigation-parser scraper=<scraper>\""
```

**Linux/Mac**:
```bash
xterm -e "gemini -y '/create-navigation-parser scraper=<scraper>'" &
# OR: gnome-terminal -- bash -c "gemini -y '/create-navigation-parser scraper=<scraper>'; exec bash"
```

Where:
- `browser_close()` - MCP tool to close browser session (REQUIRED first step)
- `wt -d .` (Windows Terminal) - Spawns new console with best color support
- `start powershell -NoExit` - PowerShell with good color support
- `start cmd /k` - Basic CMD (fallback, less colorful)
- `/k` (Windows CMD) - Keeps console open after command completes
- `gemini` - Gemini CLI command
- `-y` - Auto-confirm flag (no prompts)
- `/create-navigation-parser` - Next command to execute
- `scraper=<scraper>` - Passes scraper name to next command
- Current console stays open and completes naturally

### State File Continuity

Even though commands run in separate sessions, state files ensure continuity:
- Each command reads state files from `.scraper-state/` directory
- State files are written before completion
- Next command reads state files at start
- No conversation history needed

### Error Handling

If auto-chaining fails:
- The current command still completes successfully
- State files are still written
- User can manually run the next command
- Error message will indicate what failed

## Command-Specific Behavior

### `/scrape-site`
- **Next Command**: `/create-navigation-parser`
- **Auto-Chains To**: Navigation parser generation
- **Final Phase**: No (has next phase)

### `/create-navigation-parser`
- **Next Command**: `/create-details-parser`
- **Auto-Chains To**: Detail parser generation
- **Final Phase**: No (has next phase)

### `/create-details-parser`
- **Next Command**: None (this is the final phase)
- **Auto-Chains To**: N/A
- **Final Phase**: Yes (scraper generation complete)

## Benefits

1. **Faster Workflow**: Run entire pipeline with one command
2. **Less Manual Steps**: No need to copy/paste next command
3. **Consistent**: Always passes correct parameters
4. **Resumable**: Still uses state files, so can resume if interrupted
5. **Optional**: Default behavior unchanged (manual step-by-step)

## Limitations

1. **Browser Session**: Must close browser before spawning new console (prevents about:blank tabs)
2. **Shell Dependency**: Requires `gemini` CLI to be available in PATH
3. **New Console Windows**: Each chained command spawns a new console window
4. **Platform-Specific**: Uses Windows Terminal (`wt`), PowerShell, or CMD; Linux `xterm` or `gnome-terminal`
5. **Color Support**: Windows Terminal (`wt`) provides best color support; CMD is less colorful
6. **New Sessions**: Each chained command runs in a new Gemini CLI session
7. **Error Propagation**: If one phase fails, auto-chaining stops
8. **No Rollback**: If later phase fails, earlier phases are already complete
9. **Multiple Windows**: You'll have multiple console windows open (one per phase)

## Best Practices

1. **First Run**: Use manual step-by-step to verify each phase works
2. **Subsequent Runs**: Use `auto_next=true` for faster iteration
3. **Debugging**: Disable `auto_next` to inspect each phase individually
4. **Testing**: Test with `auto_next=false` first, then enable for production runs

## Troubleshooting

### Auto-chaining doesn't execute

**Check**:
- Is `gemini` CLI in your PATH?
- Did you provide `auto_next=true` parameter?
- Check shell command execution permissions

### Next command runs but fails

**Check**:
- State files exist in `.scraper-state/` directory
- Scraper name matches between commands
- Required prerequisites are met (e.g., discovery must complete before navigation)

### Commands run but in wrong order

**Note**: Commands are designed to be independent and read state files. Order is enforced by:
- State file existence checks
- Phase status validation
- Prerequisite validation

If you see this issue, check that state files are being written correctly.

