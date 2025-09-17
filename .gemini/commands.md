# Custom Slash Commands for Web Scraping

## Overview
This document defines the custom slash commands for specialized web scraping modes, integrating with the existing DataHen V3 framework and Playwright MCP tools.

## Mode Selection Commands

### `/explore` - Exploration Mode
**Purpose**: Rapid CSV-based parser generation and testing
**Use Case**: Quick prototyping, CSV-driven development, rapid iteration

**Subcommands**:
- `/explore:start [csv_file] [target_url]` - Initialize exploration mode
- `/explore:analyze [page_type]` - Analyze specific page type
- `/explore:generate [page_type]` - Generate parser for page type
- `/explore:test [parser_name]` - Test specific parser
- `/explore:optimize` - Optimize entire scraper
- `/explore:deploy` - Deploy completed scraper

### `/aiconfig` - Aiconfig Mode
**Purpose**: Structured parser generation using aiconfig.yaml
**Use Case**: Complex projects, configuration-driven development, production-ready scrapers

**Subcommands**:
- `/aiconfig:init [config_file]` - Initialize aiconfig mode
- `/aiconfig:analyze [page_type]` - Analyze page type from config
- `/aiconfig:generate [page_type]` - Generate parser from config
- `/aiconfig:test [parser_name]` - Test parser against config
- `/aiconfig:validate` - Validate entire scraper
- `/aiconfig:deploy` - Deploy configuration-compliant scraper

## Mode-Specific GEMINI.md Files

### Exploration Mode (`.gemini/commands/explore.md`)
- **Focus**: Speed and rapid iteration
- **CSV-Driven**: Uses CSV specifications as primary driver
- **Browser-First**: Always starts with live website analysis
- **Immediate Testing**: Tests every parser immediately after generation

### Aiconfig Mode (`.gemini/commands/aiconfig.md`)
- **Focus**: Structure and configuration compliance
- **Config-Driven**: Uses aiconfig.yaml as source of truth
- **Systematic**: Follows structured development approach
- **Production-Ready**: Generates production-quality scrapers

## Integration with Existing System

Both modes integrate seamlessly with the existing system configuration:

### System.md Integration
- **Working Directory**: All development in `./generated_scraper/[scraper_name]/`
- **Parser Testing**: Uses `parser_tester` MCP tool for all validation
- **Browser Tools**: Follows mandatory selector verification protocol
- **Variable Passing**: Implements robust context management
- **Error Handling**: Includes comprehensive error handling requirements

### GEMINI.md Integration
- **Strategic Layer**: High-level methodology and business logic
- **Quality Standards**: Maintains quality-first development approach
- **Testing Philosophy**: Offline-first, comprehensive testing
- **Tool Integration**: Leverages Playwright MCP tools effectively

## Usage Examples

### Exploration Mode Example
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

### Aiconfig Mode Example
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

## Mode Selection Guidelines

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

## Quality Assurance

Both modes maintain the same high quality standards:

### Technical Standards
- **Selector Accuracy**: >90% match rate using browser_verify_selector
- **Data Extraction**: >95% of required fields successfully extracted
- **Error Handling**: Graceful handling of missing elements and edge cases
- **Variable Passing**: Proper context preservation throughout pipeline

### Testing Requirements
- **Mandatory Testing**: All parsers must be tested with parser_tester MCP tool
- **Browser Verification**: All selectors must be verified using browser tools
- **Data Flow Testing**: Complete pipeline testing from seeder to output
- **Edge Case Testing**: Comprehensive testing of error conditions

### Documentation Standards
- **Clear Comments**: All code must include explanatory comments
- **Selector Documentation**: Document selector choices and fallbacks
- **Business Logic**: Explain complex extraction logic
- **Error Handling**: Document all error handling scenarios

This command structure provides specialized tools for different scraping scenarios while maintaining consistency with the existing system architecture and quality standards.
