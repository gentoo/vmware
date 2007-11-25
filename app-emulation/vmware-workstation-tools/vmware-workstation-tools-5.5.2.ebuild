# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-workstation-tools/vmware-workstation-tools-5.5.2.ebuild,v 1.2 2007/03/05 09:32:14 ikelos Exp $

inherit eutils vmware

DESCRIPTION="Guest-os tools for VMware Workstation"
HOMEPAGE="http://www.vmware.com/"
SRC_URI=""

LICENSE="vmware"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE="X"
RESTRICT=""

RDEPEND="sys-apps/pciutils"

S=${WORKDIR}/vmware-tools-distrib

RUN_UPDATE="no"

dir=/opt/vmware/tools
Ddir=${D}/${dir}

ANY_ANY=
TARBALL="VMwareTools-5.5.2-29772.tar.gz"
MY_P=${TARBALL/.tar.gz/}

src_install() {
	vmware_src_install

	dodir ${dir}/sbin
	keepdir ${dir}/sbin

	# if we have X, install the default config
	if use X ; then
		insinto /etc/X11
		doins ${FILESDIR}/xorg.conf
	fi
}
