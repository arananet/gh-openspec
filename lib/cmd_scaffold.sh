#!/usr/bin/env bash
# gh openspec scaffold <feature-name> [flags]

cmd_scaffold() {
  local feature_name=""
  local spec_type="feature"
  local author=""
  local status="draft"
  local force=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --type)    spec_type="$2"; shift 2 ;;
      --author)  author="$2"; shift 2 ;;
      --status)  status="$2"; shift 2 ;;
      --force)   force=true; shift ;;
      -*)        error "Unknown flag: $1"; exit 1 ;;
      *)
        if [ -z "$feature_name" ]; then
          feature_name="$1"
        else
          error "Unexpected argument: $1"
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [ -z "$feature_name" ]; then
    error "Feature name is required."
    info  "Usage: gh openspec scaffold <feature-name> [--type feature|bugfix]"
    exit 1
  fi

  require_git_repo
  require_openspec

  # Validate type
  if [[ "$spec_type" != "feature" && "$spec_type" != "bugfix" ]]; then
    error "Invalid spec type: $spec_type (must be 'feature' or 'bugfix')"
    exit 1
  fi

  # Validate status
  if [[ "$status" != "draft" && "$status" != "review" && "$status" != "approved" ]]; then
    error "Invalid status: $status (must be 'draft', 'review', or 'approved')"
    exit 1
  fi

  # Resolve author
  if [ -z "$author" ]; then
    author=$(git config user.name 2>/dev/null || get_gh_username || echo "unknown")
  fi

  # Slugify feature name: lowercase, spaces→hyphens, strip non-alphanumeric
  local slug
  slug=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | sed 's/[[:space:]]/-/g; s/[^a-z0-9-]//g; s/--*/-/g; s/^-//; s/-$//')

  if [ -z "$slug" ]; then
    error "Could not generate a valid slug from: '$feature_name'"
    info  "Use a name with letters, numbers, and spaces."
    exit 1
  fi

  local spec_file=".openspec/specs/${slug}.spec.yaml"

  if [ -f "$spec_file" ] && ! $force; then
    error "Spec file already exists: $spec_file"
    info  "Use --force to overwrite."
    exit 1
  fi

  local template_file=".openspec/templates/${spec_type}.spec.yaml"
  if [ ! -f "$template_file" ]; then
    error "Template not found: $template_file"
    info  "Run 'gh openspec init' to restore missing templates."
    exit 1
  fi

  local date_str
  date_str=$(date +%Y-%m-%d)

  cp "$template_file" "$spec_file"

  # Apply substitutions
  template_substitute "$spec_file" "FEATURE_NAME" "$feature_name"
  template_substitute "$spec_file" "SLUG"         "$slug"
  template_substitute "$spec_file" "AUTHOR"       "$author"
  template_substitute "$spec_file" "DATE"         "$date_str"
  template_substitute "$spec_file" "STATUS"       "$status"

  echo ""
  success "Spec created: $spec_file"
  echo ""
  info "Fill in before committing:"
  echo "   description:          what this feature does and why"
  echo "   acceptance_criteria:  your definition of done (at least one)"
  echo "   test_plan:            how you'll verify each acceptance criterion"
  echo "   out_of_scope:         what this feature explicitly does NOT include"
  echo "   implementation_skill: frontend-pro | backend-pro | data-eng-pro | devops-pro | mobile-pro | null"
  echo ""
  info "When ready, update status to 'review' or 'approved', then commit:"
  echo "   git add $spec_file"
  echo "   git commit -m 'spec: scaffold ${slug}'"

  # Open in editor if available
  if [ -n "${EDITOR:-}" ]; then
    "$EDITOR" "$spec_file"
  fi
}
