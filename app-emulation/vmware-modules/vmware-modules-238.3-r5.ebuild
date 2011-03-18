# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-modules/vmware-modules-1.0.0.26.ebuild,v 1.2 2010/05/03 16:53:39 vadimk Exp $

EAPI="2"

inherit eutils flag-o-matic linux-info linux-mod

DESCRIPTION="VMware kernel modules"
HOMEPAGE="http://www.vmware.com/"

SRC_URI=""

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	|| ( ~app-emulation/vmware-player-3.1.3.324285
		 ~app-emulation/vmware-workstation-7.1.3.324285 )"

S=${WORKDIR}

pkg_setup() {
	if kernel_is ge 2 6 37; then
		CONFIG_CHECK="BKL"
		linux-info_pkg_setup
	fi

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
	epatch "${FILESDIR}/jobserver.patch"
	kernel_is 2 6 36 && epatch "${FILESDIR}/unlocked_ioctl.patch"
	kernel_is ge 2 6 37 && epatch "${FILESDIR}/sema.patch"
}

src_install() {
	linux-mod_src_install
	local udevrules="${T}/60-vmware.rules"
	cat > "${udevrules}" <<-EOF
		KERNEL=="vmci",  GROUP="vmware", MODE=660
		KERNEL=="vmmon", GROUP="vmware", MODE=660
		KERNEL=="vsock", GROUP="vmware", MODE=660
	EOF
	insinto /etc/udev/rules.d/
	doins "${udevrules}"
}
