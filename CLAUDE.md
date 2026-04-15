# Claude Code Instructions — gh-openspec Extension

## Project Overview

This repo IS the `gh openspec` CLI extension. It is also the template source:
the `template/` directory contains everything stamped into new repos when
developers run `gh openspec create` or `gh openspec init`.

## Repo Structure

```
gh-openspec          ← extension entry point (must stay executable)
lib/                 ← subcommand implementations
  utils.sh           ← shared helpers
  cmd_create.sh      ← gh openspec create
  cmd_init.sh        ← gh openspec init
  cmd_scaffold.sh    ← gh openspec scaffold
  cmd_check.sh       ← gh openspec check
template/            ← what gets copied into user repos
  .openspec/         ← config template with {{PLACEHOLDER}} tokens
  .github/           ← CI workflows, AI agent instructions
  hooks/             ← git hooks
  setup.sh           ← hook installer
  CLAUDE.md          ← AI onboarding wizard for user repos
.openspec/           ← specs for THIS extension's own features
.github/             ← CI for THIS repo
hooks/               ← hooks for THIS repo
setup.sh             ← install hooks for THIS repo
```

## Key Constraint: This Repo Uses OpenSpec on Itself

Before adding a new subcommand or significant feature:
1. Check `.openspec/specs/` for an existing spec
2. If none exists: `gh openspec scaffold "<feature-name>"` (dogfood it)
3. Get the spec to `review` status before writing implementation code

## Testing the Extension Locally

```bash
# Install from local path
gh extension install .

# Test all subcommands
gh openspec --help
gh openspec version
gh openspec check
gh openspec scaffold "test feature"

# Full end-to-end (creates a real repo)
gh openspec create test-repo-$(date +%s) --public
```

## Making Changes

- **Subcommand changes**: edit `lib/cmd_<name>.sh`
- **Template changes**: edit files under `template/`
- **Self-governance specs**: edit `.openspec/specs/`
- Always update the corresponding spec in `.openspec/specs/` in the same commit as implementation changes

## CI

`.github/workflows/spec-check.yml` validates that PRs to THIS repo also follow OpenSpec.
Every PR that touches `lib/` or `gh-openspec` must include a spec change in `.openspec/specs/`.

## OpenSpec Status

This repo is fully configured — `.openspec/config.yaml` has no placeholder tokens.
Run `gh openspec check` at any time to validate.
