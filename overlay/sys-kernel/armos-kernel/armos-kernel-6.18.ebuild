EAPI=8

DESCRIPTION="ARMOS custom kernel 6.18 with ARMOS branding and minimal config"
HOMEPAGE="https://armos.local/"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

SRC_URI="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.tar.xz"
S="${WORKDIR}/linux-6.18"

DEPEND="
	sys-devel/bc
	sys-devel/flex
	sys-devel/bison
	sys-devel/make
"
RDEPEND=""

src_prepare() {
	default

	# ARMOS boot banner and boot logo.
	patch -p1 < "${FILESDIR}/armos-branding.patch" || die "branding patch failed"
	cp "${FILESDIR}/logo_linux_clut224.ppm" \
		drivers/video/logo/logo_linux_clut224.ppm || die "logo copy failed"

	# Our own configuration instead of the distribution one.
	install -m644 "${FILESDIR}/config-6.18-armos" .config || die "config copy failed"
	emake olddefconfig
}

src_compile() {
	emake -j"$(nproc)" bzImage modules
}

src_install() {
	local kver="6.18.0-armos"

	install -Dm644 arch/x86/boot/bzImage \
		"${ED}/boot/vmlinuz-${kver}" || die
	install -Dm644 System.map "${ED}/boot/System.map-${kver}" || die
	install -Dm644 .config "${ED}/boot/config-${kver}" || die

	emake INSTALL_MOD_PATH="${ED}" INSTALL_MOD_STRIP=1 modules_install

	# Keep the exact config in /usr/src for later rebuilds.
	insinto "/usr/src/armos-kernel-${kver}"
	doins .config "${FILESDIR}/armos-branding.patch" \
		"${FILESDIR}/logo_linux_clut224.ppm"
}
