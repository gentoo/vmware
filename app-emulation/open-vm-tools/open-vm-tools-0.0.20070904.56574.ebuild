# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils linux-mod versionator

MY_DATE="$(get_version_component_range 3)"
MY_PV="${MY_DATE:0:4}.${MY_DATE:4:2}.${MY_DATE:6:2}-$(get_version_component_range 4)"
MY_P="${PN}-${MY_PV}"

S="${WORKDIR}/${MY_P}"

DESCRIPTION="Opensourced tools for VMware guests"
HOMEPAGE="http://open-vm-tools.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${MY_P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~x86 ~amd64"
IUSE="pam X xinerama"
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
		"

RDEPEND="${DEPEND/virtual\/linux\-sources/}
		X? (
			x11-base/xorg-server
			x11-drivers/xf86-video-vmware
			x11-drivers/xf86-input-vmmouse
		)
"

VMWARE_MOD_DIR="modules/linux"
VMWARE_MODULE_LIST="vmblock vmhgfs vmmemctl vmxnet"

pkg_setup() {

	linux-mod_pkg_setup
	MODULE_NAMES=""
	BUILD_TARGETS="auto-build KERNEL_DIR=${KERNEL_DIR} KBUILD_OUTPUT=${KV_OUT_DIR}"

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

	enewgroup vmware

}

src_unpack() {
	unpack ${A}
}

src_compile() {
	cd ${S}
	if ! use X; then
		epatch ${FILESDIR}/disable-toolbox.patch
		rm -rf ${S}/toolbox
	fi

	econf \
	$(use_with X x) \
	$(use_enable xinerama multimon) \
	|| die "Error: econf failed!"

	linux-mod_src_compile 
	
	emake || die
}

src_install() {

	linux-mod_src_install
	
	if use pam; then
		LIB="$(get_libdir)"
		PAMFILE="${D}/etc/pam.d/vmware-guestd"
		dodir ${ROOT}${LIB}
		dodir ${ROOT}etc/pam.d
		echo '#%PAM-1.0' > ${PAMFILE}
		if [[ -e ${ROOT}${LIB}/security/pam_unix2.so ]];
		then
			PAM_VER=2
		fi
	
		echo -e	"auth\tsufficient\t${ROOT}${LIB}/security/pam_unix${PAM_VER}.so\tshadow\tnullok" >> ${PAMFILE}
		echo -e "auth\trequired\t${ROOT}${LIB}/security/pam_unix_auth.so\tshadow\tnullok" >> ${PAMFILE}
		echo -e "account\tsufficient\t${ROOT}${LIB}/security/pam_unix${PAM_VER}.so" >> ${PAMFILE}
		echo -e "account\trequired\t${ROOT}${LIB}/security/pam_unix_acct.so" >> ${PAMFILE}

	fi

	# Install the various tools
	cd ${S}
	VMWARE_BIN_LIST="hgfsclient" # xferlogs
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
	
	# Deal with the hgfsmounter
	into ${ROOT}
	newsbin hgfsmounter/hgfsmounter mount.vmhgfs
	fperms u+s ${ROOT}sbin/mount.vmhgfs

	# Install the /etc/ files
	insinto ${ROOT}etc/vmware-tools
	doins ${FILESDIR}/tools.conf
	# Only install this, when X is being used. Else it's useless waste of
	# ressources when checking continuously for processes that will never appear
	use X && doins ${FILESDIR}/xautostart.conf
	newinitd ${FILESDIR}/open-vm.initd vmware-tools
	
	# not needed anymore - the initscript takes care of this
	# as it is in /tmp - portage shouldn't have to take care of removing
	# it on unmerging the package
	#diropts -m1777
	#dodir ${ROOT}tmp/vmware/dnd

	if use X;
	then
		elog "To be able to use the drag'n'drop feature of VMware for file"
		elog "exchange, you need to do this:"
		elog "	Add 'vmblock' to your list of autoloaded modules"
		elog "	Add 'vmware-guestd' to your default runlevel"
		elog "	Add the users which should have access to this function"
		elog "	to the group 'vmware'"
	fi
}

