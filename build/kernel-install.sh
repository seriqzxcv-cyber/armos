#!/usr/bin/env bash
# Install the built ARMOS kernel into the prepared rootfs and generate its
# initramfs. Runs inside the privileged builder container.
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"
if ! mountpoint -q "$ROOTFS/proc"; then setup_mounts; fi

SRC=/armos/build/kernel-install
KVER="${KVER:-6.18.0-armos}"
[[ -f "$SRC/vmlinuz-$KVER" ]] || die "Run 'build/kernel.sh' first"

log "Installing ARMOS kernel $KVER into rootfs ..."
rm -rf "$ROOTFS/lib/modules/$KVER"
mkdir -p "$ROOTFS/lib/modules/$KVER" "$ROOTFS/boot"
cp -a "$SRC/lib/modules/$KVER/." "$ROOTFS/lib/modules/$KVER/"
install -m644 "$SRC/vmlinuz-$KVER" "$ROOTFS/boot/vmlinuz-$KVER"
install -m644 "$SRC/System.map-$KVER" "$ROOTFS/boot/System.map-$KVER"
install -m644 "$SRC/config-$KVER" "$ROOTFS/boot/config-$KVER"

in_chroot '
  kver=6.18.0-armos
  dracut --force --no-hostonly \
    --add 'plymouth' \
    --add-drivers "virtio_blk virtio_pci virtio_net ext4 squashfs overlay bochs drm" \
    --kver "$kver" "/boot/initramfs-${kver}.img"
  chmod 0644 "/boot/initramfs-${kver}.img"
  echo "ARMOS kernel $kver installed"
'
log "ARMOS kernel installed into $ROOTFS/boot"
