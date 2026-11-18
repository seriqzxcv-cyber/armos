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
- [x] GUI verification in QEMU (autologin, XFCE, wallpaper, ARMOS desklet)
- [x] MIME associations, Super+C / Super+S shortcuts, XDG folders for live user
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

## M5 — собственное ядро (по запросу пользователя, параллельно с M1–M4)

Выбран **вариант 3**: полностью своё ядро из исходников с собственными патчами
и брендингом, а не `gentoo-kernel` / `gentoo-sources` с готовым конфигом.

- [x] Ванильные исходники `linux-6.18` распакованы (кэш distfiles)
- [x] Патч `armos-branding.patch` (баннер ARMOS при загрузке)
- [x] Своя иконка загрузки `logo_linux_clut224.ppm` (монорамма A, 224 цвета)
- [x] Свой `.config`: `configs/kernel/config-6.18-armos` (defconfig + virtio,
      ext4/squashfs/overlayfs/loop/dm-crypt, USB/NVMe/AHCI, DRM, аудио, сеть)
- [ ] Сборка `vmlinuz` + модулей (`build/kernel.sh`)
- [ ] dracut-initramfs для своего ядра
- [ ] Проверка загрузки в QEMU (BIOS и UEFI) и на реальном железе
- [ ] Переключение `base.sh` / `live.sh` на своё ядро, пересборка ISO
- [ ] Опциональная урезка firmware (2 ГБ → ~400–600 МБ) после проверки железа
- [ ] `gentoo-kernel-bin` оставить как запасной вариант для отката
