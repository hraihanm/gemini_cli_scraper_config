# Practical Gemini CLI: Bring your own system instruction  

If you have been using Gemini CLI for even a little bit, the fact that you can customise the way it works using a `GEMINI.md` file wouldn’t have escaped you.  
In fact this is very similar to any other AI‑based coding assistant tools, each of which has the ability to use an MD file to customise how the model behaves in the code base and to provide information and context that is specific to that code base.

Gemini CLI is no different. You will see a lot of gists with sample `GEMINI.md` files, such as this excellent set of gists by **Philipp Schmid** like [Plan mode](https://gist.github.com/philschmid/379cf06d9d18a1ed67ff360118a575e5) and [Explain mode](https://gist.github.com/philschmid/64ed5dd32ce741b0f97f00e9abfa2a30).

In case you missed it, I created an [Implement mode](https://gist.github.com/ksprashu/a714be14052266ef9a95f5c8ca1274cb) inspired by Philipp.

As you start working on such instructions, eventually you will end up with something more complex, spanning 100s of lines of markdown, which will end up confusing the model and it won’t follow instructions very well, and this is what folks fondly refer to as [context rot](https://simonwillison.net/2025/Jun/18/context-rot/).

So when I came up with these instructions that defines an elaborate [thinking workflow](https://gist.github.com/ksprashu/e844f8000538648119aaf65b42237aaf), and a comprehensive [tech stack selection guide](https://gist.github.com/ksprashu/567f6e2fcb30f933361e14e14a1b94ce), I was left scratching my head on why it wasn’t always following the defined instructions and I had to keep reminding Gemini CLI to follow the guidelines whenever it made a mistake.

That’s when I started doing some deep dive into the implementation of Gemini CLI and struck upon this amazing ability to override the system prompt of Gemini CLI.

## Uncovering the Core Prompt  

It felt obvious to me that some part of the core system instruction was overriding or conflicting with my own `GEMINI.md` instructions.  
Gemini CLI has core instructions hard‑coded in `packages/core/src/core/prompts.ts` within https://github.com/google-gemini/gemini-cli.

Something as simple as the below prompt will give you the comprehensive hard‑coded system prompt:

```text
There is a system prompt in the file @code/github/gemini-cli/packages/core/src/core/prompts.ts
Extract this content into @code/tmp/SYSTEM.md
```

I have saved the prompt (as on 20‑Jul‑2025) in [this gist](https://gist.github.com/ksprashu/61194be375dba10d8950df43e33742fb).

## Investigating the Core System Prompt  

When I was asking Gemini CLI (in Explain mode) to parse this hard‑coded system instruction, we discovered that the file also has a function called `getCoreSystemPrompt` that puts together the main instructions every single time you run a command.  
This instruction isn't just a simple "be helpful" line; it's a huge document that controls everything.

In there we found code that checks for an environment variable called `GEMINI_SYSTEM_MD`.  
It’s a built‑in, secret way to tell the CLI, “Hey, ignore your default rules and use my file instead!” This feature provides a method to completely replace the default system prompt with user‑defined content.

## The `GEMINI_SYSTEM_MD` Override Mechanism  

The `GEMINI_SYSTEM_MD` environment variable is the key to achieving advanced customization.  
It instructs the Gemini CLI to source its core behavioural instructions from an external file rather than its hard‑coded defaults.

- When the variable is set to `true` or `1`, the CLI searches for a file named `system.md` within a `.gemini` directory at the project's root. This approach is recommended for project‑specific configurations.
- Setting the variable to any other string value directs the CLI to treat that string as an absolute path to a custom markdown file.

**It is critical to note that the content of the specified file does not amend but completely replaces the default system prompt.**  
This offers significant control but requires careful implementation.

When a custom prompt is active, the CLI footer displays a `|⌐■_■|` icon, providing a persistent visual confirmation of the modified operational state.

This feature enables sophisticated use cases, such as enforcing strict project‑specific coding standards, simulating different developer personas (e.g., senior architect, security specialist), or distributing a standardized agent configuration across a development team to ensure operational consistency.

> Great, let’s just point it to our `GEMINI.md` file and we are done! Right?  
> Not!

If you read my [previous post on tool selection](https://medium.com/@ksprashu/practical-gemini-cli-tool-calling-52257edb3f8f), you’ll note that there are some specific and detailed instructions in the core system prompt that are essential and mandatory for the proper functioning of Gemini CLI.

Replacing the system prompt without properly reviewing it beforehand will not be a good idea.

## A Conceptual Framework for Configuration: `SYSTEM.md` vs. `GEMINI.md`

Working with Gemini CLI, after analysing my `GEMINI.md` file and how I wanted it to behave, we arrived at the following understanding.

### `SYSTEM.md`: The Firmware Layer  

> This file should contain the **fundamental, non‑negotiable operational rules** for the agent. Its purpose is to ensure the safe, stable, and correct execution of tools, independent of the specific task.

This layer is analogous to a system’s **BIOS or firmware**.  
It provides low‑level instructions on how to operate the available tools without necessarily understanding the high‑level objective.

This file is the appropriate location for strict tool usage protocols (e.g., mandating absolute file paths), security and safety directives (e.g., requiring explanations for destructive commands), and detailed workflow mechanics (e.g., the precise sequence for Git operations).

### `GEMINI.md`: The Strategic Layer  

> This file defines the **high‑level strategy, persona, and mission‑specific context** for a given task.

This layer can be compared to an **Operating System and a specific application**.  
It dictates the agent’s persona, its problem‑solving framework, and the ultimate goal, while relying on the “Firmware” (`SYSTEM.md`) for safe execution.

This file should contain persona definitions (“You are a senior Go developer specializing in performance optimization”), custom methodologies (“Follow the Perceive → Reason → Act → Refine loop”), and project‑specific information or high‑level technology guidelines.

### Merging the two files  

Here is where Gemini CLI itself can help immensely.  
It is able to do a proper diff of two files, compare the content, and ensure there isn’t any duplication or redundancy, and can merge the best parts of both files, or split the content as the case may be.

When I compared the system prompt that I extracted with the instructions in my [GEMINI.md file](https://gist.github.com/ksprashu/5ce25ae8e451eccdcc974f4f6cdbf031), I was able to remove redundant instructions from the `SYSTEM.md` file while keeping the best parts of `GEMINI.md`.

> Note: My `GEMINI.md` has been heavily modified as compared to the linked gists, but this is because I have introduced another pattern to fix a bloated instruction set, which I will talk about in the next blog.

### How I prompted this solution  

Initially I asked Gemini CLI to compare my two files:

```
I am using a comprehensive set of instructions located in @GEMINI.md. However,
the Gemini CLI also includes its own core system instructions, and I suspect they
are conflicting with my configured ones.

I have the option to set custom core instructions, which would override the
hardcoded system instructions. My concern is that doing so might cripple some
of the Gemini CLI's functionality.

I have extracted the core instructions into @SYSTEM.md.
Could you please review and compare @SYSTEM.md and @GEMINI.md and advise me on how
to proceed?
```

Then when it suggested the merges, I didn’t want to bloat the `GEMINI.md` file and I wanted it to modularise the files:

```
Is there anything in GEMINI.md that you will remove or modify?

There is an option to pass my own SYSTEM.md as the core instruction to the model
along with a GEMINI.md.

Do you think that will be a good option rather than make the GEMINI.md longer and more complex?
```

Now the model understood the task and clearly separated the responsibilities of both files.  
I asked it to check the files one last time and also asked it to clearly define the roles and responsibility of the 2 files. The output of this is what you read in the “Conceptual Framework” above.

> Approved. But Final question before we proceed.  
> Is there anything from GEMINI.md that you will move to SYSTEM.md to keep clear separation of concerns? How will you define GEMINI.md and SYSTEM.md? What are their roles and responsibilities?

You see that “Approved” bit? That is due to my custom instructions in `GEMINI.md` where I have asked Gemini CLI to always confirm with me before executing a major change or refactoring operation.

I was able to clearly define the role and responsibility of `GEMINI.md` vs `SYSTEM.md` thanks to Gemini CLI and it also split up the files very nicely such that there is no redundancy and no loss of instructions.

## Conclusion  

This layered model promotes a cleaner configuration architecture, allowing `GEMINI.md` to remain a high‑level strategic document while `SYSTEM.md` provides a robust and stable foundation of core operational safety.  
By leveraging this override mechanism, users can elevate the Gemini CLI from a general‑purpose assistant to a highly specialised and consistent tool tailored to specific development workflows and standards.

Did you too find an issue that your instructions weren’t being followed? Did you try this feature where you can override the system prompt? Let me know how this worked for you.