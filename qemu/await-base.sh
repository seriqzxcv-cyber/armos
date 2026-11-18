#!/usr/bin/env bash
# Wait for `make base` to finish, then build the base image and boot it in a
# graphical QEMU window. Useful when the base build runs in the background.
#
# Usage: qemu/await-base.sh
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOTFS="$PROJECT_ROOT/build/rootfs"
LOG="$PROJECT_ROOT/build/qemu-base.gui.log"

echo "[ARMOS] waiting for the base build to finish ..."
while pgrep -f 'armos/build/base\.sh' >/dev/null 2>&1; do
  sleep 15
done

KERNEL=$(ls "$ROOTFS"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 || true)
KVER=$(basename "${KERNEL:-vmlinuz-x}" | sed 's/^vmlinuz-//')
INITRD="$ROOTFS/boot/initramfs-${KVER}.img"
if [[ -z "$KERNEL" || ! -s "$KERNEL" || ! -s "$INITRD" || ! -e "$ROOTFS/boot/initramfs.img" ]]; then
  echo "[ARMOS] base build did not complete: kernel/initramfs symlinks missing." >&2
  echo "[ARMOS] check the build log and run 'make base' again." >&2
  exit 1
fi

echo "[ARMOS] base is ready: $(basename "$KERNEL")"
echo "[ARMOS] launching QEMU (log: $LOG)"
cd "$PROJECT_ROOT"
GUI=1 "$PROJECT_ROOT/qemu/run-base.sh" >"$LOG" 2>&1
