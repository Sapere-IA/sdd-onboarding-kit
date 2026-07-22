---
doc: requirements
title: Requirements — Recent notes command
task_id: TASK-001
feature_slug: example-feature
status: spec_draft
author: spec-author
human_approval: pending
---

## Summary

Add a `notes recent` CLI command that lists the user's most recent notes, newest first, with an optional `--limit` flag.

## Functional requirements

REQ-001: When the user runs `notes recent`, the system shall print at most five notes ordered by recency.
REQ-002: When the user passes `--limit N` with N greater than zero, the system shall print at most N notes.
REQ-003: If the user passes an invalid limit, the system shall return a clear validation error and exit with a non-zero code.

## Non-functional requirements

NFR-001: The command shall complete in under 200 ms for stores of up to 10,000 notes.

## Edge cases

EDGE-001: An empty note store prints "You do not have any notes yet." and exits 0.
EDGE-002: Fewer stored notes than the limit prints all of them without error.

## Error states

ERR-001: `--limit 0`, a negative number, or a non-numeric value prints `Invalid --limit: expected a positive integer.`

## Acceptance criteria

AC-001: With 6 stored notes, `notes recent` prints exactly 5, newest first.
AC-002: With 6 stored notes, `notes recent --limit 2` prints exactly 2.
AC-003: `notes recent --limit abc` exits non-zero with the ERR-001 message.

## UI acceptance criteria

Not applicable.

## Visual evidence

Not applicable.

## External dependencies

None.

## Documentation expectations

CLI reference in `README.md` (the `notes` command table).

## Decision candidates

None.

## Requirement-to-test mapping

| Requirement | Expected test(s) |
| --- | --- |
| REQ-001 | AT1 |
| REQ-002 | AT2 |
| REQ-003 | AT-ERR-1 |
