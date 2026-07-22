---
name: run-and-verify
description: Run the project and verify behavior using its real commands. Use when validating an implementation, reproducing a bug, or confirming acceptance criteria before review.
---

# Run and verify

## Purpose

Run, inspect, and verify the target project using its actual commands and
services, so implementation claims ("it works") are backed by observed
behavior instead of assumptions.

> **This pack is generated, not copied.** When selected, the installed
> skill is produced from `templates/run-and-verify.md.template`, filled
> with the target project's real commands: dev server, test (all and
> targeted), lint, typecheck, build, required services, environment
> variable names (never values), and UI/API verification steps. Sources:
> the Phase 1 repository inspection first, then the questions in
> `questions.md` §15 for whatever could not be inferred. Unknown commands
> stay as `TODO: ask the developer`. This file documents the pack and the
> generic procedure; the generated file is the one Claude uses in the
> target project.

## When to use

- Before marking an implementation task ready for review.
- When the reviewer validates an implementation against its spec.
- Reproducing a reported bug before fixing it.
- Confirming acceptance criteria that describe runtime behavior.

## When not to use

- Pure documentation or comment changes with no runtime effect.
- When required services or credentials are unavailable — record a TODO
  and say verification was not performed, rather than faking it.

## Required inputs

- Project commands (from `CLAUDE.md` / the project map): dev server, test,
  lint, typecheck, build.
- Required services and environment variables (names only — values come
  from the developer's environment, never from this file).
- The acceptance criteria or expected behavior being verified.

## Procedure

1. Identify the narrowest check that exercises the change (targeted test,
   single route, one CLI invocation).
2. Run it; capture actual output.
3. Run the broader applicable checks (tests, lint, typecheck) the project
   defines.
4. Compare observed behavior against the spec's acceptance criteria.
5. Report honestly: what ran, what passed, what failed (with output), what
   could not be verified and why.

## Output artifact

Verification evidence in the task's review notes (`review.md`) or the
implementation summary: commands run, results, and unverified items.

## Safety constraints

- Never invent commands; unknown commands are `TODO: ask the developer`.
- Do not run destructive operations (migrations, data deletion, deploys)
  without explicit approval.
- Never store secrets in this skill, specs, or evidence; reference
  variable names only.
- Prefer local/test environments; never verify against production without
  explicit instruction.
