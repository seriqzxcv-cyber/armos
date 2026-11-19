#!/usr/bin/env bash
# M2: build a hybrid BIOS/UEFI live ISO from the prepared rootfs.
#
# Layout (flat dracut dmsquash-live):
#   /boot/vmlinuz                 kernel
#   /boot/initramfs-live.img      dracut initramfs with dmsquash-live
#   /LiveOS/squashfs.img          squashfs of the whole root filesystem
#   /boot/grub/grub.cfg           BIOS/UEFI menu
#
# dracut mounts the squashfs through overlayfs. Persistence uses an ext4
# partition labeled ARMOS_PERSIST prepared by `armos-persistence-init`:
#   /LiveOS/overlay   (upperdir)   /LiveOS/ovlwork (workdir)
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"
[[ -d "$ROOTFS/usr/share/xfce4" ]] || warn "XFCE does not look installed; building a base-only live ISO"
ensure_configs
setup_mounts

ISO_NAME="${ISO_NAME:-armos-1.0-gen-amd64.iso}"
ISO_LABEL="${ISO_LABEL:-ARMOS_LIVE}"
PERSIST_LABEL="${PERSIST_LABEL:-ARMOS_PERSIST}"
WORK="$PROJECT_ROOT/build/live"
STAGE="$WORK/iso"
SQUASHFS_IMG="$STAGE/LiveOS/squashfs.img"

log "Cleaning the rootfs ..."
in_chroot '
  rm -rf /tmp/* /var/tmp/*
  # /var/cache/distfiles and /var/cache/binpkgs are bind-mounted from the host
  # cache; they are excluded from the squashfs below instead of being deleted.
  rm -rf /var/log/portage /var/log/emerge.log /var/log/emerge-fetch.log
  rm -f /root/.bash_history /home/*/.bash_history
  rm -f /etc/machine-id
  : > /etc/machine-id
  rm -f /etc/ssh/ssh_host_*
  # The live system must not try to fsck its squashfs as a block root.
  if [[ -f /etc/fstab ]]; then
    sed -i "/^\/dev\/vd/d" /etc/fstab
  fi
'

KVER="${KVER:-$(ls "$ROOTFS/lib/modules" 2>/dev/null | sort -V | tail -1)}"
[[ -n "$KVER" ]] || die "No kernel found: run 'make base'"
log "Kernel: $KVER"

log "Preparing GRUB theme fonts ..."
in_chroot '
  theme=/boot/grub/themes/armos
  if command -v grub-mkfont >/dev/null 2>&1 && [[ -d "$theme" ]]; then
    mkdir -p "$theme/fonts"
    font=$(fc-match -f "%{file}" "Noto Sans:style=Regular" 2>/dev/null || true)
    [[ -n "$font" && -f "$font" ]] || font=$(ls /usr/share/fonts/dejavu/DejaVuSans.ttf 2>/dev/null || true)
    mono=$(fc-match -f "%{file}" "Noto Sans Mono:style=Regular" 2>/dev/null || true)
    [[ -n "$mono" && -f "$mono" ]] || mono=$(ls /usr/share/fonts/dejavu/DejaVuSansMono.ttf 2>/dev/null || true)
    if [[ -n "$font" && -f "$font" ]]; then
      grub-mkfont -s 24 -o "$theme/fonts/title-24.pf2" "$font" || true
      grub-mkfont -s 16 -o "$theme/fonts/item-16.pf2" "$font" || true
    fi
    if [[ -n "$mono" && -f "$mono" ]]; then
      grub-mkfont -s 14 -o "$theme/fonts/terminal-14.pf2" "$mono" || true
    fi
  fi
'

log "Building live initramfs ..."
in_chroot "
  dracut --force --no-hostonly \
    --add 'dmsquash-live plymouth' \
    --add-drivers 'squashfs loop overlay isofs sr_mod cdrom virtio_blk virtio_pci virtio_net ext4 drm bochs' \
    --kver '$KVER' /boot/initramfs-live.img
"

log "Preparing live workdir ..."
rm -rf "$WORK"
mkdir -p "$STAGE/boot/grub" "$STAGE/LiveOS"
cp -f "$ROOTFS/boot/vmlinuz-$KVER" "$STAGE/boot/vmlinuz"
cp -f "$ROOTFS/boot/initramfs-live.img" "$STAGE/boot/initramfs-live.img"
if [[ -d "$ROOTFS/boot/grub/themes/armos" ]]; then
  cp -a "$ROOTFS/boot/grub/themes" "$STAGE/boot/grub/"
fi

# Do not copy the bind-mounted caches or pseudo-filesystems into the squashfs.
teardown_mounts
trap - EXIT

log "Installing the ARMOS ebuild repository ..."
rm -rf "$ROOTFS/var/db/repos/armos"
mkdir -p "$ROOTFS/var/db/repos/armos"
cp -a "$PROJECT_ROOT/overlay/." "$ROOTFS/var/db/repos/armos/"

