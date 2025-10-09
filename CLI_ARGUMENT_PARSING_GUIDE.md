# Gemini CLI Argument Parsing Guide for Multi-Agent System

## Overview

This document explains how our AIConfig multi-agent system properly handles Gemini CLI's custom slash command argument parsing, based on the official Gemini CLI documentation.

## Key Concepts

### 1. Argument Parsing with `{{args}}`

**How it works:**
- All arguments after the command are treated as a **single block of text**
- The `{{args}}` placeholder injects the entire argument string into the prompt
- The **LLM is responsible for parsing** the arguments based on prompt instructions
- Arguments are **shell-escaped** when used in `!{...}` blocks

**Example:**
```bash
/aiconfig:start analyze categories pns-hk-scraper
```
- Command: `/aiconfig:start`
- Arguments: `analyze categories pns-hk-scraper`
- `{{args}}` = `"analyze categories pns-hk-scraper"`

### 2. Namespacing Rules

**File Path → Command Name:**
- `.gemini/commands/aiconfig/start.toml` → `/aiconfig:start`
- `.gemini/commands/aiconfig/monitor.toml` → `/aiconfig:monitor`
- `.gemini/commands/aiconfig/launch.toml` → `/aiconfig:launch`

**Path Separators:**
- `/` or `\` become `:` in command names
- Subdirectories create namespaced commands

### 3. Command Scoping

**Project-scoped commands** (our setup):
- Location: `.gemini/commands/`
- Available only within this project
- Can be checked into Git repositories

**User-scoped commands:**
- Location: `~/.gemini/commands/`
- Available across all Gemini CLI projects

## Our Implementation

### Command Structure

All our AIConfig commands follow this pattern:

```toml
description = "Command description"
prompt = """
You are the **Command Handler** - responsible for [purpose].

## Command: /aiconfig:command

**Purpose**: [purpose description]

**Usage**: `/aiconfig:command [action] [target] [options]`

**Argument Parsing**: All arguments are passed as a single string via `{{args}}` and parsed by the LLM based on the following format:
- **Format**: `action [target] [options]`
- **Actions**: [list of valid actions]
- **Targets**: [list of valid targets]
- **Examples**: 
  - `/aiconfig:command action1 target1`
  - `/aiconfig:command action2 target2 option1`

## Available Actions

[Detailed action descriptions]

## Argument Parsing Instructions

**CRITICAL**: Parse the arguments from `{{args}}` using the following format:
- **Format**: `action [target] [options]`
- **Actions**: [list with descriptions]
- **Targets**: [list with descriptions]

**Parse the input**: `{{args}}`

**Examples of valid input**:
- `action1 target1` → Action: action1, Target: target1
- `action2 target2 option1` → Action: action2, Target: target2, Option: option1

**Your task**: Parse the arguments and execute the appropriate action based on the parsed values.

Now, let's execute your command: {{args}}
"""
```

### Updated Commands

#### 1. `/aiconfig:start`

**Usage**: `/aiconfig:start [action] [page_type] [scraper_name] [options]`

**Actions**: `analyze`, `selectors`, `parser`, `all`

**Examples**:
- `/aiconfig:start analyze categories pns-hk-scraper`
- `/aiconfig:start selectors listings my-scraper`
- `/aiconfig:start all pns-hk-scraper`
- `/aiconfig:start parser details`

#### 2. `/aiconfig:monitor`

**Usage**: `/aiconfig:monitor [action] [target] [options]`

**Actions**: `status`, `logs`, `results`, `coordinate`

**Examples**:
- `/aiconfig:monitor status`
- `/aiconfig:monitor logs navigation-agent`
- `/aiconfig:monitor results listings`
- `/aiconfig:monitor coordinate`

#### 3. `/aiconfig:launch`

**Usage**: `/aiconfig:launch [agent] [page_type] [task_description]`

**Agents**: `navigation-agent`, `selector-agent`, `parser-agent`, `all`

**Examples**:
- `/aiconfig:launch navigation-agent categories "Analyze site navigation"`
- `/aiconfig:launch all listings "Complete scraper development"`
- `/aiconfig:launch parser-agent details`

## Best Practices

### 1. Always Use `{{args}}` Placeholder

**Good:**
```toml
prompt = """
Parse the arguments: {{args}}
Your task is to handle: {{args}}
"""
```

**Bad:**
```toml
prompt = """
Handle the command arguments.
# No {{args}} placeholder - arguments appended at end
"""
```

### 2. Provide Clear Parsing Instructions

**Include in every command:**
- Expected argument format
- Valid values for each position
- Examples of valid input
- Clear parsing instructions for the LLM

### 3. Handle Optional Arguments

**Use defaults:**
```toml
**Scraper Name**: Optional, defaults to "pns-hk-scraper" if not provided
**Task Description**: Optional, defaults to "AIConfig parser generation task"
```

### 4. Provide Examples

**Always include examples:**
```toml
**Examples of valid input**:
- `analyze categories pns-hk-scraper` → Action: analyze, Page Type: categories, Scraper: pns-hk-scraper
- `selectors listings my-scraper` → Action: selectors, Page Type: listings, Scraper: my-scraper
```

## Testing Commands

### Test Argument Parsing

```bash
# Test basic parsing
/aiconfig:start analyze categories pns-hk-scraper

# Test with quotes
/aiconfig:launch navigation-agent categories "Analyze site navigation"

# Test minimal arguments
/aiconfig:monitor status

# Test all agents
/aiconfig:start all my-scraper
```

### Expected Behavior

1. **Command Recognition**: Gemini CLI should recognize the command
2. **Argument Injection**: `{{args}}` should be replaced with the full argument string
3. **LLM Parsing**: The LLM should parse arguments according to instructions
4. **Action Execution**: Appropriate action should be executed based on parsed values

## Troubleshooting

### Common Issues

1. **Command Not Found**
   - Check file path: `.gemini/commands/aiconfig/command.toml`
   - Verify namespacing: `aiconfig/command.toml` → `/aiconfig:command`

2. **Arguments Not Parsed**
   - Ensure `{{args}}` placeholder is used
   - Check parsing instructions are clear
   - Verify argument format matches examples

3. **Wrong Action Executed**
   - Review parsing instructions
   - Check action mapping
   - Verify examples match expected input

### Debug Steps

1. **Check Command File**: Verify `.toml` file exists and is properly formatted
2. **Test Simple Command**: Try `/aiconfig:monitor status` (no arguments)
3. **Test With Arguments**: Try `/aiconfig:start analyze categories`
4. **Check Logs**: Review agent logs for parsing errors

## Conclusion

Our multi-agent system now properly handles Gemini CLI's argument parsing by:

1. **Using `{{args}}` placeholder** for all commands
2. **Providing clear parsing instructions** for the LLM
3. **Including comprehensive examples** for each command
4. **Following namespacing conventions** for command organization
5. **Handling optional arguments** with sensible defaults

This ensures that our AIConfig multi-agent workflow integrates seamlessly with Gemini CLI's custom slash command system while maintaining the interactive agent spawning capabilities that allow operators to monitor and control the parser generation process in real-time.
