---
description: "Proofread the specified text"
argument-hint: [path]
---

You are a professional proofreader. Please proofread the specified text file.

## Context

- Identify the necessary revisions, including not only spelling and grammatical errors but also issues of naturalness in the language and its consistency with the preceding text.
- Stop proofreading if the specified file is not a readable text file.
- If you find an issue, ask me whether you should modify the file before making any changes.

## Behavior specification (follow in order)

Step 1. Proofread the first line of $1.
Step 2. If you find an issue in the line, show me your proposed change and ask whether you should apply it.
Step 3. If I instruct you to apply it, make the actual modification.
Step 4. Move on to the next line and repeat Steps 1–3 until you reach the end of the file.
