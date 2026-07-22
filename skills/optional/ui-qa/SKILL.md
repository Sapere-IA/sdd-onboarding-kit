---
name: ui-qa
description: Verify UI changes against spec acceptance criteria. Use when a task changes user-visible interface behavior, layout, or flows.
---

# UI QA

## Purpose

Check that UI changes match their spec's acceptance criteria — routes,
visual states, interaction flows, responsive behavior, and accessibility —
and record the evidence.

Two execution paths:

- **Browser-tester agent** (when installed — `questions.md` §18 option 2):
  invoke the `browser-tester` subagent to walk the criteria in a real
  browser through its scoped Playwright MCP. Browser tools exist only
  inside that agent (see `mcps/playwright-policy.md` in the kit).
- **Manual path** (always available): use the verification means already
  in the project — dev server, manual steps, existing UI test commands,
  developer-provided screenshots.

## When to use

- A task changes user-visible behavior, layout, styling, or flows.
- A spec contains visual or interaction acceptance criteria.
- A UI bug fix needs before/after confirmation.

## When not to use

- Backend-only or non-visual changes.
- When no UI can be run or observed in the environment — record that QA
  was not performed instead of claiming it was.

## Required inputs

- The spec's UI acceptance criteria: target route/component, expected
  visual state, interaction flow; screenshots or mockups if provided.
- The spec's `Visual evidence` section, when present (filled by the
  `spec-from-screenshot` skill if installed): image inventory with IDs,
  observed/expected behavior, affected routes. For bug fixes, compare
  the *before* screenshot with the implemented *after* state.
- How to run the UI locally (dev server command from `CLAUDE.md` / the
  project map).
- Test account credentials **names** if auth is required — provided by the
  developer at run time, never stored.

## Procedure

0. If the project has the `browser-tester` agent installed
   (`.claude/agents/browser-tester.md`), invoke it with the spec's UI
   acceptance criteria — it executes steps 1–3 in a real browser and
   returns the per-criterion checklist. Continue manually only for
   criteria it could not verify.
1. Start the UI with the project's dev command (or use the running
   instance the developer points to).
2. Walk each acceptance criterion: navigate to the target route, perform
   the interaction, compare the observed state with the expected one
   (screenshots/mockups when provided).
3. Check the spec's responsive and accessibility criteria where present.
4. Run the project's existing UI test suite if one exists.
5. Record per-criterion results: pass, fail (with what was observed), or
   not verifiable (with why).

## Output artifact

A UI QA checklist in the task's review notes: criterion → result →
evidence (screenshot reference or description). When the spec has visual
evidence, record the comparisons in the `Visual verification` section of
`review.md` (criterion/image → evidence → result).

## Safety constraints

- Never store credentials in specs, skills, or evidence; ask the developer
  to provide them at run time and prefer test accounts.
- Require explicit approval before using any credentials.
- No destructive actions against shared or production environments;
  verify against local/test instances.
