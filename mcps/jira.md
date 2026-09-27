# Jira MCP notes

Use Jira when the organization manages work through Jira tickets.

## Recommended SDD mapping

| SDD concept | Jira concept |
|---|---|
| Task | Jira issue |
| Status | Jira workflow status |
| Spec | Local files, ticket description, or linked docs |
| Approval | Jira status or approval comment |
| Done | Jira done/resolved status |

## Questions before configuring

1. Which Jira project should be used?
2. Which Jira issue types map to SDD tasks?
3. Which statuses map to `pending`, `spec_ready`, `human_approved`, `in_progress`, `review`, `done`?
4. Should the agent write comments to Jira?
5. Should the agent update Jira status automatically?

## Safe default

Use Jira as a read source first. Avoid automatic writes until the mapping is confirmed.
