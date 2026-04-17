# AI Agent Instructions — {{PROJECT_NAME}}

This project uses **OpenSpec** for spec-driven development.
Every feature must have a spec file before code is written.

## Core Rule

No production code without a spec. Check `.openspec/specs/` before implementing anything.

## Quick Commands

```bash
# Check if a spec exists
ls .openspec/specs/

# Create a spec for a new feature
gh openspec scaffold "<feature-name>"

# Create a bugfix spec
gh openspec scaffold "<bug-description>" --type bugfix

# Validate all specs
gh openspec check

# Check spec coverage for a PR
gh openspec check --pr <number>
```

## Spec File Location

`.openspec/specs/<slug>.spec.yaml`

## Onboarding

If `.openspec/config.yaml` contains `{{` placeholder tokens, the project has
not been configured yet. Read `CLAUDE.md` for the guided setup flow.

## Coding Standards

Apply these during implementation (once a spec is approved).

**Think before coding** — state assumptions explicitly. If something is unclear, ask. Don't pick between interpretations silently.

**Simplicity first** — write the minimum code that satisfies `acceptance_criteria`. No features, abstractions, or error handling beyond what the spec defines.

**Surgical changes** — touch only what the spec requires. Don't refactor adjacent code, match existing style, and remove only the dead code your own changes created.

**Goal-driven execution** — treat each `acceptance_criteria` item as a verifiable success criterion. Don't mark work done until every criterion is met.

---

## Config

`.openspec/config.yaml` — controls enforcement levels, required spec fields,
CI behavior, and git hook settings.
