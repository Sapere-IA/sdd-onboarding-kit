# Memory policy

Claude Code has several places where knowledge can persist across sessions. They differ in scope, visibility, and risk. This policy defines which layer to use for what, and one non-negotiable rule:

**Claude never writes global memory silently. Every memory write — global or project — requires explicit developer approval of the specific entry text.**

## Memory layers

| Layer | Location | Scope | Versioned with the repo | Who sees it |
|---|---|---|---|---|
| Global (user) memory | `~/.claude/CLAUDE.md` | All projects of this user | No | Only this user |
| Auto memory | `~/.claude/projects/<project>/memory/` (`MEMORY.md` index + topic files) | One project, one user | No | Only this user |
| Project memory — instructions | `./CLAUDE.md` (team) and `./CLAUDE.local.md` (personal, gitignored) | One project | `CLAUDE.md` yes; `CLAUDE.local.md` no | Team / only this user |
| Project memory — decision logs | `decisions/` (e.g. `answers.md`, failure-learning entries) | One project | Yes | Team |
| Task history | `history.md` | One project | Yes | Team |
| Review notes | `specs/<feature-slug>/review.md` | One task | Yes | Team |

Notes on the layers:

- **Global memory** is the user-level `CLAUDE.md`, loaded into every session in every project. It is the most expensive and most dangerous layer: a project-specific rule written there contaminates unrelated projects. Project-specific rules go to global memory only when the developer explicitly approves exactly that.
- **Auto memory** is maintained by Claude Code itself (toggle with `/memory` or the `autoMemoryEnabled` setting). It is project-scoped but lives outside the repo and is not reviewed by the team. Under this policy, lessons and decisions that matter to the project go to **versioned project artifacts**, not auto memory — artifacts survive machine changes, are reviewable, and are shared.
- **Project memory** is the preferred destination for durable project knowledge. Load-bearing rules belong in `CLAUDE.md` (short, see `reference/context-economy.md`); decisions and lessons belong in `decisions/`; completed-work summaries in `history.md`.
- **Task history and review notes** are the cheapest layer: correct for one-off findings that do not generalize.

## What may be stored where

| Kind of knowledge | Correct layer |
|---|---|
| Personal, project-independent preference ("I prefer concise answers") | Global memory — with approval |
| Reusable project lesson (convention, pitfall, corrected assumption) | `decisions/` entry; promote to `CLAUDE.md` rule if load-bearing |
| Architectural decision | Decision log / ADR |
| One-off finding tied to a task | `review.md` / `history.md` |
| Secrets, credentials, tokens | Nowhere. Never. |
| Personal/private data unrelated to the project | Nowhere. Never. |
| Speculative conclusions the developer has not confirmed | Nowhere until confirmed |

## Mandatory confirmation before any memory write

Before writing any memory entry (global or project), Claude must show the exact proposed text and ask:

```text
I found a reusable lesson from this mistake:

<proposed memory entry>

Do you want me to add this to memory?
1. Yes, global memory.
2. Yes, project memory only.
3. No, keep it only in the review/history.
4. Revise the wording first.
```

Mapping of the options:

1. **Global memory** → append to `~/.claude/CLAUDE.md`. Allowed only after this explicit choice; double-check that the entry is genuinely project-independent and contains no project internals.
2. **Project memory** (default recommendation) → append to the project's decision log (e.g. `decisions/failure-learnings.md`) using the entry format below; propose a `CLAUDE.md` rule additionally only if the lesson is load-bearing for every session.
3. **Review/history only** → record in `review.md` / `history.md`; no memory write.
4. **Revise** → rewrite the entry and ask again.

If the developer does not answer, nothing is written.

## Entry format

Memory entries use the format in `templates/memory/failure-learning-entry.md`: title, date, scope, trigger, what went wrong, root cause, rule to remember, where to apply, where not to apply, source task/spec/review.

## Security and privacy

- Never store secrets, credentials, tokens, or connection strings in any memory layer.
- Never store personal or private data unrelated to the project.
- Never put project-specific rules in global memory unless the developer explicitly approved exactly that.
- Memory entries that cite code should cite paths and rules, not paste sensitive content.
- Anything in `decisions/`, `history.md`, or `CLAUDE.md` is visible to everyone with repo access — write accordingly.

## Relationship to the failure-learning skill

The optional `failure-learning` pack (`skills/optional/failure-learning/SKILL.md`) implements this policy for implementation mistakes: it drafts the entry, shows the confirmation prompt, and writes only where the developer chose. The advisory hook examples under `hooks/examples/failure-learning/` may *suggest* running the skill; they never write memory themselves.

---

Memory locations and commands verified against the Claude Code docs (2026-06): user memory `~/.claude/CLAUDE.md`; project `CLAUDE.md` / `CLAUDE.local.md`; auto memory directory `~/.claude/projects/<project>/memory/` with `MEMORY.md` index; `/memory` command lists and edits memory files; `@path` imports supported. Sources: code.claude.com/docs `memory`, `interactive-mode`, `commands`.
