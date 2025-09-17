# Custom Slash Commands for Web Scraping

## Overview

Based on the articles you provided and your current configuration, I've created specialized slash commands for two distinct scraping workflows:

1. **Exploration Mode** (`/explore`) - For rapid CSV-based parser generation
2. **Aiconfig Mode** (`/aiconfig`) - For structured parser generation using aiconfig.yaml

## Files Created

### 1. `.gemini/commands/explore.md`
**Purpose**: Exploration mode for rapid CSV-based parser generation
**Key Features**:
- Speed-first approach (complete scraper in 30 minutes)
- CSV-driven development
- Browser-first analysis
- Immediate testing after generation

### 2. `.gemini/commands/aiconfig.md`
**Purpose**: Aiconfig mode for structured parser generation
**Key Features**:
- Configuration-driven development
- Systematic approach
- Production-ready output
- Comprehensive validation

### 3. `.gemini/commands.md`
**Purpose**: Command reference and integration guide
**Contains**:
- Complete command reference
- Usage examples
- Mode selection guidelines
- Integration details

### 4. Updated `GEMINI.md`
**Purpose**: Integrated specialized modes into main configuration
**Added**:
- Specialized mode integration section
- Mode selection guidelines
- Quality assurance across modes
- Workflow descriptions

## How to Use

### Exploration Mode Commands

```bash
# Start exploration with CSV and target URL
/explore:start spec_general_sample.csv https://example-store.com

# Analyze listing pages
/explore:analyze listings

# Generate listings parser
/explore:generate listings

# Test the generated parser
/explore:test listings

# Deploy when ready
/explore:deploy
```

### Aiconfig Mode Commands

```bash
# Initialize with aiconfig.yaml
/aiconfig:init aiconfig.yaml

# Analyze details page from config
/aiconfig:analyze details

# Generate details parser
/aiconfig:generate details

# Test against configuration
/aiconfig:test details

# Validate entire scraper
/aiconfig:validate

# Deploy configuration-compliant scraper
/aiconfig:deploy
```

## Mode Selection

### Choose Exploration Mode When:
- Working with CSV specifications
- Need rapid prototyping
- Want quick iteration and testing
- Have simple to moderate complexity requirements
- Need to get working scraper quickly

### Choose Aiconfig Mode When:
- Working with complex configurations
- Need production-ready scrapers
- Have detailed configuration requirements
- Want structured, systematic development
- Need comprehensive validation and testing

## Integration with Existing System

Both modes integrate seamlessly with your existing configuration:

- **System.md**: All operational rules and tool protocols remain the same
- **GEMINI.md**: Strategic approach and quality standards maintained
- **Working Directory**: All development in `./generated_scraper/[scraper_name]/`
- **Parser Testing**: Uses `parser_tester` MCP tool for all validation
- **Browser Tools**: Follows mandatory selector verification protocol

## Quality Standards

Both modes maintain the same high quality standards:

- **Selector Accuracy**: >90% match rate using browser_verify_selector
- **Data Extraction**: >95% of required fields successfully extracted
- **Error Handling**: Graceful handling of missing elements and edge cases
- **Variable Passing**: Proper context preservation throughout pipeline
- **Testing**: Mandatory testing with parser_tester MCP tool
- **Documentation**: Clear comments and comprehensive documentation

## Next Steps

1. **Test the Commands**: Try using the slash commands with your existing projects
2. **Customize as Needed**: Modify the mode-specific GEMINI.md files based on your specific requirements
3. **Add More Commands**: Extend the command structure with additional specialized workflows
4. **Integrate with Workflow**: Incorporate these commands into your regular development process

The specialized modes provide targeted tools for different scraping scenarios while maintaining consistency with your existing system architecture and quality standards.
