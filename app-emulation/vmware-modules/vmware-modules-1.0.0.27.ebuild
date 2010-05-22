# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-modules/vmware-modules-1.0.0.26.ebuild,v 1.2 2010/05/03 16:53:39 vadimk Exp $

EAPI="2"

inherit eutils flag-o-matic linux-mod

DESCRIPTION="VMware kernel modules"
HOMEPAGE="http://www.vmware.com/"

SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	~app-emulation/vmware-player-3.1.0.261024"

S=${WORKDIR}

pkg_setup() {
	linux-mod_pkg_setup

	VMWARE_VER="VME_V65" # THIS VALUE IS JUST A PLACE HOLDER
	VMWARE_GROUP=${VMWARE_GROUP:-vmware}

	VMWARE_MODULE_LIST="vmblock vmci vmmon vmnet vsock"
	VMWARE_MOD_DIR="${PN}-${PVR}"

	BUILD_TARGETS="auto-build VMWARE_VER=${VMWARE_VER} KERNEL_DIR=${KERNEL_DIR} KBUILD_OUTPUT=${KV_OUT_DIR}"

	enewgroup "${VMWARE_GROUP}"
	filter-flags -mfpmath=sse

	for mod in ${VMWARE_MODULE_LIST}; do
		MODULE_NAMES="${MODULE_NAMES} ${mod}(misc:${S}/${mod}-only)"
	done
}

src_unpack() {
	cd "${S}"
	for mod in ${VMWARE_MODULE_LIST}; do
		tar -xf /opt/vmware/lib/vmware/modules/source/${mod}.tar
	done
}

src_prepare() {
	epatch "${FILESDIR}/1.0.0.26-makefile-kernel-dir.patch"
	epatch "${FILESDIR}/1.0.0.26-makefile-include.patch"
	epatch "${FILESDIR}/apic.patch"
}

src_install() {
	# this adds udev rules for vmmon*
	if echo ${VMWARE_MODULE_LIST} | grep -q vmmon ; then
		dodir /etc/udev/rules.d
		echo 'KERNEL=="vmmon*", GROUP="'${VMWARE_GROUP}'", MODE=660' >> "${D}/etc/udev/rules.d/60-vmware.rules" || die
		echo 'KERNEL=="vmnet*", GROUP="'${VMWARE_GROUP}'", MODE=660' >> "${D}/etc/udev/rules.d/60-vmware.rules" || die
	fi

	linux-mod_src_install
}
