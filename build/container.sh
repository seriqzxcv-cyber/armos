#!/usr/bin/env bash
# Run a command inside the privileged Gentoo builder container.
# Usage: build/container.sh <command string>
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# Use a distinct name: IMAGE is a build parameter (target disk/ISO image) that
# is forwarded to the container below, so it must not be shadowed here.
BUILDER_IMAGE="${ARMOS_BUILDER_IMAGE:-gentoo/stage3:latest}"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required" >&2
  exit 1
fi

if ! docker image inspect "$BUILDER_IMAGE" >/dev/null 2>&1; then
  echo "[ARMOS] pulling $BUILDER_IMAGE ..."
  docker pull "$BUILDER_IMAGE"
fi

args=(
  run --rm --privileged --network host
  --hostname armos-builder
  -e TERM=xterm-256color
  -v "$PROJECT_ROOT:/armos"
  -w /armos
)

# Pass build parameters that scripts read from the environment.
for var in SIZE IMAGE ISO_NAME ISO_LABEL PERSIST_LABEL; do
  if [[ -n "${!var:-}" ]]; then
    args+=(-e "$var=${!var}")
  fi
done

if [[ "${ARMOS_TTY:-0}" == "1" ]]; then
  args+=(-it)
fi

exec docker "${args[@]}" "$BUILDER_IMAGE" /bin/bash -lc "$*"
