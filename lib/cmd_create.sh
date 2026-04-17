#!/usr/bin/env bash
# gh openspec create <repo-name> [flags]

cmd_create() {
  local repo_name=""
  local visibility="--private"
  local description=""
  local do_clone=true

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --public)        visibility="--public"; shift ;;
      --private)       visibility="--private"; shift ;;
      --description)   description="$2"; shift 2 ;;
      --no-clone)      do_clone=false; shift ;;
      -*)              error "Unknown flag: $1"; exit 1 ;;
      *)
        if [ -z "$repo_name" ]; then
          repo_name="$1"
        else
          error "Unexpected argument: $1"
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$repo_name" ]; then
    error "Repository name is required."
    info  "Usage: gh openspec create <repo-name> [--public] [--description <text>]"
    exit 1
  fi

  # Validate repo name
  if ! echo "$repo_name" | grep -qE '^[a-zA-Z0-9_.-]+$'; then
    error "Invalid repository name: '$repo_name'"
    info  "Use only letters, numbers, hyphens, underscores, and dots."
    exit 1
  fi

  require_gh_auth

  local owner
  owner=$(get_gh_username)
  if [ -z "$owner" ]; then
    error "Could not determine GitHub username. Are you authenticated?"
    exit 1
  fi

  local full_name="${owner}/${repo_name}"
  local date_str
  date_str=$(date +%Y-%m-%d)

  step "Creating repository $full_name..."

  # Build gh repo create command — use the openspec-template repo for reliable bootstrap
  local create_args=("$full_name" "$visibility" "--template" "arananet/openspec-template")
  [ -n "$description" ] && create_args+=(--description "$description")
  if $do_clone; then
    create_args+=(--clone)
  fi

  if ! gh repo create "${create_args[@]}"; then
    error "Failed to create repository."
    exit 1
  fi

  if $do_clone; then
    if [ ! -d "$repo_name" ]; then
      error "Repository was created but the local clone directory '$repo_name' was not found."
      exit 1
    fi

    step "Applying project substitutions..."
    substitute_dir "$repo_name" "$repo_name" "$owner" "$date_str"

    step "Committing OpenSpec configuration..."
    (
      cd "$repo_name"
      git add -A
      git diff --cached --quiet || git commit -m "chore: apply project-specific OpenSpec configuration

- Substitute {{PROJECT_NAME}}, {{GITHUB_OWNER}}, and {{DATE}} tokens
- Repository: $full_name"
      git push -u origin HEAD
    )

    echo ""
    success "Repository $full_name is ready with OpenSpec enforcement."
    echo ""
    info "Next steps:"
    echo "   cd $repo_name"
    echo "   bash setup.sh              # install git hooks"
    echo ""
    info "Then open the project in Claude Code:"
    echo "   Claude Code will read CLAUDE.md and guide you through"
    echo "   filling in .openspec/config.yaml and creating your first spec."
    echo ""
    info "Or configure manually:"
    echo "   edit .openspec/config.yaml"
    echo "   gh openspec scaffold 'my first feature'"
  else
    echo ""
    success "Repository $full_name created from OpenSpec template."
    info "Clone it, then open in Claude Code — CLAUDE.md will guide you through config."
  fi
}
