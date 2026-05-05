#!/usr/bin/env bash
# coder-bash.sh
# Run a bash command inside the coder container (default: easv3_coder)
# Usage:
#   ./docker/coder/coder-bash.sh "<bash command>"
#   ./docker/coder/coder-bash.sh <container_name> "<bash command>"
# Examples:
#   ./docker/coder/coder-bash.sh "ls -la ~"
#   ./docker/coder/coder-bash.sh easv3_coder "node -v"

set -euo pipefail

DEFAULT_CONTAINER="easv3_coder"

err()   { printf "Error: %s\n" "$*" >&2; }
note()  { printf "%s\n" "$*"; }

if ! command -v docker >/dev/null 2>&1; then
  err "docker is not installed or not in PATH."
  exit 1
fi

if [[ $# -lt 1 ]]; then
  err "missing command. Usage: coder-bash.sh [container] \"<bash command>\""
  exit 1
fi

CONTAINER="$DEFAULT_CONTAINER"
CMD="$*"

# If first arg looks like a container name, treat it as such
if [[ $# -ge 2 ]]; then
  case "$1" in
    easv3_coder|coder)
      CONTAINER="$1"
      shift
      CMD="$*"
      ;;
  esac
fi

# Ensure container is running
if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  err "container \"$CONTAINER\" is not running."
  note "Running containers:"
  docker ps --format '  - {{.Names}}'
  exit 1
fi

# Use appropriate user/workdir for coder
USER="dev"
WORKDIR="/home/dev"

exec docker exec -u "$USER" -w "$WORKDIR" -it "$CONTAINER" bash -lc "$CMD"
