#!/usr/bin/env bash
# gh openspec init [flags]

cmd_init() {
  local force=false
  local skip_hooks=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)       force=true; shift ;;
      --skip-hooks)  skip_hooks=true; shift ;;
      -*)            error "Unknown flag: $1"; exit 1 ;;
      *)             error "Unexpected argument: $1"; exit 1 ;;
    esac
  done

  require_gh_auth
  require_git_repo

  if [ -d ".openspec" ] && ! $force; then
    error ".openspec/ already exists in this directory."
    info  "Use --force to overwrite."
    exit 1
  fi

  local template_dir="$SCRIPT_DIR/template"
  if [ ! -d "$template_dir" ]; then
    error "Template directory not found at $template_dir"
    info  "Your gh-openspec installation may be corrupted. Try reinstalling."
    exit 1
  fi

  # Detect project metadata from git remote
  local repo_name
  repo_name=$(get_git_repo_name)
  local owner
  owner=$(get_git_repo_owner)
  local date_str
  date_str=$(date +%Y-%m-%d)

  step "Copying OpenSpec template into current repository..."
  cp -r "$template_dir/." "./"

  step "Applying project substitutions..."
  substitute_dir "." "$repo_name" "$owner" "$date_str"

  if ! $skip_hooks; then
    step "Installing git hooks..."
    bash setup.sh
  fi

  echo ""
  success "OpenSpec initialized in $(pwd)"
  echo ""
  info "Files added:"
  echo "   .openspec/config.yaml       ← configure your project settings"
  echo "   .openspec/templates/        ← spec templates"
  echo "   .github/workflows/          ← PR gate and bootstrap CI"
  echo "   hooks/                      ← git hooks (installed into .git/hooks/)"
  echo "   CLAUDE.md                   ← AI agent instructions + onboarding wizard"
  echo ""
  info "Next steps:"
  echo "   1. Open this project in Claude Code — it will guide you through config"
  echo "   2. Or edit .openspec/config.yaml manually"
  echo "   3. Run: gh openspec scaffold 'your first feature'"
  echo "   4. Run: gh openspec check"
}
