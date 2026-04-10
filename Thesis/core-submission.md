# Core Standards Project Submission

## Submission Information

-   **Student name: Morgan Ballesteros**
-   **GitHub username: MorganBallesteros**
-   **Assignment name/description: Integrative Data Project**
-   **Date of submission: 3/9/2026**

## Submission Instructions

1.  Confirm that all code chunks run as expected and that all .Rmd/.qmd/.md files knit without error.
    -   If you are not able to resolve code errors, disable the code chunks that produce them before submission by adding `eval = FALSE` to the chunk options and add inline comments explaining why the code does not run.
    -   If you are not able to resolve knitting errors, comment out the problematic sections using HTML comments (`<!--` and `-->`) and add inline comments explaining why the section does not knit.
2. Complete this form, including:
    -  Assign numeric scores to any applicable core standards and describe your reasoning. 
    -  Optionally, complete the reflection section for enrichment points or describe other ways you believe you have earned enrichment points.
    -  Complete the AI use attestation at the end of this document. *Your submission will not be graded without this attestation.*
3.  Confirm your repo contains all files needed for grading, including:
    -   The .qmd file for this assignment
    -   Any data files needed to run the code
    -   Any knitted output (HTML, PDF, or Word document)
    -   This completed `core-submission.qmd` file
    -   Any files required by the assignment instructions
    -   Anything else that your grader will need to fully run and grade your project from a cloned repo
    -   *Note:* If necessary files are being ignored by your `.gitignore` file, you should add them as exceptions in the .gitignore.
4.  Commit all changes and push all necessary files to the associated GitHub repo. Refer to the [Guidelines for GitHub Submissions](d2m-r.github.io/assessment/misc/gh-submission.html) for more details.
    -  If submitting in a dedicated repo (i.e., *not* GitHub classrooms):
        -  Confirm the repo contains all necessary files (e.g., .qmd, data files if any, knitted output, a copy of this submission document)
        -  Confirm the repo is *private*
        -  Follow the instructions in the GH submission guidelines to create your `feedback` branch and open a pull request
    -  If submitting via other means, confirm submission formats with your instructor.
5.  Complete the [Project Submission Form](d2m-r.github.io/submit.html) to submit your work for grading.
    -   **Note:** Pushing your work and adding an issue to GitHub serves to let your grader know which repo and version to grade, but will not add your work to the grading queue. *Your work is not submitted until completing the Project Submission Form!*
    
Graders will refer to your self-evaluation in this document in reviewing your work, leaving feedback, and assigning grades.
Grades and comments (if applicable) will be shared with you via the pull request.

## Assessment

Instructions for **student self-evaluation:**

1.  Review the core standards and decide which ones you have demonstrated in this assignment.
2.  For each standard you are demonstrating, assign yourself a point value (4, 5, or 6).
3.  Provide a brief explanation of why you believe you have earned that score.
    -   Some assignments include specific notes about grading for certain standards, which you should be sure to address in your explanations.
    -   Where an assignment notes that completing the assignment as written earns a certain score, your explanation can be minimal (e.g., "I completed all tasks about functions with error-free code.").
    -   Where an assignment does not give clear guidance about a standard's scoring, being specific about how you met or exceeded the standard, including the line numbers of relevant code, will help your grader give full credit for your work.

### Core standards

For each standard you are demonstrating, assign yourself the point value you believe you have earned. Refer to the course website for more details on each standard. If you are not attempting to demonstrate a particular standard, leave it blank.

| Points | Label | Description |
|------------------------|------------------------|------------------------|
| *No grade (blank)* | *No demonstration* | *You have not yet demonstrated this skill.* |
| **4** | **Meets Expectations** | You demonstrate the skill correctly in structured or familiar contexts (for example, following a guided assignment or closely modeled example). |
| **5** | **Exceeds Expectations** | You apply the skill correctly and independently in a novel context, with clear, well-chosen code that would generalize to new datasets or problems. |
| **6** | **Outstanding** | You use the skill in an especially expansive way: combining it with other skills, applying it to a complex or less-structured task, or going beyond the scope of in-class examples. |


