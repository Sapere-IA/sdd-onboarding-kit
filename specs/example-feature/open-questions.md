---
doc: open-questions
title: Open questions — Recent notes command
task_id: TASK-001
feature_slug: example-feature
source_document: functional-brief (example)
created: 2026-07-22
---

## Summary

- Blocking: 0 · Non-blocking: 1 · Resolved: 0

## Open

::: card
#### Q1 — Should archived notes appear? [!warning Non-blocking]

- **Question:** Does `notes recent` include archived notes?
- **Why it matters:** Changes the filter applied before sorting.
- **Default if unanswered:** Exclude archived notes, matching the default list view.
- **Affected files / sections:** `src/commands/recent.py`; requirements REQ-001
- **Related requirements:** REQ-001
:::

## Resolved

None yet.

## Deferred

None yet.
