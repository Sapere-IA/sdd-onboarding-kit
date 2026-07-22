---
doc: acceptance-tests
title: Acceptance tests — Recent notes command
task_id: TASK-001
feature_slug: example-feature
source_document: functional-brief (example)
created: 2026-07-22
---

## Test strategy

- Testing style: `pytest, unit-level, one behavior per test`
- Test command: `pytest tests/test_recent.py`
- Test locations: `tests/test_recent.py`

## Coverage matrix

| Requirement | Acceptance test(s) | Covered |
| --- | --- | --- |
| REQ-001 | AT1 | !blocking No |
| REQ-002 | AT2 | !blocking No |
| REQ-003 | AT-ERR-1 | !blocking No |

## Acceptance tests

::: card
#### AT1 — Default limit shows five newest notes [!draft Draft]

- **Requirements:** REQ-001
- **Scenario:** User with 6 notes runs `notes recent`
- **Preconditions:** Store contains 6 notes with distinct `updated_at`
- **Action:** Run `notes recent`
- **Expected result:** Exactly 5 notes printed, newest first
- **Negative expectations:** The oldest note is not printed
- **Test location:** `tests/test_recent.py`
:::

::: card
#### AT2 — Explicit limit is respected [!draft Draft]

- **Requirements:** REQ-002
- **Scenario:** User with 6 notes runs `notes recent --limit 2`
- **Preconditions:** Store contains 6 notes
- **Action:** Run `notes recent --limit 2`
- **Expected result:** Exactly 2 notes printed, newest first
- **Negative expectations:** No more than 2 notes appear
- **Test location:** `tests/test_recent.py`
:::

::: card
#### AT-ERR-1 — Invalid limit is rejected [!draft Draft]

- **Requirements:** REQ-003
- **Scenario:** User passes a non-numeric limit
- **Preconditions:** Any store state
- **Action:** Run `notes recent --limit abc`
- **Expected result:** Exit code non-zero and the ERR-001 message on stderr
- **Negative expectations:** No notes are printed
- **Test location:** `tests/test_recent.py`
:::

::: card
#### AT-EDGE-1 — Empty store shows the empty-state message [!draft Draft]

- **Requirements:** EDGE-001
- **Scenario:** User with no notes runs `notes recent`
- **Preconditions:** Empty store
- **Action:** Run `notes recent`
- **Expected result:** Prints "You do not have any notes yet." and exits 0
- **Negative expectations:** No error output
- **Test location:** `tests/test_recent.py`
:::

## Manual acceptance checklist

- [ ] Every requirement has at least one acceptance test.
- [ ] Main success path, empty state and invalid input are covered, where relevant.
- [ ] Permission / security behavior is covered, if relevant.
- [ ] Non-goals are protected, if relevant.
- [ ] Tests are feasible with the current project test setup.
- [ ] No acceptance test depends on hidden assumptions.
