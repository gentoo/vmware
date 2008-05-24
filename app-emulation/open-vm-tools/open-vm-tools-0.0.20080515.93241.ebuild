# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/open-vm-tools/open-vm-tools-0.0.20071121.64693.ebuild,v 1.2 2007/12/22 23:05:54 mr_bones_ Exp $

inherit pam eutils linux-mod autotools versionator

MY_DATE="$(get_version_component_range 3)"
MY_BUILD="$(get_version_component_range 4)"
MY_PV="${MY_DATE:0:4}.${MY_DATE:4:2}.${MY_DATE:6:2}-${MY_BUILD}"
MY_P="${PN}-${MY_PV}"

S="${WORKDIR}/${MY_P}"

DESCRIPTION="Opensourced tools for VMware guests"
HOMEPAGE="http://open-vm-tools.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="X xinerama icu"
DEPEND="
		virtual/linux-sources
		sys-apps/ethtool
		X? (
			x11-libs/libX11
			x11-libs/gtk+
			)
		xinerama? (
			x11-libs/libXinerama
			)
		!app-emulation/vmware-workstation-tools
		!app-emulation/vmware-server-tools
		!app-emulation/vmware-esx-tools
		sys-process/procps
		dev-libs/libdnet
		icu? ( dev-libs/icu )
		"

RDEPEND="${DEPEND/virtual\/linux\-sources/}
		 virtual/pam
		 X? (
			x11-base/xorg-server
			x11-drivers/xf86-video-vmware
			x11-drivers/xf86-input-vmmouse
		 )
"

VMWARE_MOD_DIR="modules/linux"
VMWARE_MODULE_LIST="vmblock vmhgfs vmsync vmmemctl vmxnet"

pkg_setup() {

	linux-mod_pkg_setup
	MODULE_NAMES=""
	BUILD_TARGETS="auto-build HEADER_DIR=${KERNEL_DIR}/include BUILD_DIR=${KV_OUT_DIR}"

	for mod in ${VMWARE_MODULE_LIST};
	do
		if [[ "${mod}" == "vmxnet" ]];
		then
			MODTARGET="net"
		else
			MODTARGET="openvmtools"
		fi
		MODULE_NAMES="${MODULE_NAMES} ${mod}(${MODTARGET}:${S}/${VMWARE_MOD_DIR}/${mod})"
	done

	ewarn "If you're compiling for a hardened target, please use the hardened"
	ewarn "toolchain (see bug #200376, comment 18)."

	enewgroup vmware

}

src_unpack() {
	unpack ${A}
	cd "${S}"
	# epatch "${FILESDIR}/${PN}-as-needed.patch"

	eautoreconf
}

src_compile() {
	econf \
	$(use_with icu) \
	$(use_with X x) \
	$(use_enable xinerama multimon) \
	|| die "Error: econf failed!"

	linux-mod_src_compile

	emake || die
}

src_install() {

	linux-mod_src_install

	pamd_mimic_system vmware-guestd auth account

	# Install the various tools
	cd "${S}"
	VMWARE_BIN_LIST="hgfsclient xferlogs"
	VMWARE_SBIN_LIST="guestd checkvm"
	if use X; then
		# Fix up the vmware-user tool's name
		mv vmware-user/vmware-user vmware-user/user
		mv vmware-user user
		VMWARE_BIN_LIST="${VMWARE_BIN_LIST} user toolbox"
	fi
	for i in ${VMWARE_BIN_LIST}; do
		newbin ${i}/${i} vmware-${i} || die "Failed installing ${i}"
	done
	for i in ${VMWARE_SBIN_LIST}; do
		newsbin ${i}/${i} vmware-${i} || die "Failed installing ${i}"
	done

	dolib libguestlib/.libs/libguestlib.{so.0.0.0,a}

	# Deal with the hgfsmounter
	into /
	newsbin hgfsmounter/hgfsmounter mount.vmhgfs
	fperms u+s /sbin/mount.vmhgfs
	### FROM THIS POINT ON, into IS SET TO ${ROOT}/ not ${ROOT}/usr !!!

	# Install the /etc/ files
	exeinto /etc/vmware-tools
	doexe scripts/linux/*
	insinto /etc/vmware-tools
	doins "${FILESDIR}/tools.conf"
	# Only install this, when X is being used. Else it's useless waste of
	# ressources when checking continuously for processes that will never appear
	use X && doins "${FILESDIR}/xautostart.conf"
	newinitd "${FILESDIR}/open-vm.initd" vmware-tools
	newconfd "${FILESDIR}/open-vm.confd" vmware-tools

	if use X;
	then
		elog "To be able to use the drag'n'drop feature of VMware for file"
		elog "exchange, you need to do this:"
		elog "	Add 'vmware-tools' to your default runlevel"
		elog "	Add the users which should have access to this function"
		elog "	to the group 'vmware'"
	fi
}
