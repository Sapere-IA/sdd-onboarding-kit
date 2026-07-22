# SDD examples

A complete example spec lives in the kit under `specs/example-feature/` — markdown
sources filled in end-to-end through review, plus their rendered HTML (open the
HTML in a browser to see the target output). The fragments below are quick
references; the full markdown conventions are in `spec-format.md`.

## Example task entry

```json
{
  "id": "FEAT-007",
  "title": "Add recent notes CLI command",
  "slug": "cli-recent-notes",
  "description": "Add a CLI command that prints recent notes with an optional limit.",
  "sdd": true,
  "status": "pending",
  "spec_path": "specs/cli-recent-notes",
  "approval": {
    "required": true,
    "approved_by": null,
    "approved_at": null,
    "notes": null
  }
}
```

## Example EARS requirements

```md
REQ-001: When the user runs `notes recent` without `--limit`, the system shall print at most five notes ordered by descending creation time.
REQ-002: When the user runs `notes recent --limit N` with N greater than zero, the system shall print at most N notes.
REQ-003: If the user provides a non-positive limit, the system shall return a validation error and not print notes.
```

## Example design excerpt

```md
## Files to change

| File | Change | Reason |
| --- | --- | --- |
| `src/cli.py` | Add `recent` subcommand and `--limit` argument | CLI entrypoint |
| `src/notes.py` | Add `get_recent_notes(limit)` | Business logic |
| `tests/test_cli_recent.py` | Add CLI behavior tests | Requirement coverage |
```

## Example tasks

Tasks in `tasks.md` are an ordered list with status markers (`[ ]` pending,
`[x]` done, `[>]` in progress, `[!]` blocked); the renderer turns it into the
milestone timeline:

```md
1. [x] T1: Add tests for the default limit (REQ-001) — Failing test first; at most five notes, newest first.
2. [>] T2: Add tests for a custom positive limit (REQ-002)
3. [ ] T3: Add tests for invalid limits (REQ-003)
4. [ ] T4: Implement `get_recent_notes(limit)` — Business logic in `src/notes.py`.
5. [ ] T5: Register the `notes recent` subcommand — Wire `--limit` in `src/cli.py`.
6. [ ] T6: Run validation — Tests, lint and typecheck as configured in CLAUDE.md.
```

## Example: editing open-questions.md during spec_draft

This is a valid and expected operation. The `block-implementation-before-approval`
hook must allow it — `open-questions.md` is a spec file, not an implementation file.

A task in `spec_draft` has a blocking question card in `open-questions.md`:

```md
::: card blocking-yes
#### Q1 — Authentication mechanism [!blocking Blocking]

- **Question:** Should the endpoint use API key or OAuth2?
- **Why it matters:** Changes the security design and the dependency set.
- **Default if unanswered:** None — blocking.
:::
```

The spec-author (or developer) records the decision and moves the card to the
`## Resolved` section:

```md
::: card
#### Q1 — Authentication mechanism [!ok Resolved]

- **Question:** Should the endpoint use API key or OAuth2?
- **Decision:** API key for the MVP. OAuth2 in a follow-up task.
- **Resolved by:** developer, 2026-06-10
:::
```

After all blocking questions are resolved, the spec-author sets the task status
to `spec_ready` and requests human approval.

## Example review traceability

The traceability table in `review.md` uses cell verdict markers
(`!ok`, `!warning`, `!blocking`, `!pending`):

```md
| Requirement | Implemented? | Tested? | Evidence |
| --- | --- | --- | --- |
| REQ-001 | !ok Yes | !ok Yes | `src/cli.py`, `tests/test_cli_recent.py::test_default_limit` |
| REQ-002 | !ok Yes | !ok Yes | `src/cli.py`, `tests/test_cli_recent.py::test_custom_limit` |
| REQ-003 | !ok Yes | !warning Partial | `src/cli.py`; missing test for limit = 0 |
```
