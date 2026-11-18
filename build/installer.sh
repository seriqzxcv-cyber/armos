#!/usr/bin/env bash
# M2: install Calamares and the ARMOS installer configuration into the rootfs.
set -euo pipefail
source /armos/build/lib.sh

require_root
[[ -f "$ROOTFS/etc/gentoo-release" ]] || die "Run 'make bootstrap' first"
ensure_configs
setup_mounts

log "Installing Calamares (Qt6, this can take a while) ..."
in_chroot '
  emerge --ask=n --quiet-build=y --noreplace app-admin/calamares
'

log "Installing ARMOS Calamares configuration ..."
CAL_SRC="$PROJECT_ROOT/live/calamares"
CAL_DST="$ROOTFS/etc/calamares"
BR_DST="$ROOTFS/usr/share/calamares/branding/armos"

rm -rf "$CAL_DST" "$BR_DST"
install -d "$CAL_DST/modules" "$CAL_DST/branding" "$BR_DST"
cp -a "$CAL_SRC/settings.conf" "$CAL_DST/settings.conf"
cp -a "$CAL_SRC/modules/." "$CAL_DST/modules/"
cp -a "$CAL_SRC/branding/armos/." "$CAL_DST/branding/armos/"
cp -a "$CAL_SRC/branding/armos/." "$BR_DST/"

log "Installing branding images ..."
for dst in "$BR_DST" "$CAL_DST/branding/armos"; do
  install -m 0644 "$PROJECT_ROOT/assets/generated/armos-logo-256.png" "$dst/productLogo.png"
  install -m 0644 "$PROJECT_ROOT/assets/generated/armos-logo-128.png" "$dst/productIcon.png"
  install -m 0644 "$PROJECT_ROOT/overlay/x11-themes/armos-branding/files/root/usr/share/backgrounds/armos/armos-gen-1080p.png" "$dst/productWelcome.png"
done

log "Installing post-install hook ..."
install -Dm755 "$PROJECT_ROOT/live/installer/post-install.sh" \
  "$ROOTFS/usr/local/bin/armos-postinstall"

log "Calamares installed."
log "Next: make live (includes the installer in the ISO)"
