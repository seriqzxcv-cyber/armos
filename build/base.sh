#!/usr/bin/env bash
# M0: install kernel, firmware, network, base services and build an initramfs.
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"
prepare_cache
ensure_configs

setup_mounts

log "Installing base packages (this can take a while) ..."
in_chroot '
  emerge --ask=n --quiet-build=y --noreplace \
    sys-kernel/gentoo-kernel-bin \
    sys-kernel/dracut \
    sys-kernel/linux-firmware \
    sys-boot/grub \
    sys-boot/os-prober \
    dev-libs/libisoburn \
    sys-fs/mtools \
    app-arch/cpio \
    sys-fs/squashfs-tools \
    sys-fs/dosfstools \
    sys-fs/xfsprogs \
    sys-fs/btrfs-progs \
    sys-fs/cryptsetup \
    sys-fs/lvm2 \
    sys-block/parted \
    sys-apps/gptfdisk \
    sys-apps/pciutils \
    sys-apps/usbutils \
    sys-apps/ethtool \
    net-misc/networkmanager \
    net-wireless/wpa_supplicant \
    net-wireless/iw \
    net-wireless/bluez \
    net-misc/openssh \
    net-misc/chrony \
    sys-auth/elogind \
    sys-auth/polkit \
    sys-apps/dbus \
    app-admin/sudo \
    app-arch/7zip \
    app-arch/unzip \
    app-arch/zip \
    app-arch/xz-utils \
    app-arch/zstd \
    app-shells/bash-completion
'

log "Configuring locale, timezone, hostname and services ..."
in_chroot '
  # Locale
  sed -i -e "s/^# *ru_RU.UTF-8/ru_RU.UTF-8/" -e "s/^# *en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen
  locale-gen

  cat > /etc/env.d/02locale <<EOF
LANG=ru_RU.UTF-8
LC_MESSAGES=ru_RU.UTF-8
LC_TIME=ru_RU.UTF-8
LC_COLLATE=ru_RU.UTF-8
EOF
  env-update
  source /etc/profile

  # Timezone
  echo "Europe/Moscow" > /etc/timezone
  ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
  emerge --config sys-libs/timezone-data >/dev/null 2>&1 || true

  # Hostname
  echo "armos" > /etc/hostname
  sed -i "/127.0.1.1/d" /etc/hosts
  echo "127.0.1.1 armos.localdomain armos" >> /etc/hosts

  # Console keymap (X keyboard layout is configured separately)
  cat > /etc/conf.d/keymaps <<EOF
keymap="us"
windowkeys="YES"
EOF

  # Services
  rc-update add dbus default
  rc-update add elogind default
  rc-update add polkitd default 2>/dev/null || true
  rc-update add NetworkManager default
  rc-update add bluetooth default
  rc-update add chronyd default
  rc-update add sshd default
  rc-update del net.eth0 default 2>/dev/null || true

  # Root password for the M0 console image (changed/disabled for release)
  echo "root:armos" | chpasswd

  # Serial console for QEMU
  if ! grep -q "ttyS0" /etc/inittab; then
    cat >> /etc/inittab <<EOF

# ARMOS serial console
s0:12345:respawn:/sbin/agetty -L 115200 ttyS0 vt100
EOF
  fi

  # Minimal fstab for the M0 root disk
  cat > /etc/fstab <<EOF
/dev/vda    /        ext4    defaults,noatime    0 1
proc        /proc    proc    defaults            0 0
sysfs       /sys     sysfs   defaults            0 0
tmpfs       /run     tmpfs   defaults            0 0
EOF

  # Generic initramfs with virtio and storage support
  kver=$(ls /lib/modules | sort -V | tail -1)
  echo "Kernel: $kver"
  dracut --force --no-hostonly \
    --add 'plymouth' \
    --add-drivers "virtio_blk virtio_pci virtio_net ext4 drm bochs" \
    --kver "$kver" "/boot/initramfs-${kver}.img"

  # Stable names for bootloaders and the installer.
  ln -sf "vmlinuz-${kver}" /boot/vmlinuz
  ln -sf "initramfs-${kver}.img" /boot/initramfs.img

  echo "Base configuration complete"
'

log "Base system ready."
log "Kernel: $(ls "$ROOTFS"/boot/vmlinuz-* 2>/dev/null | tail -1)"
log "Initramfs: $(ls "$ROOTFS"/boot/initramfs-*.img 2>/dev/null | tail -1)"
log "Next: make qemu-base"
