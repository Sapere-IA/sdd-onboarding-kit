---
doc: acceptance-tests
title: Acceptance tests — Recent notes command
task_id: TASK-001
feature_slug: example-feature
source_document: functional-brief (example)
created: 2026-07-22
---

## Summary

- Style: `pytest, one behavior per test` · Command: `pytest tests/test_recent.py` · Location: `tests/test_recent.py`

## Acceptance tests

::: card
#### AT1 — Default limit shows the five newest notes [!draft Draft]

- **Requirements:** REQ-001, AC-001
- **Given:** 6 notes with distinct `updated_at`
- **When:** `notes recent`
- **Then:** exactly 5 notes, newest first; the oldest is absent
:::

::: card
#### AT2 — Explicit limit is respected [!draft Draft]

- **Requirements:** REQ-002, AC-002
- **Given:** 6 notes
- **When:** `notes recent --limit 2`
- **Then:** exactly 2 notes, newest first
:::

::: card
#### AT-ERR-1 — Invalid limit is rejected [!draft Draft]

- **Requirements:** REQ-003, ERR-001, AC-003
- **Given:** any store
- **When:** `notes recent --limit abc`
- **Then:** non-zero exit, the ERR-001 message on stderr, no notes printed
:::

::: card
#### AT-EDGE-1 — Empty store shows the empty-state message [!draft Draft]

- **Requirements:** EDGE-001
- **Given:** an empty store
- **When:** `notes recent`
- **Then:** "You do not have any notes yet." and exit 0
:::

## Manual checks

- [ ] `notes --help` lists `recent` and its `--limit` option.
