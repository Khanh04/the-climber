# Documentation

Documentation should keep product decisions, engineering constraints, and implementation behavior aligned.

## Design Docs

The current design modules live in `docs/` and use this structure:

- MVP Scope
- Core Requirements
- Implementation Notes
- Post-MVP
- Open Questions
- Risks
- Suggested First Tasks

When behavior changes, update the affected design module in the same change.

## Engineering Docs

- `ARCHITECTURE.md`: structure, dependency direction, scene boundaries, and platform seams.
- `CODING_STANDARDS.md`: typed GDScript, no fallback, and SOLID-oriented rules.
- `TESTING.md`: test layout, commands, and coverage rules.
- `DOCUMENTATION.md`: documentation workflow.

## ADRs

Use ADRs for decisions that affect architecture, tooling, platform SDKs, monetization policy, or MVP scope.

ADR files live in `docs/adr/` and should use this naming pattern:

```text
0001-short-title.md
```

## Traceability

Every implemented MVP feature should trace back to one of the design docs or an ADR. If implementation differs from the docs, update the docs before treating the work as complete.