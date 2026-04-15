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

  # Build gh repo create command
  local create_args=("$full_name" "$visibility")
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

    step "Copying OpenSpec template..."
    local template_dir="$SCRIPT_DIR/template"
    if [ ! -d "$template_dir" ]; then
      error "Template directory not found at $template_dir"
      info  "Your gh-openspec installation may be corrupted. Try reinstalling."
      exit 1
    fi

    # Copy all template files (including dotfiles) into the cloned repo
    cp -r "$template_dir/." "$repo_name/"

    step "Applying project substitutions..."
    substitute_dir "$repo_name" "$repo_name" "$owner" "$date_str"

    step "Committing OpenSpec bootstrap..."
    (
      cd "$repo_name"
      git add -A
      git commit -m "chore: bootstrap OpenSpec enforcement

- Add .openspec/config.yaml with project configuration template
- Add .openspec/templates/ with feature and bugfix spec templates
- Add .github/workflows/ for PR spec gate and bootstrap notification
- Add hooks/ and setup.sh for local git hook installation
- Add CLAUDE.md for AI-guided onboarding wizard
- Add .github/AGENTS.md and copilot-instructions.md for AI agents"
      git push origin main
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
    success "Repository $full_name created (no local clone)."
    info "Clone it and run: gh openspec init"
  fi
}
