---
name: bro
description: Re-explain something concisely in plain language. Use when the developer says there is too much text, does not understand a message, a spec item (REQ-003, A1, Q2, T1), a file, a term or a concept, and wants it simply.
argument-hint: "[text, file, spec ID, term or concept — empty = your previous message]"
---

# Bro — say it simply

## Purpose

The developer got too much text, or text they do not follow. Re-explain it short and plain. This skill only explains: it never decides, implements or edits.

## What to explain

- **No argument:** your previous message in this conversation.
- **Pasted text:** that text.
- **A file path:** that file (or the part the developer points at).
- **A spec ID** (`REQ-003`, `A1`, `Q2`, `T1`, `TASK-001`…): find it under `specs/` (and `tasks.json` for task IDs). If it matches more than one spec, ask which feature, or use the active task's spec and say so. If not found, say so and stop.
- **A term or concept:** explain it as it applies to this project; read the project map or `AGENTS.md` only if the meaning is project-specific.

## Output contract

Reply in the developer's language. At most ~150 words in total.

```text
**TL;DR:** <one line>

<Plain-words explanation: short sentences, no jargon — or define each
term the first time. One everyday analogy only if it really helps.>

**What this means for you:** <the practical consequence, 1–2 lines>
**What you need to decide:** <only if there is a pending decision: the
choice, the options, the recommended one>

Want me to go deeper on any part?
```

Drop "What you need to decide" when nothing is pending. Keep the last line as a single short offer.

## Rules

- Add no new claims: every statement must come from the source. No new facts, risks, recommendations or numbers.
- If the source is ambiguous or contradicts itself, say so in one line instead of guessing what it meant.
- Do not repeat or quote the original text back; rephrase it.
- Do not change any file, task state or memory. Read only.
- Do not pad: no preamble, no recap of what was asked, no headings beyond the contract.
- If the developer asks to go deeper, answer only the part they named, with the same plain style.
