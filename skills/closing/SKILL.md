---
name: closing
description: Close a working session so a fresh session with empty context can continue from the files alone — audit the artifacts, update project memory, commit, push, and say whether it is safe to close. Use when the developer is about to stop, switch tasks, compact, or hand the work to someone else.
argument-hint: "[optional focus, e.g. a task ID; 'no push' or 'no commit' to stop earlier]"
---

# Closing — leave the repo resumable

## Purpose

Answer three questions before the session ends:

1. Is everything important written down?
2. Are the durable artifacts and memory files up to date with what actually happened?
3. If a new session with empty context opened this repo, could it continue from here?

Chat history is lost; the artifacts are the record (`reference/session-recovery.md`, and the "Session recovery" rule in `AGENTS.md`). This skill closes the gap between the two.

**Invoking this skill is the developer's approval** to update project memory, commit the session's work and push it, as described in steps 3, 7 and 8. Do not ask again whether to commit, push or update memory; do it and report. The developer can narrow this in the invocation (`no push`, `no commit`); the project's git policy and the limits below still apply.

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
- Memory writes and decision-log entries: the invocation counts as the developer's choice of **project memory** under the memory policy (`reference/memory-policy.md` § Closing). Write project-scoped entries (decision logs, `AGENTS.md` facts that changed, the harness's project memory if the project uses one) without asking, and list the exact text of each in the report. Never write global memory from this skill: list a project-independent lesson as a proposal instead.
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
✓/✗ decisions and project memory recorded (exact entries listed; global-memory proposals listed, not written)
✓/✗ no pending feedback.md
✓/✗ handoff written
✓/✗ cold-start test passed
A fresh session can resume from: <file and section>
```

Explain every ✗ in one line.

### 7. Commit

Show `git status` and a short summary of the diff, then commit the session's work following the project's git policy (`AGENTS.md`, and the `git-discipline` skill if installed): its branch rules, message convention and attribution. Use one commit per logical change when the policy asks for it; otherwise one commit.

- Stage only files this session produced or changed. Leave out anything that looks like a secret or credential (`.env`, keys, tokens), large generated or binary files, and unrelated changes that were already there before the session; list them in the report.
- If a commit hook fails, fix the cause and commit again; never bypass hooks (`--no-verify` or equivalent).
- If the git policy forbids committing on the current branch (for example the default or a protected branch), do not commit: report it and leave the work uncommitted.

### 8. Push and finish

- Push the current branch to its upstream (set the upstream on first push if the policy allows it). Never force-push, and never push a branch the git policy says not to push directly.
- Never stash, reset, rebase, delete branches or discard changes.
- If the push is rejected (remote ahead, no remote, no permission), stop: do not pull, merge or rebase on your own. Report the reason.
- Re-check `git status` and the branch's ahead/behind count against its upstream after pushing.

End the report with one line:

- `✓ Safe to close the session.` — the checklist is all ✓ (or every ✗ is explained and recorded in the handoff), memory is written, the work is committed and pushed, and the working tree is clean apart from files deliberately left out.
- `✗ Not safe to close yet: <reason>` — and what the developer needs to do or decide.
