# Harness Engineering applied to SDD

Harness Engineering is the practice of building a working harness around an AI so that it follows a specific workflow in a repeatable, auditable and safe way.

SDD is the workflow. The harness is the infrastructure that enforces or facilitates that workflow.

## Goal of the harness

The goal is not for Claude Code to "remember" a preference. The goal is for the repository to contain artifacts that guide the work persistently:

- project instructions;
- specialized subagents;
- reusable skills;
- deterministic hooks;
- external memory in files;
- spec templates;
- validation scripts;
- optional integration with external tools via MCP.

## Harness components

### 1. Persistent instructions

The project must have a `CLAUDE.md` with short, specific rules.

### 2. Subagents

The workflow is split into roles:

- `leader`: inspects task state and recommends which phase and agent comes next (the main conversation orchestrates);
- `spec-author`: generates requirements, design and tasks;
- `implementer`: implements code against the approved spec;
- `reviewer`: validates traceability, tests and quality.

### 3. External memory

Important context is stored outside the chat:

- `tasks.json`: task state;
- `specs/<feature>/`: versionable specs;
- `history.md`: execution history;
- `docs/architecture.md`: architecture;
- `docs/conventions.md`: conventions.

### 4. SDD skill

The skill contains the long procedure. This avoids bloating `CLAUDE.md` with instructions that are only needed during SDD tasks.

### 5. Hooks

Hooks can enforce deterministic rules, for example blocking code edits when no approved spec exists.

Hooks must be enabled only after developer approval.

### 6. MCPs

MCPs connect Claude Code to external tools: GitHub, Linear, Jira, documentation, memory, databases or internal systems.

They should be configured only if the project actually needs them.

## Design principle

The harness must be:

- explicit;
- versionable;
- reviewable;
- portable;
- configurable per project;
- strict where there is risk;
- flexible where the developer needs judgment.
