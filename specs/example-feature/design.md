---
doc: design
title: Design — Recent notes command
task_id: TASK-001
feature_slug: example-feature
status: spec_draft
---

## Technical summary

Add a `recent` subcommand to the existing CLI parser. It reuses the note store's `list()` API, sorts by `updated_at` descending, and truncates to the limit (REQ-001, REQ-002). Limit validation happens at argument-parse time (REQ-003).

## Data flow

::: diagram
<svg width="560" height="140" viewBox="0 0 560 140" aria-label="Data flow: CLI args to sorted output">
  <defs>
    <marker id="arrowhead" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0, 8 3, 0 6" fill="#6b7280"/>
    </marker>
  </defs>
  <rect x="20" y="50" width="120" height="40" rx="6" fill="#eff6ff" stroke="#2563eb" stroke-width="1.5"/>
  <text x="80" y="75" text-anchor="middle" font-family="sans-serif" font-size="12" fill="#1e3a8a">CLI args</text>
  <line x1="140" y1="70" x2="218" y2="70" stroke="#6b7280" stroke-width="1.5" marker-end="url(#arrowhead)"/>
  <rect x="220" y="40" width="120" height="60" rx="6" fill="#f5f3ff" stroke="#7c3aed" stroke-width="1.5"/>
  <text x="280" y="68" text-anchor="middle" font-family="sans-serif" font-size="12" fill="#4c1d95">recent()</text>
  <text x="280" y="84" text-anchor="middle" font-family="sans-serif" font-size="10" fill="#4c1d95">sort + truncate</text>
  <line x1="340" y1="70" x2="418" y2="70" stroke="#6b7280" stroke-width="1.5" marker-end="url(#arrowhead)"/>
  <rect x="420" y="50" width="120" height="40" rx="6" fill="#eafaf1" stroke="#27ae60" stroke-width="1.5"/>
  <text x="480" y="75" text-anchor="middle" font-family="sans-serif" font-size="12" fill="#14532d">stdout</text>
</svg>
:::

## Project map references

None (no project map).

## Files to change

| File | Change | Reason |
| --- | --- | --- |
| `src/cli.py` | Register the `recent` subcommand and `--limit` option | REQ-001, REQ-002 |
| `src/commands/recent.py` | New command implementation | REQ-001–REQ-003 |
| `tests/test_recent.py` | New test module | Test design |

## Files not to change

| File or directory | Reason |
| --- | --- |
| `src/store.py` | `list()` already returns what we need; sorting stays in the command |

## Interfaces and contracts

```text
notes recent [--limit N]    # N: positive integer, default 5
recent(store: NoteStore, limit: int = 5) -> list[Note]
```

## Data model changes

None.

## External dependencies and freshness

None.

## Security and permissions

None.

## Documentation targets

`README.md` — CLI command table (from requirements' Documentation expectations).

## Test design

- AT1/AT2 as unit tests on `recent()` (REQ-001, REQ-002); AT-ERR-1 as a parser test (REQ-003).
- EDGE-001/EDGE-002 as unit tests on the empty and short-store paths.

## UI verification plan

Not applicable.

## Risks and trade-offs

- Sorting in the command keeps the store API untouched; acceptable up to NFR-001's 10k-note bound.
- Rejected: adding a `recent()` store method — premature for one caller.

## Rollback plan

Remove the subcommand registration in `src/cli.py`; the new module is unreachable without it.
