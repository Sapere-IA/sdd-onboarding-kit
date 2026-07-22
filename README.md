# SDD Onboarding Kit for Claude Code

This kit installs a **Spec Driven Development (SDD)** harness in any repository you work on with Claude Code.

It is not a global user configuration. It is a reusable template that produces a project-specific configuration: `CLAUDE.md`, `.claude/agents/`, `.claude/skills/`, `.claude/settings.json`, `specs/`, `tasks.json`, `history.md`, and validation scripts.

## Documentation

Full operational documentation lives in **[`DOCUMENTATION.html`](DOCUMENTATION.html)** (open it in a browser). The documentation is layered:

- `README.md` — quick start, purpose, installation, default safety model (this file);
- `DOCUMENTATION.html` — full operational documentation;
- `reference/` — deeper theory and policy material;
- `skills/` — reusable procedural instructions (installed as `.claude/skills/`);
- `agents/` — role-specific agents (installed as `.claude/agents/`).

**English is canonical for all reusable kit files.** Generated project-specific artifacts (specs, decisions, history) may use the target project's preferred language; see the language policy in `DOCUMENTATION.html`.

The kit is designed to protect Claude Code's context window: generated `CLAUDE.md` files stay short and link out, long procedures live in skills, and durable knowledge lives in versioned artifacts instead of chat history. See [`reference/context-economy.md`](reference/context-economy.md).

Onboarding also generates a concise **project map** (default `.claude/context/project-map.md`): directory tree, entrypoints, commands, and protected areas — so Claude knows where things live without loading many files.

## What SDD does

When the harness is installed, Claude Code works like this:

1. The developer selects or describes a task.
2. Claude creates a spec (requirements, design, implementation tasks) before touching any code.
3. The developer reviews and approves the spec.
4. Claude implements only against the approved spec.
5. Claude runs tests and validation.
6. Claude reviews traceability between requirements, design, tasks, code and tests.
7. When the change affects documentation, a documenter updates the affected docs after review — a task is not complete while required documentation is stale.
8. The task is marked done or returned for correction.

## How to use this kit

Copy or add this folder to the project where you want to install SDD. For example:

```text
my-project/
└── sdd-onboarding-kit/
```

Then open Claude Code in `my-project/` and run:

```text
Read `sdd-onboarding-kit/instructions.md` and configure this repository to use Spec Driven Development. Ask me all necessary questions before making project-specific decisions.
```

Claude Code will inspect the repository, ask you the configuration questions from `questions.md`, and generate a complete project-specific SDD harness.

## What gets installed?

**Installed by default** (every onboarding):

- A short, project-specific `CLAUDE.md` generated from the kit's template — links out, never duplicates skill bodies.
- `.claude/agents/`: leader, spec-author, implementer, reviewer, documenter.
- `.claude/skills/sdd-workflow/`: the core SDD skill with workflow, state machine, review checklist, and markdown spec templates.
- `.claude/skills/sdd-update/` plus `.claude/sdd-kit-manifest.json`: the self-update mechanism — run `/sdd-update` in an installed project to pull in new kit versions (see `CHANGELOG.md`).
- A spec renderer (`scripts/render-spec.mjs` for Node projects or `scripts/render_spec.py` for Python projects, zero dependencies): specs are written in markdown (the source of truth, cheap for the model to read and write) and rendered on demand to styled, self-contained HTML for human review; rendered HTML is gitignored.
- `specs/`, `tasks.json`, `history.md`, `decisions/answers.md`, and the project map.
- Validation scripts adapted to the project, including a `jq`-free PowerShell port of the structure validator for Windows-primary teams.

**Optional — only with your explicit selection:**

- Any of the ten skill packs (§14 of `questions.md`).
- Hooks — shipped as examples, never enabled without approval.
- MCPs — none configured by default; the browser-tester agent scopes Playwright to itself when chosen.
- Decision-log files, git text templates, autonomy beyond read-only monitoring, paid deep-review modes.

Nothing in the kit phones home, stores credentials, or enables external access by itself — the default install is fully local.

## Key files

| File | Purpose |
|---|---|
| `instructions.md` | Step-by-step procedure Claude Code follows to install the harness |
| `questions.md` | Project-specific decisions Claude must ask before writing files |
| `agents/` | Subagent templates: leader, spec-author, implementer, reviewer, documenter |
| `skills/sdd-workflow/` | Full SDD workflow skill (copied to `.claude/skills/`) |
| `skills/optional/` | Optional skill packs, installed only when selected during onboarding |
| `hooks/` | Hook policies, settings snippets and example hook scripts |
| `mcps/` | Criteria for deciding which MCPs to configure |
| `templates/` | File templates Claude adapts to the target project |
| `specs/example-feature/` | Complete example spec: markdown sources plus rendered HTML (open the HTML in a browser) |
| `scripts/` | Base scripts: spec renderers (Node and Python), structure/environment/test validation (bash, plus a `jq`-free PowerShell validator port for Windows) |
| `CHANGELOG.md` / `VERSION` | Kit version history with per-release migration notes, consumed by `/sdd-update` |
| `reference/` | SDD theory, harness engineering, Claude Code primitives |
| `output-project-structure.md` | Expected structure of the target project after onboarding |
| `usage-prompts.md` | Ready-to-use prompts for daily SDD use |
| `DOCUMENTATION.html` | Full documentation: installation, daily workflow, features (open in a browser) |

