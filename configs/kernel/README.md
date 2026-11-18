# Kernel configuration (M1+)

For M0 the build uses `sys-kernel/gentoo-kernel-bin` to get a bootable base
quickly. M1 will switch to `sys-kernel/gentoo-kernel` (6.18 LTS) with a
savedconfig covering:

- virtio (blk, net, pci, console), AHCI, NVMe, USB storage
- ext4, btrfs, xfs, vfat, iso9660, squashfs, overlayfs, loop
- dm-crypt, LUKS, LVM, mdraid
- amdgpu, i915, nouveau, radeon, virtio-gpu, qxl, vmwgfx
- Realtek/Intel Wi-Fi, Bluetooth, HID, HDA/SOF audio, webcams
- EFI stub, framebuffer, EFI vars

The resulting config will be stored as `configs/kernel/config-6.18`.
