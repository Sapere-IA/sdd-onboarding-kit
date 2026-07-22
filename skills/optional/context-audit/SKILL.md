---
name: context-audit
description: Inspect and reduce Claude Code context-window usage. Use when a session has grown long, behavior degrades, or before starting a new unrelated task in the same session.
---

# Context audit

## Purpose

Keep the context window healthy by auditing what is loaded and recommending
targeted cleanup, following `reference/context-economy.md` (copied or
linked during onboarding).

## When to use

- A session has been running long and responses degrade or lose track.
- Before switching to an unrelated task in the same session.
- After a noisy investigation (many files read, long tool outputs).
- The developer asks "why is context full?" or similar.

## When not to use

- Short sessions with no symptoms — auditing costs context too.
- Mid-implementation of an approved task: finish or reach a stable point
  first, so compaction does not drop in-flight details.

## Required inputs

- Current task status (from `tasks.json`) and any unresolved questions —
  these must survive any compaction.

## Procedure

1. Run `/context` and identify the dominant consumers.
2. Decide: continue, compact, or restart.
3. If compacting, use `/compact` **with focus instructions** to preserve:
   decisions made, current task state, architecture constraints, and
   unresolved questions.
4. Before compacting, write anything durable to its artifact (`tasks.json`,
   spec files, decision log, `history.md`) — artifacts, not chat, are the
   source of truth.
5. Recommend subagents for upcoming noisy exploration instead of doing it
   in the main conversation.

## Output artifact

No file output by default. If durable information was only in chat, the
output is updated artifacts (task status, decision entries) written before
compaction.

## Safety constraints

- Never discard unresolved questions or unrecorded decisions by compacting.
- Do not write to memory or global configuration; this skill only inspects
  and advises.
