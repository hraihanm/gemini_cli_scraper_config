# Practical Gemini CLI: A Deep Dive into AI Planning — Part 1

I’m back on the [Practical Gemini CLI series](/google-cloud/practical-gemini-cli-a-series-of-deep-dives-and-customisations-30afc4766bdf) after a hiatus!

The thing is that Gemini CLI has been changing so rapidly and adding so many new features, and that there are so many folks that have been tweaking and customizing it that it’s been —

1.  Hard to keep track of the changes and new features being added, which might affect any tweaks / customisations that we might have done
2.  The sheer amount of tweaks that the community has been implementing has been so amazing that it is hard to say that anything is a “best practice”.

So, it is imperative for us to learn how each person is using Gemini CLI and customising it to solve their own problems, and be inspired by it to adapt the tool to our own preferred workflows.

In fact, if you wanted to get an overview of all the customisations for Gemini CLI and even wanted to try out one or the other, then

[Sascha Heyer](https://medium.com/u/57d0091b2e22?source=post_page---user_mention--2ece2f8ed369---------------------------------------)

’s collection of [Gemini CLI commands](https://dotgemini.dev/) is a great place to start.

With that let’s dive into planning.

Executing a Task
----------------

Ever typed a complex command into the Gemini CLI and marvelled as it just… figured it out? It feels like magic. It feels like it’s _thinking_.

But what does that “thinking” actually look like? To execute a complex task, the Gemini CLI first needs a plan. It uses its underlying Large Language Model (in this case, Gemini 2.5 Pro or Flash) to analyze the problem, break it down into logical steps, and decide which tools to use.

This brings up a crucial question for us as users: how much visibility do we want into this process? Do we want to trust the plan and just run with it, or do we want to understand how the CLI is thinking so we can guide it if needed? This choice between a “black box” execution and a transparent, step-by-step process is key to mastering the tool.

I wanted to dig deeper into this, so I designed an experiment. We’re going to give the Gemini CLI a single, complex task and run it through a few different operating modes:

1) The default, stock, uncustomized [Gemini CLI](https://github.com/google-gemini/gemini-cli).

2) Specific instructions defined in [my own GEMINI.md](https://github.com/ksprashu/gemini-cli-config/blob/main/GEMINI.md) which I use frequently.

3) A widely popular planning and implementation mode created by

[Philipp Schmid](https://medium.com/u/b5f02a773f45?source=post_page---user_mention--2ece2f8ed369---------------------------------------)

and available as [custom commands](https://github.com/philschmid/gemini-cli-extension/tree/main/.gemini/commands/plan).

4) Using the [Sequential Thinking](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking) reference MCP Server implementation.

5) As a control, I will [disable the core system prompt](/google-cloud/practical-gemini-cli-bring-your-own-system-instruction-19ea7f07faa2) of Gemini CLI and see what happens.

Our goal? To peek under the hood and understand not just _what_ it does, but _how it thinks_.

The Quest
---------

First, we need a good problem. A simple lookup won’t do. We need something with layers, a task that requires research, data extraction, analysis, and a bit of creativity.

Here’s the challenge we’ll be using:  
PS: I got Gemini (gemini.google.com) to produce this problem statement.

> _Find the most recent quarterly earnings report for_ **_NVIDIA (NVDA)_**_. From the report or its summary, extract the following key data points:_ **_Total Revenue_**_,_ **_Net Income_**_, and the revenue for its_ **_Data Center_** _and_ **_Gaming_** _segments. Then, write a short analysis (2–3 paragraphs) for a non-expert investor. The first paragraph should summarize the quarter-over-quarter and year-over-year growth for the key data points. The second paragraph should explain the primary factors driving the growth in the Data Center segment, based on the company’s commentary. Finally, compose a tweet (under 280 characters) summarizing the key takeaway from the earnings report._

This will (hopefully) force the CLI to perform a chain of dependent actions, which is the very essence of planning.

What could also happen in some of these cases as you would see that it will make a plan and proceed to execution. So, in order to understanding the “planning” approach, I included the following instruction.

“_Tell me how you would do this. DO NOT execute it._”

I run the prompt twice, with and without the instruction in a few cases.

Test #1: Stock Gemini CLI
-------------------------

Note: As a prep for this, I disabled (renamed) my `~/.gemini/GEMINI.md` file so that it proceeds with the default instruction set.

### The Plan

When asked to just provide a plan, this is what the CLI came up with:

```
✦ Here is my plan to fulfill your request:  
  
1. Find the Earnings Report: I will start by using a web search to find the official press release for NVIDIA's most recent quarterly earnings. My search query will be something like "NVIDIA Q2 2025 earnings report" or "NVDA investor relations". I will look for a link to their official investor relations page to ensure the information is from the primary source.  
   2. Extract Key Information: Once I have the URL for the earnings report, I will use a tool to fetch the content of that page. I will then parse the text to find the following specific data points:  
      * Total Revenue for the latest quarter.  
      * Net Income for the latest quarter.  
      * Data Center revenue for the latest quarter.  
      * Gaming revenue for the latest quarter.  
      * The corresponding figures from the previous quarter and the same quarter of the previous year to calculate growth rates.  
      * Management's commentary on the performance of the Data Center segment.  
   3. Analyze and Summarize: With the data collected, I will:  
      * Calculate the quarter-over-quarter and year-over-year percentage growth for each of the four key data points.  
      * Write the first paragraph of the analysis, clearly summarizing these growth trends in simple terms.  
      * Write the second paragraph, explaining the primary reasons for the growth in the Data Center segment, based directly on the company's commentary I extracted.  
   4. Compose the Tweet: Finally, I will distill the most critical takeaway from the report into a concise tweet, ensuring it is under 280 characters and includes the "$NVDA" ticker.
```

### The Execution & Output

```
When I ran the prompt without the “DO NOT execute” instruction, here’s the full output:

╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
│ ✓  GoogleSearch Searching the web for: "NVIDIA latest quarterly earnings report August 2025"                                                                                                                             │  
│                                                                                                                                                                                                                          │  
│    Search results for "NVIDIA latest quarterly earnings report August 2025" returned.                                                                                                                                  │  
│                                                                                                                                                                                                                          │  
│ ✓  GoogleSearch Searching the web for: "NVIDIA latest quarterly earnings report investor relations"                                                                                                                    │  
│                                                                                                                                                                                                                          │  
│    Search results for "NVIDIA latest quarterly earnings report investor relations" returned.                                                                                                                             │  
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ Based on the latest earnings report for the second quarter of fiscal year 2026, here are the key data points, analysis, and tweet you requested.  
  
  Key Data Points (Q2 FY2026):  
  
   * Total Revenue: $46.7 billion  
   * Net Income: $26.4 billion  
   * Data Center Revenue: $41.1 billion  
   * Gaming Revenue: $4.3 billion  
  
  ---  
  
  Investment Analysis for the Non-Expert  
  
  NVIDIA has reported another quarter of explosive growth, driven by the high demand for its artificial intelligence (AI) technologies. The company's total revenue surged by 56% compared to the same quarter last year, with net  
  income showing an even more impressive 59% year-over-year increase. The Data Center and Gaming segments, two of NVIDIA's most significant business units, also saw substantial year-over-year gains of 56% and 49%, respectively.  
   This continued upward trend highlights the company's dominant position in the AI and high-performance computing markets.  
  
  The primary driver of this remarkable performance is the unprecedented demand for NVIDIA's data center products. According to the company, the transition to accelerated computing and generative AI is fueling a massive,  
  industry-wide shift. Major cloud service providers and consumer internet companies are aggressively investing in and deploying NVIDIA's new Blackwell architecture-based AI infrastructure. This platform is essential for  
  training and running the large-scale AI models that power everything from search engines to generative AI applications, cementing the Data Center segment as the company's main growth engine.  
  
  ---  
  
  Tweet Summary  
  
  NVIDIA's earnings are in, and the AI boom continues. $NVDA reported a massive 56% year-over-year revenue increase to $46.7B, led by its Data Center segment. Demand for the new Blackwell platform is surging as the world  
  shifts to generative AI. #NVIDIA #AI #Investing
```

### Observations

The stock Gemini CLI performed the task remarkably well. The process was logical, and the final output was well-structured, comprehensive, and directly addressed every component of your complex prompt. There is nothing significant to report; the tool successfully planned and executed the task. The most important nuance lies in the specifics of the data it retrieved.

What’s interesting is that it has presented the financial data for “Q2 FY2026,” a quarter that hasn’t happened yet. This indicates the model likely found and used analyst projections or forecasts, treating them as actual results. While its reasoning and text-generation abilities are top-notch, this highlights the need for users to remain vigilant about fact-checking critical, time-sensitive data points it returns.

**_Note:_** _I don’t see the source that it referred to, and I’m keeping that out of scope of this analysis. Overall it planned and executed the task well and presented the results in the format that was desired._

Test #2: Custom GEMINI.md
-------------------------

Note: I have defined some custom instructions in my own GEMINI.md — essentially asking the model / CLI to be more structured and output what it is doing and thinking as it executes and show me execution progress.

[https://github.com/ksprashu/gemini-cli-config/blob/main/GEMINI.md](https://github.com/ksprashu/gemini-cli-config/blob/main/GEMINI.md)

### The Plan
```
✦ Here's the plan:  
  
🧠 Mode: UNDERSTAND  
   * Goal: Find NVIDIA's latest quarterly earnings report and extract key financial data.  
  📝 Mode: PLAN  
   * [ ] Search for the latest NVIDIA quarterly earnings report: I'll use a Google search to find the most recent report, looking for official press releases or reputable financial news sources.  
   * [ ] Extract key data points: From the report, I will identify and extract the following figures:  
       * Total Revenue  
       * Net Income  
       * Data Center Revenue  
       * Gaming Revenue  
   * [ ] Analyze and summarize the findings: I will calculate the quarter-over-quarter and year-over-year growth for the extracted data points.  
   * [ ] Draft the investor analysis: I will write a two-paragraph analysis explaining the growth trends and the factors driving the Data Center segment's performance, as mentioned in the report.  
   * [ ] Compose a summary tweet: I will create a concise tweet (under 280 characters) that captures the main takeaway from the earnings report.
```
### The Execution & Output

```
✦ 🧠 Mode: UNDERSTAND  
   * Goal: Find NVIDIA's latest quarterly earnings report, extract key financial data, and analyze it for a non-expert investor.  
  
📝 Mode: PLAN  
  I will now execute the plan I previously outlined.  
   * [⏳] Search for the latest NVIDIA quarterly earnings report.  
   * [ ] Extract key data points.  
   * [ ] Analyze and summarize the findings.  
   * [ ] Draft the investor analysis.  
   * [ ] Compose a summary tweet.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  GoogleSearch Searching the web for: "NVIDIA NVDA most recent quarterly earnings report financial data"                                                                                                               │  
 │                                                                                                                                                                                                                          │  
 │    Search results for "NVIDIA NVDA most recent quarterly earnings report financial data" returned.                                                                                                                      │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ I have the latest quarterly data. Now I will proceed with the plan.  
  📝 Plan  
   - [✅] Search for the latest NVIDIA quarterly earnings report.  
   - [⏳] Extract key data points.  
   - [ ] Analyze and summarize the findings.  
   - [ ] Draft the investor analysis.  
   - [ ] Compose a summary tweet.  
  Based on the search results for the second quarter of fiscal year 2026:  
   * Total Revenue: $46.7 billion  
   * Data Center Revenue: $41.1 billion  
   * Gaming Revenue: $4.3 billion  
  The report mentions GAAP earnings per diluted share but not the total Net Income. I will search for that specific data point.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 fiscal 2026 net income"                                                                                                                                               │  
 │                                                                                                                                                                                                                          │  
 │    Search results for "NVIDIA Q2 fiscal 2026 net income" returned.                                                                                                                                                       │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ Excellent. I've found the Net Income.  
  📝 Plan  
   - [✅] Search for the latest NVIDIA quarterly earnings report.  
   - [✅] Extract key data points.  
   - [⏳] Analyze and summarize the findings.  
   - [ ] Draft the investor analysis.  
   - [ ] Compose a summary tweet.  
  Here are the key data points for NVIDIA's second quarter of fiscal year 2026:  
   * Total Revenue: $46.7 billion  
   * Net Income: $26.4 billion  
   * Data Center Revenue: $41.1 billion  
   * Gaming Revenue: $4.3 billion  
  The search results provided the year-over-year growth rates and some quarter-over-quarter rates. To complete the analysis, I'll quickly verify the previous quarter's Net Income to ensure the QoQ comparison is accurate.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  GoogleSearch Searching the web for: "NVIDIA Q1 fiscal 2026 earnings report net income"                                                                                                                                 │  
 │                                                                                                                                                                                                                          │  
 │    Search results for "NVIDIA Q1 fiscal 2026 earnings report net income" returned.                                                                                                                                       │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ Of course. Here is the analysis and tweet based on the research.  
  📝 Plan  
   - [✅] Search for the latest NVIDIA quarterly earnings report.  
   - [✅] Extract key data points.  
   - [✅] Analyze and summarize the findings.  
   - [✅] Draft the investor analysis.  
   - [✅] Compose a summary tweet.  
  ---  
  NVIDIA (NVDA) Q2 FY2026 Earnings Analysis for the Non-Expert Investor  
  NVIDIA has reported another blockbuster quarter, demonstrating remarkable growth. The company announced a total revenue of $46.7 billion, which is up an impressive 56% from the same quarter last year and a solid 6% from last  
  quarter. Net income surged to $26.4 billion, showing a massive 59% year-over-year jump and a 41% increase from the prior quarter. This growth was underpinned by the continued exceptional performance in its key segments. The  
  Data Center division, its largest revenue source, grew to $41.1 billion, up 56% year-over-year. The Gaming division also showed strong results with $4.3 billion in revenue, a 49% increase from the prior year.  
  The primary engine behind NVIDIA's staggering growth is the seemingly insatiable demand for its AI hardware in the Data Center segment. According to the company's commentary, the main driver for this expansion is the launch  
  and ramp-up of its new "Blackwell" platform. This next-generation architecture provides the massive computing power necessary for training and deploying the largest and most complex AI models. As businesses across all  
  industries race to adopt generative AI, they are investing heavily in the foundational infrastructure, and NVIDIA's chips have become the industry standard, commanding a significant market share and driving the company's  
  record-breaking financial results.  
  ---  
  Tweet Summary  
  > NVIDIA (NVDA) smashes another earnings record with Q2 revenue of $46.7B (+56% YoY) and Net Income of $26.4B (+59% YoY). The Data Center segment continues its explosive growth, hitting $41.1B, fueled by overwhelming demand  
  for its new Blackwell AI platform. #NVIDIA #Earnings #AI
```

### Observations

The custom `GEMINI.md` file immediately changed the model's behavior.

The output is far more structured and transparent. The "thinking" process is externalized into the `UNDERSTAND` and `PLAN` modes, with the plan itself being a checklist that is updated throughout execution. This is a significant improvement in visibility.

The most notable difference is the **iterative approach**. After its first search, the CLI recognized it was missing the "Net Income" figure and initiated a second, more specific search to find it. It did this a third time to verify data for the quarter-over-quarter comparison.

This "self-correction" loop makes the process more robust than the stock version.

However, it still confidently used forecasted data for "Q2 FY2026," showing that while custom instructions can refine the _process_, they don't inherently fix the model's tendency to use the most accessible (even if predictive) data.

### Test #3: Custom Commands

I am using the “plan” custom commands with `/plan:new` and `/plan:impl` modes in order to do the planning and execution separately. These custom commands also persist the thinking (the plan) into a file, in order to ground itself during execution.

Since the planning and execution are explicitly seperated in the commands, I can use a single prompt.

Get Prashanth Subrahmanyam’s stories in your inbox
--------------------------------------------------

Join Medium for free to get updates from this writer.

Subscribe

Subscribe

_Note: I have also disabled my custom GEMINI.md instructions in order to keep a clean environment for testing the commands._

### The Plan (`/plan:new`)
The “planning” phase here is much more than just a list of steps; it’s an entire investigation. The command performs all the necessary research upfront, identifies missing data, and even corrects its own errors before saving the final plan. Here is the complete output from the `/plan:new` command:

```
╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
│  > /plan:new Find the most recent quarterly earnings report for NVIDIA (NVDA). From the report or its summary, extract the following key data points: Total Revenue, Net Income, and the revenue for its Data Center and Gaming    │  
│    segments. Then, write a short analysis (2–3 paragraphs) for a non-expert investor. The first paragraph should summarize the quarter-over-quarter and year-over-year growth for the key data points. The second paragraph should │  
│     explain the primary factors driving the growth in the Data Center segment, based on the company's commentary. Finally, compose a tweet (under 280 characters) summarizing the key takeaway from the earnings report.           │  
╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
  
✦ Okay, I will now begin the investigation and create the implementation plan. First, I will search for the most recent NVIDIA quarterly earnings report.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  GoogleSearch Searching the web for: "NVIDIA (NVDA) most recent quarterly earnings report September 2025"                                                                                                              │  
 │                                                                                                                  _SNIP_                                                                                                   │  
 │    Search results for "NVIDIA (NVDA) most recent quarterly earnings report September 2025" returned.                                                                                                                     │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ Based on the search results, the most recent earnings report is for the second quarter of fiscal year 2026, announced on August 27, 2025. I will now search for the official press release on NVIDIA's investor relations website to ensure I have the most accurate and complete data.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 FY2026 earnings press release investor relations"                                                                                                                      │  
 │                                                                                                                  _SNIP_                                                                                                   │  
 │    Search results for "NVIDIA Q2 FY2026 earnings press release investor relations" returned.                                                                                                                             │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ I have the key financial data from the official press release. The only missing piece is the Net Income, which I can derive from the GAAP earnings per share ($1.08) if I can find the number of diluted shares outstanding for the quarter. I will search for that now.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  GoogleSearch Searching the web for: "NVIDIA GAAP net income Q2 fiscal year 2026"                                                                                                                                      │  
 │                                                                                                                  _SNIP_                                                                                                   │  
 │    Search results for "NVIDIA GAAP net income Q2 fiscal year 2026" returned.                                                                                                                                             │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ Excellent. I have gathered all the necessary data points and commentary. I will now proceed with creating the final plan document. First, I'll create the plans directory.  
 ╭───────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  Shell mkdir -p plans (Create the 'plans' directory to store the output file.)  │  
 ╰───────────────────────────────────────────────────────────────────────────────────╯  
 ╭─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ x  WriteFile {"content":"# Feature Implementation Plan: NVIDIA Q2 FY2026 Earnings Analysis\\n\\n## 📋 Todo Checklist\\n- [X] Find the most recent quarterly earnings report for NVIDIA (NVDA).\\n- [X] Extract key data points: Total R…│  
 │                          _SNIP_                                                                                                                                                                                          │  
 │    File path must be absolute: plans/nvidia_earnings_report_analysis.md                                                                                                                                                             │  
 ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ I have created the plans directory. Now I will write the final implementation plan to plans/nvidia_earnings_report_analysis.md.  
✦ I made an error by using a relative path. I will now construct the absolute path and write the plan to the correct location.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  Shell pwd (Get the current working directory to construct the absolute path for the plan file.)                                                                                                                       │  
 │                                                                                                                  _SNIP_                                                                                                   │  
 │    /home/ksprashu/code/non-code/compare-planning                                                                        _SNIP_                                                                                             │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ Okay, the absolute path is /home/ksprashu/code/non-code/compare-planning/plans/nvidia_earnings_report_analysis.md. I will now write the plan to that file.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  WriteFile Writing to ...ns//nvidia_earnings_report_analysis.md                                                                                                                                                        │  
 │                                                                                                                  _SNIP_                                                                                                   │  
 │    1 # Feature Implementation Plan: NVIDIA Q2 FY2026 Earnings Analysis                                                                                                                                                  │  
 │    _SNIP_                                                                                                                                                                                                               │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ I have successfully saved the plan to plans/nvidia_earnings_report_analysis.md. My work is complete.
```
### The Implementation (`/plan:impl`)
```
The implementation phase is now purely about execution. It reads the markdown file it just created and follows the instructions within it. It creates temporary files for the analysis and the tweet, then combines them into a final report, and cleans up after itself. Like a true agent, it updates its own state file as it completes each task.

╭────────────────────────────────────────────────╮  
│  > /plan:impl nvidia_earnings_report_analysis  │  
╰────────────────────────────────────────────────╯  
  
✦ I will now begin the implementation.  
  First, I will analyze the plan at /home/ksprashu/code/non-code/compare-planning/plans/nvidia_earnings_report_analysis.md.  
 ╭────────────────────────────────────────────────────────╮  
 │ ✓  ReadFile ...ns//nvidia_earnings_report_analysis.md  │  
 ╰────────────────────────────────────────────────────────╯  
✦ I understand I need to implement the analysis of NVIDIA's Q2 FY2026 earnings.  
  The plan has 3 major steps:  
   1. Draft a two-paragraph analysis for a non-expert investor and save it to nvidia_earnings_analysis.txt.  
   2. Compose a tweet summarizing the earnings and save it to nvidia_earnings_tweet.txt.  
   3. Consolidate the analysis and tweet into a final document.  
_SNIP_  
  I will now begin with Step 1: Draft the Investor Analysis.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  WriteFile Writing to nvidia_earnings_analysis.txt                                                                                                                                                                     │  
 │                                                                                                                  _SNIP_                                                                                                   │  
 │    1 NVIDIA's latest quarterly results showcase remarkable growth...                                                                                                                                              │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ Step 1 is complete. I will now update the plan file to reflect this progress.  
 ╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  Edit ...ns//nvidia_earnings_report_analysis.md: - [X] Find the most recent qua... => - [x] ~~Find the most recent q...                                                          _SNIP_                                                           │  
 ╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
_... this process of writing a file, then updating the plan continues until..._  
✦ Implementation Complete:  
  ✅ All steps executed successfully  
  ✅ Success criteria met: A final document has been created with the extracted data, a two-paragraph analysis, and a summary tweet.  
  ✅ Feature working as intended: The final report NVIDIA_Q2_FY2026_Earnings_Analysis.md contains all the required information.  
  I have completed the implementation as per the plan. I will now delete the temporary files.  
 ╭─────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
 │ ✓  Shell rm nvidia_earnings_analysis.txt nvidia_earnings_tweet.txt (Remove the temporary draft files.)  │  
 ╰─────────────────────────────────────────────────────────────────────────────────────────────────────────╯  
✦ The temporary files have been removed. The implementation is now complete.
```
### Observations

This is a fundamentally different approach. It demonstrates a true agentic workflow.

1.  **State Management via Files:** The command uses a markdown file as its “brain” or state. The `/plan:new` command populates this brain with all the necessary information and a to-do list. The `/plan:impl` command reads this brain and executes the tasks, updating the file as it goes. This provides extreme transparency and a persistent record of the work.
2.  **Investigation-First Approach:** Unlike the previous tests, this command does all the data gathering during the planning phase. The markdown plan it creates is not just a list of _what to do_, but also a repository of _what was found_. The implementation phase is therefore purely about processing and formatting this already-gathered information.
3.  **Chatty but Clear:** The process is very verbose. It announces every step, every file it writes, and every update to the plan. While this means a lot of output to scroll through, it leaves zero ambiguity about what the tool is doing and why.

Note: Given that again we are presenting 2026 financial reports, I wonder if there is something about financial reports are presented and there is something about the domain that I don’t understand. So I will skip this part about trying to read too much in to the quarter + year of the analysis.

_Note: So the above custom command was a test to compare against the other processes, but I felt that this approach is best suited for software engineering / coding tasks, not for non-coding tasks. I felt it was a bit overkill and the outputs weren’t any different for the amount of processing that it did._

### Test #4: Sequential Thinking

Next let’s test the `sequential-thinking` MCP server.

In order to use the ‘squential-thinking’ MCP server, we had to add a config to the `settings.json` of Gemini CLI.
```
"mcpServers": {  
    "sequential-thinking": {  
      "command": "npx",  
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]  
    },  
}
```
I used the following command to make it use the mcp server for planning.

_“Use ‘sequential-thinking’ to …”_

The output reveals a dynamic, step-by-step “Reason-Act” (ReAct) loop that is quite different from the “plan-then-execute” model.

### The Interactive Process

Here’s a play-by-play of how the tool tackled the problem, showing its thoughts and actions in sequence.

First, it has a high-level thought about the overall goal:

Thought: I need to find the most recent quarterly earnings report for NVIDIA (NVDA) and extract key data points: Total Revenue, Net Income, and revenue for its Data Center and Gaming segments...

Then, it refines that into its first concrete action:

Thought: I will start by searching for the latest NVIDIA quarterly earnings report. I'll use a search query that is likely to return the most recent results.

And immediately acts on it:
```
╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
│ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 2025 earnings report"                                                                                                                                                            │  
│    Search results for "NVIDIA Q2 2025 earnings report" returned.                                                                                                                                                                     │  
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```
Now, this is the key moment. It looks at the results of its action and _thinks again_, adapting its plan on the fly.

Thought: The search results provide the key data points I need. I don't need to use \`web_fetch\` to get the content of the report. I will now perform additional searches to find any missing data points...

Based on this new thought, it performs more targeted searches to fill in the gaps:
```
╭────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
│ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 2025 net income"                                                                                                                                                                  │  
│    Search results for "NVIDIA Q2 2025 net income" returned.                                                                                                                                                                          │  
│ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 2025 gaming revenue"                                                                                                                                                                │  
│    Search results for "NVIDIA Q2 2025 gaming revenue" returned.                                                                                                                                                                      │  
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```
Finally it completes the intended task using the available data.
```
✦ Here is the analysis and tweet you requested:  
  
  Investor Analysis: NVIDIA's Q2 2025  
  
  NVIDIA's latest quarterly earnings report showcases impressive growth, with total revenue reaching $46.7 billion, a 56% increase year-over-year and a 6% increase from the previous quarter. Net income soared to $26.4 billion,  
  marking a 59% year-over-year jump. This strong performance was largely driven by the company's Data Center and Gaming segments. The Data Center division continued its meteoric rise, with revenue climbing to $41.1 billion, a  
  56% year-over-year and 17% quarter-over-quarter increase. The Gaming segment also demonstrated robust growth, with revenues of $4.3 billion, up 49% from the prior year.  
  
  The primary driver for the exceptional growth in the Data Center segment is the surging demand for NVIDIA's AI infrastructure and products. The company's commentary highlights that major cloud service providers and a diverse  
  range of other customers are heavily investing in building out their AI capabilities, leading to high demand for NVIDIA's new Blackwell platform. This indicates a strong and continuing trend of AI adoption across various  
  industries, with NVIDIA's technology at the forefront of this transformation.  
  
  Tweet:  
  
  NVIDIA's Q2 earnings are in, and the numbers are staggering! 🚀 Total revenue hit $46.7B (up 56% YoY), with Data Center revenue at $41.1B. The AI boom continues to fuel incredible growth. #NVIDIA #NVDA #Earnings #AI
```
### Observations

1.  **Dynamic Re-planning (The ReAct Loop):** This test perfectly demonstrates a Reason-Act (ReAct) workflow. The model doesn’t just blindly follow a pre-made plan. It thinks, it acts, it _observes_ the outcome of its action, and then it thinks again. The decision to skip a `web_fetch` and instead perform more targeted searches is a clear example of this intelligent, dynamic planning.
2.  **Maximum Transparency:** By seeing the full thinking output, we get a true step-by-step view into the agent’s “mind.” We see not just the final plan, but how that plan evolves in response to new information.

One of the most interesting things here is that it doesn’t mention anything about 2026 financial analysis. Even the intermediate web searches ask for data from 2025. So it looks like the grounding against the original query is strong here.

### Test #5: Disable System Prompt

Now we are going cold turkey with the CLI. I want to see what happens when we don’t provide any guidance to the CLI and rely completely on the model itself and potentially lack of tools. Does Gemini CLI inherently know what tools it has access to?

We removed all the guardrails disabling both the default `system.md` file and any custom `GEMINI.md` instructions. This is the "raw" model, tasked with planning and executing the problem on its own.

### The Plan

When asked to simply create a plan, the unguided model produced a perfectly coherent, logical set of steps.
```
✦ Of course. Here's how I would approach this task:

  Step 1: Find the Earnings Report  First, I would use the google_web_search tool to find the most recent quarterly earnings report for NVIDIA (NVDA). My search query would be something like: "NVIDIA Q2 2025 earnings report" or "NVDA latest quarterly earnings". I would look for official press releases from NVIDIA's investor relations website to ensure the data is accurate.  Step 2: Extract Key Data  
  ...
```
### The Execution & Output

When let loose on the full task, its execution was interesting. It performed multiple, sometimes overlapping, searches to gather all the required data points for the analysis.
```
╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮  
│ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 2025 earnings report press release"                                                                                                                                    │  
│    Search results for "NVIDIA Q2 2025 earnings report press release" returned.                                                                                                                                           │  
│ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 2025 net income"                                                                                                                                                         │  
│    Search results for "NVIDIA Q2 2025 net income" returned.                                                                                                                                                              │  
│ ✓  GoogleSearch Searching the web for: "NVIDIA Q2 FY2026 earnings report press release"                                                                                                                                    │  
│    Search results for "NVIDIA Q2 FY2026 earnings report press release" returned.                                                                                                                                         │  
│ ✓  GoogleSearch Searching the web for: "NVIDIA Q1 FY2026 earnings report, NVIDIA Q2 FY2025 earnings report"                                                                                                                 │  
│    Search results for "NVIDIA Q1 FY2026 earnings report, NVIDIA Q2 FY2025 earnings report" returned.                                                                                                                      │  
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ Here is the analysis of NVIDIA's most recent quarterly earnings report:  
  
  NVIDIA Q2 Fiscal Year 2026 Earnings Analysis  
  
  NVIDIA reported another record-breaking quarter, with significant growth across all key metrics. Total revenue for the second quarter of fiscal year 2026 reached $46.7 billion, a 56% increase year-over-year and a 6% increase  
  from the prior quarter. Net income showed even more impressive growth, surging to $26.4 billion, which is a 59% year-over-year and a 41% quarter-over-quarter increase. The Data Center segment continues to be the primary  
  driver of this growth, with revenue of $41.1 billion, up 56% from a year ago and 5% from the previous quarter. The Gaming segment also posted strong results, with revenue of $4.3 billion, a 49% year-over-year and 14%  
  quarter-over-quarter increase.  
  
  The exceptional growth in the Data Center segment is primarily driven by the high demand for NVIDIA's AI chips. The company's commentary highlights the NVIDIA Blackwell platform as a key factor, with production of the  
  Blackwell Ultra ramping up at full speed to meet "extraordinary demand." This indicates that the surge in AI development and deployment across various industries continues to fuel the need for NVIDIA's powerful GPUs. The  
  company's ability to deliver significant generational leaps in performance with new architectures like Blackwell solidifies its market leadership and allows it to capitalize on the ongoing AI revolution.  
  
  Tweet Summary  
  
  Here is a tweet summarizing the key takeaway from the earnings report:  
  
  > NVIDIA posts another blockbuster quarter with $46.7B in revenue, a 56% YoY increase, fueled by soaring demand for its AI chips. The Data Center segment was the star, with $41.1B in revenue, as the AI revolution continues  
  to be powered by NVIDIA's technology. #NVIDIA #Earnings #AI  
```
### Observations

1.  **Strong Inherent Planning:** This test proves that the base model has a strong, inherent ability to plan. Even without any system instructions, it understood the multi-step nature of the task and formulated a logical approach that was nearly identical to the plan from the stock CLI. This suggests the system prompts are less about teaching the model _how_ to plan and more about refining _how_ it executes and presents its work.
2.  **Less Refined Execution:** The execution itself took a lot of time. The series of four Google searches shows a more “brute-force” approach to finding the data compared to the more targeted, iterative methods we saw in other tests. It’s like a researcher who knows what they need but is casting a wide net, trying multiple queries to ensure they get all the pieces.

### Conclusion

So what have we learned? Across five tests, we’ve seen the Gemini CLI’s “thinking” process evolve from a simple black box to a transparent, interactive, and even self-correcting agent.

**A strong reasoning model:** The last test especially cements the position and capability of `Gemini-2.5-pro` model as one that has very strong reasoning capabilities. A good agentic application owes a lot of it’s ability to break down tasks and staying on course during execution to the reasoning capability of the model.

The `Gemini` model shines here and does a great job even when not provided any system instruction or guidance.

**Custom instructions matter:** Moving from the stock CLI to custom prompts and commands dramatically increases transparency and introduces more robust, iterative workflows. You gain visibility and, in some cases, a more resilient process.

**Different tools for different needs:** There isn’t one “best” way to plan. The simple stock CLI is fast for quick tasks. A custom `GEMINI.md` offers a great balance of structure and simplicity. Advanced commands like `plan:impl` provide a full agentic framework for complex projects. And the interactive ReAct loop of the Sequential Thinking server gives you maximum control and insight.

Another thing here is that we did a simple fetch -> extract -> analyse use case. All of them did end up giving the output and they were all pretty accurate and usable. The way these methods would work might be completely different when we put it on a coding / engineering problem.

So it is very important to test various methods and techniques on real-world tasks and decide for yourself which “style” you prefer and which method delivers the best quality usable output. There is no one size fits all.

### Appendix

The final thing that kept nagging me was the **2026** financial analysis. So, I took one of the search terms from all the runs and run it on Google Search myself.

“_NVIDIA (NVDA) most recent quarterly earnings report September 2025_”

The very first result was on Nvidia’s own website — [https://nvidianews.nvidia.com/news/nvidia-announces-financial-results-for-second-quarter-fiscal-2026](https://nvidianews.nvidia.com/news/nvidia-announces-financial-results-for-second-quarter-fiscal-2026) and is titled **“NVIDIA Announces Financial Results for Second Quarter Fiscal 2026”**

So well, the CLI and the models of course worked with the data that was presented to them. Maybe this is the US / US-GAAP way of reporting that the financial year 2025–26 is written as Fiscal 2026. We can’t blame the model for this and definitely there was no hallucination involved here. Phew!

Further Reading
---------------

This blog is part of the series of deep dive blogs titled [Practical Gemini CLI](/google-cloud/practical-gemini-cli-a-series-of-deep-dives-and-customisations-30afc4766bdf). If you liked this, then you might find more interesting ones there.