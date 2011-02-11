# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils flag-o-matic linux-mod versionator

DESCRIPTION="VMware kernel modules for vmware server 1.0.x"
HOMEPAGE="http://www.vmware.com/"

MY_PV=$(get_version_component_range 1-2 "${PV}")
MY_P=${PN}-${MY_PV}
GENPATCHES_VER=$(get_version_component_range 3 "${PV}")
MY_SV=$(get_version_component_range 2 "${PV}")
SRC_URI="http://ftp.disconnected-by-peer.at/vmware/${MY_P}-genpatches-${GENPATCHES_VER}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	=app-emulation/vmware-server-1.0.${MY_SV}*"

S=${WORKDIR}

pkg_setup() {
	linux-mod_pkg_setup

	VMWARE_GROUP=${VMWARE_GROUP:-vmware}

	VMWARE_MODULE_LIST="vmmon vmnet"
	VMWARE_MOD_DIR="${PF}"

	BUILD_TARGETS="auto-build VMWARE_VER=${VMWARE_VER} KERNEL_DIR=${KERNEL_DIR} KBUILD_OUTPUT=${KV_OUT_DIR}"

	enewgroup "${VMWARE_GROUP}"
	filter-flags -mfpmath=sse

	for mod in ${VMWARE_MODULE_LIST}; do
		MODULE_NAMES="${MODULE_NAMES} ${mod}(misc:${S}/${mod}-only)"
	done
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	for mod in ${VMWARE_MODULE_LIST}; do
		tar -xf /opt/vmware/server/lib/modules/source/${mod}.tar
	done
}

src_prepare() {
	EPATCH_FORCE=yes EPATCH_SUFFIX="patch" EPATCH_SOURCE="${WORKDIR}/patches" epatch
	sed -i -e '/\smake\s/s/make/$(MAKE)/g' {vmmon,vmnet}-only/Makefile || die "Sed failed."

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
