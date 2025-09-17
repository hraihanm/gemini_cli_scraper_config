# Gemini CLI Custom Slash Commands for Web Scraping

## Overview

Based on the [official Google Cloud blog post about Gemini CLI custom slash commands](https://cloud.google.com/blog/topics/developers-practitioners/gemini-cli-custom-slash-commands), I've created specialized `.toml` files for your web scraping workflow. The commands are now properly formatted according to the official Gemini CLI specification.

## File Structure

```
.gemini/commands/
├── explore.toml                    # Main exploration mode command
├── explore/
│   ├── analyze.toml               # Analyze page type for selectors
│   ├── generate.toml              # Generate parser for page type
│   └── test.toml                  # Test specific parser
├── aiconfig.toml                  # Main aiconfig mode command
└── aiconfig/
    ├── analyze.toml               # Analyze page type from config
    ├── generate.toml              # Generate parser from config
    └── validate.toml              # Validate entire scraper
```

## Available Commands

### Exploration Mode Commands

#### `/explore [target_url]`
**Purpose**: Rapid CSV-based parser generation and testing
**Best For**: Quick prototyping, CSV-driven development, rapid iteration
**Time Target**: Complete scraper generation within 30 minutes

**Usage**:
```bash
/explore https://example-store.com
```

#### `/explore:analyze [page_type]`
**Purpose**: Analyze specific page type for selector discovery
**Usage**:
```bash
/explore:analyze listings
/explore:analyze details
/explore:analyze categories
```

#### `/explore:generate [page_type]`
**Purpose**: Generate parser for specific page type
**Usage**:
```bash
/explore:generate listings
/explore:generate details
/explore:generate categories
```

#### `/explore:test [parser_name]`
**Purpose**: Test specific parser with comprehensive validation
**Usage**:
```bash
/explore:test listings
/explore:test details
/explore:test categories
```

### Aiconfig Mode Commands

#### `/aiconfig [config_file]`
**Purpose**: Structured parser generation using aiconfig.yaml
**Best For**: Complex projects, configuration-driven development, production-ready scrapers
**Time Target**: Complete scraper generation within 45 minutes

**Usage**:
```bash
/aiconfig aiconfig.yaml
```

#### `/aiconfig:analyze [page_type]`
**Purpose**: Analyze page type from aiconfig.yaml configuration
**Usage**:
```bash
/aiconfig:analyze list
/aiconfig:analyze details
```

#### `/aiconfig:generate [page_type]`
**Purpose**: Generate parser from aiconfig.yaml configuration specifications
**Usage**:
```bash
/aiconfig:generate list
/aiconfig:generate details
```

#### `/aiconfig:validate`
**Purpose**: Validate entire scraper against aiconfig.yaml configuration
**Usage**:
```bash
/aiconfig:validate
```

## Key Features

### Exploration Mode Features
- **Speed-First Approach**: Complete scraper generation within 30 minutes
- **CSV-Driven Development**: Uses CSV specifications as primary driver
- **Browser-First Analysis**: Always starts with live website analysis
- **Immediate Testing**: Tests every parser immediately after generation

### Aiconfig Mode Features
- **Configuration-Driven**: Uses aiconfig.yaml as source of truth
- **Systematic Development**: Follows structured approach to parser generation
- **Comprehensive Testing**: Thorough testing at each stage
- **Production-Ready**: Generates production-quality scrapers from the start

## Integration with Existing System

Both modes integrate seamlessly with your existing configuration:

### System.md Integration
- All development happens in `./generated_scraper/[scraper_name]/`
- Uses `parser_tester` MCP tool for all validation
- Follows mandatory selector verification protocol
- Implements robust context management
- Includes comprehensive error handling

### GEMINI.md Integration
- Maintains quality-first development approach
- Follows browser-first analysis methodology
- Implements comprehensive testing strategy
- Leverages Playwright MCP tools effectively
- Ensures production-ready output quality

## Quality Standards

Both modes maintain the same high quality standards:

### Technical Standards
- **Selector Accuracy**: >90% match rate using browser_verify_selector
- **Data Extraction**: >95% of required fields successfully extracted
- **Error Handling**: Graceful handling of missing elements and edge cases
- **Variable Passing**: Proper context preservation throughout pipeline

### Testing Requirements
- **Mandatory Testing**: All parsers must be tested with parser_tester MCP tool
- **Browser Verification**: All selectors must be verified using browser tools
- **Complete Pipeline Testing**: Test complete data flow from seeder to output
- **Comprehensive Edge Case Testing**: Test all error conditions

## Usage Examples

### Complete Exploration Mode Workflow
```bash
# Start exploration with target URL
/explore https://example-store.com

# Analyze listing pages
/explore:analyze listings

# Generate listings parser
/explore:generate listings

# Test the generated parser
/explore:test listings

# Continue with details parser
/explore:analyze details
/explore:generate details
/explore:test details
```

### Complete Aiconfig Mode Workflow
```bash
# Initialize with aiconfig.yaml
/aiconfig aiconfig.yaml

# Analyze list page from config
/aiconfig:analyze list

# Generate list parser
/aiconfig:generate list

# Test list parser
/aiconfig:test list

# Generate details parser
/aiconfig:analyze details
/aiconfig:generate details

# Validate entire scraper
/aiconfig:validate
```

## Mode Selection Guidelines

### Choose Exploration Mode When:
- Working with CSV specifications
- Need rapid prototyping and iteration
- Have simple to moderate complexity requirements
- Want to get working scraper quickly
- Need to explore and understand website structure

### Choose Aiconfig Mode When:
- Working with complex configurations
- Need production-ready scrapers
- Have detailed configuration requirements
- Want structured, systematic development
- Need comprehensive validation and testing

## Next Steps

1. **Test the Commands**: Try using the slash commands with your existing projects
2. **Customize as Needed**: Modify the `.toml` files based on your specific requirements
3. **Add More Commands**: Extend the command structure with additional specialized workflows
4. **Integrate with Workflow**: Incorporate these commands into your regular development process

The specialized modes provide targeted tools for different scraping scenarios while maintaining consistency with your existing system architecture and quality standards.

## References

- [Official Gemini CLI Custom Slash Commands Documentation](https://cloud.google.com/blog/topics/developers-practitioners/gemini-cli-custom-slash-commands)
- [Gemini CLI Documentation](https://github.com/google-gemini/gemini-cli)
- [Model Context Protocol (MCP) Documentation](https://modelcontextprotocol.io/)
