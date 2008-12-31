# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/open-vm-tools/open-vm-tools-0.0.20081223.137496.ebuild,v 1.1 2008/12/31 00:39:39 ikelos Exp $

inherit pam eutils linux-mod versionator

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
IUSE="X xinerama icu unity"
DEPEND="
		virtual/linux-sources
		sys-apps/ethtool
		X? (
			x11-libs/libX11
			x11-libs/gtk+
			)
		unity? (
			x11-libs/libXScrnSaver
			dev-libs/uriparser
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
		 unity? (
			x11-libs/libXScrnSaver
			dev-libs/uriparser
		 )
"

VMWARE_MOD_DIR="modules/linux"
VMWARE_MODULE_LIST="vmblock vmhgfs vmsync vmmemctl vmxnet"

pkg_setup() {
	use unity && ! use xinerama && \
	  die 'The Unity USE flag requires USE="xinerama" as well'

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

	ewarn "If you're compiling with a hardened toolchain, please use the"
	ewarn "hardenednopie gcc profile (see bug #200376, comment 18)."

	enewgroup vmware
}

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/default-scripts.patch"
}

src_compile() {
	econf \
	--without-kernel-modules \
	$(use_with icu) \
	$(use_with X x) \
	$(use_enable unity) \
	$(use_enable xinerama multimon) \
	|| die "Error: econf failed!"

	linux-mod_src_compile

	emake || die
}

src_install() {

	linux-mod_src_install

	pamd_mimic_system vmware-guestd auth account

	emake install DESTDIR="${D}" || die "Failed to install"

	newinitd "${FILESDIR}/open-vm.initd" vmware-tools
	newconfd "${FILESDIR}/open-vm.confd" vmware-tools

	if use X;
	then
		exeinto /etc/X11/xinit/xinitrc.d
		doexe "${FILESDIR}/10-vmware-tools"

		elog "To be able to use the drag'n'drop feature of VMware for file"
		elog "exchange, you need to do this:"
		elog "	Add 'vmware-tools' to your default runlevel"
		elog "	Add the users which should have access to this function"
		elog "	to the group 'vmware'"
	fi
}
