#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

targets=(
  "${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
  "${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
)

dry_run=0

usage() {
  cat <<'USAGE'
Usage: scripts/link-skills.sh [--dry-run]

Find every SKILL.md in this repository and symlink its containing directory
into ~/.agents/skills and ~/.claude/skills.

Environment overrides:
  AGENTS_SKILLS_DIR   Target directory for agent skills
  CLAUDE_SKILLS_DIR   Target directory for Claude skills
USAGE
}

while (($#)); do
  case "$1" in
    --dry-run)
      dry_run=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

run() {
  if ((dry_run)); then
    printf 'DRY RUN:'
    printf ' %q' "$@"
    printf '\n'
    return 0
  fi

  "$@"
}

link_skill() {
  local skill_dir="$1"
  local target_dir="$2"
  local skill_name
  local link_path
  local current_target

  skill_name="$(basename -- "$skill_dir")"
  link_path="$target_dir/$skill_name"

  run mkdir -p "$target_dir"

  if [[ -L "$link_path" ]]; then
    current_target="$(readlink -- "$link_path")"
    if [[ "$current_target" == "$skill_dir" ]]; then
      echo "ok: $link_path -> $skill_dir"
      return 0
    fi

    run ln -sfn "$skill_dir" "$link_path"
    if ((dry_run)); then
      echo "would update: $link_path -> $skill_dir"
    else
      echo "updated: $link_path -> $skill_dir"
    fi
    return 0
  fi

  if [[ -e "$link_path" ]]; then
    echo "skip: $link_path already exists and is not a symlink" >&2
    return 1
  fi

  run ln -s "$skill_dir" "$link_path"
  if ((dry_run)); then
    echo "would link: $link_path -> $skill_dir"
  else
    echo "linked: $link_path -> $skill_dir"
  fi
}

mapfile -d '' skill_files < <(find "$repo_root" -type f -name SKILL.md -print0 | sort -z)

if ((${#skill_files[@]} == 0)); then
  echo "no SKILL.md files found under $repo_root" >&2
  exit 1
fi

failed=0
declare -A skill_names=()

for skill_file in "${skill_files[@]}"; do
  skill_dir="$(dirname -- "$skill_file")"
  skill_name="$(basename -- "$skill_dir")"

  if [[ -n "${skill_names[$skill_name]:-}" ]]; then
    echo "duplicate skill directory name '$skill_name':" >&2
    echo "  ${skill_names[$skill_name]}" >&2
    echo "  $skill_dir" >&2
    echo "rename one of these directories before linking skills" >&2
    exit 1
  fi

  skill_names[$skill_name]="$skill_dir"
done

for skill_file in "${skill_files[@]}"; do
  skill_dir="$(dirname -- "$skill_file")"
  for target_dir in "${targets[@]}"; do
    if ! link_skill "$skill_dir" "$target_dir"; then
      failed=1
    fi
  done
done

exit "$failed"
