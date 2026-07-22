# Deep review policy

Every SDD task gets the standard reviewer pass. Some changes deserve
more: a deeper review mode, a security-focused pass, or independent
adversarial reviewers. This policy says when to escalate and what a
deep review must produce. Two rules frame everything:

1. **Deep review supplements the SDD reviewer — it never replaces it.**
   The reviewer agent, the checklist, and `review.md` still run; deep
   review feeds extra findings into them.
2. **Deep review is recommended, not required**, unless the project
   records a stricter rule (e.g. in `decisions/workflow-decisions.md`).
   The kit never assumes paid or limited features are available: every
   escalation step has an included-cost fallback.

## High-risk categories

Recommend a deep review when the change touches any of:

- **Security-sensitive code** — crypto, input handling on trust
  boundaries, secrets handling, sandboxing.
- **Authentication / authorization** — login, sessions, tokens, roles,
  permission checks.
- **Payment flows** — anything that moves money or stores payment data.
- **Database migrations** — schema changes, data backfills, anything
  irreversible.
- **Infrastructure / deployment changes** — CI/CD, IaC, runtime
  configuration, container/network setup.
- **Public API changes** — published contracts other systems depend on.
- **Large cross-cutting refactors** — many files, shared abstractions,
  behavior-preserving claims that are hard to verify locally.
- **Data-loss risks** — deletion paths, retention changes, destructive
  scripts.

These are the same categories the dependency-freshness policy treats as
high-risk; the spec-author should already mark them in the design, and
the reviewer confirms the marking.

## Review modes — what exists

Capability-level summary (names verified against the official docs on
2026-06-12; re-verify before relying on exact syntax — features and
pricing move fast):

- **Standard session review** — the SDD reviewer agent plus commands
  like `/review` (read-only PR review), `/code-review` (bugs and
  cleanups in the current diff, with selectable effort levels), and
  `/security-review` (security analysis of pending branch changes).
  Included cost.
- **Extended reasoning** — raising the session effort level, or the
  `ultrathink` keyword for one-off deeper reasoning on a single turn.
  General-purpose, not review-specific. Included cost.
- **Adversarial / parallel review** — independent subagents reviewing
  the same diff from different lenses (security, correctness,
  performance), or agent teams running competing reviews. Included
  cost; uses more tokens.
- **Cloud deep review** — `/code-review ultra` ("ultrareview"): a fleet
  of reviewer agents in a remote sandbox that independently reproduce
  and verify findings. Slower (minutes) and **paid beyond free runs**.
- **Automated PR review services** — the Code Review GitHub App
  (Team/Enterprise research preview, paid per review) and review
  prompts via the Claude Code GitHub Action. **Availability depends on
  plan and admin setup.**

## Escalation ladder

For a high-risk change, escalate in this order, stopping at the highest
rung actually available to the project:

1. **Always:** the SDD reviewer with the `High-risk review` checklist
   section, at raised effort, including `/security-review` (or an
   equivalent security-focused pass) when the change is in a
   security-relevant category.
2. **Recommended:** an adversarial second pass — at least one
   independent reviewer subagent per relevant lens (security,
   correctness/edge cases, performance), each trying to refute the
   implementation rather than confirm it.
3. **Optional, if available and the developer approves the cost:**
   cloud deep review (ultra mode) or the automated PR review service.
   Never run paid review modes without explicit developer approval per
   invocation.

Rungs 1–2 use only included features, so the policy works on every
plan. If a paid mode is unavailable or declined, rung 2 is the
accepted substitute — note that in `review.md` and move on; a missing
paid feature never blocks a task.

## Output expectations

A deep review (whatever the mode) must report, explicitly:

- **Security findings** — vulnerabilities, trust-boundary issues,
  secrets exposure; `None found` is a valid result, silence is not.
- **Performance findings** — regressions, hot-path costs, N+1 patterns,
  resource leaks.
- **Edge cases** — inputs, states, and failure modes the
  implementation misses; each mapped to a requirement or flagged as a
  spec gap.
- **Reproduction attempts** — for each claimed bug, whether it was
  actually reproduced (command, input, observed behavior) or remains
  theoretical. Unreproduced findings are labeled as such.
- **Remediation plan** — per finding: severity, suggested fix, and
  whether it blocks approval. Blocking findings return the task to
  `in_progress`; the rest follow the normal non-blocking rule (resolve
  or record an explicit deferral before `done`).

Findings land in `specs/<feature-slug>/review.md` alongside the
standard checklist results — one review record per task, whatever mix
of modes produced it.

## Integration with the SDD workflow

- The **spec-author** marks high-risk categories in the design, so the
  deep-review recommendation is visible before implementation starts.
- The **reviewer** runs the `High-risk review` checklist section,
  recommends the appropriate rung, and records which rungs ran and
  their findings in `review.md`. A high-risk change reviewed only at
  rung 1 without a recorded reason is a checklist failure.
- The **documentation phase** is unchanged: deep-review findings that
  alter behavior, APIs, or operational guidance feed the documentation
  targets like any other review finding.
- Deep review does not change the state machine: `review → done` still
  requires the reviewer's decision plus the docs check, and autonomous
  workflows still cannot perform the transition
  (`reference/autonomy-policy.md`).
