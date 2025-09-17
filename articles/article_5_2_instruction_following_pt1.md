# Practical Gemini CLI: Instruction Following — GEMINI.md hierarchy — Part 1

In the [last post](https://ksprashu.medium.com/practical-gemini-cli-instruction-following-system-prompts-and-context-d3c26bed51b6) you saw how the context may have some implicit information that could affect the results of what the model generates.

Typically in all Agentic AI Coding Assistants there is this magic file — `AGENT.md` (aka `GEMINI.md`, `CLAUDE.md` etc) which comes across as a silver bullet. It is fair to say that how this file is built and what is present in this file could make or break your experience.

Gemini CLI is no different. `GEMINI.md` plays a very important role. However the best thing about Gemini CLI is that it is Open Source. This means there is no suspense on how the CLI behaves — you can actually see the code, understand the logic, and structure your instructions in a way that makes the most sense to suit your use case.

This is super powerful and great power in your hands as a developer.

Let’s look at it practically.

### Default System Instructions

In the [previous post](https://ksprashu.medium.com/practical-gemini-cli-instruction-following-system-prompts-and-context-d3c26bed51b6), we didn’t have any `GEMINI.md` files, but we did see the instructions in the hard coded system prompt. Given that, the prompt to generate a simple web app resulted in a basic HTML + CSS + JS app.

I’m using a similar prompt again —

> Create a web page that displays a single word in a large bold font in the center of the screen and upon mouse click anywhere on the page the text color and background color changes.

This creates a 3 file app like before.

![](https://miro.medium.com/v2/resize:fit:254/1*WjaeMpHfi9AkbvSuYmVp7Q.png)

With a random text as the output that changes colors upon clicking anywhere on the screen.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*Bbwc8l5Z-Bpi06TGLJ8j-Q.gif)

Let’s now start to see how to customise it with `GEMINI.md`

### My first `GEMINI.md` file

I am going to create a local file and add an instruction in it to run a server always and run it on port 3003.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:838/1*xpAnaHdooym36P2r4nCjyw.png)

Now I will run the same prompt to generate the simple web app.

When you run Gemini CLI you will notice that it has picked up and is using 1 `GEMINI.md` file. This number will give you the indication of what all is “influencing” Gemini CLIs behaviour.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*CaBy7nXE-GwmasAMw1hW9w.png)

And very easily, I have Gemini CLI following my explicit instructions.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*gT6S9sW72tmQIX2GOrGvJA.png)

### GEMINI.md hierarchy

But, that’s not all. Gemini CLI also follows the hierarchy of `GEMINI.md` files. It goes up the folder tree and picks up any `GEMINI.md` file along the way and adds that context to the instructions too.

What I have now is a folder hierarchy — `tmp/test3/test2` with the following instructions.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*m6_vWOWMUY8J2WVCLwb2sg.png)

Now let’s run our favourite prompt. You can see that it has picked up 2 `GEMINI.md` files in the path.

![](https://miro.medium.com/v2/resize:fit:601/1*nYbo1Iioi1VvlQaKtKVNmQ.png)

Recall it would previously always create a 3 file (.html, .css, .js) app.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*_NVoHH62_7KeCbFTwVBnzg.png)

Now we have a single `.html` file just as we had requested.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*PR7fGAI9hldrjgcxWCaRjg.png)

And it still follows the instructions to run a server after creating / modifying a web page, on port 3003.

But, there is yet another hierachy that Gemini CLI follows when picking up `GEMINI.md` files, and that is in the `.gemini/` folder in the HOME dir — `~/` in the case of Mac / Linux.

Let’s keep the system instruction aside for now and I have created an instruction in the `~/.gemini/` folder.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*tQ4oHvDtB_sDsRQ_1_UbXA.png)

Running the file, as expected, we now have a HTML in one page, using JQuery selectors.

![](https://miro.medium.com/v2/resize:fit:625/1*ZwWLMidt7ExQw8sWWXbtug.png)

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*-MkGUWal1qhwxIv4mTMPZA.gif)

JQ powered app

### Adding more complexity.

It’s all fun and games so far. Let’s take it up a notch.

I will now create 3 folders within `test3/test3` called `a`, `b`, `c`. I will create 3 `GEMINI.md` files with them. Now we have a set up that look like this —

![](https://miro.medium.com/v2/resize:fit:298/1*iNV-lPyNrxxJvHHDhRPmFw.png)

And we have the following `GEMINI.md` files.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*eqQpAmPm4CO2LhAXYzMfJw.png)

IMPORTANT: We will now run gemini from the `test3/test3` folder, which means `a`, `b`, and `c` are subfolders from where I am running `gemini`.

Take a look at this now.

![](https://miro.medium.com/v2/resize:fit:586/1*7ie39Ok_Mq2AcL1aXmTRnA.png)

Do you see it? 6 `GEMINI.md` files.

I have 1 in the current dir, 1 in the parent dir, and 1 in the user HOME dir `~`. Where did the other 3 come from?

Gemini CLI, also traverses `down` the subdirectory hierarchy, and not just `up` in order to fetch the `GEMINI.md` files.

So, with all these conditions and restrictions and hierachy of instructions, this is what Gemini CLI decided to write for me.

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*J8sq-n0BPHFP1zpKWrzNBA.png)

A perfect amalgamation of all rules provided!

Press enter or click to view image in full size

![](https://miro.medium.com/v2/resize:fit:875/1*IunzZOuxKxB24B_ou99ECw.gif)

Wonderful no?

### Key takeaway

While this seems trivial / frivolous, the point is this —

Software development is a complex endeavour. There are various signals — from the codebase, from the folder structure, to the hierarchy of instructions. What you think you see is probably not the whole picture.

When you understand how the system behaves, you are able to understand what is happening, possibly predict what will happen, and use this knowledge to set clear direction to the AI to build what you intend as an output.

### Next is what?

But then, this must beg the next question. What about conflicts? Which file overrides the others? What is the order of precedence?

To answer this question, look to the [upcoming blog](https://ksprashu.medium.com/practical-gemini-cli-instruction-following-gemini-md-hierarchy-part-2-84386bba51a6). 😊

Further Reading
---------------

This blog is part of the series of deep dive blogs titled [Practical Gemini CLI](/google-cloud/practical-gemini-cli-a-series-of-deep-dives-and-customisations-30afc4766bdf). If you liked this, then you might find more interesting ones there.