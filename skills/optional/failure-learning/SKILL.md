---
name: failure-learning
description: Propose a reusable lesson after a meaningful implementation mistake. Use when a wrong assumption, convention violation, or repeated error was corrected by tests, the reviewer, or the developer.
---

# Failure learning

## Purpose

Capture reusable lessons from real mistakes so they are not repeated —
always as a **proposal** to the developer, never as a silent memory write.

> Kit source note: the full memory policy (layers, storage rules, security)
> lives in `reference/memory-policy.md`; the entry format lives in
> `templates/memory/failure-learning-entry.md`. When installing this pack,
> the entry template is copied next to this file as `entry-template.md`.

## When to use

A memorable failure happened, such as:

- failed tests caused by a wrong project convention;
- the reviewer found an architectural violation;
- the developer corrected a repeated assumption;
- the wrong command/tool was used;
- code was edited outside the approved scope;
- the wrong API/framework pattern was used;
- the same error happened more than once.

## When not to use

Do not memorize:

- one-off syntax mistakes or typos;
- secrets, credentials, or tokens — never, in any layer;
- personal/private data unrelated to the project;
- speculative conclusions the developer has not confirmed;
- project-specific rules in global memory, unless the developer explicitly
  approved exactly that.

## Required inputs

- What went wrong, the root cause, and the correction.
- The source task/spec/review where it happened.

## Procedure

1. Draft the entry using `entry-template.md` (title, date, scope, trigger,
   what went wrong, root cause, rule to remember, where to apply, where not
   to apply, source task/spec/review).
2. Show the exact proposed text and ask — this prompt is mandatory before
   any memory write:

   ```text
   I found a reusable lesson from this mistake:

   <proposed memory entry>

   Do you want me to add this to memory?
   1. Yes, global memory.
   2. Yes, project memory only.
   3. No, keep it only in the review/history.
   4. Revise the wording first.
   ```

3. Write only where the developer chose:
   - **Global memory** (option 1): append to the user memory file
     `~/.claude/CLAUDE.md`. Only after this explicit choice; verify the
     entry is project-independent and contains no project internals.
   - **Project memory** (option 2, the default recommendation): append to
     the project's decision log (e.g. `decisions/failure-learnings.md`).
   - **Review/history** (option 3): record in the task's `review.md` or
     `history.md`; no memory write.
   - **Revise** (option 4): rewrite and ask again.
   If the developer does not answer, write nothing.
4. If the same lesson is proposed twice, that is a signal it belongs in a
   more visible place (e.g. a `CLAUDE.md` rule) — suggest that explicitly,
   still requiring approval.

## Output artifact

An approved lesson entry in the layer the developer chose — nothing if the
developer declines.

## Safety constraints

- Never write any memory (project or global) without explicit approval of
  the specific entry text.
- Prefer project memory; global memory only via option 1 above.
- Never record secrets, credentials, or personal data in a lesson.
- Advisory hooks may suggest running this skill; they never write memory.
