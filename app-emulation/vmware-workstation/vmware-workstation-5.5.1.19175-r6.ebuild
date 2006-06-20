# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit vmware eutils

MY_P="VMware-workstation-5.5.1-19175"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="mirror://vmware/software/wkst/${MY_P}.tar.gz
	http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/obselete/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/obselete/${ANY_ANY}.tar.gz"

LICENSE="vmware"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""
RESTRICT="strip"

# vmware-workstation should not use virtual/libc as this is a 
# precompiled binary package thats linked to glibc.
RDEPEND="sys-libs/glibc
	amd64? (
		app-emulation/emul-linux-x86-gtklibs )
	x86? (
		|| (
			(
				x11-libs/libXrandr
				x11-libs/libXcursor
				x11-libs/libXinerama
				x11-libs/libXi )
			virtual/x11 )
		virtual/xft )
	!app-emulation/vmware-player
	!app-emulation/vmware-server
	~app-emulation/vmware-modules-1.0.0.13
	>=dev-lang/perl-5
	sys-apps/pciutils"

S=${WORKDIR}/vmware-distrib

RUN_UPDATE="no"

dir=/opt/vmware/workstation
Ddir=${D}/${dir}

src_install() {
	not-vmware_src_install

#	dosed 's/mknod -m 600/mknod -m 660/' /etc/vmware/init.d/vmware || die
#	dosed '/c 119 "$vHubNr"/ a\
#		chown root:vmware /dev/vmnet*\
#		' /etc/vmware/init.d/vmware || die
}
