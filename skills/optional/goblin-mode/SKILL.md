---
name: goblin-mode
description: Run one SDD task end to end with no human checkpoints — the invocation is the developer's approval — until it is implemented, reviewed, documented, marked done, committed and pushed on a feature branch with a pull request, and the repo is closed so a fresh session can start the next task. Use when the developer says "goblin mode", "just do TASK-xxx", or wants a task finished unattended.
argument-hint: "[TASK-ID — empty = next eligible task]"
---

# Goblin mode — one task, start to pushed, unattended

## Purpose

The developer wants to walk away. Take one SDD task through the whole
workflow (`sdd-workflow` skill) without stopping for approval, review
sign-off or git permission, then leave the repository resumable
(`closing` skill). The deliverable is a pushed feature branch with a pull
request and a clean handoff — never a merge.

This skill is a **recorded autonomy exception** (`reference/autonomy-policy.md`
§ "Recorded exception: goblin-mode"). It applies only when the developer
invokes it explicitly, only to the one task named, and only for the session
in which it was invoked. Everything it relaxes is listed here; everything
else in the SDD workflow, the git policy and the autonomy policy still holds.

## What the invocation means

Invoking this skill on a task is the developer's explicit, in-advance
approval of that task's spec and the pre-authorization of the git actions
listed in § Git. Record it, do not assume it:

```json
"approval": {
  "required": true,
  "approved_by": "<developer name from git config user.name, or 'developer'>",
  "approved_at": "<ISO timestamp of the invocation>",
  "notes": "Approved in advance by goblin-mode invocation; the spec was not reviewed by a human before implementation."
}
```

The note is mandatory and must say the spec was not human-reviewed. A
reader of `tasks.json` or `history.md` must be able to tell a goblin-mode
task from a normally approved one.

## Goal condition

The run ends successfully only when **all** of these are true:

1. The task is `done` in `tasks.json`, with reviewer decision, documentation
   fields resolved (`updated` or `not_required`) and a `history.md` entry.
2. Every subtask in `specs/<slug>/tasks.md` is `[x]`; no `[>]` or `[!]` remains.
3. Validation commands from `AGENTS.md` (or the `run-and-verify` skill) pass.
4. The working tree is clean; every commit is on the task's feature branch
   and pushed; the PR exists (or its text is in the final report when PR
   tooling is unavailable) and `tasks.json` `links.branch` / `links.pr` are
   filled.
5. The `closing` checklist is all ✓ and the `## Resume here` handoff names
   the next candidate task.

Write this condition out in the first message of the run. If the harness
has a goal or persistence feature (§ Per-harness persistence), hand it this
exact condition.

## Bounds

- **Fix attempts:** at most 3 consecutive fix-and-retry cycles per failure
  (failing validation, reviewer rejection, docs re-check gap). The 4th
  failure of the same kind stops the run.
- **Immediate stops** (no retry): a hook denies an action; a permission
  prompt is denied or cannot be answered; a question the skill may not
  decide alone (§ Deciding alone); the task turns out to touch a
  never-autonomous area (§ Refuse to start) that the spec did not reveal.
- **No time or turn cap** beyond what the harness enforces. The developer
  accepted this at install time; record it in `decisions/answers.md`.

## Refuse to start

Check before touching anything, and stop with a one-line reason if any holds:

- The argument names a task that does not exist, or is already `done`.
- The task is `blocked` on something external (a credential, a third party,
  an unanswered question in a protected area).
- `git status` shows uncommitted developer changes (git-discipline rule 2:
  never overwrite them). Untracked, gitignored artifacts do not count.
- The task's scope or spec touches a never-autonomous item: production
  deploys, database migrations, payment / authentication / security-relevant
  changes, protected files or directories from `AGENTS.md`, or pushing to a
  protected branch. Run the normal `sdd-workflow` instead and stop at
  `spec_ready` for a human.
