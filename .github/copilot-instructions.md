# Copilot Instructions — gh-openspec Extension

This repo implements the `gh openspec` CLI extension using shell scripts.
It also uses OpenSpec on itself — check `.openspec/specs/` before suggesting
code for any new feature.

## Key Files

- `gh-openspec` — entry point, subcommand dispatch
- `lib/utils.sh` — shared helpers (colors, auth, template substitution)
- `lib/cmd_*.sh` — one file per subcommand
- `template/` — files copied into new repos by `gh openspec create/init`
- `.openspec/specs/` — specs for this extension's features

## Before Suggesting New Code

1. Check `.openspec/specs/` for an existing spec
2. If none: suggest `gh openspec scaffold "<feature-name>"`
3. Reference `acceptance_criteria` as the definition of done
