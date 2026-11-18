#!/usr/bin/env bash
# Boot the M0 base system in QEMU using the kernel/initramfs from the rootfs.
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ROOTFS="$PROJECT_ROOT/build/rootfs"
IMAGE="${IMAGE:-$PROJECT_ROOT/build/armos-base.img}"

[[ -d "$ROOTFS" ]] || { echo "rootfs missing: run make bootstrap" >&2; exit 1; }
[[ -f "$ROOTFS/etc/gentoo-release" ]] || { echo "rootfs incomplete: run make bootstrap" >&2; exit 1; }

if [[ ! -f "$IMAGE" || "${REBUILD:-0}" == "1" ]]; then
  "$PROJECT_ROOT/build/container.sh" /armos/build/make-image.sh
fi

KVER="${KVER:-}"
if [[ -z "$KVER" ]]; then
  KVER=$(basename "${KERNEL:-vmlinuz-x}" | sed 's/^vmlinuz-//')
fi
KERNEL="${KERNEL:-$ROOTFS/boot/vmlinuz-$KVER}"
[[ -f "$KERNEL" ]] || KERNEL=$(ls "$ROOTFS"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 || true)
INITRD="$ROOTFS/boot/initramfs-${KVER}.img"
[[ -f "$INITRD" ]] || INITRD=$(ls "$ROOTFS"/boot/initramfs-[0-9]*.img 2>/dev/null | sort -V | tail -1 || true)

[[ -n "$KERNEL" ]] || { echo "kernel not found: run make base" >&2; exit 1; }
[[ -n "$INITRD" ]] || { echo "initramfs not found: run make base" >&2; exit 1; }

ACCEL=()
if [[ -r /dev/kvm ]]; then
  ACCEL=(-enable-kvm -cpu host)
else
  ACCEL=(-cpu max)
fi

MONITOR_ARGS=()
if [[ -n "${MONITOR_SOCK:-}" ]]; then
  # Unix monitor socket: lets us issue `screendump` against the guest framebuffer.
  MONITOR_ARGS=(-monitor "unix:${MONITOR_SOCK},server,nowait")
fi

DISPLAY_ARGS=(-nographic)
SERIAL_ARGS=()
if [[ "${GUI:-0}" == "1" ]]; then
  DISPLAY_ARGS=(-display gtk)
  if [[ -n "${SERIAL_LOG:-}" ]]; then
    # Detached GUI run: capture the serial console to a file instead of stdio.
    SERIAL_ARGS=(-serial "file:${SERIAL_LOG}")
  else
    SERIAL_ARGS=(-serial mon:stdio)
  fi
fi

echo "[ARMOS] kernel:    $KERNEL"
echo "[ARMOS] initramfs: $INITRD"
echo "[ARMOS] disk:      $IMAGE"
echo "[ARMOS] console:   ttyS0 / tty1 (root/armos)"
if [[ "${GUI:-0}" == "1" ]]; then
  echo "[ARMOS] window:    GTK (tty1 for login)"
fi
echo

exec qemu-system-x86_64 \
  -name ARMOS-base \
  -machine q35 \
  -m 4096 \
  -smp 4 \
  "${ACCEL[@]}" \
  -drive file="$IMAGE",format=raw,if=virtio \
  -kernel "$KERNEL" \
  -initrd "$INITRD" \
  -append "root=/dev/vda rw rootfstype=ext4 console=tty0 console=ttyS0,115200 loglevel=6 consoleblank=0" \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  -device virtio-rng-pci \
  "${DISPLAY_ARGS[@]}" \
  "${SERIAL_ARGS[@]}" \
  "${MONITOR_ARGS[@]}" \
  -no-reboot
