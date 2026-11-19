#!/usr/bin/env bash
# Shared helpers for ARMOS build scripts. Runs inside the Gentoo builder container.
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/armos}"
ROOTFS="${ROOTFS:-$PROJECT_ROOT/build/rootfs}"
CACHE_DIR="${CACHE_DIR:-$PROJECT_ROOT/build/cache}"
DISTFILES_DIR="${DISTFILES_DIR:-$CACHE_DIR/distfiles}"
BINPKGS_DIR="${BINPKGS_DIR:-$CACHE_DIR/binpkgs}"
OVERLAY_DIR="${OVERLAY_DIR:-$PROJECT_ROOT/overlay}"

log()  { printf '\033[1;36m[ARMOS]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[ARMOS]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[ARMOS]\033[0m %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ "${EUID}" -eq 0 ]] || die "This script must run as root inside the builder container"
}

prepare_cache() {
  mkdir -p "$CACHE_DIR" "$DISTFILES_DIR" "$BINPKGS_DIR"
}

setup_mounts() {
  require_root
  mkdir -p "$ROOTFS"/{proc,sys,dev,run,var/cache/distfiles,var/cache/binpkgs,var/db/repos/armos}
  mountpoint -q "$ROOTFS/proc" || mount --rbind /proc "$ROOTFS/proc"
  mountpoint -q "$ROOTFS/sys"  || mount --rbind /sys  "$ROOTFS/sys"
  mountpoint -q "$ROOTFS/dev"  || mount --rbind /dev  "$ROOTFS/dev"
  mountpoint -q "$ROOTFS/run"  || mount --rbind /run  "$ROOTFS/run"
  mountpoint -q "$ROOTFS/var/cache/distfiles" || mount --bind "$DISTFILES_DIR" "$ROOTFS/var/cache/distfiles"
  mountpoint -q "$ROOTFS/var/cache/binpkgs"   || mount --bind "$BINPKGS_DIR"   "$ROOTFS/var/cache/binpkgs"
  mountpoint -q "$ROOTFS/var/db/repos/armos"  || mount --bind "$OVERLAY_DIR"  "$ROOTFS/var/db/repos/armos"
  mkdir -p "$ROOTFS/armos"
  mountpoint -q "$ROOTFS/armos" || mount --bind "$PROJECT_ROOT" "$ROOTFS/armos"
  cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf"
  trap teardown_mounts EXIT
}

teardown_mounts() {
  set +e
  for m in armos var/db/repos/armos var/cache/binpkgs var/cache/distfiles run dev sys proc; do
    if mountpoint -q "$ROOTFS/$m"; then
      umount -R "$ROOTFS/$m" 2>/dev/null || umount -l "$ROOTFS/$m" 2>/dev/null
    fi
  done
}

in_chroot() {
  # $1 is a shell command string executed inside the target rootfs.
  chroot "$ROOTFS" /bin/bash -lc "set -e; $*"
}

ensure_configs() {
  local src="$PROJECT_ROOT/configs/portage"
  install -d "$ROOTFS/etc/portage/package.use" \
             "$ROOTFS/etc/portage/package.accept_keywords" \
             "$ROOTFS/etc/portage/package.license" \
             "$ROOTFS/etc/portage/repos.conf"
  install -m 0644 "$src/make.conf" "$ROOTFS/etc/portage/make.conf"
  cp -a "$src/package.use/." "$ROOTFS/etc/portage/package.use/"
  cp -a "$src/package.accept_keywords/." "$ROOTFS/etc/portage/package.accept_keywords/"
  cp -a "$src/package.license/." "$ROOTFS/etc/portage/package.license/"
  cp -a "$src/repos.conf/." "$ROOTFS/etc/portage/repos.conf/"
}
