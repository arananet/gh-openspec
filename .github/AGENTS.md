# AI Agent Instructions — gh-openspec Extension

This repo IS the `gh openspec` CLI extension and uses OpenSpec on itself.

## Core Rule

Every new subcommand or significant feature requires a spec in `.openspec/specs/`
before implementation code is written.

## Quick Commands

```bash
# Check current spec state
gh openspec check

# Scaffold a spec for a new feature
gh openspec scaffold "<feature-name>"

# Test the extension locally
gh extension install .
gh openspec --help
```

## Repo Layout

- `gh-openspec` — entry point (keep executable)
- `lib/` — subcommand implementations
- `template/` — files stamped into user repos (changes here affect all future `gh openspec create` calls)
- `.openspec/specs/` — specs for this extension's own features

## Before Writing Code

1. Check `.openspec/specs/` for an existing spec for the feature
2. If none exists, create one: `gh openspec scaffold "<feature-name>"`
3. Do not write production code until `acceptance_criteria` is filled in
