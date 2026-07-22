# Spec Driven Development: operational theory

Spec Driven Development (SDD) is a workflow in which the specification sits at the center of the development process.

The practical thesis is simple: before asking an AI to write code, you must define precisely enough what it should build, how the system should behave, and how the result will be validated.

## What a spec is

A spec is an explicit representation of the software to be implemented. It may contain:

- functional requirements;
- non-functional requirements;
- user stories;
- acceptance criteria;
- error scenarios;
- technical design;
- file changes;
- implementable tasks;
- testing strategy;
- architecture constraints.

In this kit, a feature spec is split by default into four documents:

```text
specs/<feature-slug>/
├── requirements.md
├── design.md
├── tasks.md
└── review.md
```

## The spec as source of truth

In SDD, the AI does not implement directly from a vague conversation. It implements against concrete documents.

This reduces three common problems of AI-assisted development:

1. context loss in long conversations;
2. ambiguity in natural-language instructions;
3. difficulty verifying that the generated code actually matches what was requested.

## General flow

The base flow is:

```text
specify → approve → implement → validate → close or iterate
```

Translated into work states:

```text
pending → spec_draft → spec_ready → human_approved → in_progress → review → done
```

## The human's role

This kit is not designed to remove the developer from the process. It is designed so the developer keeps control over:

- product intent;
- architecture;
- acceptance criteria;
- test validation;
- security decisions;
- the final decision to mark a task as complete.

The AI accelerates the process, but technical judgment remains the team's responsibility.

## Relationship with TDD

SDD does not necessarily replace TDD. It can include TDD.

A well-written spec should make test generation easy. If a notation such as EARS or Given/When/Then is used, each requirement can be turned into one or more tests.

## When to use SDD

Use SDD for:

- multi-step features;
- changes that affect architecture;
- changes with API impact;
- significant business logic;
- changes where traceability is valuable;
- tasks that require new or modified tests.

SDD is not always needed for:

- typos;
- trivial cosmetic changes;
- local renames;
- minor documentation;
- small obvious fixes.

The project must explicitly define which tasks may skip SDD.
