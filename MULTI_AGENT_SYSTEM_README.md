# Multi-Agent Parser Generation System

## Overview

This system implements a sophisticated multi-agent orchestration for web scraping parser generation using the filesystem-as-state pattern from the [AI Positive Substack article](https://aipositive.substack.com/p/how-i-turned-gemini-cli-into-a-multi).

## Architecture

### Master Orchestrator
- **Command**: `/master` - Complete parser generation workflows
- **Command**: `/orchestrate` - Advanced multi-agent coordination
- **Command**: `/run` - Execute queued tasks with filesystem-as-state

### Specialized Agents

#### 🧭 Navigation Agent (`navigation-agent`)
- **Role**: Website structure analysis and navigation pattern discovery
- **Tasks**: Site mapping, pagination detection, category navigation, URL pattern analysis
- **Tools**: Playwright MCP tools, browser automation, network request analysis

#### 🔧 Parser Agent (`parser-agent`)
- **Role**: Ruby parser development and implementation
- **Tasks**: Parser creation, error handling, memory management, testing
- **Tools**: Ruby development, DataHen V3 framework, parser_tester MCP tool

#### 🎯 Selector Agent (`selector-agent`)
- **Role**: CSS selector optimization and verification
- **Tasks**: Selector creation, verification, cross-page testing, fallback strategies
- **Tools**: Playwright MCP tools, browser automation, selector testing

## Filesystem-as-State Pattern

### Directory Structure
```
.gemini/agents/
├── tasks/                    # Task queue (JSON files)
│   ├── task_001.json        # Navigation analysis task
│   ├── task_002.json        # Selector verification task
│   └── task_003.json        # Parser development task
├── plans/                    # Long-term context storage
│   ├── site_analysis.md     # Navigation agent findings
│   ├── selector_map.md      # Selector agent results
│   └── parser_spec.md       # Parser agent specifications
├── logs/                     # Execution logs and history
│   ├── navigation_agent.log
│   ├── selector_agent.log
│   └── parser_agent.log
└── workspace/                # Agent working directory
    ├── generated_scraper/
    └── cache/
```

### Task Lifecycle
1. **Queued**: Task created and waiting for execution
2. **Running**: Agent instance launched and working
3. **Completed**: Task finished successfully
4. **Failed**: Task encountered an error
5. **Retry**: Failed task queued for retry

## Usage Examples

### Complete Parser Generation
```bash
# 1. Analyze and plan
/master:analyze https://example-store.com/product/123 details

# 2. Create parser
/master:create https://example-store.com/product/123 details

# 3. Test parser
/master:test example-store-scraper details
```

### Advanced Orchestration
```bash
# Advanced multi-agent coordination
/orchestrate:analyze https://example-store.com/product/123 details
/orchestrate:create https://example-store.com/product/123 details
/orchestrate:test example-store-scraper details
```

### Manual Task Management
```bash
# Queue specific tasks
/agents:start navigation-agent "Analyze website structure for https://example-store.com"
/agents:start selector-agent "Create CSS selectors for product data"
/agents:start parser-agent "Implement Ruby parser for product details"

# Execute tasks
/run

# Monitor progress
/agents:status

# View logs
/agents:logs navigation-agent
```

## Workflow Phases

### Phase 1: Site Analysis & Navigation Discovery
- **Navigation Agent**: Analyzes website structure and navigation patterns
- **Selector Agent**: Identifies CSS selectors for product data extraction
- **Parser Agent**: Plans Ruby parser structure and data flow

### Phase 2: Parser Development
- **Parser Agent**: Creates Ruby parser using verified selectors
- **Selector Agent**: Verifies selectors work across different product variations
- **Navigation Agent**: Tests pagination and navigation patterns

### Phase 3: Testing & Quality Assurance
- **Parser Agent**: Tests parser with parser_tester MCP tool
- **Selector Agent**: Cross-verifies selectors on multiple product pages
- **Navigation Agent**: Validates complete scraping pipeline

## Quality Standards

### Technical Requirements
- **Selector Accuracy**: >90% match rate using browser_verify_selector
- **Data Extraction**: >95% of required fields successfully extracted
- **Error Handling**: Graceful handling of missing elements and edge cases
- **Variable Passing**: Proper context preservation throughout pipeline

### Performance Standards
- **Site Analysis**: Complete within 10 minutes
- **Parser Generation**: Complete within 15 minutes
- **Testing**: Complete within 10 minutes
- **Total Workflow**: Complete within 45 minutes

## Agent Identity Fix

The system addresses the critical identity crisis bug where agents would try to delegate tasks back to the orchestrator. The solution uses explicit identity establishment:

```bash
# CORRECT - establishes clear identity
gemini -e parser-agent -y -p "You are the parser-agent. Your Task ID is task_001. Your task is to: Create a Ruby parser for product details page using verified selectors from the selector-agent analysis."
```

## Benefits

1. **Specialized Expertise**: Each agent brings focused capabilities
2. **Parallel Processing**: Multiple aspects can be developed simultaneously
3. **Quality Assurance**: Continuous verification throughout development
4. **Scalable Architecture**: Easy to add new agent types
5. **Production Ready**: Ensures deployment-ready scrapers
6. **Transparent State**: All system state visible in filesystem
7. **Easy Debugging**: Complete audit trail and logging

## Getting Started

1. **Choose Your Approach**: Use `/master`, `/orchestrate`, or manual task management
2. **Queue Tasks**: Use `/agents:start` to create tasks
3. **Execute Tasks**: Use `/run` to launch agents
4. **Monitor Progress**: Use `/agents:status` to track execution
5. **Debug Issues**: Use `/agents:logs` to view detailed logs

## Integration with DataHen V3

The multi-agent system integrates seamlessly with the DataHen V3 framework:

- **Working Directory**: All development happens in `./generated_scraper/[scraper_name]/`
- **Parser Testing**: Uses `parser_tester` MCP tool for validation
- **Selector Verification**: Uses `browser_verify_selector` for accuracy testing
- **Browser Automation**: Leverages Playwright MCP tools for site analysis

## Troubleshooting

### Common Issues
1. **Agent Identity Crisis**: Ensure explicit identity establishment in agent launches
2. **Task Dependencies**: Check that all dependencies are satisfied before execution
3. **Selector Failures**: Use fallback strategies and cross-page testing
4. **Parser Errors**: Implement comprehensive error handling and testing

### Debugging
- Check task status with `/agents:status`
- View agent logs with `/agents:logs [agent-name]`
- Examine task files in `.gemini/agents/tasks/`
- Review execution logs in `.gemini/agents/logs/`

The multi-agent system is now ready to coordinate specialized agents for parser generation with the filesystem-as-state pattern.
