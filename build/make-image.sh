#!/usr/bin/env bash
# Create a raw ext4 image from build/rootfs without loop devices.
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"

IMAGE="${IMAGE:-$PROJECT_ROOT/build/armos-base.img}"
SIZE="${SIZE:-6G}"

log "Creating $IMAGE ($SIZE) ..."
rm -f "$IMAGE"
mke2fs -q -t ext4 -L ARMOS_ROOT -d "$ROOTFS" "$IMAGE" "$SIZE"
# The image is created by root inside the builder container but booted by the
# host user's QEMU, which opens it read-write.
chmod 0666 "$IMAGE"
sync
log "Image ready: $IMAGE"
