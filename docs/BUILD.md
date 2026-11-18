# Building ARMOS

## Prerequisites

- Linux host (Fedora 44 tested).
- Docker (the build uses a privileged `gentoo/stage3` container).
- QEMU (`qemu-system-x86_64`) for testing.
- ~100 GB free space.
- 8+ GB RAM; 16 GB recommended.

The project path may contain spaces and non-ASCII characters; all scripts quote
paths. If Docker cannot access the bind mount on an SELinux host, add `:z` to the
volume in `build/container.sh` or run Docker with `--security-opt label=disable`.

## First build

```bash
cd armos
make bootstrap
make base
make qemu-base
```

`make bootstrap` downloads the Gentoo stage3 tarball and Portage snapshot into
`build/cache/`, extracts them into `build/rootfs/`, installs the ARMOS Portage
configuration and selects the generic desktop profile (Gentoo has no dedicated
XFCE profile; XFCE is pulled in by the package set).

`make base` installs the kernel, firmware, NetworkManager, OpenRC services and
builds a generic initramfs. It uses `gentoo-kernel-bin` for M0; M1 switches to a
custom `gentoo-kernel` config.

`make qemu-base` creates a raw ext4 image from the rootfs (without loop devices)
and boots it with the kernel and initramfs from the image. The serial console is
`ttyS0`; log in as `root` / `armos`. Use `GUI=1 make qemu-base` for a QEMU
window and log in on `tty1`.

## Live ISO

```bash
make desktop    # XFCE, LightDM, apps, branding
make installer  # Calamares + ARMOS configuration
make live       # squashfs + hybrid BIOS/UEFI ISO in out/
make qemu-live  # BIOS boot
UEFI=1 make qemu-live
```

The ISO uses a flat squashfs (`/LiveOS/squashfs.img`) mounted by dracut's
`dmsquash-live` through overlayfs. The live session runs from RAM-backed overlay;
changes are lost on shutdown unless persistence is enabled.

### Persistence

Prepare an ext4 partition with the label `ARMOS_PERSIST`:

```bash
sudo armos-persistence-init /dev/sdXN
```

Then boot the "Live with persistence" GRUB entry. The helper creates
`/LiveOS/overlay` and `/LiveOS/ovlwork` as expected by dracut.

### QEMU options

`qemu/run-live.sh` supports `UEFI=1`, `MEM=8192`, `CPUS=4`, `HEADLESS=1`, and
`PERSIST=path/to/disk.img` for persistence testing.

## Entering the build chroot

```bash
make shell
```

This runs a privileged container, bind-mounts `/proc`, `/sys`, `/dev`, `/run`,
the distfiles cache and the binpkg cache, then chroots into `build/rootfs`.

## Caches

- `build/cache/stage3-*.tar.xz` — stage3 tarball.
- `build/cache/portage-latest.tar.xz` — Portage tree snapshot.
- `build/cache/distfiles/` — source tarballs (shared across rebuilds).
- `build/cache/binpkgs/` — binary packages (`FEATURES=buildpkg`).

Use `make distclean` to remove the rootfs and caches.

## Troubleshooting

- **`/bin/bash: ...: No such file or directory`** — the project path contains
  spaces; ensure Makefile recipes quote `$(RUN)` and `$(PROJECT)`.
- **Docker permission denied on the bind mount** — SELinux; see above.
- **`mount: permission denied`** — the container must run with `--privileged`.
- **Out of memory during LibreOffice/Firefox** — lower `MAKEOPTS` in
  `configs/portage/make.conf` (e.g. `-j4`) or use `--jobs=1`.
- **No network in chroot** — check `/etc/resolv.conf` inside the rootfs; the
  build scripts copy the host resolver into the chroot before emerging.
- **Kernel boots but root not found** — verify virtio/ext4 drivers are in the
  initramfs; rebuild with `dracut --no-hostonly`.
