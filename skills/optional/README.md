# Optional skill packs

Source templates for optional, per-project skills. The core SDD behavior
lives in `skills/sdd-workflow/` and is always installed; the packs in this
directory are installed **only when the developer selects them** during
onboarding (see `questions.md` §14) or asks for them later.

## Installation rule

For each selected pack, copy `skills/optional/<name>/` to
`.claude/skills/<name>/` in the target project and adapt placeholders and
project-specific details. Record the selection (installed and declined) in
`decisions/answers.md`.

Do not install unselected packs "just in case", and do not paste skill
bodies into `CLAUDE.md` — list installed skills there by name with a
one-line purpose at most. Skill bodies load only when invoked, which is
what keeps them cheap (see `reference/context-economy.md`).

## Available packs

The third column is the question to answer before installing: what does the
pack add **over the always-on baseline** (the `documenter` agent, the
project map Phase 3 generates anyway, and the profile's failure-learning
proposals)? Three packs overlap that baseline — install them only if you
want the extra they describe; the others are net-new.

| Skill | Purpose | Adds over the always-on baseline |
|---|---|---|
| `context-audit` | Inspect and reduce context-window usage in long sessions. | Net-new. |
| `project-map` | Generate or refresh the project map artifact. | Phase 3 already generates the initial map; this adds an on-demand skill to **refresh** it when structure changes. |
| `run-and-verify` | Run the project and verify behavior using its real commands. | Net-new (generated from a template, not copied). |
| `dependency-freshness` | Check current docs before changing external dependencies/APIs. | Net-new. |
| `git-discipline` | Clean branches, commits, and PR descriptions without risky git actions. | Net-new. |
| `decision-log` | Record durable architectural/workflow decisions. | Net-new. |
| `documentation-update` | Update affected documentation after review, before done. | The doc phase already runs via the always-installed `documenter` agent; this adds the same procedure as a **standalone, invokable/customizable skill**. |
| `failure-learning` | Propose a reusable lesson after a meaningful mistake. | Proposing lessons is already on by default in the profile; this adds a **structured skill + entry template** for capturing the lesson as a memory entry. |
| `ui-qa` | Verify UI changes against spec acceptance criteria. | Net-new. |
| `spec-from-screenshot` | Turn screenshots, mockups, and visual evidence into structured spec material. | Net-new. |

Every pack documents: purpose, when to use, when not to use, required
inputs, output artifact, and safety constraints. All packs are advisory or
permission-gated: none mutates git state, external systems, or memory
without explicit developer approval.

## Suggested themed bundles

There are ten packs, so they do not fit a single structured chooser capped
at four options. Group them into these four themed bundles when presenting
the choice; selecting a bundle means *proposing* its packs — each is still
installed individually on confirmation, never silently as a set.

| Bundle | Packs |
|---|---|
| Verification | `run-and-verify`, `ui-qa`, `dependency-freshness` |
| Git & decisions | `git-discipline`, `decision-log` |
| Docs & knowledge | `documentation-update`, `project-map`, `failure-learning` |
| Context & visual intake | `context-audit`, `spec-from-screenshot` |
