# ARMOS status

## M0 — base system

- [x] Stage3 extracted and configured
- [x] Portage profile selected (`default/linux/amd64/23.0/desktop`)
- [x] Kernel + firmware installed (`gentoo-kernel-bin-6.18.63`)
- [x] Base services configured (NetworkManager, elogind, dbus, sshd, chronyd, bluetooth)
- [x] Initramfs built (dracut, 43.6 MB)
- [x] Ext4 image created (`build/armos-base.img`, 8 G)
- [x] QEMU console boot verified (root/armos, Russian locale/MSK)

## M1 — live desktop

- [x] XFCE + LightDM (427/427 packages installed; `display-manager` service
      via `gui-libs/display-manager-init`, `DISPLAYMANAGER="lightdm"`)
- [x] Russian locale and keyboard (`us,ru`, Alt+Shift, Europe/Moscow)
- [x] Firefox, LibreOffice, VLC, GIMP (+ ARMOS Welcome/Center/Store/Updater)
- [x] Branding assets (SVG + rendered PNG)
- [x] Branding applied to XFCE/LightDM/GRUB/Plymouth; neutral dark GTK3 CSS and
      bottom full-width centred panel (`p=12`) installed via `armos-branding`
- [x] Live user `live`/`live` with NOPASSWD sudo, LightDM autologin
- [ ] GUI verification in QEMU ( rebuilding 8 G image with the desktop )
- [ ] squashfs + GRUB hybrid ISO (scripts drafted in `build/live.sh`)
- [ ] QEMU BIOS/UEFI live boot

## M2 — installer

- [ ] Calamares
- [ ] Partitioning + LUKS
- [ ] Post-install script
- [ ] Installed system boot test

## M3 — ecosystem

- [x] ARMOS Welcome (GTK3, live install entry)
- [x] ARMOS Center (settings hub)
- [x] ARMOS Store (curated Portage catalog)
- [x] ARMOS Updater (sync / check / update)
- [ ] Ebuilds built and verified in the image
- [ ] Local binpkg repository

## M4 — release

- [ ] Test matrix
- [ ] SHA256 + docs
- [ ] ISO release

## M5 — собственное ядро (не начинать до завершения M0–M4)

Выбран **вариант 3**: полностью своё ядро из исходников с собственными патчами
и брендингом, а не `gentoo-kernel` / `gentoo-sources` с готовым конфигом.

- [ ] Скопировать исходники ядра в `overlay/sys-kernel/armos-kernel/`
- [ ] Набор патчей ARMOS (в том числе логотип загрузки и `CONFIG_LOCALVERSION="-armos"`)
- [ ] Свой `.config`: только нужные драйверы и ФС (ext4, squashfs, overlayfs, loop,
      isofs, virtio, NVMe/AHCI, USB, i915/amdgpu/nouveau, input, audio)
- [ ] Сборка `vmlinuz` + модулей, dracut-initramfs
- [ ] Проверка загрузки в QEMU (BIOS и UEFI) и на реальном железе
- [ ] Переключение `base.sh` / `live.sh` на своё ядро, пересборка ISO
- [ ] Опциональная урезка firmware (2 ГБ → ~400–600 МБ) после проверки железа
- [ ] `gentoo-kernel-bin` оставить как запасной вариант для отката

**Важно:** работу по M5 не начинать, пока не собрано и не проверено основное
live ISO (M1–M4). Текущие этапы идут на `gentoo-kernel-bin-6.18.63`.
