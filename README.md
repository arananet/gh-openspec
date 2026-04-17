# gh-openspec

> Spec-driven development enforcement, baked in from day 0.

A `gh` CLI extension that creates new GitHub repositories pre-wired with
OpenSpec — a lightweight spec-driven workflow that ensures every feature has
a written specification before code is committed.

Works natively with Claude Code, GitHub Copilot, and Cursor via built-in AI
agent instructions.

---

## Two ways to use it

### Option A — GitHub UI (no CLI needed)

> **Important:** For GitHub UI use, mark the **`openspec-template`** repo as the
> template — not this one. This repo contains the extension source code.
> `openspec-template` contains only the clean project files (the contents of
> `template/` here) and is what developers should click "Use this template" on.

1. Go to `arananet/openspec-template` on GitHub and click **"Use this template" → "Create a new repository"**
2. Fill in your repo name and click Create
3. GitHub copies all files into your new repo — `.openspec/`, `CLAUDE.md`, CI workflows, hooks — all with blank config and OpenSpec instructions ready to follow
4. On the first push, `spec-bootstrap.yml` fires and creates a **"Complete OpenSpec configuration"** issue in your repo linking to `CLAUDE.md`
5. Open the project in Claude Code or a Codespace — onboarding runs automatically

> **Codespaces**: `.devcontainer/devcontainer.json` runs `bash setup.sh` on container creation, so git hooks are installed before you write a single line of code.

**What the new repo contains — no past config, only instructions:**

```
.openspec/
  config.yaml       ← blank fields waiting to be filled (triggers AI wizard)
  onboarding.yaml   ← the questions Claude Code will ask you
  specs/            ← empty, ready for your first spec
  templates/        ← feature and bugfix spec templates
CLAUDE.md           ← AI wizard: interviews you, writes config, scaffolds first spec
.github/
  AGENTS.md         ← instructions for all AI agents
  copilot-instructions.md
  workflows/
    spec-check.yml      ← blocks PRs with no spec changes
    spec-bootstrap.yml  ← creates setup issue on first push
hooks/ + setup.sh   ← git hooks (installed via devcontainer or bash setup.sh)
```

### Option B — CLI

```bash
gh extension install arananet/gh-openspec
gh openspec create my-project
cd my-project && bash setup.sh
```

---

## Quick Start (CLI)

```bash
# Create a new repo with OpenSpec baked in
gh openspec create my-project

# Change into the repo and install git hooks
cd my-project
bash setup.sh

# Open in Claude Code — it auto-detects unconfigured repos
# and interviews you to fill in .openspec/config.yaml
code .
```

Claude Code reads `CLAUDE.md`, detects the placeholder config,
and walks you through setup questions before letting you write any code.

---

## Commands

### `gh openspec create <repo-name>`

Creates a new GitHub repo and stamps it with the full OpenSpec template.

```bash
gh openspec create my-api
gh openspec create my-api --public
gh openspec create my-api --description "Payments service"
gh openspec create my-api --no-clone
```

After creation: `cd my-api && bash setup.sh`, then open in Claude Code.

---

### `gh openspec init`

Adds OpenSpec to an **existing** repo (run from inside it).

```bash
gh openspec init
gh openspec init --force
gh openspec init --skip-hooks
```

---

### `gh openspec scaffold <feature-name>`

Creates a new spec file at `.openspec/specs/<slug>.spec.yaml`.

```bash
gh openspec scaffold "user authentication"
gh openspec scaffold "fix login crash" --type bugfix
gh openspec scaffold "user auth" --author alice --status review
```

---

### `gh openspec check`

Validates spec coverage and quality. Used locally and in CI.

```bash
gh openspec check
gh openspec check --strict
gh openspec check --pr 42
gh openspec check --commit abc123
```

Exit code `0` = pass, `1` = failure.

---

## How It Works

