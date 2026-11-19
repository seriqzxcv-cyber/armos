#!/usr/bin/env bash
# Boot the ARMOS live ISO in QEMU. Defaults to BIOS; UEFI=1 enables OVMF.
# Environment:
#   ISO=path        ISO to boot (default: newest out/*.iso)
#   UEFI=1          boot via UEFI (OVMF)
#   MEM=4096        RAM in MiB
#   CPUS=4          vCPU count
#   PERSIST=path    raw image attached as a second disk (persistence tests)
#   HEADLESS=1      no graphical window (serial console only)
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ISO="${ISO:-$(ls -t "$PROJECT_ROOT"/out/*.iso 2>/dev/null | head -1 || true)}"

[[ -n "$ISO" && -f "$ISO" ]] || { echo "ISO not found: run make live" >&2; exit 1; }

MEM="${MEM:-4096}"
CPUS="${CPUS:-4}"

ACCEL=()
if [[ -r /dev/kvm ]]; then
  ACCEL=(-enable-kvm -cpu host)
else
  ACCEL=(-cpu max)
fi

DISPLAY_ARGS=(-display gtk)
SERIAL_ARGS=(-serial mon:stdio)
if [[ "${HEADLESS:-0}" == "1" ]]; then
  DISPLAY_ARGS=(-display none)
fi

MONITOR_ARGS=()
if [[ -n "${MONITOR_SOCK:-}" ]]; then
  MONITOR_ARGS=(-monitor "unix:${MONITOR_SOCK},server,nowait")
  if [[ -n "${SERIAL_LOG:-}" ]]; then
    SERIAL_ARGS=(-serial "file:${SERIAL_LOG}")
  fi
fi

DISK_ARGS=()
if [[ -n "${PERSIST:-}" ]]; then
  [[ -f "$PERSIST" ]] || { echo "Persistence image not found: $PERSIST" >&2; exit 1; }
  DISK_ARGS=(-drive "file=$PERSIST,format=raw,if=virtio")
fi

UEFI_ARGS=()
if [[ "${UEFI:-0}" == "1" ]]; then
  OVMF_CODE=""
  for c in /usr/share/edk2/ovmf/OVMF_CODE.fd /usr/share/OVMF/OVMF_CODE.fd; do
    [[ -f "$c" ]] && OVMF_CODE=$c && break
  done
  OVMF_VARS=""
  for v in /usr/share/edk2/ovmf/OVMF_VARS.fd /usr/share/OVMF/OVMF_VARS.fd; do
    [[ -f "$v" ]] && OVMF_VARS=$v && break
  done
  [[ -n "$OVMF_CODE" && -n "$OVMF_VARS" ]] || { echo "OVMF firmware not found" >&2; exit 1; }
  mkdir -p "$PROJECT_ROOT/build/qemu"
  VARS_COPY="$PROJECT_ROOT/build/qemu/OVMF_VARS.fd"
  [[ -f "$VARS_COPY" ]] || cp "$OVMF_VARS" "$VARS_COPY"
  UEFI_ARGS=(
    -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
    -drive "if=pflash,format=raw,file=$VARS_COPY"
  )
fi

echo "[ARMOS] ISO:  $ISO"
echo "[ARMOS] mode: $([[ "${UEFI:-0}" == 1 ]] && echo UEFI || echo BIOS)"
echo "[ARMOS] live login: live / live (autologin enabled)"
echo

exec qemu-system-x86_64 \
  -name ARMOS-live \
  -machine q35 \
  -m "$MEM" \
  -smp "$CPUS" \
  "${ACCEL[@]}" \
  "${UEFI_ARGS[@]}" \
  "${DISK_ARGS[@]}" \
  -cdrom "$ISO" \
  -boot d \
  -device virtio-rng-pci \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0 \
  "${DISPLAY_ARGS[@]}" \
  "${SERIAL_ARGS[@]}" \
  "${MONITOR_ARGS[@]}" \
  -no-reboot
