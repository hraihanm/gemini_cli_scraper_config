[11\. Gemini CLI - Custom slash commands](#10)
----------------------------------------------

You've just seen how to customize **`GEMINI.md`** to create a plan mode. The previous section also provided you links to an Explain mode.

What if you wanted to configure both these modes and instruct Gemini CLI to go into any of these modes via **`/plan`** or **`/explain`** slash commands. This is exactly what Gemini CLI Custom slash commands are about.

As the [documentation](https://github.com/google-gemini/gemini-cli/blob/36750ca49b1b2fa43a3d7904416b876203a1850f/docs/cli/commands.md#custom-commands) states, "Custom commands allow you to save and reuse your favorite or most frequently used prompts as personal shortcuts within Gemini CLI. You can create commands that are specific to a single project or commands that are available globally across all your projects, streamlining your workflow and ensuring consistency."

Let us create a couple of Custom slash commands: **`/plan`** and **`/explain`**.

The next step is to understand where Gemini CLI picks up the Custom commands from. As per the documentation, it discovers commands from two locations, loaded in a specific order:

1.  User Commands (Global): Located in **`~/.gemini/commands/`**. These commands are available in any project you are working on.
2.  Project Commands (Local): Located in **`<your-project-root>/.gemini/commands/`**. These commands are specific to the current project and can be checked into version control to be shared with your team.

Let's pick the current project folder from where you have launched Gemini CLI. So this will be **`<your-project-root>/.gemini/commands/`** folder. Go ahead and create the folder structure.

What do we need to create inside this folder? We need two TOML files (**`plan.toml`** and **`explain.toml`**). You can read more on the namespaces and naming conventions if you'd like [here](https://github.com/google-gemini/gemini-cli/blob/36750ca49b1b2fa43a3d7904416b876203a1850f/docs/cli/commands.md#naming-and-namespacing).

Each TOML file needs to have two fields : **`description`** and **`prompt`**. Ensure that the description is short and crisp since it will be shown next to the command in the Gemini CLI. TOML file sample below is taken from the [official Custom slash commands blog post](https://cloud.google.com/blog/topics/developers-practitioners/gemini-cli-custom-slash-commands?e=48754805).

A sample plan.toml file is shown below. Notice that the prompt contains a special placeholder **`{{args}}`**, the CLI will replace that exact placeholder with all the text the user typed after the command name.

    description="Investigates and creates a strategic plan to accomplish a task."prompt = """Your primary role is that of a strategist, not an implementer.Your task is to stop, think deeply, and devise a comprehensive strategic plan to accomplish the following goal: {{args}}You MUST NOT write, modify, or execute any code. Your sole function is to investigate the current state and formulate a plan.Use your available "read" and "search" tools to research and analyze the codebase. Gather all necessary context before presenting your strategy.Present your strategic plan in markdown. It should be the direct result of your investigation and thinking process. Structure your response with the following sections:1.  **Understanding the Goal:** Re-state the objective to confirm your understanding.2.  **Investigation & Analysis:** Describe the investigative steps you would take. What files would you need to read? What would you search for? What critical questions need to be answered before any work begins?3.  **Proposed Strategic Approach:** Outline the high-level strategy. Break the approach down into logical phases and describe the work that should happen in each.4.  **Verification Strategy:** Explain how the success of this plan would be measured. What should be tested to ensure the goal is met without introducing regressions?5.  **Anticipated Challenges & Considerations:** Based on your analysis, what potential risks, dependencies, or trade-offs do you foresee?Your final output should be ONLY this strategic plan."""

Try to create an **explain.toml** file too. You can refer to [Gemini Explain mode](https://gist.github.com/philschmid#gemini-cli-explain-mode) to pick some content from.

Restart Gemini CLI. Now you will find that it has a slash command (**`/plan`**) as shown below:

![8b0720ba31b6c251.png](/static/gemini-cli-hands-on/img/8b0720ba31b6c251.png)