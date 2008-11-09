# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-server-console/vmware-server-console-1.0.5.80187.ebuild,v 1.4 2008/04/26 15:40:42 ikelos Exp $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit eutils versionator vmware

MY_PN=${PN/vm/VM}
MY_PV=$(replace_version_separator 3 '-')
MY_P="${MY_PN}-${MY_PV}"
FN="VMware-server-linux-client-${MY_PV}"
S="${WORKDIR}/${PN}-distrib"

DESCRIPTION="VMware Remote Console for Linux"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="mirror://vmware/software/vmserver/${FN}.zip"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="~amd64 ~x86"
RESTRICT="strip"

DEPEND=">=sys-libs/glibc-2.3.5
	virtual/os-headers
	>=dev-lang/perl-5
	>=sys-apps/portage-2.0.54
	app-arch/unzip"

# vmware-server-console should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
RDEPEND=">=sys-libs/glibc-2.3.5
	amd64? ( app-emulation/emul-linux-x86-gtklibs )
	!amd64? ( x11-libs/libSM
		x11-libs/libICE
		x11-libs/libX11
		x11-libs/libXau
		x11-libs/libXcursor
		x11-libs/libXdmcp
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXft
		x11-libs/libXi
		x11-libs/libXrandr
		x11-libs/libXrender
		x11-libs/libXt
		x11-libs/libXtst )
	>=dev-lang/perl-5
	!<sys-apps/dbus-0.62"

etcdir="/etc/${PN}"
ANY_ANY=""

pkg_setup() {
	vmware_pkg_setup
	enewgroup "${VMWARE_GROUP}"
}

src_unpack() {
	cd "${WORKDIR}"
	unpack ${A}
	unpack ./${MY_P}.tar.gz
}

src_install() {
	echo 'libdir = "'${VMWARE_INSTALL_DIR}'/lib"' > etc/config
	vmware_src_install

	# Fix an ugly GCC error on start
	rm -f "${D}${VMWARE_INSTALL_DIR}/lib/lib/libgcc_s.so.1/libgcc_s.so.1"
	make_desktop_entry ${PN} "VMWare Remote Console" ${PN}.png System

	dodir /usr/bin
	dosym ${VMWARE_INSTALL_DIR}/bin/${PN} /usr/bin/${PN}
}

pkg_config() {
	einfo "Running ${ROOT}${dir}/bin/vmware-config-server-console.pl"
	"${ROOT}${dir}/bin/vmware-config-server-console.pl"
}
