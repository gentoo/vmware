# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-modules/vmware-modules-1.0.0.17.ebuild,v 1.3 2007/11/25 12:43:20 ikelos Exp $

KEYWORDS="~amd64 ~x86"
VMWARE_VER="VME_V604" # THIS VALUE IS JUST A PLACE HOLDER

inherit eutils vmware-mod

VMWARE_MODULE_LIST="vmmon vmnet vmblock"
SRC_URI="x86? ( mirror://vmware/software/vmplayer/VMware-player-2.0.4-93057.i386.tar.gz )
		 amd64? ( mirror://vmware/software/vmplayer/VMware-player-2.0.4-93057.x86_64.tar.gz )"
VMWARE_MOD_DIR="vmware-player-distrib/lib/modules/source/"

src_unpack() {
	vmware-mod_src_unpack
	cd ${S}/vmblock-only
	epatch ${FILESDIR}/patches/vmblock/010_all_kernel-2.6.25.patch
}
