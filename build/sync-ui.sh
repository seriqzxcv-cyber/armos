#!/usr/bin/env bash
# Copy the ARMOS UI sources from the overlay into the prepared rootfs.
# Re-runnable; all paths are absolute inside the privileged builder container.
set -euo pipefail

ROOTFS=${ROOTFS:-/armos/build/rootfs}
OVERLAY=/armos/overlay
BRANDING="$OVERLAY/x11-themes/armos-branding/files/root"
TOOLS="$OVERLAY/app-admin/armos-tools/files"
R="$ROOTFS"

[[ -d "$R/etc" ]] || { echo "no rootfs at $R" >&2; exit 1; }

# Branding: new GEN wallpaper, session defaults and GTK/panel styling.
for png in armos-gen-4k.png armos-gen-1600p.png armos-gen-1080p.png; do
  install -Dm644 "$BRANDING/usr/share/backgrounds/armos/$png" \
    "$R/usr/share/backgrounds/armos/$png"
done
install -Dm755 "$BRANDING/usr/bin/armos-desktop-defaults" \
  "$R/usr/bin/armos-desktop-defaults"
install -Dm644 "$BRANDING/usr/share/armos/config/xfce4/xfce4-desktop.xml" \
  "$R/usr/share/armos/config/xfce4/xfce4-desktop.xml"
install -Dm644 "$BRANDING/usr/share/armos/config/xfce4/xsettings.xml" \
  "$R/usr/share/armos/config/xfce4/xsettings.xml"
install -Dm644 "$BRANDING/usr/share/armos/config/lightdm/lightdm-gtk-greeter.conf" \
  "$R/usr/share/armos/config/lightdm/lightdm-gtk-greeter.conf"
install -Dm644 "$BRANDING/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" \
  "$R/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"
install -Dm644 "$BRANDING/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml" \
  "$R/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
install -Dm644 "$BRANDING/etc/xdg/mimeapps.list" "$R/etc/xdg/mimeapps.list"
install -Dm644 "$BRANDING/etc/gtk-3.0/gtk.css" \
  "$R/etc/gtk-3.0/gtk.css"
install -Dm644 "$BRANDING/boot/grub/themes/armos/theme.txt" \
  "$R/boot/grub/themes/armos/theme.txt"
install -Dm644 "$BRANDING/boot/grub/themes/armos/background.png" \
  "$R/boot/grub/themes/armos/background.png"
for asset in armos.plymouth armos.script background.png logo.png bar-bg.png bar-fg.png; do
  install -Dm644 "$BRANDING/usr/share/plymouth/themes/armos/$asset" \
    "$R/usr/share/plymouth/themes/armos/$asset"
done

# ARMOS tools: shared palette and the new desktop widget.
install -Dm644 "$TOOLS/armos_common.py" "$R/usr/lib/armos/armos_common.py"
install -Dm755 "$TOOLS/armos-desklet" "$R/usr/bin/armos-desklet"
install -Dm644 "$TOOLS/armos-desklet-autostart.desktop" \
  "$R/etc/xdg/autostart/armos-desklet.desktop"
for app in armos armos-settings armos-quicksettings armos-first-run; do
  install -Dm755 "$TOOLS/$app" "$R/usr/bin/$app"
done
for desktop in armos-settings.desktop armos-quicksettings.desktop; do
  install -Dm644 "$TOOLS/$desktop" "$R/usr/share/applications/$desktop"
done
install -Dm644 "$TOOLS/armos-first-run-autostart.desktop" \
  "$R/etc/xdg/autostart/armos-first-run.desktop"

chown -R 0:0 \
  "$R/usr/share/backgrounds/armos" \
  "$R/usr/bin/armos-desktop-defaults" \
  "$R/usr/bin/armos" \
  "$R/usr/bin/armos-desklet" \
  "$R/usr/bin/armos-settings" \
  "$R/usr/bin/armos-quicksettings" \
  "$R/usr/bin/armos-first-run" \
  "$R/usr/share/applications/armos-settings.desktop" \
  "$R/usr/share/applications/armos-quicksettings.desktop" \
  "$R/usr/lib/armos/armos_common.py" \
  "$R/etc/gtk-3.0/gtk.css" \
  "$R/etc/xdg/autostart" \
  "$R/etc/xdg/xfce4/xfconf/xfce-perchannel-xml" \
  "$R/etc/xdg/mimeapps.list" \
  "$R/usr/share/armos/config" \
  "$R/boot/grub/themes/armos" \
  "$R/usr/share/plymouth/themes/armos"

echo "[ARMOS] UI files synced into $R"