log "Installing live helpers ..."
install -Dm755 "$PROJECT_ROOT/live/persistence/armos-persistence-init" \
  "$ROOTFS/usr/sbin/armos-persistence-init"

log "Building squashfs (this can take a while) ..."
SQUASHFS=$(command -v mksquashfs || true)
if [[ -n "$SQUASHFS" ]]; then
  SQUASHFS_LIBS=""
else
  SQUASHFS="$PROJECT_ROOT/build/host-tools/mksquashfs"
  SQUASHFS_LIBS="$PROJECT_ROOT/build/host-tools/lib"
fi
[[ -x "$SQUASHFS" ]] || die "mksquashfs not found"
rm -f "$SQUASHFS_IMG"
if [[ -n "$SQUASHFS_LIBS" ]]; then
  LD_LIBRARY_PATH="$SQUASHFS_LIBS${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$SQUASHFS" "$ROOTFS" "$SQUASHFS_IMG" \
    -comp zstd -Xcompression-level 15 -b 1M -noappend -no-progress \
    -e proc/* -e sys/* -e dev/* -e run/* -e tmp/* \
    -e var/tmp/* -e var/cache/distfiles -e var/cache/binpkgs \
    -e var/log/*
else
  "$SQUASHFS" "$ROOTFS" "$SQUASHFS_IMG" \
    -comp zstd -Xcompression-level 15 -b 1M -noappend -no-progress \
    -e proc/* -e sys/* -e dev/* -e run/* -e tmp/* \
    -e var/tmp/* -e var/cache/distfiles -e var/cache/binpkgs \
    -e var/log/*
fi

log "Writing GRUB configuration ..."
cat > "$STAGE/boot/grub/grub.cfg" <<EOF
set default=0
set timeout=10
set color_normal=light-gray/black
set menu_color_normal=light-gray/black
set menu_color_highlight=blue/black

insmod all_video
insmod gfxterm
insmod gfxmenu
set gfxmode=1920x1080,1280x720,auto

search --no-floppy --set=root --label $ISO_LABEL

if [ -f /boot/grub/themes/armos/fonts/title-24.pf2 ]; then
    loadfont /boot/grub/themes/armos/fonts/title-24.pf2
fi
if [ -f /boot/grub/themes/armos/fonts/item-16.pf2 ]; then
    loadfont /boot/grub/themes/armos/fonts/item-16.pf2
fi
if [ -f /boot/grub/themes/armos/fonts/terminal-14.pf2 ]; then
    loadfont /boot/grub/themes/armos/fonts/terminal-14.pf2
fi

if [ -f /boot/grub/themes/armos/theme.txt ]; then
    set theme=/boot/grub/themes/armos/theme.txt
fi

terminal_output gfxterm

menuentry "ARMOS 1.0 GEN — Live" {
    linux /boot/vmlinuz root=live:CDLABEL=$ISO_LABEL rd.live.image rd.live.overlay.overlayfs=1 console=tty0 console=ttyS0,115200 quiet splash loglevel=4 plymouth.ignore-serial-consoles
    initrd /boot/initramfs-live.img
}

menuentry "ARMOS 1.0 GEN — Live with persistence" {
    linux /boot/vmlinuz root=live:CDLABEL=$ISO_LABEL rd.live.image rd.live.overlay.overlayfs=1 rd.live.overlay=LABEL=$PERSIST_LABEL:/LiveOS/overlay console=tty0 console=ttyS0,115200 quiet splash loglevel=4 plymouth.ignore-serial-consoles
    initrd /boot/initramfs-live.img
}

menuentry "ARMOS 1.0 GEN — Live (safe graphics)" {
    linux /boot/vmlinuz root=live:CDLABEL=$ISO_LABEL rd.live.image rd.live.overlay.overlayfs=1 nomodeset console=tty0 console=ttyS0,115200
    initrd /boot/initramfs-live.img
}

menuentry "ARMOS 1.0 GEN — Live (RAM)" {
    linux /boot/vmlinuz root=live:CDLABEL=$ISO_LABEL rd.live.image rd.live.ram rd.live.overlay.overlayfs=1 console=tty0 console=ttyS0,115200 quiet splash loglevel=4 plymouth.ignore-serial-consoles
    initrd /boot/initramfs-live.img
}
EOF

# grub-mkrescue lives inside the target rootfs; remount the chroot for it.
setup_mounts

log "Building hybrid ISO ..."
mkdir -p "$PROJECT_ROOT/out"
rm -f "$PROJECT_ROOT/out/$ISO_NAME"
in_chroot "grub-mkrescue --compress=xz --locales=ru \
  -o '/armos/out/$ISO_NAME' '/armos/build/live/iso' -- -volid '$ISO_LABEL'"

log "Checksums ..."
( cd "$PROJECT_ROOT/out" && sha256sum "$ISO_NAME" > "$ISO_NAME.sha256" )

log "Done: $PROJECT_ROOT/out/$ISO_NAME ($(du -h "$PROJECT_ROOT/out/$ISO_NAME" | cut -f1))"
log "Test with: make qemu-live  (BIOS) or UEFI=1 make qemu-live"
