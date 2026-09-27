---
name: project-map
description: Generate or refresh the project map artifact. Use after significant repository structure changes or when the map is missing or stale.
---

# Project map

## Purpose

Create or update the project map — the concise orientation artifact
(default `<harness-dir>/context/project-map.md`) that tells the agent where things
live without loading many files. See DOCUMENTATION.html §16 in the kit.

## When to use

- The map does not exist (generation was deferred at onboarding).
- A top-level or load-bearing directory was added, renamed, or removed.
- An entrypoint moved, or build/test/lint commands changed.
- A new protected area or generated path appeared.
- The map demonstrably disagrees with the repository.

## When not to use

- Routine file additions inside existing directories.
- As a substitute for reading actual code when implementing.

## Required inputs

- The map template (`templates/project-map.md.template` in the kit, or the
  existing generated map).
- Repository inspection: directory tree (depth 2–3), package manifests,
  scripts, CI config, docs.
- The project `AGENTS.md` protected-areas section.

## Procedure

1. Inspect the repository (prefer a subagent if the survey is large).
2. Fill or update the map's eight sections: tree, entrypoints, commands,
   framework/runtime assumptions, important docs, protected areas, SDD
   locations, generated/do-not-edit files.
3. Keep it one to two screens; annotate, do not enumerate.
4. Record unknown commands as `TODO: ask the developer` — never invent.
5. Verify `AGENTS.md` links the map at its configured location.

## Output artifact

The project map file at its configured location (default
`<harness-dir>/context/project-map.md`).

## Safety constraints

- Never record secrets, credentials, or tokens.
- Do not change `AGENTS.md` beyond the map link without approval.
- If the map's configured location is unclear, ask instead of creating a
  second map.