```
gh openspec create my-repo
        │
        ├── Creates GitHub repo
        ├── Copies template/ into the clone
        ├── Substitutes {{PROJECT_NAME}}, {{GITHUB_OWNER}}, {{DATE}}
        └── Commits + pushes "chore: bootstrap OpenSpec enforcement"

Open in Claude Code
        │
        ├── Claude Code reads CLAUDE.md (automatically)
        ├── Detects {{PLACEHOLDER}} tokens → enters onboarding mode
        ├── Reads .openspec/onboarding.yaml (question schema)
        ├── Asks setup questions (team, domain, description, etc.)
        ├── Writes answers into .openspec/config.yaml
        └── Optionally: gh openspec scaffold "<first feature>"

Every commit
        │
        └── pre-commit hook: blocks if source files changed but no spec staged

Every PR
        │
        └── spec-check.yml: fails if source files changed but no spec changed
```

---

## AI Agent Integration

Three files are added to every repo for AI tool integration:

| File | Read by |
|------|---------|
| `CLAUDE.md` | Claude Code (auto-loaded on project open) |
| `.github/AGENTS.md` | Claude Code fallback, Cursor, Copilot Workspace |
| `.github/copilot-instructions.md` | GitHub Copilot (auto-loaded) |

### The Onboarding Wizard

`CLAUDE.md` contains a status check that Claude Code runs automatically:

```bash
grep -c '{{' .openspec/config.yaml && echo "NOT_CONFIGURED" || echo "CONFIGURED"
```

If `NOT_CONFIGURED`, Claude Code reads `.openspec/onboarding.yaml` and
interviews the user through each setup question before allowing any code work.

---

## What Gets Added to New Repos

```
.openspec/
  config.yaml          ← project settings (filled in via AI wizard)
  onboarding.yaml      ← question schema for AI agents
  specs/               ← feature specs live here
  templates/
    feature.spec.yaml  ← template for new features
    bugfix.spec.yaml   ← template for bugfixes
.github/
  AGENTS.md
  copilot-instructions.md
  workflows/
    spec-check.yml     ← PR gate (blocks PRs without spec changes)
    spec-bootstrap.yml ← creates a setup issue on first push
hooks/
  pre-commit           ← blocks commits without spec changes
  commit-msg           ← optional: enforce spec reference in messages
setup.sh               ← installs hooks into .git/hooks/
CLAUDE.md              ← AI onboarding wizard + working instructions
```

---

## Configuration Reference

`.openspec/config.yaml`:

```yaml
project:
  name: "my-project"
  owner: "my-org"
  team: "platform"
  domain: "payments"
  description: "One sentence description"

spec:
  required_fields: [title, description, acceptance_criteria, status]
  enforce_on_pr: true
  enforce_on_commit: true

ci:
  fail_on_missing_spec: true

hooks:
  pre_commit:
    block_if_no_spec: true
  commit_msg:
    require_spec_reference: false
```

---

## Feature Spec Format

```yaml
title: "User Authentication"
slug: "user-authentication"
type: feature
status: draft

author: "alice"
created_at: "2026-04-15"

description: |
  Allow users to sign in with email/password.

acceptance_criteria:
  - "Given a valid email and password, when POST /auth/login, then returns 200 with a JWT."
  - "Given an invalid password, when POST /auth/login, then returns 401."

out_of_scope:
  - "OAuth / social login (separate spec)"

linked_issues: []
```

---

## Self-Governance

This repo uses OpenSpec on itself. Every subcommand has a spec in
`.openspec/specs/`. PRs to this repo follow the same enforcement rules.

---

## Contributing

1. Check `.openspec/specs/` for the relevant spec
2. `gh openspec scaffold "<feature>"` if no spec exists
3. Fill in `acceptance_criteria` before writing code
4. Include the spec in your PR

## License

MIT © Arananet

---

## Author

Built by **Eduardo Arana** — this project is developed using OpenSpec,
meaning every feature in this extension was written spec-first: acceptance
criteria defined before a single line of implementation code.
