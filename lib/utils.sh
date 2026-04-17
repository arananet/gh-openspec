#!/usr/bin/env bash
# Shared utilities for gh-openspec

# ── Color output ─────────────────────────────────────────────────────────────

_color() {
  if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
    printf "%b%s%b\n" "$1" "$2" "\033[0m"
  else
    echo "$2"
  fi
}

info()    { _color "\033[0;34m" "  $*"; }
success() { _color "\033[0;32m" "✓ $*"; }
warn()    { _color "\033[0;33m" "⚠ $*" >&2; }
error()   { _color "\033[0;31m" "✗ $*" >&2; }
step()    { _color "\033[0;36m" "→ $*"; }

# ── Prerequisite checks ───────────────────────────────────────────────────────

require_gh_auth() {
  if ! gh auth status &>/dev/null; then
    error "Not authenticated with GitHub. Run: gh auth login"
    exit 1
  fi
}

require_git_repo() {
  if ! git rev-parse --git-dir &>/dev/null; then
    error "Not inside a git repository."
    exit 1
  fi
}

require_openspec() {
  if [ ! -f ".openspec/config.yaml" ]; then
    error "OpenSpec not initialized in this directory."
    info  "Run: gh openspec init"
    exit 1
  fi
}

# ── GitHub helpers ────────────────────────────────────────────────────────────

get_gh_username() {
  gh api user --jq '.login' 2>/dev/null || echo ""
}

get_git_repo_name() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  if [ -n "$remote_url" ]; then
    basename "$remote_url" .git
  else
    basename "$(pwd)"
  fi
}

get_git_repo_owner() {
  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  if [ -n "$remote_url" ]; then
    # handles both https://github.com/owner/repo.git and git@github.com:owner/repo.git
    echo "$remote_url" | sed -E 's|.*[:/]([^/]+)/[^/]+\.git.*|\1|; s|.*[:/]([^/]+)/[^/]+$|\1|'
  else
    get_gh_username
  fi
}

# ── Template substitution ─────────────────────────────────────────────────────

# Replace {{KEY}} with value in a file, in-place (macOS + Linux compatible)
template_substitute() {
  local file="$1"
  local key="$2"
  local value="$3"
  # Escape only chars special in a sed replacement string: \, &, and the | delimiter
  local escaped_value
  escaped_value=$(printf '%s\n' "$value" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g' -e 's/|/\\|/g')
  local tmp
  tmp=$(mktemp)
  sed "s|{{${key}}}|${escaped_value}|g" "$file" > "$tmp" && mv "$tmp" "$file"
}

# Apply all standard substitutions to a file
apply_template_substitutions() {
  local file="$1"
  local project_name="$2"
  local github_owner="$3"
  local date_str="$4"

  template_substitute "$file" "PROJECT_NAME"   "$project_name"
  template_substitute "$file" "GITHUB_OWNER"   "$github_owner"
  template_substitute "$file" "DATE"           "$date_str"
}

# Recursively substitute all {{PLACEHOLDER}} tokens in a directory
substitute_dir() {
  local dir="$1"
  local project_name="$2"
  local github_owner="$3"
  local date_str="$4"

  while IFS= read -r -d '' file; do
    if file "$file" | grep -q text; then
      apply_template_substitutions "$file" "$project_name" "$github_owner" "$date_str"
    fi
  done < <(find "$dir" -type f -print0)
}

# ── YAML helpers (no parser required) ────────────────────────────────────────

# Read a scalar value from a simple YAML file by top-level key
yaml_get() {
  local file="$1"
  local key="$2"
  grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed "s/^${key}:[[:space:]]*//" | tr -d '"'
}

# Check if config.yaml still has unsubstituted placeholder tokens
config_has_placeholders() {
  local config="${1:-.openspec/config.yaml}"
  grep -q '{{' "$config" 2>/dev/null
}

# ── Help ──────────────────────────────────────────────────────────────────────

print_help() {
  cat <<'EOF'
gh openspec — spec-driven development enforcement from day 0

USAGE
  gh openspec <subcommand> [flags]

SUBCOMMANDS
  create <repo-name>        Create a new GitHub repo with OpenSpec baked in
  init                      Add OpenSpec to an existing repo
  scaffold <feature-name>   Create a new spec file for a feature
  check                     Validate spec coverage in the current repo
  version                   Show version
  help                      Show this help

QUICK START
  gh openspec create my-project
  cd my-project && bash setup.sh
  # Open in Claude Code — it will guide you through config

COMMON FLAGS
  create:
    --public              Make the repo public (default: private)
    --description <text>  Set repo description
    --no-clone            Create without cloning locally

  init:
    --force               Overwrite existing .openspec/ directory
    --skip-hooks          Skip running setup.sh automatically

  scaffold:
    --type feature|bugfix  Spec type (default: feature)
    --author <name>        Override author name
    --status <status>      Initial status (default: draft)

  check:
    --strict              Treat warnings as errors
    --pr <number>         Check files changed in a specific PR

LEARN MORE
  https://github.com/arananet/gh-openspec
EOF
}
