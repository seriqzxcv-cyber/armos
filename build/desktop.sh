#!/usr/bin/env bash
# M1: XFCE desktop, LightDM, applications, Russian locale, branding.
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"
ensure_configs
setup_mounts

log "Installing XFCE and desktop applications (long build) ..."
# M1 uses *-bin for Firefox and LibreOffice to keep the first ISO build within
# a reasonable time/memory budget. Source builds can replace them later from
# the same ebuilds (www-client/firefox, app-office/libreoffice).
in_chroot '
  emerge --ask=n --quiet-build=y --noreplace \
    xfce-base/xfce4-meta \
    xfce-extra/xfce4-whiskermenu-plugin \
    xfce-extra/xfce4-pulseaudio-plugin \
    xfce-extra/xfce4-screenshooter \
    xfce-extra/xfce4-taskmanager \
    xfce-extra/xfce4-notifyd \
    xfce-extra/xfce4-clipman-plugin \
    xfce-base/xfce4-power-manager \
    xfce-extra/thunar-archive-plugin \
    xfce-extra/thunar-media-tags-plugin \
    xfce-base/thunar-volman \
    x11-terms/xfce4-terminal \
    app-editors/mousepad \
    media-gfx/ristretto \
    media-video/parole \
    app-arch/xarchiver \
    app-admin/armos-tools \
    x11-themes/armos-branding \
    sys-boot/plymouth \
    x11-misc/lightdm \
    x11-misc/lightdm-gtk-greeter \
    x11-themes/papirus-icon-theme \
    x11-themes/arc-theme \
    media-fonts/noto \
    media-fonts/noto-emoji \
    media-fonts/dejavu \
    media-fonts/liberation-fonts \
    media-fonts/fira-sans \
    media-fonts/jetbrains-mono \
    media-libs/mesa \
    x11-base/xorg-server \
    x11-base/xorg-drivers \
    x11-apps/xinit \
    x11-misc/xkeyboard-config \
    x11-drivers/xf86-input-libinput \
    media-sound/pavucontrol \
    media-sound/alsa-utils \
    media-video/pipewire \
    media-video/wireplumber \
    net-wireless/blueman \
    www-client/firefox-bin \
    app-office/libreoffice-bin \
    media-video/vlc \
    media-gfx/gimp \
    app-text/atril \
    gnome-base/gvfs \
    gnome-extra/polkit-gnome \
    sys-fs/udisks \
    sys-power/upower \
    net-print/cups \
    dev-vcs/git
'

log "Configuring X keyboard, LightDM and services ..."
bash /armos/build/desktop-config.sh

log "Desktop stage complete."
log "Next: test in QEMU with a graphical console, then build the live ISO."
