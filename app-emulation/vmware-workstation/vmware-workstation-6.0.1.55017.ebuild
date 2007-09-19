# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-workstation/vmware-workstation-5.5.3.34685.ebuild,v 1.4 2006/12/14 18:35:44 wolf31o2 Exp $

inherit vmware eutils versionator

MY_PN="VMware-workstation-$(replace_version_separator 3 - $PV)"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="
	x86? (
		mirror://vmware/software/wkst/${MY_PN}.i386.tar.gz
		http://download.softpedia.ro/linux/${MY_PN}.i386.tar.gz )
	amd64? (
		mirror://vmware/software/wkst/${MY_PN}.x86_64.tar.gz
		http://download.softpedia.ro/linux/${MY_PN}.x86_64.tar.gz )
	mirror://gentoo/${ANY_ANY}.tar.gz
	http://platan.vc.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://platan.vc.cvut.cz/ftp/pub/vmware/obsolete/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/obsolete/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/obsolete/${ANY_ANY}.tar.gz"

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
	~app-emulation/vmware-modules-1.0.0.16
	!<app-emulation/vmware-modules-1.0.0.16
	!>=app-emulation/vmware-modules-1.0.0.17
	>=dev-lang/perl-5
	sys-apps/pciutils"

S=${WORKDIR}/vmware-distrib

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
	einfo "${ANY_ANY}.tar.gz is also necessary for compilation"
	einfo "but should already have been fetched."
}

src_install() {
	vmware_src_install

	ICONDIR=/opt/vmware/workstation/lib/share/icons/hicolor/scalable/apps/
	make_desktop_entry vmware "VMWare Workstation" ${ICONDIR}/${PN}.svg System
	make_desktop_entry vmplayer "VMWare Player" ${ICONDIR}/vmware-player.svg System

	# Nasty hack to ensure the EULA is included
	insinto /opt/vmware/workstation/lib/share
	newins doc/EULA EULA.txt
}
