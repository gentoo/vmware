# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-server/vmware-server-1.0.1.29996-r4.ebuild,v 1.2 2006/10/30 15:53:14 wolf31o2 Exp $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit eutils versionator vmware

MY_PV=$(replace_version_separator 3 '-' )
MY_P="VMware-server-${MY_PV}"

DESCRIPTION="VMware Server for Linux"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://download3.vmware.com/software/vmserver/${MY_P}.tar.gz
		http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
		http://ftp.cvut.cz/vmware/obselete/${ANY_ANY}.tar.gz
		http://knihovny.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
		http://knihovny.cvut.cz/ftp/pub/vmware/obselete/${ANY_ANY}.tar.gz
		http://dev.gentoo.org/~ikelos/devoverlay-distfiles/${PN}-perl-fixed-rpath-libs.tar.bz2
		mirror://gentoo/${PN}-perl-fixed-rpath-libs.tar.bz2
		http://dev.gentoo.org/~wolf31o2/sources/dump/vmware-libssl.so.0.9.7l.tar.bz2
		mirror://gentoo/vmware-libssl.so.0.9.7l.tar.bz2
		http://dev.gentoo.org/~wolf31o2/sources/dump/vmware-libcrypto.so.0.9.7l.tar.bz2
		mirror://gentoo/vmware-libcrypto.so.0.9.7l.tar.bz2"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="nostrip"

DEPEND=">=sys-libs/glibc-2.3.5
	>=dev-lang/perl-5
	sys-apps/pciutils
	sys-apps/findutils
	virtual/os-headers"
# vmware-server should not use virtual/libc as this is a 
# precompiled binary package thats linked to glibc.
RDEPEND=">=sys-libs/glibc-2.3.5
	amd64? (
			app-emulation/emul-linux-x86-baselibs
			app-emulation/emul-linux-x86-gtklibs )
	!amd64? (
			virtual/xft
			x11-libs/libX11
			x11-libs/libXtst
			x11-libs/libXext
			x11-libs/libXt
			x11-libs/libICE
			x11-libs/libSM
			x11-libs/libXrender )
	>=dev-lang/perl-5
	!<sys-apps/dbus-0.62
	!app-emulation/vmware-player
	!app-emulation/vmware-workstation
	~app-emulation/vmware-modules-1.0.0.15
	sys-apps/pciutils
	virtual/pam
	sys-apps/xinetd"

S=${WORKDIR}/vmware-server-distrib

RUN_UPDATE="no"
PATCHES="general"

src_unpack() {
	EPATCH_SUFFIX="patch"
	vmware_src_unpack
	cd ${WORKDIR}
	unpack ${PN}-perl-fixed-rpath-libs.tar.bz2

	# patch the vmware /etc/pam.d file to ensure that only 
	# vmware group members can log in
	cp ${FILESDIR}/vmware-authd ${S}/etc/pam.d/vmware-authd
}

src_install() {
	vmware_src_install

	# Fix the amd64 emulation pam stuff
	use amd64 && dosed "s:pam_:/emul/linux/x86/lib/security/pam_:" ${config_dir}/pam.d/vmware-authd

	echo "${VMWARE_GROUP}" > ${D}${config_dir}/vmwaregroup

	dosym /etc/init.d/xinetd ${config_dir}/init.d
}

pkg_config() {
	einfo "Running ${ROOT}${dir}/bin/vmware-config.pl"
	${ROOT}${dir}/bin/vmware-config.pl
}

pkg_postinst() {
	vmware_pkg_postinst
	einfo "Remember by default xinetd only allows connections from localhost"
	einfo "To allow external users access to vmware-server you must edit"
	einfo "    /etc/xinetd.d/vmware-authd"
	einfo "and specify a new 'only_from' line"
	echo
	ewarn "VMWare Server also has issues when running on a JFS filesystem.  For more"
	ewarn "information see http://bugs.gentoo.org/show_bug.cgi?id=122500#c94"
}

