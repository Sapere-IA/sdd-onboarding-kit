# SDD review checklist

The reviewer must validate the implementation against the approved spec.

## 1. Spec completeness

- [ ] `requirements.md` exists.
- [ ] `design.md` exists.
- [ ] `tasks.md` exists.
- [ ] Human approval is recorded if required.
- [ ] No unresolved TODOs remain in approved requirements unless explicitly accepted.

## 1b. Conciseness and duplication

- [ ] No content is duplicated within a spec file or across the spec's files — shared content is referenced by ID (`REQ-001`, a section anchor), not restated. Duplication is a finding.
- [ ] Spec files are concise: no filler narrative, no padded boilerplate sections; non-applicable sections are collapsed to a single `None.` / `Not applicable.` line.

## 2. Requirement traceability

For every functional requirement:

- [ ] There is implementation evidence.
- [ ] There is test evidence or a documented exception.
- [ ] The behavior matches the requirement.
- [ ] Edge cases are handled.
- [ ] Error states are handled.

## 3. Design conformance

- [ ] The implementation follows `design.md`.
- [ ] Files changed are listed in the design or justified.
- [ ] Public APIs were not changed unexpectedly.
- [ ] Data/schema changes are documented.
- [ ] Rollback considerations remain valid.

## 4. Testing

- [ ] New tests were added where needed.
- [ ] Existing tests were updated only when justified.
- [ ] Tests assert behavior, not implementation details, unless appropriate.
- [ ] Tests fail for the right reason before implementation if using TDD.
- [ ] All configured tests pass, or failures are documented and accepted.
- [ ] If the project has a `run-and-verify` skill (`.claude/skills/run-and-verify/SKILL.md`), applicable checks were run through it and the evidence (commands run, results, unverified items) is recorded.

## 5. Code quality

- [ ] Code follows project conventions.
- [ ] Error handling is appropriate.
- [ ] No unrelated refactor was introduced.
- [ ] No dead code or debug output remains.
- [ ] No secrets or credentials were introduced.

## 6. Safety

- [ ] Protected files were not modified without approval.
- [ ] Destructive operations were not added without explicit design approval.
- [ ] Security-sensitive changes were reviewed.
- [ ] External inputs are validated.
- [ ] External dependency/SDK/API/framework changes carry freshness evidence (docs checked with source and date, version constraints, deprecated APIs avoided) in the design's `External dependencies and freshness` section or in the review. Purely internal changes state `None`.

## 7. Documentation

- [ ] A documentation decision is recorded: required (with targets) or not required.
- [ ] If required: each target was updated by the documenter or justified as unaffected.
- [ ] Updated docs match the reviewed implementation — no unmerged, rejected, or speculative details.
- [ ] No secrets or internal-only URLs appear in updated documentation.
- [ ] The task is not marked `done` while `documentation_status` is `pending` and documentation is required.

## 8. Project memory and decisions

- [ ] Significant decisions settled by this task (architectural choices, rejected alternatives, workflow rules) were proposed for the decision log, or `None` is recorded in the review.
- [ ] No trivial decisions were flagged; proposed entries contain no secrets or sensitive operational data.
- [ ] Nothing was written to a decision log without developer approval of the entry text.

## 9. High-risk review

Applies when the change touches a high-risk category: security-sensitive
code, authentication/authorization, payment flows, database migrations,
infrastructure/deployment, public API changes, large cross-cutting
refactors, or data-loss risks (full policy:
`reference/deep-review-policy.md`).

- [ ] High-risk categories touched by this change are identified, or `None` is recorded.
- [ ] For each category touched, a deeper review ran: at minimum a security-focused pass for security-relevant changes, and an adversarial second pass (independent reviewer per lens: security, correctness/edge cases, performance) where feasible.
- [ ] Paid/limited review modes (cloud deep review, automated PR review services) were used only with explicit developer approval — and their absence did not block the task (the adversarial pass is the accepted substitute, with the substitution noted).
- [ ] The deep-review output covers: security findings, performance findings, edge cases, reproduction attempts (reproduced vs theoretical, labeled), and a remediation plan with severities.
- [ ] A high-risk change reviewed only at the standard level has the reason recorded in `review.md`.

## 10. Decision

Choose exactly one:

- `approved`
- `needs_changes`
- `spec_revision_required`
- `blocked`

A review cannot be `approved` if a blocking requirement has no implementation or test evidence, or if a high-risk external change (auth, payments, database migrations, cloud infrastructure, framework upgrades, security-sensitive code) lacks the required freshness evidence. A task cannot be marked `done` while required documentation is pending.
