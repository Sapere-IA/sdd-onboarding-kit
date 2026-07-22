# Useful prompts for using the SDD harness

## Install SDD in a project

```text
Read `sdd-onboarding-kit/instructions.md` and configure this repository to use Spec Driven Development. Ask me all necessary questions before making project-specific decisions.
```

## Start the next SDD task

```text
Use the SDD workflow. Review `tasks.json`, select the next pending task marked with `sdd: true`, generate the spec and stop for human approval.
```

## Create a new task

```text
Create a new SDD task for: <description>. First generate requirements/design/tasks and do not implement anything until I approve the spec.
```

## Approve a spec

```text
I have reviewed the spec for `<feature-slug>` and I approve it. Change the status to `human_approved` and prepare the implementation following `tasks.md`.
```

## Implement an approved spec

```text
Implement feature `<feature-slug>` following the approved spec strictly. Run tests and leave traceability of what you changed.
```

## Review an implementation

```text
Use the reviewer to validate the implementation of `<feature-slug>` against requirements.md, design.md and tasks.md. Run tests and tell me if it can be marked as done.
```

## Render a spec for reading

```text
Render the spec for `<feature-slug>` to HTML so I can review it in the browser.
```

## Update the SDD harness

```text
Run /sdd-update to bring this project's SDD harness up to date with the latest kit version. Show me what changed before applying anything.
```
