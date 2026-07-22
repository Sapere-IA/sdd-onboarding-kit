---
doc: assumptions
title: Assumptions — Recent notes command
task_id: TASK-001
feature_slug: example-feature
source_document: functional-brief (example)
created: 2026-07-22
---

## Summary

- Risk counts: low 1 · medium 0 · high 0
- Blocking assumptions present: no

## Pending

::: card risk-low
#### A1 — Recency means last update [!pending Pending]

- **Assumption:** "Most recent" orders by `updated_at`, not `created_at`.
- **Reason:** The brief says "latest notes" without defining recency; the existing list view sorts by `updated_at`.
- **Risk / impact if wrong:** Low — ordering differs for edited notes only.
- **Blocks implementation:** No
- **Related requirements:** REQ-001
:::

## Accepted

None yet.

## Rejected or replaced

None yet.
