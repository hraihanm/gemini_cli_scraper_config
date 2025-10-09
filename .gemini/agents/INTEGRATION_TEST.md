# Subagent Integration Test

This document provides a comprehensive test plan for the web scraping subagent system integration.

## 🧪 Test Overview

The integration test verifies that all components of the subagent system work together correctly, including:
- Agent definitions and extensions
- Command integration
- Task queue management
- Agent coordination
- Web scraping workflows

## 📋 Test Checklist

### ✅ Agent Definitions
- [x] scraper-agent.toml created
- [x] parser-agent.toml created
- [x] selector-agent.toml created
- [x] Agent extensions created in `.gemini/extensions/`
- [x] Agent personas created

### ✅ Command Integration
- [x] `/agents:*` commands updated with new agents
- [x] `/scrape:*` commands created for web scraping
- [x] `/parser:*` commands created for parser development
- [x] Agent validation updated in start.toml

### ✅ System Integration
- [x] DataHen V3 framework integration
- [x] Playwright MCP tools integration
- [x] Parser testing protocol integration
- [x] Browser automation workflow integration

## 🚀 Test Scenarios

### Test 1: Basic Agent Queue and Execution
```bash
# Test agent queueing
/agents:start scraper-agent "Test web scraping project management"

# Test agent execution
/agents:run

# Test status monitoring
/agents:status
```

**Expected Results**:
- Task queued successfully
- Agent launched with correct extension
- Status shows running task
- Agent completes task and reports success

### Test 2: Web Scraping Project Workflow
```bash
# Test complete scraping project
/scrape:analyze https://example-store.com

# Test parser development
/parser:create https://example-store.com/product/123 details

# Test scraper testing
/scrape:test example-store-scraper
```

**Expected Results**:
- Scraper agent analyzes target website
- Parser agent creates Ruby parsers
- Selector agent optimizes CSS selectors
- Complete scraper tested successfully

### Test 3: Agent Coordination
```bash
# Test multiple agents working together
/agents:start scraper-agent "Plan scraping project for https://example-store.com"
/agents:start selector-agent "Analyze CSS selectors for product data"
/agents:start parser-agent "Create Ruby parsers for all page types"

# Execute all tasks
/agents:run
```

**Expected Results**:
- All agents work on related tasks
- Tasks are coordinated effectively
- No conflicts between agents
- All tasks complete successfully

### Test 4: Error Handling
```bash
# Test invalid agent
/agents:start invalid-agent "Test error handling"

# Test invalid command
/scrape:invalid https://example-store.com
```

**Expected Results**:
- Error messages for invalid agents
- Error messages for invalid commands
- System remains stable
- No crashes or hangs

## 🔧 Manual Testing Steps

### Step 1: Verify Agent Extensions
```bash
# Check if extensions are properly configured
ls .gemini/extensions/
# Should show: scraper-agent/, parser-agent/, selector-agent/

# Check extension files
ls .gemini/extensions/scraper-agent/
# Should show: gemini-extension.json, scraper-agent-persona.md
```

### Step 2: Test Command Availability
```bash
# Test agent commands
/agents:start --help
/agents:run --help
/agents:status --help

# Test web scraping commands
/scrape --help
/parser --help
```

### Step 3: Test Agent Execution
```bash
# Queue a simple task
/agents:start parser-agent "Create a simple Ruby parser template"

# Execute the task
/agents:run

# Check status
/agents:status
```

### Step 4: Test Web Scraping Workflow
```bash
# Test analysis workflow
/scrape:analyze https://httpbin.org/html

# Test parser development
/parser:create https://httpbin.org/html details
```

## 📊 Success Criteria

### Functional Requirements
- [ ] All agents can be queued and executed
- [ ] Web scraping commands work correctly
- [ ] Parser development commands work correctly
- [ ] Agent coordination works without conflicts
- [ ] Error handling works properly

### Performance Requirements
- [ ] Agents start within 5 seconds
- [ ] Tasks complete within reasonable time
- [ ] No memory leaks or resource issues
- [ ] System remains stable under load

### Integration Requirements
- [ ] DataHen V3 framework integration works
- [ ] Playwright MCP tools integration works
- [ ] Parser testing protocol works
- [ ] Browser automation workflow works

## 🐛 Troubleshooting

### Common Issues
1. **Agent not found**: Check extension files and paths
2. **Command not recognized**: Check .toml file syntax
3. **Agent execution fails**: Check agent persona files
4. **Integration errors**: Check system.md and GEMINI.md

### Debug Commands
```bash
# Check agent status
/agents:status

# Check available commands
/tools

# Check system configuration
cat .gemini/system.md

# Check agent definitions
ls .gemini/agents/
```

## 📈 Performance Monitoring

### Metrics to Track
- Agent startup time
- Task completion time
- Memory usage
- Error rates
- Success rates

### Monitoring Commands
```bash
# Check system status
/agents:status

# Check running processes
ps aux | grep gemini

# Check memory usage
top -p $(pgrep gemini)
```

## ✅ Test Completion

Once all tests pass, the subagent system is ready for production use. The system should be able to:
- Queue and execute web scraping tasks
- Coordinate multiple agents effectively
- Handle complex scraping workflows
- Provide reliable error handling
- Integrate seamlessly with existing tools

## 🎯 Next Steps

After successful integration testing:
1. Deploy to production environment
2. Train users on new commands
3. Monitor performance and usage
4. Collect feedback and iterate
5. Add additional specialized agents as needed

The subagent system is now ready to revolutionize web scraping workflows with specialized AI agents!