## Optional skills

Beyond the core `sdd-workflow` skill, the kit ships ten optional skill packs under [`skills/optional/`](skills/optional/README.md): `context-audit`, `project-map`, `run-and-verify`, `dependency-freshness`, `git-discipline`, `decision-log`, `documentation-update`, `failure-learning`, `ui-qa`, and `spec-from-screenshot`. None is installed by default — onboarding asks which packs the project needs, and installed skills are listed in `CLAUDE.md` by name only (their instructions load when invoked). All packs are advisory or permission-gated. See the `Skill packs` section in `DOCUMENTATION.html`.

The `run-and-verify` pack is special: onboarding **generates a project-specific run/verify recipe** — the project's real dev-server/test/lint/typecheck/build commands, required services, environment variable names (never secret values), and how to verify UI or API behavior. Unknown commands are recorded as TODOs, never invented, and the reviewer validates implementations through this recipe. See the `Run and verify skill` section in `DOCUMENTATION.html`.

The kit also includes **freshness checks for external APIs and dependencies**: changes that touch external dependencies, SDKs, APIs, or framework configuration are verified against current documentation, with the evidence recorded in the spec, and the reviewer can block high-risk changes (auth, payments, migrations, cloud infrastructure, framework upgrades, security-sensitive code) that lack it. Purely internal changes are unaffected. See [`reference/dependency-freshness-policy.md`](reference/dependency-freshness-policy.md) and the `Dependency and API freshness` section in `DOCUMENTATION.html`.

## Failure learning

The optional `failure-learning` pack turns real mistakes (wrong assumptions, convention violations, repeated errors) into reusable lessons. Claude drafts a structured entry and **proposes** it; the developer chooses where it lives — project decision log (preferred), review/history only, or global memory. **Claude never writes global memory without explicit user approval of the exact entry text**, and never stores secrets or personal data in any memory layer. An optional advisory hook can suggest running the skill after repeated failures, but it never writes memory itself. See [`reference/memory-policy.md`](reference/memory-policy.md) and the `Memory policy` / `Failure learning` sections in `DOCUMENTATION.html`.

## Project memory and decision logs

Durable knowledge lives in versioned artifacts, not chat history. Onboarding always creates `decisions/answers.md` (the recorded onboarding answers); the optional `decision-log` pack adds `decisions/architecture-decisions.md`, `decisions/rejected-options.md`, and `decisions/workflow-decisions.md` — or uses the project's existing `docs/adr/`. When a spec or review settles something significant, Claude **proposes** an entry: trivial decisions are not logged, secrets never are, and nothing is written without approval. See the `Project memory and decision logs` section in `DOCUMENTATION.html`.

## Hooks

The kit ships example hooks under `hooks/examples/` (policy: [`hooks/hooks-policy.md`](hooks/hooks-policy.md)) that support the SDD workflow deterministically: blocking implementation before spec approval, validating spec files before status changes, suggesting targeted checks after edits, detecting spec drift against the approved task scope, pre-compact capture reminders, and failure-learning suggestions. **All hooks are optional and disabled by default** — they are examples until explicitly configured in `.claude/settings.json`, and every hook is classified (advisory / blocking / mutating / dangerous) in `hooks/hooks-policy.md`. The kit ships no mutating or dangerous hooks. See the `Hooks` section in `DOCUMENTATION.html`.

## Optional browser testing

For projects with a browser UI, onboarding can install a **browser-tester subagent** with the Playwright MCP scoped to that agent alone: the MCP server is declared inline in the agent's frontmatter, so browser tools exist only while the agent runs and never load into the main conversation. Specs gain optional UI acceptance criteria (routes, visual states, interaction flows, accessibility, responsive states), and the `ui-qa` skill routes verification through the agent. Non-UI projects are unaffected — nothing Playwright-related is installed by default, credentials are never stored, and production destructive actions are out of bounds. See [`mcps/playwright-policy.md`](mcps/playwright-policy.md) and the `Browser/UI testing with Playwright` section in `DOCUMENTATION.html`.

## CLIs and MCPs

The kit is **local-first**: it works fully with no external MCP and no external CLI. MCPs are optional and configured only on explicit approval. Where both could do a job, the kit prefers the narrower tool — a single permission-gated CLI call for one-off reads (PR metadata, deployment status), a scoped MCP for structured or repeated access — and any CLI command that mutates remote state requires explicit per-action permission. See [`reference/cli-vs-mcp-policy.md`](reference/cli-vs-mcp-policy.md) and the `CLI vs MCP` section in `DOCUMENTATION.html`.

