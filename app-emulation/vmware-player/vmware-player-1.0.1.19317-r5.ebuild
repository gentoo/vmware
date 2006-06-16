# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit eutils vmware

S=${WORKDIR}/vmware-player-distrib
MY_P="VMware-player-1.0.1-19317"
DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/player/"
SRC_URI="http://download3.vmware.com/software/vmplayer/${MY_P}.tar.gz
	http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/obselete/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/obselete/${ANY_ANY}.tar.gz
	mirror://gentoo/vmware.png"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-*"
RESTRICT="strip" # fetch"

DEPEND="${RDEPEND} virtual/os-headers
	!app-emulation/vmware-workstation"
# vmware-player should not use virtual/libc as this is a 
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
	>=dev-lang/perl-5
	!app-emulation/vmware-workstation
	!app-emulation/vmware-server
	~app-emulation/vmware-modules-1.0.0.13
	sys-apps/pciutils"

dir=/opt/vmware/player
Ddir=${D}/${dir}

src_install() {
	dodir ${dir}/bin
	cp -pPR bin/* ${Ddir}/bin

	dodir ${dir}/lib
	cp -dr lib/* ${Ddir}/lib

	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${Ddir}/lib/modules/binary
	# We also don't need to keep the icons around
	rm -rf ${Ddir}/lib/share/icons
	# We set vmware-vmx and vmware-ping suid
	chmod u+s ${Ddir}/bin/vmware-ping
	chmod u+s ${Ddir}/lib/bin/vmware-vmx

	dodoc doc/* || die "dodoc"
	# Fix for bug #91191
	dodir ${dir}/doc
	insinto ${dir}/doc
	doins doc/EULA || die "copying EULA"

	# vmware service loader
	newinitd ${FILESDIR}/vmware.rc vmware || die "newinitd"

	# vmware enviroment
	doenvd ${FILESDIR}/90vmware-player || die "doenvd"

	dodir /etc/vmware/
	cp -pPR etc/* ${D}/etc/vmware/

	vmware_create_initd

	cp -pPR installer/services.sh ${D}/etc/vmware/init.d/vmware || die
	dosed 's/mknod -m 600/mknod -m 660/' /etc/vmware/init.d/vmware || die
	dosed '/c 119 "$vHubNr"/ a\
			chown root:vmware /dev/vmnet*\
			' /etc/vmware/init.d/vmware || die

	insinto ${dir}/lib/icon
	doins ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	doicon ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	insinto /usr/share/mime/packages
	doins ${FILESDIR}/vmware.xml

	make_desktop_entry vmplayer "VMWare Player" ${PN}.png

	dodir /usr/bin
	dosym ${dir}/bin/vmplayer /usr/bin/vmplayer

	# this removes the user/group warnings
	chown -R root:0 ${D} || die

	dodir /etc/vmware
	# this makes the vmware-vmx executable only executable by vmware group
	fowners root:vmware ${dir}/lib/bin{,-debug}/vmware-vmx /etc/vmware \
		|| die "Changing permissions"
	fperms 4750 ${dir}/lib/bin{,-debug}/vmware-vmx || die
	fperms 770 /etc/vmware || die

	vmware_run_questions
}

pkg_config() {
	einfo "Running ${dir}/bin/vmware-config.pl"
	${dir}/bin/vmware-config.pl
}
