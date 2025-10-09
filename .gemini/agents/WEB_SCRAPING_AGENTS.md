# Web Scraping Subagent System

This document describes the specialized subagent system for web scraping projects using the DataHen V3 framework and Gemini CLI.

## 🎯 Overview

The web scraping subagent system extends the existing multi-agent orchestration with specialized agents designed specifically for web scraping tasks. Each agent has focused capabilities that work together to create production-ready scrapers.

## 🤖 Available Agents

### 🕷️ Scraper Agent (`scraper-agent`)
**Role**: Web scraping project management and coordination
- **Specialization**: DataHen V3 framework, e-commerce scraping, browser automation
- **Best For**: Complete scraping projects, project planning, quality assurance
- **Capabilities**: Site analysis, parser coordination, deployment management

### 🔧 Parser Agent (`parser-agent`)
**Role**: Ruby parser development and optimization
- **Specialization**: Ruby, Nokogiri, CSS selectors, DataHen V3 parsers
- **Best For**: Ruby parser creation, data extraction, error handling
- **Capabilities**: Ruby development, memory management, testing

### 🎯 Selector Agent (`selector-agent`)
**Role**: CSS selector analysis and verification
- **Specialization**: CSS selectors, browser automation, Playwright MCP tools
- **Best For**: Selector optimization, verification, cross-page testing
- **Capabilities**: Browser tool usage, selector testing, fallback strategies

## 🚀 Quick Start

### 1. Basic Agent Usage
```bash
# Queue a web scraping task
/agents:start scraper-agent "Create a complete scraper for https://example-store.com"

# Execute the task
/agents:run

# Check status
/agents:status
```

### 2. Specialized Web Scraping Commands
```bash
# Analyze target website
/scrape:analyze https://example-store.com

# Develop specific parsers
/parser:create https://example-store.com/product/123 details

# Test complete scraper
/scrape:test example-store-scraper
```

## 📋 Command Reference

### Multi-Agent Commands (`/agents:*`)
- `/agents:start [agent] [task]` - Queue a new task for a specific agent
- `/agents:run` - Execute pending tasks by launching agent instances
- `/agents:status` - View comprehensive status of all tasks and agents

### Web Scraping Commands (`/scrape:*`)
- `/scrape:analyze [url]` - Analyze target website and create scraping strategy
- `/scrape:develop [url] [page_type]` - Develop parsers for specific page types
- `/scrape:test [scraper_name]` - Test complete scraper with all parsers
- `/scrape:deploy [scraper_name]` - Deploy completed scraper to DataHen platform

### Parser Development Commands (`/parser:*`)
- `/parser:analyze [url] [page_type]` - Analyze page structure and identify data extraction points
- `/parser:create [url] [page_type]` - Create Ruby parser for specific page type
- `/parser:optimize [scraper] [parser]` - Optimize existing parser for better performance
- `/parser:test [scraper] [parser]` - Test parser with comprehensive validation

## 🔄 Workflow Examples

### Complete E-commerce Scraping Project
```bash
# Phase 1: Analysis & Planning
/agents:start scraper-agent "Analyze https://example-store.com and create scraping strategy"
/agents:start selector-agent "Analyze CSS selectors for product data extraction"
/agents:run

# Phase 2: Parser Development
/agents:start parser-agent "Create Ruby parsers for category, listings, and details pages"
/agents:start selector-agent "Optimize CSS selectors for reliability"
/agents:run

# Phase 3: Testing & Validation
/agents:start scraper-agent "Test complete scraper with parser_tester MCP tool"
/agents:run

# Phase 4: Deployment
/agents:start scraper-agent "Deploy scraper to DataHen platform"
/agents:run
```

### Quick Parser Development
```bash
# Queue specific parser development
/agents:start parser-agent "Create Ruby parser for product listings page"
/agents:start selector-agent "Optimize CSS selectors for product data"
/agents:run
```

## 🛠️ Technical Integration

### DataHen V3 Framework
- **Working Directory**: All development in `./generated_scraper/[scraper_name]/`
- **Parser Testing**: Use `parser_tester` MCP tool for validation
- **Browser Tools**: Follow mandatory selector verification protocol
- **Variable Passing**: Implement robust context management

### Playwright MCP Tools
- **browser_navigate**: Navigate to target pages
- **browser_snapshot**: Capture page structure
- **browser_inspect_element**: Get detailed DOM information
- **browser_verify_selector**: Verify selector accuracy
- **parser_tester**: Test parsers with HTML files

### Ruby Parser Standards
```ruby
# Standard parser template
html = Nokogiri::HTML(content)
vars = page['vars']

# Extract data with error handling
begin
  extracted_data = html.at_css('.selector')&.text&.strip
rescue => e
  puts "Error extracting data: #{e.message}"
  extracted_data = nil
end

# Queue next pages
pages << {
  url: next_url,
  page_type: "next_page",
  vars: vars.merge({ extracted_field: extracted_data })
}

# Generate outputs
outputs << {
  '_collection' => 'data',
  '_id' => unique_id,
  'field' => extracted_data,
  'context' => vars['context']
}
```

## 📊 Quality Standards

### Technical Requirements
- **Selector Accuracy**: >90% match rate using browser_verify_selector
- **Data Extraction**: >95% of required fields successfully extracted
- **Error Handling**: Graceful handling of missing elements and edge cases
- **Variable Passing**: Proper context preservation throughout pipeline

### Testing Protocol
- **Mandatory Testing**: All parsers must be tested with parser_tester MCP tool
- **Browser Verification**: All selectors must be verified using browser tools
- **Cross-Page Testing**: Test selectors across different page variations
- **Complete Pipeline Testing**: Test complete data flow from seeder to output

## 🔧 Agent Extensions

### Scraper Agent Extension
- **File**: `.gemini/extensions/scraper-agent/gemini-extension.json`
- **Persona**: `.gemini/extensions/scraper-agent/scraper-agent-persona.md`
- **Capabilities**: Project management, site analysis, quality assurance

### Parser Agent Extension
- **File**: `.gemini/extensions/parser-agent/gemini-extension.json`
- **Persona**: `.gemini/extensions/parser-agent/parser-agent-persona.md`
- **Capabilities**: Ruby development, DataHen V3 integration, testing

### Selector Agent Extension
- **File**: `.gemini/extensions/selector-agent/gemini-extension.json`
- **Persona**: `.gemini/extensions/selector-agent/selector-agent-persona.md`
- **Capabilities**: CSS selector optimization, browser automation, verification

## 🎯 Benefits

1. **Specialized Expertise**: Each agent brings focused capabilities to web scraping
2. **Parallel Processing**: Multiple agents can work simultaneously on different aspects
3. **Quality Assurance**: Continuous testing and validation throughout development
4. **Production Ready**: Ensures deployment-ready scrapers from the start
5. **Scalable**: Easy to add more specialized agents for specific needs

## 📚 Integration with Existing System

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

## 🚀 Getting Started

1. **Choose Your Approach**: Use `/scrape:analyze` for complete projects or `/parser:create` for specific parsers
2. **Monitor Progress**: Use `/agents:status` to track agent activity
3. **Execute Tasks**: Use `/agents:run` to launch agents
4. **Test & Deploy**: Use testing commands to validate and deploy scrapers

The web scraping subagent system is now ready to coordinate specialized agents for complete scraping projects with the DataHen V3 framework.
