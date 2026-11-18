EAPI=8

DESCRIPTION="ARMOS desktop tools: Welcome, Center, Store, Updater"
HOMEPAGE="https://armos.local/"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

S="${WORKDIR}"

RDEPEND="
	dev-python/pygobject:3
	x11-libs/gtk+:3
	x11-themes/armos-branding
	sys-auth/polkit
"

src_install() {
	insinto /usr/lib/armos
	doins "${FILESDIR}/armos_common.py"

	dobin \
		"${FILESDIR}/armos-welcome" \
		"${FILESDIR}/armos-center" \
		"${FILESDIR}/armos-store" \
		"${FILESDIR}/armos-updater" \
		"${FILESDIR}/armos-desklet"

	insinto /usr/share/applications
	doins \
		"${FILESDIR}/armos-welcome.desktop" \
		"${FILESDIR}/armos-center.desktop" \
		"${FILESDIR}/armos-store.desktop" \
		"${FILESDIR}/armos-updater.desktop"

	insinto /etc/xdg/autostart
	newins "${FILESDIR}/armos-welcome-autostart.desktop" armos-welcome.desktop
	newins "${FILESDIR}/armos-desklet-autostart.desktop" armos-desklet.desktop
}
