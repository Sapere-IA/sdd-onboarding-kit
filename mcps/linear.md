# Linear MCP notes

Use Linear when the team already manages product work in Linear.

## Recommended SDD mapping

| SDD concept | Linear concept |
|---|---|
| Task | Linear issue |
| Status | Workflow status |
| Spec | Local files linked from issue, or issue description/comments |
| Review | Issue comment or linked PR |
| Done | Linear done status |

## Questions before configuring

1. Which Linear team/project should be used?
2. Which Linear statuses map to SDD statuses?
3. Should the agent create Linear issues from local tasks?
4. Should the agent update Linear automatically when local status changes?
5. Should specs remain in git even when tasks live in Linear?

## Safe default

Keep specs in git under `specs/`. Use Linear for task visibility only after explicit approval.
