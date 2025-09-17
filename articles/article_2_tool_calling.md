# Practical Gemini CLI: Tool calling  

I have been building out some prompts and instructions to tune the way Gemini CLI executes its tasks in a way that it aligns with my style of development.  

While doing so I ended up trying to understand what are the different tools defined that come out of the box and how the system instruction instruct Gemini to utilise the provided tools.  

> **Note:** There is the [official documentation on tools](https://github.com/google-gemini/gemini-cli/blob/main/docs/tools/index.md), and there is [Romin’s excellent blog on how to use tools](https://google-cloud/gemini-cli-tutorial-series-part-4-built-in-tools-c591befa59ba). If you are interested in reading about tools, then go through those blogs.  

This blog of mine is looking at tools specifically with an eye to preserve the functionality when I go and override the core system instructions. Aha… did that raise your ‘brows?’, wait for the upcoming blog. 😊  

## The Toolbox: What Can Gemini Actually Do? 🛠️  

First, let’s look at the tools Gemini has at its disposal. Based on the source, they are organized into logical groups:  

- **File System Tools:**  
  - `glob`: Find files using patterns.  
  - `search_file_content`: Search for specific text within files.  
  - `read_file`, `read_many_files`: Read the contents of one or more files.  
  - `write_file`: Write new files.  
  - `replace`: Modify existing files by replacing text.  
  - `list_directory`: List the contents of a directory.  

- **Shell Tool:** A powerful and versatile tool that allows Gemini to execute any shell command (`run_shell_command`). This is the key to running tests, build scripts, linters, or any other command‑line utility you rely on.  

- **Web Tools:** To gather external information, Gemini can:  
  - `google_web_search`: Perform a targeted Google Search.  
  - `web_fetch`: Fetch and process content from a specific URL.  

- **Memory Tool:** A unique tool for personalization. `save_memory` allows the model to remember user‑specific preferences or facts across sessions, like a preferred coding style or a common project alias.  

You can also get the list of tools by using the `/tools` command.  

```text
╭────────────╮
│  > /tools  │
╰────────────╯

ℹ Available Gemini CLI tools:

- Edit
- FindFiles
- GoogleSearch
- ReadFile
- ReadFolder
- ReadManyFiles
- Save Memory
- SearchText
- Shell
- WebFetch
- WriteFile
```

## Guiding tool usage with System Instructions  

So, the model knows **what** tools it has, but how does it know **when** and **how** to use them effectively and safely? This is governed by a carefully crafted **system prompt**, located in `packages/core/src/core/prompts.ts`. Think of this prompt as Gemini's internal operating manual.  

### Primary Workflows for Software Engineering  

This section provides a high‑level, strategic playbook for common tasks. It tells Gemini to follow a specific sequence, explicitly naming which tools to use at each stage:  

1. **Understand:** Use `grep` and `glob` to search the codebase and `read_file` or `read_many_files` to understand the context.  
2. **Plan:** Formulate a plan. This is a cognitive step, but it’s informed by the understanding gained from the tools.  
3. **Implement:** Use tools like `edit`, `write_file`, and `shell` to act on the plan and make changes.  
4. **Verify:** Use the `shell` tool to run tests, linters, and build commands to ensure the changes are correct and adhere to project standards.  

This structured workflow prevents the model from jumping straight to a solution and encourages a more robust, human‑like development process.  

### General Tool Usage Guidelines  

This section provides the tactical, ground‑level rules for using tools safely and correctly:  

- **Precision:** Always use absolute file paths.  
- **Safety:** Explain potentially modifying shell commands to the user before execution.  
- **Efficiency:** Execute independent tool calls (like multiple searches) in parallel.  
- **User Experience:** Avoid interactive shell commands that could hang the process and always respect when a user cancels a tool call.  
- **Personalization:** Use the `save_memory` tool only for user‑specific preferences that should persist across sessions.  

## Putting It All Together: A Complete Example  

Let’s trace what would happen in the case of a simple user request: **“Refactor the database connection logic in `db.ts` to use environment variables.”**  

1. **Prompt Received:** Gemini receives the request.  
2. **Understand Phase:** Consulting its “Primary Workflows,” Gemini knows the first step is to understand. It decides to use the `read_file` tool to see the current contents of `db.ts`.  
3. **Tool Call:** The model generates a structured request: `{ "tool_name": "read_file", "arguments": { "path": "/path/to/project/db.ts" } }`.  
4. **Execution:** The `ToolRegistry` receives this request, finds the `read-file.ts` implementation, and executes it. The file's content is returned to the model.  
5. **Plan & Implement Phase:** The model now understands the code. It plans the change and uses the `edit` tool to replace the hardcoded connection string with logic to read from `process.env`.  
6. **Verify Phase:** After implementing the change, the workflow tells Gemini to verify. It might use the `shell` tool to run a command like `npm test` to ensure the refactoring didn't break anything.  
7. **Response:** Gemini reports back to the user with the changes it made and the results of the verification step.  

This seamless cycle of understanding, planning, acting, and verifying — all mediated by a clear set of tools and rules — is what makes the Gemini CLI such a powerful assistant for any developer.  

Finally, the actual texts from `prompts.ts`  

```
## Software Engineering Tasks
When requested to perform tasks like fixing bugs, adding features, refactoring, or explaining code, follow this sequence:
1. **Understand:** Think about the user's request and the relevant codebase context...
2. **Plan:** Build a coherent and grounded (based on the understanding in step 1) plan for how you intend to resolve the user's task...
3. **Implement:** Use the available tools (e.g., `${EditTool.Name}`, `${WriteFileTool.Name}` `${ShellTool.Name}` ...) to act on the plan, strictly adhering to the project's established conventions...
4. **Verify (Tests):** If applicable and feasible, verify the changes using the project's testing procedures...
5. **Verify (Standards):** VERY IMPORTANT: After making code changes, execute the project-specific build, linting and type-checking commands...
```

## The “Tool Usage” Section  

```
## Tool Usage
- **File Paths:** Always use absolute paths when referring to files with tools like `${ReadFileTool.Name}` or `${WriteFileTool.Name}`. Relative paths are not supported.
- **Parallelism:** Execute multiple independent tool calls in parallel when feasible (i.e. searching the codebase).
- **Command Execution:** Use the `${ShellTool.Name}` tool for running shell commands, remembering the safety rule to explain modifying commands first.
...
```

These two sections, working together, form the complete set of instructions that Gemini uses to understand and operate its available tools.  

Was this useful? Interesting? Let me know.  

This was foundational knowledge to what I’m going to be writing about next. This was a digression, but I wanted to understand what is happening before I overrode the hardcoded system instructions.  

## Further Reading  

This blog is part of the series of deep dive blogs titled [Practical Gemini CLI](https://google-cloud/practical-gemini-cli-a-series-of-deep-dives-and-customisations-30afc4766bdf). If you liked this, then you might find more interesting ones there.  

