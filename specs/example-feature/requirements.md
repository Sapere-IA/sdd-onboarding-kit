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

## Requirements

REQ-001: When the user runs `notes recent`, the system shall print at most five notes, newest first.
REQ-002: When the user passes `--limit N` with N > 0, the system shall print at most N notes.
REQ-003: If the user passes an invalid limit, the system shall print a validation error and exit non-zero.
NFR-001: The command shall complete in under 200 ms for stores of up to 10,000 notes.

## Edge cases and errors

EDGE-001: An empty store prints "You do not have any notes yet." and exits 0.
EDGE-002: A store with fewer notes than the limit prints all of them.
ERR-001: A limit of 0, a negative number or a non-number prints `Invalid --limit: expected a positive integer.`

## Acceptance criteria

AC-001: With 6 notes, `notes recent` prints exactly 5, newest first (REQ-001).
AC-002: With 6 notes, `notes recent --limit 2` prints exactly 2 (REQ-002).
AC-003: `notes recent --limit abc` exits non-zero with the ERR-001 message (REQ-003).