- The project's git policy in `AGENTS.md` forbids the agent from pushing or
  opening PRs and no recorded decision allows goblin-mode to. Then the run
  may still execute everything up to the local commits; say so up front and
  end with the branch unpushed.

## Procedure

Announce once, then stop asking: task ID and slug, branch name, the goal
condition, the bounds. After that message no question goes to the developer
until the final report.

### 1. Select the task

`$ARGUMENTS` is one task ID. If empty, pick the next eligible task from the
task store exactly as `sdd-workflow` § 1 does, and name it in the announcement.

### 2. Branch

Follow the branch convention from the git policy in `AGENTS.md`. If none is
recorded, use `sdd/<task-id-lowercase>-<slug>` from the project's default
branch. Write the branch name to `tasks.json` `links.branch`.

### 3. Spec

- `pending` / `spec_draft`: write or finish the spec per `sdd-workflow`
  (`spec-format.md`, `assumptions-policy.md`, `open-questions-policy.md`).
- `spec_ready`: apply `specs/<slug>/feedback.md` first if it exists
  (`spec-format.md` § Feedback file), then continue.
- Resolve open questions and unconfirmed assumptions per § Deciding alone.
- Render the spec, set `spec_ready`, then set `human_approved` with the
  approval block from § What the invocation means. Commit: `spec: <slug> (TASK)`.

### 4. Implement

`sdd-workflow` § 6, unchanged: `in_progress`, subtasks in order, tests,
validation, markers in `tasks.md`. Commit at least once per subtask group
using `templates/commit-message.template` (task ID in every message), then
set `review`.

### 5. Review

Run the reviewer role (`agents/reviewer.md`, `review-checklist.md`) as a
subagent where the harness supports one, inline otherwise. Write
`review.md`, re-render.

- Approved: continue.
- Rejected: apply the exact corrections, re-run validation, re-review.
  Count it as one fix attempt.

### 6. Documentation phase

`sdd-workflow` § 8, unchanged: reviewer decides targets, documenter updates
them, reviewer re-checks. Gaps returned by the re-check count as fix attempts.

### 7. Complete

`sdd-workflow` § 9: `done`, reviewer decision recorded, `history.md` entry
(include the goblin-mode approval note), commit.

Decision-log and memory entries stay **propose-only** even here: do not
write `decisions/*.md` or any memory file. Put the proposed entry text in
`review.md` under "Proposed decisions" and in the PR description; the
developer accepts or drops them later.

### 8. Close the session

Run the `closing` skill procedure with these substitutions: memory and
decision-log proposals are listed, not asked about; the commit question is
already answered. The `## Resume here` block must name the **next candidate
task** from `tasks.json` and list every auto-decided question (§ Deciding
alone) as a line the developer should glance at.

### 9. Push and open the PR

1. Push the branch to the remote.
2. Build the PR description from `review.md` with the
   `git-discipline` mapping into `templates/git/pr-description.md.template`.
   Add a short **Goblin mode** section: approval was by invocation, list of
   auto-decided questions and assumptions, fix attempts used.
3. Open the PR against the project's default branch with the available
   tooling (a permission-gated CLI call per `reference/cli-vs-mcp-policy.md`,
   or a configured MCP). If no tooling is available or allowed, put the full
   PR text in the final report instead — that is not a failure.
4. Write the PR URL to `tasks.json` `links.pr`, commit `chore: link PR for TASK`,
   push again. The tree must be clean after this.

### 10. Report

```text
Goblin mode — TASK-NNN <slug>
✓/✗ done in tasks.json (reviewer: <decision>, docs: <status>)
✓/✗ all subtasks [x]
✓/✗ validation passing: <commands>
✓/✗ branch <name> pushed · PR <url or "text below">
✓/✗ closing checklist · Resume here → next: TASK-MMM
Auto-decided: Q2 (chose option B — conservative), A3 confirmed by code
Fix attempts used: <n>/3
Proposed decisions / memory entries: <count, in review.md>
```

