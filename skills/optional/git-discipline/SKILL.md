---
name: git-discipline
description: Work cleanly with branches, diffs, commits, and PR descriptions without risky git actions. Use when the developer asks for commits, branches, or PR text tied to SDD tasks.
---

# Git discipline

## Purpose

Produce clean, traceable git artifacts (branches, commits, PR
descriptions, release notes) tied to SDD tasks, while keeping every
mutating git action permission-gated. This skill supports the SDD
workflow; it never bypasses it — no git text or operation substitutes
for spec approval, review, or the documentation phase.

## Rules

1. **Inspect `git status` (and the relevant diff) before changes** —
   know what state the working tree is in before touching it.
2. **Never overwrite user changes.** Uncommitted developer work is
   untouchable: no checkout/restore/stash over it, no edits that
   silently revert it. If it blocks the task, stop and ask.
3. **Do not commit unless asked.**
4. **Do not push unless asked.**
5. **Do not force-push unless explicitly approved — and document it**
   (what was rewritten, why, and the approval) in the conversation and
   the task's review notes.
6. **Do not merge PRs unless explicitly instructed.** Merging is a
   human decision (see also `reference/autonomy-policy.md` — never
   autonomous).
7. **When commits are requested, reference the task/spec** (task ID,
   spec slug) in the message, following the project's convention from
   `CLAUDE.md` / `questions.md` §8 answers.

A project may pre-authorize specific operations in its git policy
(e.g. "commit after each task"); everything not pre-authorized stays
ask-first.

## When to use

- The developer asks to commit, branch, or open a PR.
- Writing a commit message, PR description, or release-note entry for
  completed SDD work.
- Inspecting repository state before starting changes.

## When not to use

- As permission to perform git operations the developer did not request.
- For resolving complex history surgery (interactive rebase, force-push
  recovery) — surface the situation and let the developer drive.

## Required inputs

- The task/spec reference the change traces to.
- The project's git policy from `CLAUDE.md` (branch naming, commit
  conventions, whether Claude may commit/push at all).
- For PR descriptions: the task's `review.md`, when it exists.

## Procedure

1. Inspect `git status` and the diff before any action; never overwrite
   uncommitted developer changes.
2. If a branch is needed, follow the project's naming convention; ask if
   none is defined.
3. For commits, fill `templates/commit-message.template`: task/spec
   reference, what changed, why. Check the diff for secrets first.
4. For PRs, fill `templates/pr-description.md.template` from the
   reviewer's output (see mapping below).
5. For release notes/changelogs, fill
   `templates/release-note.md.template` — user-visible behavior only,
   no internal task mechanics.
6. Confirm before each mutating operation unless the project's git
   policy explicitly pre-authorizes it.

## Reviewer output → PR description

When `review.md` exists for the task, build the PR description from
it instead of re-deriving:

| PR template field | Source in `review.md` |
|---|---|
| Summary / what changed | Traceability table + findings resolved |
| Spec reference | The spec slug the review belongs to |
| Checks run | `Commands run` section |
| Review status | `Decision` section (+ deferred non-blocking findings) |
| Safety notes | High-risk review record, visual verification, freshness evidence |

A PR description must not claim more than the review supports — if the
review is pending, say so rather than implying approval.

## Output artifact

Commits, branches, PR descriptions, or release-note entries — only
those explicitly requested — with traceable text generated from the
templates in `templates/` (copied from the kit's `templates/git/`
during onboarding and adapted to the project's conventions).

## Safety constraints

- Do not commit, push, merge, or open PRs unless asked.
- Never force-push, rewrite shared history, or skip hooks without
  explicit approval recorded in the conversation.
- Never commit secrets; check the diff for credentials before
  committing.
- Respect protected branches and the project's git policy at all times.
