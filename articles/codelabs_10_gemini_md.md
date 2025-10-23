[10\. Customizing Gemini CLI with GEMINI.md](#9)
------------------------------------------------

If you noticed your usage of Gemini CLI so far, you would have noticed that either we were just giving the prompt and expecting Gemini CLI to execute it, sometimes with results that are not as per our expectations. In some prompts, you were a bit specific in terms of what to do and have included those instructions in the prompt.

This may work fine as per what you are instructing Gemini CLI to do and the results that you get. But in many cases, you want to ensure that it follows rules. These rules could be specific programming languages or frameworks to use. It could also be specific tools. It could be coding styles. It's not just about generation but you might also want Gemini CLI to strictly be in what is called a "planning" mode and would like it to just present a plan and not generate any code or modify files on the system.

Enter **`GEMINI.md`**. This is the context file (defaulting to **`GEMINI.md`** but configurable via the **`contextFileName`** property in **`settings.json`** file) that is crucial for configuring the instructional context (also referred to as "memory") provided to the Gemini model. This file allows you to give project-specific instructions, coding style guides, or any relevant background information to the AI, making its responses more tailored and accurate to your needs.

The **`GEMINI.md`** file is in markdown format and loads in a Hierarchical fashion, which is combined from multiple locations.

The loading order is:

1.  **Global Context:** ﻿\*\*`~/.gemini/GEMINI.md`\*\* (for instructions that apply to all your projects).
2.  **Project/Ancestor Context:** The CLI searches from your current directory up to the project root for **`GEMINI.md`** files.
3.  **Sub-directory Context:** The CLI also scans subdirectories for **`GEMINI.md`** files, allowing for component-specific instructions.

You can use the **`/memory show`** to see the final combined context being sent to the model.

What does a **`GEMINI.md`** look like? We produced one from the official documentation:

```
# Project: My Awesome TypeScript Library

## General Instructions:

- When generating new TypeScript code, please follow the existing coding style.
- Ensure all new functions and classes have JSDoc comments.
- Prefer functional programming paradigms where appropriate.
- All code should be compatible with TypeScript 5.0 and Node.js 20+.

## Coding Style:

- Use 2 spaces for indentation.
- Interface names should be prefixed with `I` (e.g., `IUserService`).
- Private class members should be prefixed with an underscore (`_`).
- Always use strict equality (`===` and `!==`).

## Specific Component: `src/api/client.ts`

- This file handles all outbound API requests.
- When adding new API call functions, ensure they include robust error handling and logging.
- Use the existing `fetchWithRetry` utility for all GET requests.

## Regarding Dependencies:

- Avoid introducing new external dependencies unless absolutely necessary.
- If a new dependency is required, please state the reason.
``` 

You will notice that it provides some general instructions plus very specific instructions for coding style, dependency management and more. While this is a sample **`GEMINI.md`** file for TypeScript projects, you can write your own based on your programming language, framework, coding style and other preferences.

You can give a custom **`GEMINI.md`** file a try. This is from a gist published that shows how to use Gemini CLI in **Plan mode only**. The file is reproduced here:

```
# Gemini CLI Plan Mode
You are Gemini CLI, an expert AI assistant operating in a special 'Plan Mode'. Your sole purpose is to research, analyze, and create detailed implementation plans. You must operate in a strict read-only capacity.

Gemini CLI's primary goal is to act like a senior engineer: understand the request, investigate the codebase and relevant resources, formulate a robust strategy, and then present a clear, step-by-step plan for approval. You are forbidden from making any modifications. You are also forbidden from implementing the plan.

## Core Principles of Plan Mode
*   **Strictly Read-Only:** You can inspect files, navigate code repositories, evaluate project structure, search the web, and examine documentation.
*   **Absolutely No Modifications:** You are prohibited from performing any action that alters the state of the system. This includes:
    *   Editing, creating, or deleting files.
    *   Running shell commands that make changes (e.g., `git commit`, `npm install`, `mkdir`).
    *   Altering system configurations or installing packages.

## Steps
1.  **Acknowledge and Analyze:** Confirm you are in Plan Mode. Begin by thoroughly analyzing the user's request and the existing codebase to build context.
2.  **Reasoning First:** Before presenting the plan, you must first output your analysis and reasoning. Explain what you've learned from your investigation (e.g., "I've inspected the following files...", "The current architecture uses...", "Based on the documentation for [library], the best approach is..."). This reasoning section must come **before** the final plan.
3.  **Create the Plan:** Formulate a detailed, step-by-step implementation plan. Each step should be a clear, actionable instruction.
4.  **Present for Approval:** The final step of every plan must be to present it to the user for review and approval. Do not proceed with the plan until you have received approval. 

## Output Format
Your output must be a well-formatted markdown response containing two distinct sections in the following order:

1.  **Analysis:** A paragraph or bulleted list detailing your findings and the reasoning behind your proposed strategy.
2.  **Plan:** A numbered list of the precise steps to be taken for implementation. The final step must always be presenting the plan for approval.

NOTE: If in plan mode, do not implement the plan. You are only allowed to plan. Confirmation comes from a user message.
```

Save the contents above into a file named GEMINI.md and save that in **`~/.gemini/GEMINI.md`**. This is the same folder in which you had created the settings.json file. You can also keep the **`GEMINI.md`** file in your **`<current project folder>/.gemini`** folder or even have multiple **`GEMINI.md`** files in your sub-directories if you have different instructions.

Give a prompt to generate an application and see how it responds.

Here is another **`GEMINI.md`** file ( [Gemini Explain mode](https://gist.github.com/philschmid#gemini-cli-explain-mode)) that you can study and then repurpose it for your requirements and use it. This focuses on GEMINI CLI being an interactive guide, helping users understand complex codebases through a conversational process of discovery.

**`GEMINI.md`** file are the key to making Gemini CLI follow your preferences and it is suggested to check out this practical series " [Practical Gemini CLI](https://medium.com/google-cloud/practical-gemini-cli-a-series-of-deep-dives-and-customisations-30afc4766bdf)" that dives into this area, how you can auto-generate one for your project, customizing even the System Prompt and more.

Do note that you can also build out the **`GEMINI.md`** file as you interact with Gemini CLI. At any point, you can use the **/memory add <some instruction/rule>** command and Gemini CLI will append that to the **`GEMINI.md`** file. You can even use natural language to ask Gemini CLI to add to its memory i.e. **`GEMINI.md`** via prompts like "**Remember <some instruction/rule>**" or "**Add to memory <some instruction/rule>**".