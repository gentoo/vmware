# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-server/vmware-server-1.0.4.56528.ebuild,v 1.3 2007/11/25 13:08:59 ikelos Exp $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit eutils versionator vmware

MY_PV=$(replace_version_separator 3 '-' )
MY_PV="e.x.p-$(get_version_component_range 4)"
MY_PN="VMware-server-${MY_PV}"

DESCRIPTION="VMware Server for Linux"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="
	x86? (
		mirror://vmware/software/vmserver/${MY_PN}.i386.tar.gz
		http://download.softpedia.ro/linux/${MY_PN}.i386.tar.gz )
	amd64? (
		mirror://vmware/software/vmserver/${MY_PN}.x86_64.tar.gz
		http://download.softpedia.ro/linux/${MY_PN}.x86_64.tar.gz )
	"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-*"
RESTRICT="strip"

DEPEND=">=sys-libs/glibc-2.3.5
	>=dev-lang/perl-5
	sys-apps/pciutils
	sys-apps/findutils
	virtual/os-headers"
# vmware-server should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
RDEPEND=">=sys-libs/glibc-2.3.5
	virtual/xft
	x11-libs/libX11
	x11-libs/libXtst
	x11-libs/libXext
	x11-libs/libXt
	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libXrender
	>=dev-lang/perl-5
	!<sys-apps/dbus-0.62
	!app-emulation/vmware-player
	!app-emulation/vmware-workstation
	~app-emulation/vmware-modules-1.0.0.19
	!<app-emulation/vmware-modules-1.0.0.19
	!>=app-emulation/vmware-modules-1.0.0.20
	sys-apps/pciutils
	virtual/pam
	sys-apps/xinetd"

S=${WORKDIR}/vmware-server-distrib

ANY_ANY=""
RUN_UPDATE="no"

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

	insinto /etc/vmware/hostd
	doins ${FILESDIR}/authorization.xml
}

pkg_config() {
	einfo "Running ${ROOT}${dir}/bin/vmware-config.pl"
	"${ROOT}${dir}/bin/vmware-config.pl"
}

pkg_postinst() {
	vmware_pkg_postinst
	elog "Remember by default xinetd only allows connections from localhost"
	elog "To allow external users access to vmware-server you must edit"
	elog "    /etc/xinetd.d/vmware-authd"
	elog "and specify a new 'only_from' line"
	echo
	ewarn "VMWare Server also has issues when running on a JFS filesystem.  For more"
	ewarn "information see http://bugs.gentoo.org/show_bug.cgi?id=122500#c94"
}
