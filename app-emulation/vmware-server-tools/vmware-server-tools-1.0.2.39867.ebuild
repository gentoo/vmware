# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit versionator vmware-mod eutils vmware

DESCRIPTION="Guest-os tools for VMware Server"
HOMEPAGE="http://www.vmware.com/"
SRC_URI=""

LICENSE="vmware"
SLOT="0"
KEYWORDS="-* -amd64 ~x86"
IUSE="X"
RESTRICT=""

RDEPEND="sys-apps/pciutils
		 X? ( x11-drivers/xf86-video-vmware
		      x11-drivers/xf86-input-vmmouse )"

S=${WORKDIR}/vmware-tools-distrib

RUN_UPDATE="no"
ANY_ANY=""
TARBALL="VMwareTools-$(get_version_component_range 1-3)-$(get_version_component_range 4).tar.gz"
VMWARE_MOD_DIR="lib/modules/source"


pkg_setup() {
	vmware-mod_pkg_setup
	vmware_pkg_setup
}

src_unpack() {
	vmware_src_unpack
	vmware-mod_src_unpack
}

src_install() {
	vmware-mod_src_install
	vmware_src_install

	dodir ${VMWARE_INSTALL_DIR}/sbin
	keepdir ${VMWARE_INSTALL_DIR}/sbin

	# if we have X, install the default config
	#if use X ; then
	#	insinto /etc/X11
	#	doins ${FILESDIR}/xorg.conf
	#fi
}

pkg_postinst() {
	if use X; then
		einfo You should now alter your xorg.conf
		einfo  Video Driver: vmware
		einfo  Mouse Driver: vmmouse
	fi
}
