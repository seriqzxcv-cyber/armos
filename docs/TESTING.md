# ARMOS testing

## 1. Base image (M0)

```bash
make base
make qemu-base
```

Expected:

- GRUB/kernel messages, then an OpenRC boot sequence.
- `armostest login:` (or the hostname from `/etc/hostname`) on `ttyS0`.
- Log in as `root` / `armos`.
- `rc-status` shows `dbus`, `elogind`, `polkitd`, `NetworkManager`,
  `bluetooth`, `chronyd`.
- `ip a` shows `eth0` (DHCP from QEMU user networking).
- `uname -r` matches a kernel in `/lib/modules`.

Quick checks:

```bash
ls -l /boot/vmlinuz* /boot/initramfs*
rc-service NetworkManager status
ping -c1 10.0.2.2
```

## 2. Desktop image (M1)

```bash
make desktop
REBUILD=1 make qemu-base   # rebuild the ext4 image with the desktop
```

Because the base runner uses `-nographic`, use the live ISO for graphical
checks. For a desktop without an ISO, run QEMU manually with `-display gtk`.

Expected in the live session:

- LightDM autologin as `live` (no password).
- XFCE panel, Arc-Dark theme, Papirus-Dark icons.
- ARMOS wallpaper on the default monitor.
- `us,ru` layout switching with Alt+Shift.
- Russian UI where translations exist (`LANG=ru_RU.UTF-8`).
- ARMOS Welcome starts automatically; Store/Center/Updater open.
- Firefox, LibreOffice, VLC, GIMP, Atril, Thunar, Xarchiver available.

## 3. Live ISO (M1/M2)

```bash
make live
make qemu-live          # BIOS
UEFI=1 make qemu-live   # UEFI
```

Expected:

- Branded GRUB menu with the cyan accent and four entries.
- `dmsquash-live` mounts the squashfs; boot continues from RAM overlay.
- LightDM autologin to XFCE.
- ISO size below 4.5 GB.

Serial console: `-serial mon:stdio`; press `Ctrl-a c` to reach the QEMU
monitor and `quit` to exit.

## 4. Persistence

```bash
qemu-img create -f raw build/persist.img 4G
# boot the live ISO once, then inside the live session:
sudo armos-persistence-init /dev/vdb
```

Alternatively prepare the partition on the host:

```bash
sudo mkfs.ext4 -L ARMOS_PERSIST build/persist.img
sudo mount -o loop build/persist.img /mnt
sudo mkdir -p /mnt/LiveOS/overlay /mnt/LiveOS/ovlwork
sudo umount /mnt
```

Boot the “Live with persistence” entry:

```bash
PERSIST=build/persist.img make qemu-live
```

Create a file in `/home/live`, reboot, and confirm it survived. Changes to
system files should also persist through the overlay.

## 5. Installer (M2)

```bash
make installer
make live
make qemu-live
```

Inside the live session:

1. Start Calamares from ARMOS Welcome.
2. Choose language (Russian is preselected by locale), keyboard `us,ru`.
3. Select “Erase disk” on the second QEMU disk, ext4, no swap.
4. Create a user, set passwords.
5. Install and reboot (remove the ISO from the virtual drive).
6. Verify GRUB theme, LightDM login as the created user, NetworkManager,
   audio (PipeWire), and that the `live` account is gone.

Automated installed-system check:

```bash
qemu-system-x86_64 -machine q35 -m 4096 -smp 4 \
  -drive file=build/armos-installed.img,format=raw,if=virtio \
  -display none -serial mon:stdio
```

## 6. Known limitations

- NVIDIA proprietary drivers are not installed by default; install
  `x11-drivers/nvidia-drivers` from ARMOS Store.
- Plymouth is installed with the ARMOS theme, but the installed initramfs is
  built without the plymouth dracut module in 1.0.
- The local ARMOS ebuild repository is shipped read-only; `auto-sync = no`.
- Builds are unsigned; verify artifacts with the generated SHA256 file.
