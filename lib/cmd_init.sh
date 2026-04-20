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
  # Don't clobber existing root-level files (README, LICENSE, etc.) in an
  # existing repo unless --force was passed. Directory contents are still
  # merged so new workflows / hooks / specs always land.
  local cp_flag="-n"
  $force && cp_flag="-f"
  find "$template_dir" -mindepth 1 -maxdepth 1 -print0 | while IFS= read -r -d '' entry; do
    cp -r $cp_flag "$entry" "./"
  done

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
  echo "   .openspec/defaults.yaml     ← pre-filled DevOps defaults"
  echo "   .openspec/templates/        ← feature & bugfix spec templates"
  echo "   .openspec/specs/            ← example spec + your future specs"
  echo "   .claude/                    ← Claude Code slash commands & hooks"
  echo "   .github/workflows/          ← spec-check, AI review, CodeQL, secret-scan, SBOM, labeler, stale, release-drafter"
  echo "   .github/ISSUE_TEMPLATE/     ← bug / feature / spec question forms"
  echo "   .github/CODEOWNERS, dependabot.yml, pull_request_template.md"
  echo "   hooks/                      ← git hooks (installed into .git/hooks/)"
  echo "   CLAUDE.md, README.md, CONTRIBUTING.md, CHANGELOG.md"
  echo "   CODE_OF_CONDUCT.md, SECURITY.md, SUPPORT.md, LICENSE"
  echo "   .editorconfig, .gitattributes, .gitignore, .yamllint, .pre-commit-config.yaml"
  echo "   docs/BRANCH_PROTECTION.md"
  echo ""
  info "Next steps:"
  echo "   1. Open this project in Claude Code — it will guide you through config"
  echo "   2. Or edit .openspec/config.yaml manually"
  echo "   3. Run: gh openspec scaffold 'your first feature'"
  echo "   4. Run: gh openspec check"
}