1.  **RStudio + Quarto workflow**
    -   Suggested score:5
    -   Explanation: I show solid YAML, labeled chunks, multiple chunk options (echo/message/warning/results), clean PDF render, relative paths, sourced .R scripts. Not using advanced Quarto features (cross-refs, multi-format, tabsets), so not 6.
2.  **GitHub repositories and version control**
    -   Suggested score:4
    -   Explanation:I performed many small commits and pushes, met all 4 point tasks, and used GitHUb appropriately.
3.  **Base R syntax and data structures**
    -   Suggested score:6
    -   Explanation: I used vectors/lists/tibbles, indexing ([[ ]], .data[[ ]]), list accumulation (counts_list), explicit NA handling, list return objects. Strong transferability.
4.  **Control flow (if/else, loops)**
    -   Suggested score:6
    -   Explanation:I used multiple branches (text vs pdf; paragraph vs document; optional write-out; category factor prep) and two explicit loops (PDF iteration and marker iteration) and validation stop() control flow.
5.  **Defining functions in Base R**
    -   Suggested score:6
    -   Explanation:I used multiple functions, required + optional arguments, meaningful return values, helper composition, error handling (requireNamespace, file.exists, validation), flexible output (long/wide)
6.  **Importing data with tidyverse tools**
    -   Suggested score:5
    -   Explanation: Quarto reads processed CSV via read_csv() with relative path; scoring function writes CSV via write_csv() and creates output directories.
7.  **Data manipulation with dplyr and pipelines**
    -   Suggested score:6
    -   Explanation: I used extensive pipelines using mutate/transmute/filter/group_by/summarize/arrange/select/across plus left_join. Multiple contexts (cleaning, scoring, summaries).
8.  **Tidy data structure**
    -   Suggested score:6
    -   Explanation:I created tidy long output (doc_id × segment_id × marker) and showed conceptual tidy reshaping via segmentation; clear use-case-driven tidy structure.
9.  **Reshaping data with tidyr**
    -   Suggested score:6
    -   Explanation:I used unnest_longer() and pivot_wider(); reshaping is parameterized via segment and output
10. **Character strings with stringr**
    -   Suggested score:6
    -   Explanation: Cleaning + regex construction + segmentation + counts: str_replace_all, str_squish, str_split, str_count, regex(ignore_case=TRUE), etc.
11. **Factors with forcats**
    -   Suggested score:5
    -   Explanation: Used base factor() and fct_infreq() conditionally for category.
12. **Basic reporting: plots and descriptives in Quarto**
    -   Suggested score:6
    -   Explanation: I use multiple plots + captions + a formatted table (kable) + clean suppression of noisy output.

## Enrichment

### Reflection

Optionally, reflect on this assignment, connecting directly to the core standards. Thoughtful reflections may earn up to 2 enrichment points.

### Other

*Describe any other ways you believe you have earned enrichment points (if applicable):*


## AI Use Attestation

### Disclosure

Check the appropriate box(es):

-   [ ] I did not use AI tools of any kind to complete this assignment. (Skip to affirmation.)
-   [ ] I used RStudio's Copilot functionality to help write code only (no written content).
-   [X] I used other AI tools to help write code only (no written content).
    -   List the tools used and a brief description of how you used them:
-   [ ] I used AI tools in other ways not listed above.
    -   List the tools used and a brief description of how you used them:

I used ChatGPT to help me write code; I would write the code out using course slides and online sources for reference. I would then test the code and use ChatGPT to help me debug. I asked ChatGPT to explain each debugging instance. 


### Affirmation

I affirm that I have not used AI tools to generate any written content in this assignment, including explanations, narrative text, reflections, or any other prose sections.

I affirm that I have not used AI tools in any ways other than disclosed above.

I understand that use of AI for written content or undisclosed uses will result in a zero on this assignment and possible further disciplinary action.

*Type your name to affirm:*
Morgan Ballesteros
------------------------------------------------------------------------
