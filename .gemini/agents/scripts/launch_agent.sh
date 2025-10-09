#!/bin/bash
# Bash script to launch interactive Gemini CLI agents
# Usage: ./launch_agent.sh navigation-agent categories nav_001

AGENT=$1
PAGE_TYPE=$2
TASK_ID=$3
TARGET_URL=$4
DESCRIPTION=$5

# Create task directory if it doesn't exist
mkdir -p ./agent_state/tasks

# Create task file
TASK_FILE="./agent_state/tasks/${TASK_ID}.json"
cat > "$TASK_FILE" << EOF
{
  "task_id": "$TASK_ID",
  "agent": "$AGENT",
  "page_type": "$PAGE_TYPE",
  "status": "queued",
  "process_id": null,
  "started_at": null,
  "target_url": "$TARGET_URL",
  "description": "$DESCRIPTION",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

echo "Created task file: $TASK_FILE"

# Launch interactive Gemini CLI process
echo "Launching interactive $AGENT for $PAGE_TYPE..."

# Create a temporary script file for the agent
TEMP_SCRIPT="/tmp/agent_${TASK_ID}.sh"
cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
# Agent Task Assignment
echo "You are the $AGENT. Your Task ID is $TASK_ID."
echo "Your task is to: $DESCRIPTION"
echo "Page Type: $PAGE_TYPE"
echo "Target URL: $TARGET_URL"
echo ""
echo "Use browser tools to analyze the site and complete your task."
echo "Save your results to agent_state/plans/ directory."
echo ""

# Launch Gemini CLI with agent extension in interactive mode with YOLO mode
echo "YOLO MODE ENABLED - All tool calls will be auto-approved"
gemini -e $AGENT -i "You are the $AGENT. Your Task ID is $TASK_ID. Your task is to: $DESCRIPTION. Page Type: $PAGE_TYPE. Target URL: $TARGET_URL. Use browser tools to analyze the site and complete your task. Save your results to agent_state/plans/ directory." -y
EOF

chmod +x "$TEMP_SCRIPT"

# Launch the agent in a new terminal
if command -v gnome-terminal &> /dev/null; then
    gnome-terminal -- bash -c "$TEMP_SCRIPT; exec bash"
elif command -v xterm &> /dev/null; then
    xterm -e "$TEMP_SCRIPT" &
elif command -v osascript &> /dev/null; then
    osascript -e "tell application \"Terminal\" to do script \"$TEMP_SCRIPT\""
else
    # Fallback to background process
    nohup bash "$TEMP_SCRIPT" > /dev/null 2>&1 &
fi

echo "Agent launched. Task ID: $TASK_ID"
echo "Monitor progress in .gemini/agents/tasks/$TASK_ID.json"
