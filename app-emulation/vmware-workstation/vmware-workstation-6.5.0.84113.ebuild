# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-workstation/vmware-workstation-6.0.2.59824.ebuild,v 1.1 2007/11/25 12:50:31 ikelos Exp $

inherit vmware eutils versionator fdo-mime gnome2-utils

MY_PN="VMware-workstation-e.x.p-$(get_version_component_range 4 $PV)"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="
	x86? (
		mirror://vmware/software/wkst/${MY_PN}.i386.tar.gz
		http://download.softpedia.ro/linux/${MY_PN}.i386.tar.gz )
	amd64? (
		mirror://vmware/software/wkst/${MY_PN}.x86_64.tar.gz
		http://download.softpedia.ro/linux/${MY_PN}.x86_64.tar.gz )
	"

LICENSE="vmware"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""
RESTRICT="strip fetch"

# vmware-workstation should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
RDEPEND="sys-libs/glibc
	amd64? (
		x11-libs/libXrandr
		x11-libs/libXcursor
		x11-libs/libXinerama
		x11-libs/libXi
		x11-libs/libview
		dev-cpp/libsexymm
		dev-cpp/cairomm
		dev-cpp/libgnomecanvasmm
		virtual/xft )
	x86? (
		x11-libs/libXrandr
		x11-libs/libXcursor
		x11-libs/libXinerama
		x11-libs/libXi
		x11-libs/libview
		dev-cpp/libsexymm
		virtual/xft )
	!app-emulation/vmware-player
	!app-emulation/vmware-server
	~app-emulation/vmware-modules-1.0.0.19
	!<app-emulation/vmware-modules-1.0.0.19
	!>=app-emulation/vmware-modules-1.0.0.20
	>=dev-lang/perl-5
	sys-apps/pciutils"

S=${WORKDIR}/vmware-distrib

ANY_ANY=""
RUN_UPDATE="no"

dir=/opt/vmware/workstation
Ddir=${D}/${dir}

QA_TEXTRELS_x86="${dir:1}/lib/lib/libgdk-x11-2.0.so.0/libgdk-x11-2.0.so.0"
QA_EXECSTACK_x86="${dir:1}/bin/vmnet-bridge
	${dir:1}/bin/vmnet-dhcpd
	${dir:1}/bin/vmnet-natd
	${dir:1}/bin/vmnet-netifup
	${dir:1}/bin/vmnet-sniffer
	${dir:1}/bin/vmware-loop
	${dir:1}/bin/vmware-ping
	${dir:1}/bin/vmware-vdiskmanager
	${dir:1}/lib/bin/vmware
	${dir:1}/lib/bin/vmware-vmx
	${dir:1}/lib/bin/vmrun
	${dir:1}/lib/bin/vmplayer
	${dir:1}/lib/bin-debug/vmware-vmx
	${dir:1}/lib/lib/libpixops.so.2.0.1/libpixops.so.2.0.1"

QA_TEXTRELS_amd64="${dir:1}/lib/lib/libgdk-x11-2.0.so.0/libgdk-x11-2.0.so.0"
QA_EXECSTACK_amd64="${dir:1}/bin/vmnet-bridge
	${dir:1}/bin/vmnet-dhcpd
	${dir:1}/bin/vmnet-natd
	${dir:1}/bin/vmnet-netifup
	${dir:1}/bin/vmnet-sniffer
	${dir:1}/bin/vmware-loop
	${dir:1}/bin/vmware-ping
	${dir:1}/bin/vmware-vdiskmanager
	${dir:1}/lib/bin/vmware
	${dir:1}/lib/bin/vmware-vmx
	${dir:1}/lib/bin/vmrun
	${dir:1}/lib/bin/vmplayer
	${dir:1}/lib/bin-debug/vmware-vmx
	${dir:1}/lib/lib/libpixops.so.2.0.1/libpixops.so.2.0.1"

pkg_setup() {
	if use x86; then
		MY_P="${MY_PN}.i386"
	elif use amd64; then
		MY_P="${MY_PN}.x86_64"
	fi

	if ! built_with_use ">=dev-cpp/gtkmm-2.4" accessibility ; then
		eerror "Rebuild dev-cpp/gtkmm with USE=\"accessibility\""
		die "VMware workstation only works with gtkmm built with USE=\"accessibility\"."
	fi

	vmware_pkg_setup
}

pkg_nofetch() {
	if use x86; then
		MY_P="${MY_PN}.i386"
	elif use amd64; then
		MY_P="${MY_PN}.x86_64"
	fi

	einfo "Please download the ${MY_P}.tar.gz at ${HOMEPAGE}"
	if [ "${ANY_ANY}" != "" ]; then
		einfo "${ANY_ANY}.tar.gz is also necessary for compilation"
		einfo "but should already have been fetched."
	fi
}

src_install() {
	vmware_src_install

	# move the icons into a location where DEs will find it:
	ICONDIR=/opt/vmware/workstation/lib/share/icons/hicolor
	rm ${D}${ICONDIR}/index.theme
	mkdir -p ${D}/usr/share/icons
	mv ${D}${ICONDIR} ${D}/usr/share/icons
	ln -s /usr/share/icons/hicolor ${D}${ICONSDIR}

	# install .desktop files:
	insinto /usr/share/applications
	doins ${FILESDIR}/vmware-workstation.desktop
	doins ${FILESDIR}/vmware-player.desktop

	# Nasty hack to ensure the EULA is included
	insinto /opt/vmware/workstation/lib/share
	newins doc/EULA EULA.txt
}

pkg_preinst() {
	vmware_pkg_preinst
	gnome2_icon_savelist
}

pkg_postinst() {
	vmware_pkg_postinst
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}

pkg_postrm() {
	vmware_pkg_postrm
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
