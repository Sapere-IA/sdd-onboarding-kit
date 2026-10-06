---
doc: design
title: Design — Recent notes command
task_id: TASK-001
feature_slug: example-feature
status: spec_draft
---

## Summary

A new `recent` subcommand reuses the store's `list()`, sorts by `updated_at` descending and truncates to the limit (REQ-001, REQ-002). The parser validates the limit (REQ-003).

## Data flow

::: diagram
<svg width="560" height="120" viewBox="0 0 560 120" aria-label="Data flow: CLI args to sorted output">
  <defs>
    <marker id="arrowhead" markerWidth="8" markerHeight="6" refX="8" refY="3" orient="auto">
      <polygon points="0 0, 8 3, 0 6" fill="#6b7280"/>
    </marker>
  </defs>
  <rect x="20" y="40" width="120" height="40" rx="6" fill="#eff6ff" stroke="#2563eb" stroke-width="1.5"/>
  <text x="80" y="65" text-anchor="middle" font-family="sans-serif" font-size="12" fill="#1e3a8a">CLI args</text>
  <line x1="140" y1="60" x2="218" y2="60" stroke="#6b7280" stroke-width="1.5" marker-end="url(#arrowhead)"/>
  <rect x="220" y="30" width="120" height="60" rx="6" fill="#f5f3ff" stroke="#7c3aed" stroke-width="1.5"/>
  <text x="280" y="58" text-anchor="middle" font-family="sans-serif" font-size="12" fill="#4c1d95">recent()</text>
  <text x="280" y="74" text-anchor="middle" font-family="sans-serif" font-size="10" fill="#4c1d95">sort + truncate</text>
  <line x1="340" y1="60" x2="418" y2="60" stroke="#6b7280" stroke-width="1.5" marker-end="url(#arrowhead)"/>
  <rect x="420" y="40" width="120" height="40" rx="6" fill="#eafaf1" stroke="#27ae60" stroke-width="1.5"/>
  <text x="480" y="65" text-anchor="middle" font-family="sans-serif" font-size="12" fill="#14532d">stdout</text>
</svg>
:::

## Files to change

| File | Change | Reason |
| --- | --- | --- |
| `src/cli.py` | Register `recent` and `--limit` | REQ-001, REQ-002 |
| `src/commands/recent.py` | New command | REQ-001–REQ-003 |
| `tests/test_recent.py` | New tests | AT1, AT2, AT-ERR-1 |
| `src/store.py` | Do not change | `list()` already suffices |

## Interfaces and data

```text
notes recent [--limit N]    # N: positive integer, default 5
recent(store: NoteStore, limit: int = 5) -> list[Note]
```

No data-model change.

## External dependencies and freshness

None.

## Security and permissions

None.

## Test design

Unit tests on `recent()` for AT1, AT2, EDGE-001 and EDGE-002; a parser test for AT-ERR-1.

## Documentation targets

`README.md` — the `notes` command table.

## Risks and rollback

- Sorting in the command keeps the store API untouched; fine up to NFR-001's 10k notes.
- Rejected: a `recent()` store method — premature for one caller (decision candidate).
- Rollback: remove the registration in `src/cli.py`; the new module becomes unreachable.
