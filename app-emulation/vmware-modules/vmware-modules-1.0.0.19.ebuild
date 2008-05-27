# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-modules/vmware-modules-1.0.0.17.ebuild,v 1.3 2007/11/25 12:43:20 ikelos Exp $

KEYWORDS="~amd64 ~x86"
VMWARE_VER="VME_V65" # THIS VALUE IS JUST A PLACE HOLDER

inherit eutils vmware-mod

VMWARE_MODULE_LIST="vmmon vmnet vmblock vmci vsock"
SRC_URI="x86? ( mirror://vmware/software/wkst/VMware-workstation-e.x.p-91182.i386.tar.gz )
		 amd64? ( mirror://vmware/software/wkst/VMware-workstation-e.x.p-91182.x86_64.tar.gz )"
VMWARE_MOD_DIR="vmware-distrib/lib/modules/source/"

src_unpack() {
	vmware-mod_src_unpack
	cd ${S}
	epatch ${FILESDIR}/${PV}-vsock-kernel-makefile.patch
	epatch ${FILESDIR}/${PV}-makefile-kernel-dir.patch
}
