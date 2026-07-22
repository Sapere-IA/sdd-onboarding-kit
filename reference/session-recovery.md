# Session recovery

Sessions get interrupted, go stale, or go wrong: days pass between
working sessions, compaction summarizes away details, or Claude heads
in a wrong direction for several turns. Claude Code ships features for
all of these — and one rule keeps them safe in an SDD project:

> **Durable artifacts are the source of truth, never chat history.**
> `tasks.json` holds task state, `specs/` holds requirements and
> design, `review.md` holds verdicts, the decision logs hold settled
> decisions, `history.md` holds what already happened. A summary,
> restored checkpoint, or resumed conversation is a convenience for
> reorienting — anything it claims is verified against the artifacts
> before acting on it.

## Feature landscape

Capability-level summary (names verified against the official docs on
2026-06-12 — re-verify before relying on exact syntax):

- **Recap** — `/recap` produces a short summary of the session; an
  automatic recap also appears after time away. Orientation only.
- **Rewind / checkpoints** — `/rewind` (double-Esc with empty input)
  restores the conversation, the code, or both to an earlier point;
  checkpoints persist across sessions. **Limitations that matter:** it
  tracks only Claude's direct file edits — not bash side effects
  (`rm`, `mv`, migrations, API calls), not manual edits, not
  concurrent sessions. It is local undo, not version control; git
  remains the authoritative history.
- **Resume** — `claude --continue` reopens the most recent session in
  the directory; `claude --resume` offers a picker (or takes a
  name/ID). Sessions are per machine and per project directory — they
  do not sync across machines.
- **Branching** — `/branch` (or resuming with a fork flag) copies the
  conversation to try an alternative approach without losing the
  current one.
- **Compaction** — `/compact [focus instructions]` replaces history
  with a summary; details not covered by the focus instructions are
  gone from context (the transcript file on disk keeps them).
  `CLAUDE.md` and memory files reload from disk and survive.
- **Stopping** — Esc stops the current turn immediately; work done so
  far is kept.
- **Transcripts** — full session logs live on disk under
  `~/.claude/projects/` (default 30-day retention); `/export` saves a
  session as text.

## The four practices

### 1. Reorient with recap-style summaries — then verify

After days away: read the recap (or run `/recap`), then open the
durable artifacts before doing anything: `tasks.json` for every task's
actual status, the active spec for what is approved, the latest
`review.md` for unresolved findings, `history.md` for what was
completed. The recap tells you where to look; the artifacts tell you
what is true. If recap and artifacts disagree, the artifacts win.

### 2. Rewind when Claude went in the wrong direction

When several turns went down a wrong path, rewinding to the fork beats
arguing the session back on course — restored context is cleaner than
corrected context. Before trusting a rewind, check what it cannot
restore: bash side effects (deleted files, installed packages, run
migrations) and external state survive the rewind. `git status` /
`git diff` after rewinding tells you what the checkpoint actually
reverted. For anything beyond local file edits, recover through git,
not checkpoints.

### 3. Stop early and reprompt when execution drifts

Drift rarely fixes itself: a wrong assumption compounds with every
turn, and each correction pollutes context further. Stop the turn
(Esc) as soon as the direction is visibly wrong, and reprompt with a
reference to the governing artifact ("follow the design in
`specs/<slug>/design.md`, section X") rather than a long in-chat
correction. If the conversation is already cluttered with failed
attempts, prefer rewinding past them or compacting with focus
instructions over pushing through.

### 4. Rely on durable artifacts as truth

This is what makes the other three safe — and it cuts both ways:

- **Reading:** after any resume, rewind, or compaction, state is read
  from `tasks.json`, specs, reviews, decision logs, and
  `history.md` — not assumed from the (possibly stale or truncated)
  conversation.
- **Writing:** decisions, task-state changes, review findings, and
  constraints are written to those artifacts *when they happen*, so
  losing a session loses nothing that matters. The pre-compact capture
  hook (`hooks/examples/pre-compact-capture/`) reminds about exactly
  this before compaction.

## Resume checklist

After resuming a session (or after compaction), before continuing work:

1. `tasks.json` — status of the task you think you are working on (and
   any task marked `in_progress`).
2. The active spec under `specs/<slug>/` — requirements and design as
   approved, not as remembered.
3. The latest `review.md` — unresolved blocking/non-blocking
   findings.
4. `git status` and the current diff — what is actually changed but
   uncommitted, including anything a rewind could not revert.
5. Decision logs / `history.md` — decisions settled since the
   context you remember.

If conversation memory and any of these disagree, trust the artifact
and say so explicitly before continuing.

## SDD constraints

- Rewind and resume never change task state by themselves: a task that
  was `in_progress` before a rewind is still `in_progress` —
  state transitions go through the normal workflow only.
- Restored or resumed context does not revive expired approvals: if a
  spec changed after the checkpoint being restored, the spec on disk —
  not the restored conversation — is authoritative, and approval status
  is whatever `tasks.json` says.
- Recovery features are session conveniences, not audit trails — the
  durable artifacts and git history remain the record (see also
  `reference/autonomy-policy.md` for runs nobody watches).
