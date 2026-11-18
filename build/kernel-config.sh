#!/usr/bin/env bash
# Create the ARMOS kernel configuration: a small x86_64 defconfig base plus
# everything the live ISO, QEMU and typical desktop hardware need.
set -euo pipefail
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
K="${KERNEL_DIR:-/home/ghost/armos-kernel-work/linux-6.18}"
[[ -f "$K/Makefile" ]] || { echo "kernel tree missing: $K" >&2; exit 1; }

# Gentoo stage3 uses a PIE-by-default toolchain; kernel host programs need -no-pie.
HOST_MAKE=(HOSTCFLAGS="-O2 -fno-pie" HOSTLDFLAGS="-no-pie")
make -C "$K" "${HOST_MAKE[@]}" x86_64_defconfig

cfg="$K/scripts/config"
config_file="$K/.config"
enable() { for symbol in "$@"; do "$cfg" --file "$config_file" --enable "$symbol"; done; }
module() { for symbol in "$@"; do "$cfg" --file "$config_file" --module "$symbol"; done; }
setstr() { "$cfg" --file "$config_file" --set-str "$1" "$2"; }

# Core: initramfs, device tree-independent PC platforms, cgroups, namespaces.
enable DEVTMPFS TMPFS CGROUPS NAMESPACES BLK_DEV_INITRD BLOCK IOSCHED_MQ

# Storage / filesystems used by the live image and the installer.
enable EXT4_FS XFS_FS BTRFS_FS FUSE_FS ISO9660_FS VFAT_FS FAT_FS
enable SQUASHFS OVERLAY_FS LOOP DM_MOD DM_CRYPT
enable SATA_AHCI ATA SCSI NVME
enable USB_CORE USB_XHCI_HCD USB_EHCI_HCD USB_STORAGE

# QEMU / virtio.
enable VIRTIO_PCI VIRTIO_BLK VIRTIO_NET VIRTIO_CONSOLE VIRTIO_BALLOON
enable VIRTIO_GPU DRM_VIRTIO_GPU DRM_BOCHS

# Graphics for real hardware.
enable DRM DRM_KMS_HELPER FB FB_VESA
module DRM_I915 DRM_AMDGPU DRM_NOUVEAU DRM_RADEON
module DRM_QXL DRM_VMWGFX

# Input, audio, networking.
enable HID USBHID I8042 EVDEV
module SND SND_HDA_INTEL SND_USB_AUDIO
module SND_SOC_SOF_PCI
module E1000 E1000E R8169 IWLWIFI ATH10K
enable BLUETOOTH BT_HCIUART BT_USB

# Kernel branding.
# GCC 16 emits new warnings in third-party drivers; do not make them fatal.
"$cfg" --file "$config_file" --disable WERROR
setstr LOCALVERSION "-armos"
enable LOGO LOGO_LINUX_CLUT224

make -C "$K" "${HOST_MAKE[@]}" olddefconfig
cp "$K/.config" "${PROJECT_ROOT}/configs/kernel/config-6.18-armos"
echo "[ARMOS] kernel config written to configs/kernel/config-6.18-armos"
