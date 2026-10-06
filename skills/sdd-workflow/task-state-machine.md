# SDD task state machine

Default states:

```text
pending → spec_draft → spec_ready → human_approved → in_progress → review → done
```

Optional states:

```text
blocked
rejected
```

## State definitions

### `pending`

The task exists but no spec has been drafted.

Allowed next states:

- `spec_draft`
- `spec_ready`
- `blocked`

### `spec_draft`

The spec is being written or revised.

Allowed next states:

- `spec_ready`
- `blocked`

### `spec_ready`

The spec is complete and awaiting human approval.

Allowed next states:

- `human_approved`
- `spec_draft`
- `blocked`

Implementation is forbidden in this state.

### `human_approved`

The developer has approved the spec.

Allowed next states:

- `in_progress`
- `spec_draft`, if approval is withdrawn or spec changes are required.

### `in_progress`

Implementation is underway.

Allowed next states:

- `review`
- `blocked`
- `spec_draft`, if the spec is discovered to be wrong.

### `review`

Implementation is complete and under validation. The documentation phase also happens in this state: after approving the implementation, the reviewer decides whether documentation is required, the documenter updates the listed targets, and the reviewer re-checks them. The phase is tracked with task fields, not extra states:

```json
{
  "documentation_required": true,
  "documentation_status": "pending|updated|not_required",
  "documentation_targets": []
}
```

Allowed next states:

- `done`
- `in_progress`
- `spec_draft`
- `blocked`
- `rejected`

### `done`

The task is complete and should not be changed without reopening.

Allowed next states:

- none by default;
- `pending` or `spec_draft` only if the developer explicitly reopens it.

### `blocked`

The task cannot progress without external input.

Allowed next states:

- previous state after unblock;
- `spec_draft`;
- `pending`.

### `rejected`

The review found blocking defects.

Allowed next states:

- `in_progress`;
- `spec_draft`;
- `blocked`.

## Transition rules

- Never transition from `spec_ready` to `in_progress` directly if human approval is mandatory.
- Never transition to `done` without reviewer approval.
- Never transition to `done` while `documentation_required` is `true` and `documentation_status` is `pending`.
- Never transition to `done` with failing tests unless the developer explicitly accepts this exception.
- Record human approval metadata when moving to `human_approved`. A feedback file with `verdict: approve` and no `change`/`reject` items counts as approval (record its `generated` timestamp); if applying it changed the spec, ask again (`spec-format.md` § Feedback file).
- Record reviewer decision when moving to `done`, `rejected` or `in_progress` after review.
