# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-player/vmware-player-2.0.2.59824.ebuild,v 1.1 2007/11/25 12:59:44 ikelos Exp $

inherit versionator eutils vmware

S=${WORKDIR}/vmware-player-distrib
MY_PN="VMware-player-$(get_version_component_range 1-3)-$(get_version_component_range 4)"
DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/player/"
SRC_URI="x86? ( mirror://vmware/software/vmplayer/${MY_PN}.i386.tar.gz )
	amd64? ( mirror://vmware/software/vmplayer/${MY_PN}.x86_64.tar.gz )
	http://dev.gentoo.org/~wolf31o2/sources/dump/vmware-libssl.so.0.9.7l.tar.bz2
	mirror://gentoo/vmware-libssl.so.0.9.7l.tar.bz2
	http://dev.gentoo.org/~wolf31o2/sources/dump/vmware-libcrypto.so.0.9.7l.tar.bz2
	mirror://gentoo/vmware-libcrypto.so.0.9.7l.tar.bz2"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="strip"

S=${WORKDIR}/vmware-player-distrib

DEPEND="${RDEPEND} virtual/os-headers
	!app-emulation/vmware-workstation"
# vmware-player should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
RDEPEND="sys-libs/glibc
	amd64? (
		app-emulation/emul-linux-x86-gtklibs )
	x86? (
		x11-libs/libXrandr
		x11-libs/libXcursor
		x11-libs/libXinerama
		x11-libs/libXi
		virtual/xft )
	>=dev-lang/perl-5
	!app-emulation/vmware-workstation
	!app-emulation/vmware-server
	~app-emulation/vmware-modules-1.0.0.17
	!<app-emulation/vmware-modules-1.0.0.17
	!>=app-emulation/vmware-modules-1.0.0.18
	sys-apps/pciutils"

ANY_ANY=""
RUN_UPDATE="no"

dir=/opt/vmware/player
Ddir=${D}/${dir}

QA_TEXTRELS_x86="${dir:1}/lib/lib/libgdk-x11-2.0.so.0/libgdk-x11-2.0.so.0"
QA_EXECSTACK_x86="${dir:1}/bin/vmnet-bridge
	${dir:1}/bin/vmnet-dhcpd
	${dir:1}/bin/vmnet-natd
	${dir:1}/bin/vmnet-netifup
	${dir:1}/bin/vmnet-sniffer
	${dir:1}/bin/vmware-ping
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
	${dir:1}/bin/vmware-ping
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
	vmware_pkg_setup
}

src_install() {
	vmware_src_install

	doicon lib/share/pixmaps/vmware-player.png
	make_desktop_entry vmplayer "VMWare Player" vmware-player.png System

	# Nasty hack to ensure the EULA is included
	insinto /opt/vmware/player/lib/share
	newins doc/EULA EULA.txt
}
