# AIConfig Multi-Agent System

## Overview

This system integrates the multi-agent architecture with your existing AIConfig workflow, spawning individual interactive command line processes for each agent so you can monitor and control the parser generation process in real-time.

## Architecture

### AIConfig Integration
- **Configuration-Driven**: Uses your existing `aiconfig.yaml` to drive agent tasks
- **Field Mapping**: Maps AIConfig fields to specific agent responsibilities
- **Interactive Monitoring**: Each agent runs in its own interactive terminal using `gemini -i`
- **Real-time Control**: You can monitor, intervene, and guide agents as they work
- **Filesystem State**: All coordination happens through filesystem state

### Agent Specializations

#### 🧭 Navigation Agent
- **Role**: Website structure analysis and navigation pattern discovery
- **AIConfig Focus**: Category hierarchies, pagination patterns, URL structures
- **Output**: Site analysis saved to `.gemini/agents/plans/site_analysis.md`

#### 🎯 Selector Agent  
- **Role**: CSS selector creation and verification
- **AIConfig Focus**: Creates selectors for all configured fields in aiconfig.yaml
- **Output**: Selector map saved to `.gemini/agents/plans/selector_map.md`

#### 🔧 Parser Agent
- **Role**: Ruby parser generation and implementation
- **AIConfig Focus**: Generates parsers matching aiconfig.yaml specifications
- **Output**: Ruby parsers saved to `.gemini/agents/workspace/generated_scraper/`

## Quick Start

### 1. Launch All Agents
```powershell
# Windows PowerShell
.\launch_aiconfig_agents.ps1 -PageType "all" -ScraperName "pns-hk-scraper"

# Or for specific page type
.\launch_aiconfig_agents.ps1 -PageType "listings" -ScraperName "pns-hk-scraper"
```

### 2. Monitor Progress
```bash
# Check agent status
/aiconfig:monitor:status

# View agent logs
/aiconfig:monitor:logs navigation-agent

# View results
/aiconfig:monitor:results listings
```

### 3. Coordinate Workflow
```bash
# Coordinate between agents
/aiconfig:monitor:coordinate

# Check dependencies
/aiconfig:monitor:dependencies
```

## Detailed Usage

### AIConfig Commands

#### `/aiconfig:start [action] [page_type] [scraper_name]`
**Purpose**: Start the complete AIConfig multi-agent workflow
**Actions**: `analyze`, `selectors`, `parser`, `all`
**Examples**:
```bash
# Start Navigation Agent for site analysis
/aiconfig:start analyze categories pns-hk-scraper

# Start Selector Agent for CSS selector creation  
/aiconfig:start selectors listings my-scraper

# Start Parser Agent for Ruby parser generation
/aiconfig:start parser details

# Start all agents for complete scraper development
/aiconfig:start all pns-hk-scraper
```

**Argument Parsing**: All arguments are passed as a single string via `{{args}}` and parsed by the LLM based on the following format:
- **Format**: `action [page_type] [scraper_name] [options]`
- **Actions**: `analyze`, `selectors`, `parser`, `all`
- **Page Types**: `categories`, `subcategories`, `listings`, `details`
- **Scraper Name**: Optional, defaults to "pns-hk-scraper" if not provided

### Monitoring Commands

#### `/aiconfig:monitor [action] [target] [options]`
**Purpose**: Monitor, manage, and coordinate the AIConfig multi-agent workflow
**Actions**: `status`, `logs`, `results`, `coordinate`
**Examples**:
```bash
# Show status of all running agents
/aiconfig:monitor status

# Show logs for a specific agent
/aiconfig:monitor logs navigation-agent
/aiconfig:monitor logs selector-agent
/aiconfig:monitor logs parser-agent

# Show results for a specific page type
/aiconfig:monitor results categories
/aiconfig:monitor results listings
/aiconfig:monitor results details

# Coordinate workflow between agents
/aiconfig:monitor coordinate
```

**Argument Parsing**: All arguments are passed as a single string via `{{args}}` and parsed by the LLM based on the following format:
- **Format**: `action [target] [options]`
- **Actions**: `status`, `logs`, `results`, `coordinate`
- **Targets**: 
  - For `logs`: Agent name (navigation-agent, selector-agent, parser-agent)
  - For `results`: Page type (categories, listings, details)
  - For `status` and `coordinate`: No target needed

## AIConfig Workflow

### Phase 1: Site Analysis
Navigation Agents analyze website structure for each page type:
- **Categories**: Main page navigation and category links
- **Subcategories**: Category page structure and subcategory links  
- **Listings**: Product listing structure and pagination

### Phase 2: Selector Development
Selector Agents create CSS selectors for all AIConfig fields:
- **Categories**: `category_name`, `category_url`
- **Subcategories**: `subcategory_name`, `subcategory_url`
- **Listings**: All 25+ product fields from aiconfig.yaml

### Phase 3: Parser Generation
Parser Agents generate Ruby parsers matching AIConfig specifications:
- **Field Mapping**: Maps all AIConfig fields to Ruby extraction code
- **Error Handling**: Implements error handling for all fields
- **Output Structure**: Matches AIConfig output specifications exactly

