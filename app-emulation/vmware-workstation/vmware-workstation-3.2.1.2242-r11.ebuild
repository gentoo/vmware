# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $ Id: $

inherit toolchain-funcs eutils vmware

MY_P="VMware-workstation-3.2.1-2242"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="mirror://vmware/software/${MY_P}.tar.gz
	http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/obsolete/${ANY_ANY}.tar.gz
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
	|| (
		(
			x11-libs/libXrandr
			x11-libs/libXcursor
			x11-libs/libXinerama
			x11-libs/libXi )
		virtual/x11 )
	virtual/xft
	!app-emulation/vmware-player
	!app-emulation/vmware-server
	~app-emulation/vmware-modules-1.0.0.8
	media-libs/gdk-pixbuf
	>=dev-lang/perl-5
	sys-apps/pciutils"

S=${WORKDIR}/vmware-distrib

RUN_UPDATE="no"

dir=/opt/vmware/workstation
Ddir=${D}/${dir}

src_compile() {
	has_version '<sys-libs/glibc-2.3.2' \
		&& GLIBC_232=0 \
		|| GLIBC_232=1

	if [ ${GLIBC_232} -eq 1 ] ; then
		$(tc-getCC) -W -Wall -shared -o vmware-glibc-2.3.2-compat.so \
			${FILESDIR}/${PV}/vmware-glibc-2.3.2-compat.c \
			|| die "could not make module"
	else
		return 0
	fi
}

src_install() {
	vmware_src_install
	# We also remove libgdk_pixbuf stuff, to resolve bug #81344.
	rm -rf ${Ddir}/lib/lib/libgdk_pixbuf.so.2

	# A simple icon I made
	insinto ${dir}/lib/icon
	doins ${DISTDIR}/vmware.png || die
	doicon ${DISTDIR}/vmware.png || die

	make_desktop_entry vmware "VMWare Workstation" vmware.png

	if [ ${GLIBC_232} -eq 1 ] ; then
		dolib.so vmware-glibc-2.3.2-compat.so
		cd ${Ddir}/lib/bin
		mv vmware-ui{,.bin}
		mv vmware-mks{,.bin}
		echo '#!/bin/sh' > vmware-ui
		echo 'LD_PRELOAD=vmware-glibc-2.3.2-compat.so exec "$0.bin" "$@"' >> vmware-ui
		chmod a+x vmware-ui
		cp vmware-{ui,mks}
	else
		return 0
	fi
}
