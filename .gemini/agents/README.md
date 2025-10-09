# Multi-Agent System for Gemini CLI

This directory contains a sophisticated multi-agent orchestration system that allows you to coordinate specialized AI agents for complex tasks. The system is based on the [AI Positive Substack article](https://aipositive.substack.com/p/how-i-turned-gemini-cli-into-a-multi) and implements a "filesystem-as-state" pattern.

## 🏗️ Architecture

### Directory Structure
```
.gemini/agents/
├── tasks/           # Task queue (JSON files)
├── plans/           # Long-term context storage
├── logs/            # Execution logs and history
├── workspace/       # Agent working directory
├── coder-agent.toml # Coder agent extension
├── writer-agent.toml # Writer agent extension
├── analyzer-agent.toml # Analyzer agent extension
└── README.md        # This file
```

### Core Components

1. **Agent Extensions** (`.toml` files): Define specialized AI personas
2. **Task Queue** (`tasks/`): JSON files representing work items
3. **Orchestration Commands**: Manage task distribution and execution
4. **Filesystem State**: All system state stored in files for transparency

## 🤖 Available Agents

### Coder Agent (`coder-agent`)
- **Specialization**: Software development, coding, debugging
- **Best For**: Code generation, bug fixes, architecture design
- **Capabilities**: Full-stack development, testing, documentation

### Writer Agent (`writer-agent`)
- **Specialization**: Content creation, documentation, technical writing
- **Best For**: Documentation, content strategy, technical writing
- **Capabilities**: Clear communication, structured content, editing

### Analyzer Agent (`analyzer-agent`)
- **Specialization**: Data analysis, research, investigation
- **Best For**: Data analysis, research, pattern recognition
- **Capabilities**: Insights generation, report creation, visualization

## 🚀 Quick Start

### 1. Queue a Task
```bash
/agents:start coder-agent "Create a Python script to parse CSV files"
```

### 2. Execute Tasks
```bash
/agents:run
```

### 3. Monitor Progress
```bash
/agents:status
```

## 📋 Commands Reference

### `/agents:start [agent] [task]`
Queue a new task for a specific agent.

**Parameters:**
- `agent`: The agent name (coder-agent, writer-agent, analyzer-agent)
- `task`: Description of the task to be performed

**Example:**
```bash
/agents:start writer-agent "Write API documentation for the user service"
```

### `/agents:run`
Execute pending tasks by launching agent instances.

**Behavior:**
- Finds the highest priority pending task
- Launches a new Gemini CLI instance with the appropriate agent
- Updates task status to "running"
- Logs the execution for monitoring

**Example:**
```bash
/agents:run
```

### `/agents:status`
View comprehensive status of all tasks and agents.

**Information Displayed:**
- Task summary (pending, running, completed, failed)
- Agent activity breakdown
- Running processes
- Detailed task information

**Example:**
```bash
/agents:status
```

## 🔧 How It Works

### Task Lifecycle
1. **Queued**: Task created and waiting for execution
2. **Running**: Agent instance launched and working
3. **Completed**: Task finished successfully
4. **Failed**: Task encountered an error

### Agent Execution
The system launches agents using this command structure:
```bash
gemini -e [agent-extension] -y -p "You are the [agent-name]. Your Task ID is [task_id]. Your task is to: [description]"
```

### Critical Implementation Details

**Identity Establishment**: Each agent is explicitly told its identity to prevent delegation loops.

**Auto-Approval**: Agents use the `-y` flag for autonomous operation.

**Background Processing**: Agents run independently without blocking the orchestrator.

**Process Monitoring**: The system tracks running processes and logs all activities.

## 📊 Task File Format

Each task is stored as a JSON file in the `tasks/` directory:

```json
{
  "id": "task_1703123456789_abc123def",
  "agent": "coder-agent",
  "description": "Create a Python script to parse CSV files",
  "status": "pending",
  "created_at": "2025-01-03T10:30:00.000Z",
  "priority": 1,
  "assigned_at": null,
  "completed_at": null,
  "result": null,
  "error": null
}
```

## 🔍 Monitoring and Debugging

### Log Files
Execution logs are stored in the `logs/` directory with timestamps and process information.

### Status Monitoring
Use `/agents:status` to monitor:
- Task progress
- Agent activity
- System health
- Performance metrics

### Error Handling
The system provides comprehensive error reporting:
- Task failures are logged with error details
- Process monitoring detects crashed agents
- File system errors are reported clearly

## 🎯 Use Cases

### E-commerce Scraping Projects
```bash
# Analysis phase
/agents:start analyzer-agent "Analyze the target e-commerce site structure"

# Development phase
/agents:start coder-agent "Create Ruby parsers for product data extraction"

# Documentation phase
/agents:start writer-agent "Write comprehensive scraper documentation"
```

### Software Development
```bash
# Code development
/agents:start coder-agent "Implement user authentication system"

# Testing
/agents:start coder-agent "Write unit tests for the authentication module"

# Documentation
/agents:start writer-agent "Create API documentation for authentication endpoints"
```

### Data Analysis Projects
```bash
# Data collection
/agents:start coder-agent "Create data collection scripts"

# Analysis
/agents:start analyzer-agent "Analyze the collected data and generate insights"

# Reporting
/agents:start writer-agent "Create a comprehensive analysis report"
```

## 🛠️ Customization

### Adding New Agents
1. Create a new `.toml` file in the `agents/` directory
2. Define the agent's specialization and capabilities
3. Update the available agents list in the commands
4. Test the new agent with sample tasks

### Modifying Agent Behavior
Edit the `.toml` files to customize agent prompts, capabilities, and working principles.

### Task Priority System
Tasks can be assigned different priority levels (1 = highest, 5 = lowest) to control execution order.

## 🔒 Safety Features

- **Process Monitoring**: Track running agent processes
- **Error Handling**: Comprehensive error reporting and recovery
- **Resource Management**: Monitor system resource usage
- **Audit Trail**: Complete logging of all agent activities
- **File System Safety**: All operations are logged and reversible

## 📈 Benefits

1. **Specialized Expertise**: Each agent has focused capabilities
2. **Parallel Processing**: Multiple agents can work simultaneously
3. **Transparent State**: All system state visible in filesystem
4. **Easy Debugging**: Complete audit trail and logging
5. **Scalable**: Easy to add new agent types
6. **Reliable**: Robust error handling and recovery

## 🚨 Important Notes

- **Auto-Approval**: Agents use the `-y` flag which auto-approves all tool calls
- **Process Management**: Monitor running processes to avoid resource conflicts
- **File System**: All state is stored in files - keep the directory structure intact
- **Agent Identity**: The system prevents agents from delegating tasks back to the orchestrator

## 🔗 References

- [Original Article](https://aipositive.substack.com/p/how-i-turned-gemini-cli-into-a-multi)
- [Gemini CLI Documentation](https://github.com/google-gemini/gemini-cli)
- [Custom Commands Guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/custom-commands.md)

---

The multi-agent system is now ready to use! Start by queuing your first task with `/agents:start` and watch your specialized AI team work together to accomplish complex projects.
