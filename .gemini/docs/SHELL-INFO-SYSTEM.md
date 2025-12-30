# Shell Info Storage System

## Overview

To avoid detecting shell type on every command execution, the system stores shell type information in `.gemini/shell-info.json`. This file is created once and reused by all commands.

## File Location

**Path**: `.gemini/shell-info.json` (global, not per-scraper)

**Why global?**
- Shell type is system-wide, not scraper-specific
- All commands can share the same shell type information
- More efficient than per-scraper storage

## File Structure

```json
{
  "shell_type": "PowerShell",
  "detected_at": "2025-11-06T20:30:00Z",
  "detection_method": "PSVersionTable",
  "spawn_command_template": "start powershell -NoExit -Command \"cd '$PWD'; `$env:PATH='$env:PATH'; {command}\""
}
```

### Fields

- **`shell_type`**: Detected shell type (`"PowerShell"`, `"CMD"`, `"WSL"`, `"Linux"`, `"Mac"`)
- **`detected_at`**: ISO timestamp when shell type was detected
- **`detection_method`**: How shell was detected (`"PSVersionTable"`, `"COMSPEC"`, `"WSL_DISTRO_NAME"`, `"SHELL"`)
- **`spawn_command_template`**: Template command for spawning new console (with `{command}` placeholder)

## Detection Logic

### First Run (File Doesn't Exist)

1. **Check for PowerShell**:
   - Execute: `if ($PSVersionTable) { "PowerShell" }`
   - If PowerShell detected: Store `shell_type: "PowerShell"`

2. **Check for CMD** (if not PowerShell):
   - Check: `%COMSPEC%` contains `cmd.exe`
   - If CMD detected: Store `shell_type: "CMD"`

3. **Check for WSL** (if not PowerShell/CMD):
   - Check: `$WSL_DISTRO_NAME` exists or running in WSL
   - If WSL detected: Store `shell_type: "WSL"`

4. **Check for Linux/Mac** (if not Windows):
   - Check: `$SHELL` variable
   - If Linux/Mac detected: Store `shell_type: "Linux"` or `"Mac"`

5. **Store to `.gemini/shell-info.json`** (USE ABSOLUTE PATH)

### Subsequent Runs (File Exists)

1. **Read `.gemini/shell-info.json`** (USE ABSOLUTE PATH)
2. **Extract `shell_type`** from JSON
3. **Use stored shell type** (no detection needed)
4. **Use `spawn_command_template`** if available, or construct command based on `shell_type`

## Usage in Commands

### All Commands Follow This Pattern

```javascript
// Step 1: Try to load shell-info.json
ReadFile({
  absolute_path: "<workspace_root>/.gemini/shell-info.json"
})

// Step 2: If file exists, use stored shell_type
if (shell_info_exists) {
  shell_type = shell_info['shell_type']
  spawn_template = shell_info['spawn_command_template']
} else {
  // Step 3: Detect shell type
  shell_type = detect_shell_type()
  
  // Step 4: Store to shell-info.json
  WriteFile({
    absolute_path: "<workspace_root>/.gemini/shell-info.json",
    content: JSON.stringify({
      shell_type: shell_type,
      detected_at: new Date().toISOString(),
      detection_method: detection_method,
      spawn_command_template: generate_template(shell_type)
    })
  })
}

// Step 5: Use shell_type to spawn new console
spawn_command = construct_spawn_command(shell_type, next_command)
```

## Spawn Command Templates

### PowerShell

```json
{
  "shell_type": "PowerShell",
  "spawn_command_template": "start powershell -NoExit -Command \"cd '$PWD'; `$env:PATH='$env:PATH'; {command}\""
}
```

### CMD

```json
{
  "shell_type": "CMD",
  "spawn_command_template": "start cmd /k \"cd /d %CD% && set PATH=%PATH% && {command}\""
}
```

### WSL

```json
{
  "shell_type": "WSL",
  "spawn_command_template": "start powershell -NoExit -Command \"wsl -e bash -c \\\"cd '$PWD' && export PATH='$PATH' && {command}\\\"\""
}
```

### Linux/Mac

```json
{
  "shell_type": "Linux",
  "spawn_command_template": "xterm -e \"cd '$PWD' && export PATH='$PATH' && {command}\" &"
}
```

## Benefits

1. **Efficiency**: Detect once, reuse many times
2. **Consistency**: All commands use same shell type
3. **Performance**: No repeated detection overhead
4. **Reliability**: Stored shell type is consistent across sessions

## Manual Override

If you need to change shell type:

1. **Delete `.gemini/shell-info.json`**
2. **Run any command** - it will detect and store new shell type
3. **Or manually edit** `.gemini/shell-info.json` to change `shell_type`

## File Management

- **Created**: First time any command runs with `auto_next=true`
- **Location**: `.gemini/shell-info.json` (global, not per-scraper)
- **Updated**: Only if file doesn't exist (detection runs once)
- **Deleted**: Can be deleted to force re-detection

## Integration with Auto-Chaining

When `auto_next=true`:

1. **Load shell-info.json** (or detect if missing)
2. **Close browser** using `browser_close()`
3. **Use stored shell type** to construct spawn command
4. **Replace `{command}`** in template with actual command
5. **Execute spawn command** to launch new console

This ensures:
- Same shell type as manual execution
- Proper colors and formatting
- Consistent behavior across all commands

