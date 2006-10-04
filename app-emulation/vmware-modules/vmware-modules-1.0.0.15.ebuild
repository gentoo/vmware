# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

KEYWORDS="~amd64 ~x86"
VMWARE_VER="VME_S1B1"

inherit toolchain-funcs vmware-mod

SRC_URI="http://download3.vmware.com/software/vmserver/VMware-server-1.0.1-29996.tar.gz"

VMWARE_MOD_DIR="vmware-server-distrib/lib/modules/source"

src_unpack() {
	vmware-mod_src_unpack

	if [[ "$(gcc-major-version)" -eq "4" ]] ; then
		if [[ $(gcc-minor-version) -ge 1 ]] ; then
			for mod in ${VMWARE_MODULE_LIST}; do
				cd "${S}"/${mod}-only
				epatch ${FILESDIR}/${PV}-gcc4-ignore-pedantic-errors.patch
			done
		fi
	fi
}
