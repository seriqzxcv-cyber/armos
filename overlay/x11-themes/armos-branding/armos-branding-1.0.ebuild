EAPI=8

DESCRIPTION="ARMOS branding: logo, wallpapers, XFCE/LightDM/GRUB/Plymouth defaults"
HOMEPAGE="https://armos.local/"
LICENSE="CC-BY-SA-4.0"
SLOT="0"
KEYWORDS="amd64"
IUSE=""

RDEPEND="
	x11-themes/arc-theme
	x11-themes/papirus-icon-theme
	media-fonts/noto
	media-fonts/fira-sans
	media-fonts/jetbrains-mono
"

S="${WORKDIR}"

src_install() {
	cp -a "${FILESDIR}/root/." "${ED}/" || die "failed to install branding files"
	fperms 0755 /usr/bin/armos-desktop-defaults
}
