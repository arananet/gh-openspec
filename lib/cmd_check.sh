#!/usr/bin/env bash
# gh openspec check [flags]

cmd_check() {
  local strict=false
  local pr_number=""
  local commit_sha=""
  local fail=0
  local warn_count=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --strict)   strict=true; shift ;;
      --pr)       pr_number="$2"; shift 2 ;;
      --commit)   commit_sha="$2"; shift 2 ;;
      -*)         error "Unknown flag: $1"; exit 1 ;;
      *)          error "Unexpected argument: $1"; exit 1 ;;
    esac
  done

  require_git_repo

  local config=".openspec/config.yaml"

  # ── Check 1: OpenSpec initialized ──────────────────────────────────────────
  if [ ! -f "$config" ]; then
    error "OpenSpec not initialized. Run: gh openspec init"
    exit 1
  fi
  success "OpenSpec initialized"

  # ── Check 2: No placeholder tokens in config ────────────────────────────────
  if config_has_placeholders "$config"; then
    warn "config.yaml still contains placeholder values ({{...}})"
    warn "Open in Claude Code or edit manually: .openspec/config.yaml"
    warn_count=$((warn_count + 1))
    if $strict; then
      fail=1
    fi
  else
    success "config.yaml has no placeholder tokens"
  fi

  # ── Check 3: Spec files valid ───────────────────────────────────────────────
  local spec_dir=".openspec/specs"
  local spec_files=()
  while IFS= read -r -d '' f; do
    spec_files+=("$f")
  done < <(find "$spec_dir" -name "*.spec.yaml" -not -name ".gitkeep" -print0 2>/dev/null)

  if [ ${#spec_files[@]} -eq 0 ]; then
    warn "No spec files found in $spec_dir"
    warn "Run: gh openspec scaffold '<feature-name>'"
    warn_count=$((warn_count + 1))
  else
    info "Validating ${#spec_files[@]} spec file(s)..."
    local required_fields=()
    while IFS= read -r f; do
      [ -n "$f" ] && required_fields+=("$f")
    done < <(yaml_get_list "$config" "spec.required_fields")
    if [ ${#required_fields[@]} -eq 0 ]; then
      required_fields=("title" "description" "acceptance_criteria" "status")
    fi

    for spec in "${spec_files[@]}"; do
      local spec_fail=0
      local spec_name
      spec_name=$(basename "$spec")

      for field in "${required_fields[@]}"; do
        if ! grep -q "^${field}:" "$spec" 2>/dev/null; then
          error "  $spec_name — missing required field: $field"
          spec_fail=1
          fail=1
        fi
      done

      # Check acceptance_criteria has at least one non-comment, non-empty item
      local ac_count
      ac_count=$(grep -A 20 '^acceptance_criteria:' "$spec" 2>/dev/null \
        | grep -E '^\s+-\s+[^#<]' | grep -v 'Add as many\|Example:' | wc -l || echo 0)
      if [ "$ac_count" -eq 0 ]; then
        warn "  $spec_name — acceptance_criteria appears empty (fill in before merging)"
        warn_count=$((warn_count + 1))
        if $strict; then fail=1; fi
      fi

      # Check status is valid
      local spec_status
      spec_status=$(yaml_get "$spec" "status" | tr -d ' ')
      if [[ "$spec_status" != "draft" && "$spec_status" != "review" && "$spec_status" != "approved" ]]; then
        error "  $spec_name — invalid status: '$spec_status' (must be draft|review|approved)"
        fail=1
        spec_fail=1
      fi

      if [ $spec_fail -eq 0 ]; then
        success "  $spec_name"
      fi
    done
  fi

  # ── Check 4: PR/commit coverage ────────────────────────────────────────────
  if [ -n "$pr_number" ]; then
    info "Checking spec coverage for PR #${pr_number}..."
    _check_pr_coverage "$pr_number" || fail=1
  fi

  if [ -n "$commit_sha" ]; then
    info "Checking spec coverage for commit ${commit_sha:0:8}..."
    _check_commit_coverage "$commit_sha" || fail=1
  fi

  # ── Summary ────────────────────────────────────────────────────────────────
  echo ""
  if [ $fail -eq 0 ] && [ $warn_count -eq 0 ]; then
    success "All checks passed."
  elif [ $fail -eq 0 ]; then
    warn "$warn_count warning(s). Run with --strict to treat warnings as errors."
  else
    error "Check failed. Fix the issues above and re-run: gh openspec check"
  fi

  exit $fail
}

_check_pr_coverage() {
  local pr_number="$1"

  local changed_files
  changed_files=$(gh pr diff "$pr_number" --name-only 2>/dev/null) || {
    error "Could not fetch PR #${pr_number} diff. Check your GH_TOKEN and network."
    return 1
  }

  local source_changed
  source_changed=$(echo "$changed_files" | grep -E '\.(py|ts|js|tsx|jsx|go|java|rb|rs|cpp|c|cs|swift|kt|php)$' || true)

  local spec_changed
  spec_changed=$(echo "$changed_files" | grep -E '\.openspec/specs/.*\.spec\.yaml$' || true)

  if [ -n "$source_changed" ] && [ -z "$spec_changed" ]; then
    error "PR #${pr_number} modifies source files but includes no spec changes."
    echo ""
    echo "  Changed source files:"
    echo "$source_changed" | sed 's/^/    /'
    echo ""
    info "Create or update a spec:"
    echo "   gh openspec scaffold '<feature-name>'"
    return 1
  fi

  if [ -n "$spec_changed" ]; then
    success "PR #${pr_number} includes spec changes"
    echo "$spec_changed" | sed 's/^/    /'
  else
    info "PR #${pr_number} has no source file changes — spec not required"
  fi
  return 0
}

_check_commit_coverage() {
  local sha="$1"

  local changed_files
  changed_files=$(git diff-tree --no-commit-id -r --name-only "$sha" 2>/dev/null) || {
    error "Could not inspect commit $sha"
    return 1
  }

  local source_changed
  source_changed=$(echo "$changed_files" | grep -E '\.(py|ts|js|tsx|jsx|go|java|rb|rs|cpp|c|cs|swift|kt|php)$' || true)

  local spec_changed
  spec_changed=$(echo "$changed_files" | grep -E '\.openspec/specs/.*\.spec\.yaml$' || true)

  if [ -n "$source_changed" ] && [ -z "$spec_changed" ]; then
    warn "Commit ${sha:0:8} modifies source files without spec changes."
    echo "$source_changed" | sed 's/^/    /'
    return 1
  fi

  success "Commit ${sha:0:8} spec coverage OK"
  return 0
}
