# Memory MCP notes

A memory MCP can store cross-session decisions, architecture notes and recurring project knowledge.

## What to store

Good candidates:

- stable architecture decisions;
- recurring implementation conventions;
- known project pitfalls;
- decisions made during spec approval;
- mappings between external tools and SDD status.

Bad candidates:

- secrets;
- transient task details;
- unreviewed external content;
- personal/private information unrelated to the project.

## Questions before configuring

1. Is memory project-scoped or user-scoped?
2. Who can read stored memories?
3. What categories of information may be stored?
4. Should Claude ask before writing memory?
5. Should memory entries link back to specs or ADRs?

## Safe default

Use local files first:

- `history.md`
- `docs/architecture.md`
- `docs/conventions.md`
- `docs/adr/`

Add memory MCP only when the team needs cross-repo or cross-session persistence beyond git.