## Filesystem State Management

### Directory Structure
```
.gemini/agents/
├── tasks/                    # Task queue (JSON files)
│   ├── nav_categories_001.json
│   ├── sel_listings_001.json
│   └── par_listings_001.json
├── plans/                    # Agent outputs
│   ├── site_analysis.md     # Navigation agent findings
│   └── selector_map.md      # Selector agent results
├── logs/                     # Execution logs
│   ├── navigation_agent.log
│   ├── selector_agent.log
│   └── parser_agent.log
└── workspace/                # Generated scrapers
    └── generated_scraper/
        └── pns-hk-scraper/
            ├── parsers/
            ├── seeder/
            └── finisher/
```

### Task File Format
```json
{
  "task_id": "nav_categories_001",
  "agent": "navigation-agent",
  "page_type": "categories",
  "status": "running",
  "process_id": 12345,
  "started_at": "2025-01-27T10:00:00Z",
  "target_url": "https://www.pns.hk/en/",
  "description": "Analyze website structure for PNS HK categories page",
  "aiconfig_fields": ["category_name", "category_url"],
  "dependencies": [],
  "output_files": [".gemini/agents/plans/site_analysis.md"]
}
```

## Interactive Agent Management

### Agent Control
Each agent runs in its own interactive terminal window:
- **Real-time Monitoring**: See exactly what each agent is doing
- **Interactive Debugging**: Debug issues as they happen
- **Individual Control**: Control each agent independently
- **Process Management**: Monitor and manage agent processes

### Task Assignment
Each agent receives specific tasks based on aiconfig.yaml:

**Navigation Agent Task**:
```
You are the navigation-agent. Your Task ID is nav_categories_001.
Your task is to: Analyze website structure for PNS HK (https://www.pns.hk/en/) 
based on aiconfig.yaml configuration. Focus on:
- Category navigation patterns for 'categories' page type
- Subcategory hierarchies for 'subcategories' page type  
- Product listing patterns for 'listings' page type
- URL structures and pagination mechanisms

Use browser tools to analyze the site structure and document your findings.
Save results to .gemini/agents/plans/site_analysis.md
```

**Selector Agent Task**:
```
You are the selector-agent. Your Task ID is sel_listings_001.
Your task is to: Create CSS selectors for PNS HK listings page based on aiconfig.yaml.
Required fields: competitor_product_id, name, brand, category, customer_price_lc, 
base_price_lc, has_discount, discount_percentage, img_url, sku, url, is_available, etc.
Use browser tools to verify all selectors with >90% accuracy.
Save results to .gemini/agents/plans/selector_map.md
```

**Parser Agent Task**:
```
You are the parser-agent. Your Task ID is par_listings_001.
Your task is to: Generate Ruby parser for PNS HK listings page matching aiconfig.yaml.
Implement all 25+ configured fields with proper error handling.
Use verified selectors from selector-agent analysis.
Test with parser_tester MCP tool using downloaded HTML.
Save parser to .gemini/agents/workspace/generated_scraper/pns-hk-scraper/parsers/
```

## Quality Assurance

### AIConfig Compliance
- **100% Field Mapping**: All aiconfig.yaml fields must be handled
- **Type Safety**: All field types must be properly handled
- **Error Handling**: All configured error scenarios must be handled
- **Output Validation**: All outputs must match aiconfig.yaml structure

### Agent Coordination
- **Dependency Management**: Ensure proper agent sequencing
- **State Synchronization**: Keep agent state synchronized
- **Progress Validation**: Validate agent progress and outputs
- **Integration Testing**: Test complete workflow integration

## Benefits

1. **Interactive Monitoring**: See exactly what each agent is doing
2. **Individual Control**: Control each agent independently
3. **Real-time Debugging**: Debug issues as they happen
4. **AIConfig Integration**: Seamless integration with existing workflow
5. **Filesystem State**: Transparent state management
6. **Quality Assurance**: Continuous validation and testing

## Troubleshooting

### Common Issues
1. **Agent Not Starting**: Check if Gemini CLI is installed and accessible
2. **Task Dependencies**: Ensure dependencies are satisfied before launching agents
3. **Selector Failures**: Use fallback strategies and cross-page testing
4. **Parser Errors**: Implement comprehensive error handling and testing

### Debugging
- Check task status with `/aiconfig:monitor:status`
- View agent logs with `/aiconfig:monitor:logs [agent]`
- Examine task files in `.gemini/agents/tasks/`
- Review execution logs in `.gemini/agents/logs/`

## Getting Started

1. **Launch Agents**: Use `.\launch_aiconfig_agents.ps1` to start all agents
2. **Monitor Progress**: Use `/aiconfig:monitor:status` to track progress
3. **View Results**: Use `/aiconfig:monitor:results [page_type]` to see outputs
4. **Coordinate Workflow**: Use `/aiconfig:monitor:coordinate` to manage dependencies

The AIConfig multi-agent system is now ready to generate parsers with interactive monitoring and control.
