# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-modules/vmware-modules-1.0.0.24-r3.ebuild,v 1.2 2011/03/16 17:36:57 vadimk Exp $

EAPI="2"

inherit eutils flag-o-matic linux-mod versionator

PV_MAJOR=$(get_major_version)
PV_MINOR=$(get_version_component_range 2)

DESCRIPTION="VMware kernel modules"
HOMEPAGE="http://www.vmware.com/"

SRC_URI="mirror://gentoo/${P}.patch.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

RDEPEND=""
DEPEND="${RDEPEND}
	=app-emulation/vmware-server-2.0.${PV_MINOR}*"

S="${WORKDIR}"

pkg_setup() {
	linux-mod_pkg_setup

	VMWARE_VER="VME_V65" # THIS VALUE IS JUST A PLACE HOLDER
	VMWARE_GROUP=${VMWARE_GROUP:-vmware}

	VMWARE_MODULE_LIST="vmci vmmon vmnet vsock"
	VMWARE_MOD_DIR="${PN}-${PVR}"

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
		tar -xf	/opt/vmware/server/lib/modules/source/${mod}.tar
	done

}

src_prepare() {
	epatch "${S}/${P}.patch"
	kernel_is ge 2 6 35 && epatch "${FILESDIR}/${PV_MAJOR}-sk_sleep.patch"
	kernel_is ge 2 6 36 && epatch "${FILESDIR}/${PV_MAJOR}-unlocked_ioctl.patch"
	kernel_is ge 2 6 37 && epatch "${FILESDIR}/${PV_MAJOR}-sema.patch"
}

src_install() {
	linux-mod_src_install
	local udevrules="${T}/60-vmware.rules"
	cat > "${udevrules}" <<-EOF
		KERNEL=="vmci",  GROUP="$VMWARE_GROUP", MODE=660
		KERNEL=="vmmon", GROUP="$VMWARE_GROUP", MODE=660
		KERNEL=="vsock", GROUP="$VMWARE_GROUP", MODE=660
	EOF
	insinto /etc/udev/rules.d/
	doins "${udevrules}"
}
