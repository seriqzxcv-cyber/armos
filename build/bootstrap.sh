#!/usr/bin/env bash
# M0: download stage3 + Portage snapshot, extract into build/rootfs, install configs.
set -euo pipefail
source /armos/build/lib.sh

require_root
prepare_cache

STAGE3_VERSION="20261115T170104Z"
STAGE3_BASE="https://distfiles.gentoo.org/releases/amd64/autobuilds/current-stage3-amd64-openrc"
STAGE3_NAME="stage3-amd64-openrc-${STAGE3_VERSION}.tar.xz"
STAGE3_URL="${STAGE3_BASE}/${STAGE3_NAME}"
STAGE3_TARBALL="$CACHE_DIR/$STAGE3_NAME"
SNAPSHOT_URL="https://distfiles.gentoo.org/snapshots/portage-latest.tar.xz"
SNAPSHOT_TARBALL="$CACHE_DIR/portage-latest.tar.xz"

if [[ ! -f "$STAGE3_TARBALL" ]]; then
  log "Downloading $STAGE3_NAME ..."
  curl -L --fail --retry 3 -o "$STAGE3_TARBALL" "$STAGE3_URL"
  curl -L --fail --retry 3 -o "$STAGE3_TARBALL.sha256" "$STAGE3_URL.sha256"
fi

if [[ -f "$STAGE3_TARBALL.sha256" ]]; then
  log "Verifying stage3 checksum ..."
  expected=$(grep -E '^[0-9a-f]{64} ' "$STAGE3_TARBALL.sha256" | awk '{print $1}' | head -1)
  actual=$(sha256sum "$STAGE3_TARBALL" | awk '{print $1}')
  [[ -n "$expected" && "$expected" == "$actual" ]] || die "stage3 checksum mismatch"
fi

if [[ ! -f "$SNAPSHOT_TARBALL" ]]; then
  log "Downloading Portage snapshot ..."
  curl -L --fail --retry 3 -o "$SNAPSHOT_TARBALL" "$SNAPSHOT_URL"
fi

if [[ ! -f "$ROOTFS/etc/gentoo-release" ]]; then
  log "Extracting stage3 into $ROOTFS ..."
  mkdir -p "$ROOTFS"
  tar -xpf "$STAGE3_TARBALL" -C "$ROOTFS" --numeric-owner --xattrs
else
  log "Stage3 already extracted, skipping"
fi

if [[ ! -d "$ROOTFS/var/db/repos/gentoo/profiles" ]]; then
  log "Extracting Portage snapshot ..."
  mkdir -p "$ROOTFS/var/db/repos/gentoo"
  tar -xpf "$SNAPSHOT_TARBALL" -C "$ROOTFS/var/db/repos/gentoo" --strip-components=1
else
  log "Portage tree already present, skipping snapshot"
fi

log "Installing ARMOS Portage configuration ..."
ensure_configs

setup_mounts

log "Selecting desktop profile ..."
in_chroot '
  if command -v eselect >/dev/null 2>&1; then
    profile=$(eselect profile list 2>/dev/null | sed -n "s/.*] *\\([^ ]*\\).*/\\1/p" | grep "desktop/xfce" | head -1)
    if [[ -z "$profile" ]]; then
      profile=$(eselect profile list 2>/dev/null | sed -n "s/.*] *\\([^ ]*\\).*/\\1/p" | grep "/desktop$" | head -1)
    fi
    if [[ -n "$profile" ]]; then
      eselect profile set "$profile"
      echo "Profile: $profile"
    else
      echo "No desktop profile found, keeping default"
    fi
  fi
'

log "Bootstrap complete."
log "Rootfs: $ROOTFS"
log "Next: make base"
