---
name: closing
description: Close a working session so a fresh session with empty context can continue from the files alone. Use when the developer is about to stop, switch tasks, compact, or hand the work to someone else.
argument-hint: "[optional focus, e.g. a task ID]"
---

# Closing — leave the repo resumable

## Purpose

Answer three questions before the session ends:

1. Is everything important written down?
2. Are the durable artifacts and memory files up to date with what actually happened?
3. If a new session with empty context opened this repo, could it continue from here?

Chat history is lost; the artifacts are the record (`reference/session-recovery.md`, and the "Session recovery" rule in `AGENTS.md`). This skill closes the gap between the two.

## Procedure

### 1. Gather what happened

- This conversation: tasks touched, decisions settled, questions answered, assumptions confirmed or rejected, approvals given, problems hit, what was left half-done.
- The repo: `git status`, `git diff --stat` (staged and unstaged), `git log --oneline -10`.

### 2. Audit the artifacts against reality

For each item, compare what the file says with what happened:

- `tasks.json` — status, `approval`, `documentation_status`, `updated_at` of every task touched.
- `specs/<slug>/tasks.md` — subtask markers (`[ ]`, `[>]`, `[x]`, `[!]`) match the work actually done.
- `specs/<slug>/requirements.md` / `design.md` — changes agreed in chat but not written into the spec.
- `specs/<slug>/open-questions.md` and `assumptions.md` — questions answered, assumptions confirmed or rejected.
- `specs/<slug>/review.md` — findings raised or resolved this session.
- `specs/**/feedback.md` — pending review feedback not yet applied (apply it or list it as the next action).
- Decision logs (`decisions/`) — significant decisions settled this session.
- `history.md` — tasks that reached `done` without an entry.
- Project memory per `reference/memory-policy.md`: `AGENTS.md`, `decisions/`, and the harness's own memory if the project uses one.
- Project map / `AGENTS.md` — commands, structure or conventions that changed.

### 3. Fix the gaps

- Write only facts that happened in this session or are visible in the repo. Never invent progress, results or decisions.
- Update subtask markers, spec text, open questions, assumptions and review notes directly.
- Task state transitions follow the SDD workflow: never set `human_approved` or `done` here unless the developer approved it in this session; if the record lags behind a real approval, update it and cite the approval.
- Memory writes and decision-log entries follow the memory policy: show the exact entry text and ask before writing. Never write global memory from this skill.
- Re-render any spec whose markdown changed (render command in `AGENTS.md`).

### 4. Write the handoff

Use the project's session-handoff location if `AGENTS.md` or `decisions/answers.md` names one. Otherwise keep a single `## Resume here` block at the top of `history.md`, above `## Entries` — replace it on each close, never append a new one:

```markdown
## Resume here

- **Updated:** YYYY-MM-DD
- **Current task:** TASK-NNN — <slug> (`<status in tasks.json>`)
- **Next action:** <one concrete step, e.g. "implement T3 in specs/<slug>/tasks.md">
- **Blockers / waiting on:** <approval, open question Qn, failing test…, or "none">
- **Uncommitted work:** <summary of git status, or "none">
- **Notes:** <anything a fresh session would otherwise rediscover the hard way>
```

Keep it short: it points at artifacts, it does not duplicate them. When no task is active, say so and name the next candidate from `tasks.json`.

### 5. Cold-start test

Using only the files (not this conversation), answer: what is the current task, its status, the next action, and any blockers? If any answer needs chat context, fix the artifact and test again.

### 6. Report

```text
Closing checklist
✓/✗ tasks.json matches the work done
✓/✗ spec subtask markers, open questions, assumptions, review up to date
✓/✗ decisions and memory recorded (or proposed and declined)
✓/✗ no pending feedback.md
✓/✗ handoff written
✓/✗ cold-start test passed
A fresh session can resume from: <file and section>
```

Explain every ✗ in one line.

### 7. Uncommitted work

Show `git status` and a short summary of the diff, then ask whether to commit, following the project's git policy (`AGENTS.md`, and the `git-discipline` skill if installed). Never commit, push, stash, reset or delete anything without explicit approval.
