#!/usr/bin/env bash
# Build the ARMOS custom kernel from source. Intended to run inside the
# privileged Gentoo builder container with the kernel tree mounted at /kernel.
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-/armos}"
K="${KERNEL_DIR:-${PROJECT_ROOT}/build/kernel-work/linux-6.18}"
OUT="${KERNEL_OUT:-${PROJECT_ROOT}/build/kernel-install}"
ASSETS="${PROJECT_ROOT}/overlay/sys-kernel/armos-kernel/files"

[[ -f "$K/Makefile" ]] || { echo "kernel tree missing: $K" >&2; exit 1; }
mkdir -p "$OUT"

# Branding: boot banner and ARMOS logo.
if ! grep -q "ARMOS 1.0 GEN: custom kernel" "$K/init/main.c"; then
  patch -d "$K" -p1 < "$ASSETS/armos-branding.patch"
fi
install -m644 "$ASSETS/logo_linux_clut224.ppm" \
  "$K/drivers/video/logo/logo_linux_clut224.ppm"

# Optional host tool prefix: allows building without root by extracting
# flex/bison and -devel headers from RPMs into $KERNEL_TOOLS.
TOOLS_INC=""
TOOLS_LIB=""
if [[ -n "${KERNEL_TOOLS:-}" ]]; then
  TOOLS_INC="-I${KERNEL_TOOLS}/usr/include"
  TOOLS_LIB="-L${KERNEL_TOOLS}/usr/lib64"
fi
HOST_CFLAGS="-O2 -fno-pie ${TOOLS_INC}"
HOST_LDFLAGS="-no-pie ${TOOLS_LIB}"

install -m644 "$PROJECT_ROOT/configs/kernel/config-6.18-armos" "$K/.config"
make -C "$K" HOSTCFLAGS="$HOST_CFLAGS" HOSTLDFLAGS="$HOST_LDFLAGS" olddefconfig

echo "[ARMOS] building kernel ($(nproc) jobs) ..."
make -C "$K" -j"$(nproc)" \
  HOSTCFLAGS="$HOST_CFLAGS" HOSTLDFLAGS="$HOST_LDFLAGS" bzImage modules

echo "[ARMOS] installing modules ..."
make -C "$K" modules_install INSTALL_MOD_PATH="$OUT" INSTALL_MOD_STRIP=1

KVER=$(make -s -C "$K" kernelrelease)
install -m644 "$K/arch/x86/boot/bzImage" "$OUT/vmlinuz-$KVER"
install -m644 "$K/System.map" "$OUT/System.map-$KVER"
install -m644 "$K/.config" "$OUT/config-$KVER"
echo "[ARMOS] kernel ready in $OUT"
