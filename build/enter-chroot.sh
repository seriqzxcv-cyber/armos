#!/usr/bin/env bash
# Enter the target rootfs interactively (run via build/container.sh).
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"

setup_mounts
chroot "$ROOTFS" /bin/bash -l
