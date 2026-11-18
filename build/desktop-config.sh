#!/usr/bin/env bash
# M1: apply the ARMOS desktop configuration to an already-populated rootfs.
# Kept separate from desktop.sh so the config can be re-applied (or repaired)
# without re-emerging all 427 desktop packages.
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"
ensure_configs

# When called from desktop.sh the mounts and the cleanup trap are already in
# place; only set them up here when running standalone.
if ! mountpoint -q "$ROOTFS/proc"; then
  setup_mounts
fi

log "Applying ARMOS desktop configuration ..."
in_chroot '
  # Apply ARMOS branding defaults
  if [[ -d /usr/share/armos ]]; then
    rm -f /etc/os-release /etc/issue /etc/motd
    cp /usr/share/armos/os-release /etc/os-release
    cp /usr/share/armos/issue /etc/issue
    cp /usr/share/armos/motd /etc/motd

    install -Dm644 /usr/share/armos/config/lightdm/lightdm-gtk-greeter.conf \
      /etc/lightdm/lightdm-gtk-greeter.conf
    install -Dm644 /usr/share/armos/config/xfce4/xsettings.xml \
      /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
    install -Dm644 /usr/share/armos/config/xfce4/xfwm4.xml \
      /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml
    install -Dm644 /usr/share/armos/config/xfce4/xfce4-desktop.xml \
      /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
    install -Dm644 /usr/share/armos/config/xfce4/keyboard-layout.xml \
      /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/keyboard-layout.xml

    if [[ -f /etc/default/grub ]]; then
      sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"/boot/grub/themes/armos/theme.txt\"|" /etc/default/grub
      grep -q "^GRUB_THEME=" /etc/default/grub || \
        echo "GRUB_THEME=\"/boot/grub/themes/armos/theme.txt\"" >> /etc/default/grub
      sed -i "s|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR=\"ARMOS\"|" /etc/default/grub
    fi

    if [[ -d /etc/plymouth ]]; then
      printf "[Daemon]\nTheme=armos\nShowDelay=0\n" > /etc/plymouth/plymouthd.conf
    fi
  fi

  mkdir -p /etc/X11/xorg.conf.d
  cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "us,ru"
    Option "XkbOptions" "grp:alt_shift_toggle,grp_led:scroll"
EndSection
EOF

  # Gentoo starts display managers through the display-manager OpenRC service,
  # which reads DISPLAYMANAGER from /etc/conf.d/display-manager. LightDM itself
  # has no init script of its own in this release (gui-libs/display-manager-init
  # owns display-manager/xdm), so `rc-update add lightdm` cannot work here.
  sed -i "s|^DISPLAYMANAGER=.*|DISPLAYMANAGER=\"lightdm\"|" /etc/conf.d/display-manager
  grep -q "^DISPLAYMANAGER=\"lightdm\"" /etc/conf.d/display-manager || \
    echo "DISPLAYMANAGER=\"lightdm\"" >> /etc/conf.d/display-manager
  rc-update add display-manager default
  rc-update add cupsd default 2>/dev/null || true

  # Temporary live-style autologin for M1 testing.
  groupadd -f autologin 2>/dev/null || true
  if ! id live >/dev/null 2>&1; then
    live_groups=""
    for g in wheel audio video input usb plugdev lp kvm autologin \
             network scanner lpadmin netdev pipewire users; do
      if getent group "$g" >/dev/null 2>&1; then
        [[ -n "$live_groups" ]] && live_groups="$live_groups,"
        live_groups="$live_groups$g"
      fi
    done
    useradd -m -G "$live_groups" -s /bin/bash live
  fi
  echo "live:live" | chpasswd
  # Standard XDG folders so file dialogs and the desktop look "lived in".
  for dir in Documents Downloads Pictures Music Videos Public Templates; do
    install -d -o live -g live "/home/live/$dir"
  done
  mkdir -p /etc/sudoers.d
  grep -q "^#includedir /etc/sudoers.d" /etc/sudoers || \
    echo "#includedir /etc/sudoers.d" >> /etc/sudoers
  echo "live ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/99-live
  chmod 0440 /etc/sudoers.d/99-live

  # Gentoo does not ship lightdm-session; without an explicit session-wrapper
  # LightDM tries to exec it, the session dies with status 1 and the greeter
  # loops. Use the wrapper from the xinit package that stock Gentoo uses.
  cat > /etc/lightdm/lightdm.conf <<EOF
[LightDM]
logind-check-graphical=false

[Seat:*]
autologin-user=live
autologin-user-timeout=0
autologin-session=xfce
user-session=xfce
greeter-session=lightdm-gtk-greeter
session-wrapper=/etc/lightdm/Xsession
EOF
'

log "Desktop configuration applied."
