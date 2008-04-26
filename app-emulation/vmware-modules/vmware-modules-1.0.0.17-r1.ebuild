# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-modules/vmware-modules-1.0.0.17-r1.ebuild,v 1.1 2008/01/26 01:22:16 ikelos Exp $

KEYWORDS="~amd64 ~x86"
VMWARE_VER="VME_V6"

VMWARE_MODULE_LIST="vmblock vmmon vmnet"

inherit vmware-mod

src_unpack() {
	vmware-mod_src_unpack
	cd "${S}"
	epatch "${FILESDIR}"/"${PV}-update115-nasty-hack.patch"
}