## Screenshots as spec inputs

Screenshots, mockups, and other visual evidence are first-class inputs for UI work: the optional `spec-from-screenshot` pack turns them into structured spec material (image inventory with provenance, observed vs expected behavior, UI acceptance criteria), and reviews compare the implemented UI against the same images. Two rules apply throughout: screenshots are evidence, not automatically complete requirements, and Claude asks when the visual intent is ambiguous. See the `Screenshots and visual evidence` section in `DOCUMENTATION.html`.

## High-risk changes get deeper review

Some changes deserve more than the standard reviewer pass: security-sensitive code, auth, payments, database migrations, infrastructure, public APIs, large refactors, data-loss risks. For those, the kit recommends an escalation ladder — a security-focused pass, then independent adversarial reviewers, then (only if available and approved) paid deep-review modes. Deep review **supplements** the SDD reviewer, never replaces it, and the kit never assumes paid features are available. See [`reference/deep-review-policy.md`](reference/deep-review-policy.md) and the `Deep review policy` section in `DOCUMENTATION.html`.

## Git safety

Every mutating git action is permission-gated. The optional `git-discipline` pack adds the working rules — inspect `git status` first, never overwrite user changes, no commit/push unless asked, no force-push without documented approval, no PR merges unless instructed — plus commit-message, PR-description, and release-note templates that tie git text to SDD tasks (PR descriptions are generated from the reviewer's `review.md`). The skill supports the SDD workflow; it never bypasses it. See the `Git discipline` section in `DOCUMENTATION.html`.

## Autonomy is opt-in

Autonomous workflows (loops, goals, scheduled routines, background or headless runs) are **controlled execution, not blanket permission**. They are fine for monitoring CI, checking deployment status, and repeated read-only verification — always with explicit stop conditions — but they can never deploy, migrate, merge, push to protected branches, or mark a task `done`: SDD state transitions stay human-gated. See [`reference/autonomy-policy.md`](reference/autonomy-policy.md) and the `Autonomy policy` section in `DOCUMENTATION.html`.

## Resumable work

Work survives interruptions because state lives in artifacts, not in chat: `tasks.json`, specs, reviews, decision logs, and `history.md` are the source of truth. Claude Code's recap, rewind, and resume features are conveniences for reorienting — after any resume, rewind, or compaction, the kit's rule is to inspect the durable artifacts before continuing, and when conversation memory disagrees with an artifact, the artifact wins. See [`reference/session-recovery.md`](reference/session-recovery.md) and the `Session recovery` section in `DOCUMENTATION.html`.

## Templates carry the policies

The spec templates make the kit's policies visible where work actually happens: generated requirements ask about external dependencies, documentation expectations, and decision-log implications; designs carry freshness evidence, security/permissions, project-map references, and docs targets; reviews record the documentation decision, spec-drift check, high-risk/deep-review results, and propose-only decision/failure-learning entries; history entries capture docs updates and recorded decisions. Every optional section has a `None` convention, so simple tasks stay simple. See the `Templates and generated artifacts` section in `DOCUMENTATION.html`.

## Recommended defaults

Onboarding offers a safe default profile in a single question, so nobody has to answer twenty sections to get started: local-first (no external MCPs/CLIs required), human approval and reviewer required, documentation phase enabled, failure-learning proposals without automatic memory writes, Playwright disabled unless a frontend is detected and the developer opts in, external MCPs off unless opted in, autonomy limited to documented read-only monitoring, and git mutations requiring explicit permission. Accepting the profile reduces onboarding to the genuinely project-specific questions (commands, protected files, SDD scope). See `questions.md` and the `Onboarding questions and defaults` section in `DOCUMENTATION.html`.

## Central principle

The onboarding produces a project-specific configuration. It does not copy generic rules without adapting them. If a decision is missing, Claude Code asks.

## Contributing

Contributions are welcome. To propose a change:

1. Fork the repository.
2. Create a branch from `main` with a descriptive name (e.g. `fix/hook-path-filter` or `feat/linear-mcp-notes`).
3. Make your changes. Keep PRs focused — one concern per PR.
4. Open a pull request against `main` with a clear description of what the change does and why.
5. Wait for review. Only the repository owner merges PRs.

### Guidelines

- Keep all files in English.
- Template files under `templates/` use `{{PLACEHOLDER}}` syntax; keep that convention.
- Hook scripts must be POSIX-compatible bash and degrade gracefully when `jq` is unavailable.
- Agent files must follow the frontmatter format (`name`, `description`, `tools`).

### Reporting issues

Open a GitHub issue with:
- A short description of the bug or request.
- Steps to reproduce (if a bug).
- The expected vs. actual behavior.

## License

MIT — see [LICENSE](LICENSE)

---