---
name: spec-from-screenshot
description: Turn screenshots, mockups, and other visual evidence into structured SDD spec material. Use when a task starts from an image — a design to build, a UI bug to fix, a regression to document, or visual acceptance criteria.
---

# Spec from screenshot

## Purpose

Convert visual inputs into structured requirements so the SDD workflow
can act on them: screenshots become inventory entries with provenance,
observations become observed/expected behavior, and visual expectations
become testable UI acceptance criteria.

Two rules govern everything this skill does:

1. **Screenshots are evidence, not automatically complete
   requirements.** An image shows one state of one screen at one
   moment. It does not show intent, edge cases, other viewports, or
   what should happen on error. Extract what is visible; never promote
   it to a requirement without confirming intent.
2. **Ask clarifying questions when visual intent is ambiguous.** If it
   is unclear whether an element is part of the request, which parts of
   a mockup are binding versus illustrative, or what the expected
   behavior is, ask — do not guess.

## When to use

- **Design inspiration / mockups** — the developer provides an image of
  what to build.
- **Visual bug reports** — a screenshot shows broken layout, styling,
  or state.
- **Regression evidence** — before/after images documenting a change in
  behavior.
- **UI acceptance criteria** — images defining what "done" looks like
  for a UI task.

## When not to use

- The image is decoration or context, not input for requirements.
- Non-visual tasks where a diagram merely illustrates architecture —
  read it, but this skill's spec sections do not apply.

## Required inputs

- The image file(s) or pasted screenshot(s).
- For each image: where it comes from (provenance — which app/route,
  which environment, which device/viewport if known, who produced it).
- The intent: build this / fix this / verify against this.

## Procedure

1. **Inventory.** List every image with a short identifier, what it
   shows, and its provenance. Unknown provenance is recorded as
   unknown, not invented.
2. **Classify intent** per image: design to build, bug evidence,
   regression before/after, or acceptance criterion.
3. **Extract observable facts only.** Layout, components, text, states,
   counts, colors if relevant. Separate what is *visible* from what is
   *inferred* — inferences are questions, not requirements.
4. **Ask about ambiguities** before writing requirements: binding vs
   illustrative parts, expected behavior not shown (hover, empty,
   error, loading states), other viewports, accessibility expectations.
5. **Map into the spec:**
   - Screenshots inventory, observed behavior, expected behavior, and
     affected routes/components → the `Visual evidence` section of
     `requirements.md`.
   - Testable visual expectations → rows in the `UI acceptance
     criteria` table (route, expected state, interaction flow,
     accessibility, responsive states).
   - Open visual questions → `open-questions.md`, like any other
     unresolved requirement.
6. **Keep the link.** Reference image identifiers from requirements and
   acceptance criteria so the reviewer and the `ui-qa` skill can verify
   the implementation against the same images.

## Output artifact

A filled `Visual evidence` section in the spec's `requirements.md`
(plus UI acceptance criteria rows where expectations are testable), with
every entry traceable to a listed image.

## Integration

- **ui-qa** (when installed): uses the visual-evidence section and the
  UI acceptance criteria as its input; for bug fixes it compares the
  *before* screenshot with the implemented *after* state.
- **browser-tester agent** (when installed): walks the criteria in a
  real browser; provide the image identifiers it should compare
  against.
- **Reviewer:** records the comparison results in the
  `Visual verification` section of `review.md`.

## Safety constraints

- Screenshots may contain secrets, tokens, API keys, or personal data.
  Flag them to the developer; never transcribe credentials or personal
  data into specs, reviews, or any kit artifact. Prefer redacted
  re-captures.
- Do not fabricate pixel-perfect requirements from low-fidelity images;
  record fidelity honestly (mockup vs production screenshot).
- Provenance is part of the evidence: an image of unknown origin is
  weaker evidence and is marked as such.
