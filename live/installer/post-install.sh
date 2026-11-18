#!/bin/sh
# ARMOS post-install hook. Runs inside the target system by Calamares.
set -eu

echo "[armos] post-install: services"
for svc in dbus elogind polkitd NetworkManager bluetooth chronyd lightdm; do
    rc-update add "$svc" default 2>/dev/null || true
done

echo "[armos] post-install: removing live session account"
if id live >/dev/null 2>&1; then
    userdel -r live 2>/dev/null || true
fi
rm -f /etc/sudoers.d/99-live

# Autologin is a live-media feature only.
if [ -f /etc/lightdm/lightdm.conf ]; then
    sed -i -e '/^autologin-user=/d' -e '/^autologin-user-timeout=/d' /etc/lightdm/lightdm.conf
fi

if [ ! -s /etc/hostname ]; then
    echo "armos-pc" > /etc/hostname
fi

echo "[armos] post-install: initramfs"
kver=$(ls /lib/modules 2>/dev/null | sort -V | tail -1)
if [ -n "$kver" ]; then
    dracut --force --hostonly --kver "$kver" "/boot/initramfs-${kver}.img"
    ln -sf "vmlinuz-${kver}" /boot/vmlinuz
    ln -sf "initramfs-${kver}.img" /boot/initramfs.img
fi

echo "[armos] post-install: GRUB configuration"
if [ -f /etc/default/grub ]; then
    if grep -q "^GRUB_THEME=" /etc/default/grub; then
        sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"/boot/grub/themes/armos/theme.txt\"|" /etc/default/grub
    else
        echo "GRUB_THEME=\"/boot/grub/themes/armos/theme.txt\"" >> /etc/default/grub
    fi
    sed -i "s|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR=\"ARMOS\"|" /etc/default/grub
fi
if command -v grub-mkconfig >/dev/null 2>&1; then
    grub-mkconfig -o /boot/grub/grub.cfg || true
fi

if [ -f /usr/share/armos/os-release ]; then
    cp /usr/share/armos/os-release /etc/os-release
fi

echo "[armos] post-install: done"
