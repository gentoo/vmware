# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $ Id: $

inherit eutils vmware

MY_P="VMware-workstation-4.5.3-19414"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="mirror://vmware/software/wkst/${MY_P}.tar.gz
	http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/obselete/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/obselete/${ANY_ANY}.tar.gz
	mirror://gentoo/vmware.png"

LICENSE="vmware"
SLOT="0"
KEYWORDS="-*"
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
	~app-emulation/vmware-modules-1.0.0.14
	>=dev-lang/perl-5
	sys-apps/pciutils"

S=${WORKDIR}/vmware-distrib

RUN_UPDATE="no"

dir=/opt/vmware/workstation
Ddir=${D}/${dir}

src_install() {
	not-vmware_src_install
	# We remove the rpath libgdk_pixbuf stuff, to resolve bug #81344.
	perl -pi -e 's#/tmp/rrdharan/out#/opt/vmware/null/#sg' \
		${Ddir}/lib/lib/libgdk_pixbuf.so.2/lib{gdk_pixbuf.so.2,pixbufloader-{xpm,png}.so.1.0.0} \
		|| die "Removing rpath"

	# A simple icon I made
	insinto ${dir}/lib/icon
	doins ${DISTDIR}/vmware.png || die
	doicon ${DISTDIR}/vmware.png || die

	make_desktop_entry vmware "VMWare Workstation" vmware.png
}