Every ✗ gets one line of explanation.

## Deciding alone

Open questions (`Qn`) and unconfirmed assumptions (`An`) have no human to
answer them. Decide them yourself when the question is about **how** to
build within the task's scope. Pick the option the spec already recommends,
otherwise the most conservative one (least new surface, easiest to reverse,
no data change). Record each decision in `assumptions.md`:

```markdown
- **A7 (auto-decided by goblin-mode, YYYY-MM-DD):** <decision>. Resolves Q2.
  Reason: <one line>. Reversible: <yes / how>.
```

Mark the question answered in `open-questions.md` pointing at the assumption.
List all of them in the handoff, the PR description and the final report.

Never decide alone — stop the run instead — when the question concerns:
protected areas, deleting or migrating data, public API or contract changes
the project guards, security or permissions, spending money or external
side effects, or anything the developer flagged "ask me" in `AGENTS.md` or
`decisions/answers.md`.

## When the run stops early

Leave the repository better than a crash would:

1. Commit work in progress on the feature branch (`wip: <what> (TASK)`),
   never on the default branch. Mark the current subtask `[!]` with a
   one-line reason in `tasks.md`.
2. Set `tasks.json` status honestly: `blocked` (with the blocker in a note),
   `in_progress`, or `rejected` after a failed review — never `done`.
3. Run the `closing` procedure; the `## Resume here` block states the exact
   blocker and the next action.
4. Push the branch if pushing is allowed, so nothing is lost.
5. Report with the checklist above; the first line names what stopped it.

## Git

Pre-authorized by the invocation, within the project's git policy:
create the feature branch, commit on it, push it, open one PR. Commit
messages follow `templates/commit-message.template`; check diffs for
secrets before each commit.

Still forbidden: committing or pushing to the default or any protected
branch, merging the PR, force-pushing, rewriting shared history, skipping or
disabling hooks, deleting branches, touching stashes or other branches.

## Per-harness persistence

The procedure above is harness-neutral. Use the harness feature that keeps
an agent working until a condition is met, with the § Goal condition and
§ Bounds as its stop condition; without such a feature, run the procedure in
one pass and resume from the `## Resume here` block if the session ends.

| Harness | How to keep going |
|---|---|
| Claude Code | Start a `/goal` with the goal condition verbatim; bounds in the same text |
| Codex CLI | Single pass; a background run may be used with turn and budget caps |
| Cursor | Single pass in the agent chat |
| OpenCode | Single pass; the harness's loop/continue feature if configured |
| Antigravity | Single pass; background agent with a stop condition if available |

Autonomy posture is unchanged by the mechanism: same permissions as an
interactive session, never with permissions fully bypassed outside a
disposable sandbox, and no hook disabled to let the run proceed.

## When not to use

- Tasks touching the never-autonomous list (§ Refuse to start).
- A task whose spec the developer wants to read before code exists — use
  `sdd-workflow` and approve it normally.
- Several tasks at once: run goblin-mode once per task, each on its own branch.
- Projects whose git policy forbids agent pushes without a recorded decision.

## Installation notes

- Installing this pack is the recorded decision that relaxes the autonomy
  policy's "never mark done / never push autonomously" items **for this
  skill only**. Record in `decisions/answers.md` (and
  `decisions/workflow-decisions.md` if the `decision-log` pack is installed):
  the pack is installed, invocation counts as approval, feature branch + PR
  only, 3 fix attempts, no time cap.
- Fill the branch convention and default branch in the project's git policy
  so § 2 and § 9 need no guessing; if the project uses a PR tool (CLI or MCP),
  name it in `AGENTS.md` so § 9 step 3 can use it.
- The kit's gate hooks keep working: the approval block written in § 3 is
  what `block-implementation-before-approval` checks, so no hook is bypassed.
