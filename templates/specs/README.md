# Spec folder format

Each SDD feature spec is a folder of markdown documents (the source of truth):

- `requirements.md` — testable behavioral requirements.
- `design.md` — technical implementation plan.
- `tasks.md` — ordered implementation tasks.
- `assumptions.md` — explicit assumptions made during spec creation.
- `open-questions.md` — unresolved questions requiring developer input.
- `acceptance-tests.md` — acceptance-level test scenarios.
- `review.md` — written by the reviewer after implementation.

`sh scripts/render-spec.sh specs/<feature-slug>/` (or `scripts/render-spec.ps1` on Windows) renders them on demand into one interactive review page, `spec.html`, a gitignored artifact; review feedback saved from that page (`feedback.md`) is gitignored too. The rendering assets live in this directory:

- `spec-shell.html.template` — HTML page shell filled by the renderer.
- `spec.css` — stylesheet, inlined into the rendered page.
- `spec.js` — TOC and collapsible-section behavior, inlined into the rendered page.

Markdown conventions (frontmatter, requirement rows, status markers, cards): see `spec-format.md`.

If the spec was generated from a functional document, `assumptions.md`, `open-questions.md`, and `acceptance-tests.md` should be created even if some sections are empty.
