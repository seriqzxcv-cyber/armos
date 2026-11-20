# ARMOS

**ARMOS 1.0 "GEN"** — source-based Linux distribution built on Gentoo.

Status: **M0 — base system done, M1 — desktop done**. M2–M4 (installer, live
ISO, release) are in progress; the custom ARMOS kernel (M5) is being built in
parallel. See [docs/STATUS.md](docs/STATUS.md) for the full checklist.

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
make sync-ui     # refresh ARMOS UI files and desktop defaults in rootfs
make image       # rebuild build/armos-base.img from rootfs (SIZE=12G)
make installer   # Calamares + ARMOS installer configuration
make live        # squashfs + GRUB hybrid ISO
make qemu-live   # boot the live ISO (BIOS)
UEFI=1 make qemu-live
```

`make live` builds a **slim** image by default (`LIVE_SLIM=1`): the squashfs
omits build toolchains, the Portage tree, unused firmware/locales/fonts/icons
and the fallback kernel's modules, and uses zstd level 19. This keeps the ISO
small enough for a single GitHub release asset. Use `LIVE_SLIM=0 make live` for
an untrimmed image and `ZSTD_LEVEL=22` for maximum (slow) compression.

Custom ARMOS kernel (variant 3, see [docs/KERNEL.md](docs/KERNEL.md)):

```bash
make kernel-config KERNEL_DIR=/path/without/spaces/linux-6.18
make kernel KERNEL_DIR=/path/without/spaces/linux-6.18
make kernel-install
KVER=6.18.0-armos make qemu-base
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
