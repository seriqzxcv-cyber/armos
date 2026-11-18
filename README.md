# ARMOS

**ARMOS 1.0 "GEN"** — source-based Linux distribution built on Gentoo.

Status: **M0 — base system build in progress**. Desktop, installer and live
ISO scripts are prepared and will run on top of the finished base.

## Goals

- Hybrid BIOS + UEFI live ISO (x86_64).
- XFCE desktop, Russian locale by default.
- Live mode with optional persistence.
- Calamares installer (BIOS/UEFI, ext4/btrfs, LUKS).
- ARMOS Welcome / Center / Store / Updater.
- Custom branding: GRUB, Plymouth, LightDM, XFCE, wallpapers, icons.
- Base apps: Firefox, LibreOffice, VLC, GIMP, Thunar, terminal, archive tools, PDF, screenshots.

## Requirements

- Linux host with Docker (or Podman) and QEMU.
- ~100 GB free disk space for builds, binpkgs and ISO.
- 8+ GB RAM (16 GB recommended for LibreOffice/Firefox builds).

## Build

```bash
make bootstrap   # download stage3 + Portage snapshot, extract, configure
make base        # kernel, firmware, network, base services, initramfs
make qemu-base   # boot the base system in QEMU (serial console; GUI=1 for a window)
```

After M0:

```bash
make desktop     # XFCE, LightDM, apps, locale, branding
make installer   # Calamares + ARMOS installer configuration
make live        # squashfs + GRUB hybrid ISO
make qemu-live   # boot the live ISO (BIOS)
UEFI=1 make qemu-live
```

Credentials used for development:

| System        | Login | Password |
|---------------|-------|----------|
| Base image    | root  | armos    |
| Live session  | live  | live     |

The live session autologins as `live`; the installed system removes that
account and asks for the user created in Calamares.

## Live persistence

```bash
sudo armos-persistence-init /dev/sdXN   # erases the partition
```

Then choose “Live with persistence” in the GRUB menu. Data is stored in
`/LiveOS/overlay` on the ext4 partition labeled `ARMOS_PERSIST`.

## Layout

```
build/      build scripts and container runner
configs/    Portage configuration, kernel config, profile
overlay/    ARMOS ebuilds (branding, welcome, center, store, updater)
live/       dracut, GRUB, Calamares, installer, persistence
assets/     logo, wallpapers, themes
qemu/       QEMU test runners
docs/       architecture and status notes
out/        release artifacts (ISO, checksums)
```

## Notes

- The build runs inside a privileged `gentoo/stage3` container and chroots into
  `build/rootfs`. Root privileges are required inside the container for mounts.
- Host user files remain owned by the host user; the rootfs keeps numeric
  ownership from the stage3 tarball.
- No proprietary NVIDIA driver is installed by default. Firmware and codecs are
  included; NVIDIA is planned as an optional store package.
