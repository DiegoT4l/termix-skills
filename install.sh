#!/usr/bin/env bash
# Install the Termix skill set into any agent that reads skill directories.
#
#   ./install.sh                 detect known agents and install into each
#   ./install.sh --dir PATH      install into an explicit skills directory
#   ./install.sh --copy          copy instead of symlinking
#   ./install.sh --uninstall     remove what this script installed
#   ./install.sh --list          show what would happen, change nothing
#
# Symlinks are the default so `git pull` updates every agent at once.
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/skills"
SKILLS=(termix-ssh termix-provisioning termix-fleet-ops)

MODE=install
LINK=symlink
TARGETS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)       TARGETS+=("${2:?--dir needs a path}"); shift 2 ;;
    --copy)      LINK=copy; shift ;;
    --uninstall) MODE=uninstall; shift ;;
    --list)      MODE=list; shift ;;
    -h|--help)   sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

# Known skill directories, used only when they already exist on this machine.
detect() {
  local d
  for d in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills" \
           "$HOME/.copilot/skills" \
           "$HOME/.config/opencode/skill"; do
    [ -d "$d" ] && printf '%s\n' "$d"
  done
}

if [ ${#TARGETS[@]} -eq 0 ]; then
  mapfile -t TARGETS < <(detect)
fi

if [ ${#TARGETS[@]} -eq 0 ]; then
  cat >&2 <<'MSG'
No known skill directory found on this machine.

Pass one explicitly:
    ./install.sh --dir ~/.config/<your-agent>/skills

If your agent has no skill system, point it at AGENTS.md in this repo instead;
the skills are plain Markdown and can be read directly.
MSG
  exit 1
fi

for dest in "${TARGETS[@]}"; do
  echo "==> $dest"
  [ "$MODE" = install ] && mkdir -p "$dest"
  for s in "${SKILLS[@]}"; do
    target="$dest/$s"
    case "$MODE" in
      list)
        printf '    %-22s %s\n' "$s" "$([ -e "$target" ] && echo 'already present' || echo 'would install')"
        ;;
      uninstall)
        if [ -L "$target" ] || [ -d "$target" ]; then
          rm -rf "$target"; printf '    %-22s removed\n' "$s"
        else
          printf '    %-22s not installed\n' "$s"
        fi
        ;;
      install)
        rm -rf "$target"
        if [ "$LINK" = symlink ]; then
          ln -s "$SRC/$s" "$target"; printf '    %-22s linked\n' "$s"
        else
          cp -R "$SRC/$s" "$target"; printf '    %-22s copied\n' "$s"
        fi
        ;;
    esac
  done
done

if [ "$MODE" = install ]; then
  cat <<MSG

Done. Verify the agent can see them, for example:
    ls -l "${TARGETS[0]}" | grep termix

Agents that use AGENTS.md instead of skill directories (opencode, Codex, and
others) should be pointed at:
    $REPO/AGENTS.md
MSG
fi
