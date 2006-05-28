# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

inherit linux-mod eutils versionator toolchain-funcs

PARENT_PN=${PN/-modules/}
MY_PV="e.x.p-$(get_version_component_range 4)"

DESCRIPTION="Modules for Vmware Programs"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://ftp.cvut.cz/vmware/vmware-any-any-update${PV}.tar.gz"

S=${WORKDIR}

RESTRICT="userpriv"
LICENSE="vmware"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"

IUSE=""
DEPEND="dev-lang/perl
		>=sys-apps/portage-2.0.54
		|| ( app-emulation/vmware-server
			 app-emulation/vmware-workstation
			 app-emulation/vmware-player )"

VMWARE_GROUP=${VMWARE_GROUP:-vmware}

BUILD_TARGETS="auto-build"

pkg_setup() {
	linux-mod_pkg_setup

	MODULE_NAMES="vmmon(misc:${S}/vmmon-only)
				  vmnet(misc:${S}/vmnet-only)"
				  # vmppuser(misc:${S}/vmppuser-only)"

	# BUILD_PARAMS="KERNELPATH=${KV_OUT_DIR}"
}

src_unpack() {
	unpack ${A}

	for dir in vmmon vmnet; do
		cd ${S}
		# tar -xf ${DISTDIR}/$dir.tar
		unpack ./vmware-any-any-update${PV}/${dir}.tar
		cd ${S}/${dir}-only
		epatch ${FILESDIR}/${P}-makefile.patch
		convert_to_m ${S}/${dir}-only/Makefile
	done
}

src_compile() {
	einfo "Determining build version..."
	${S}/vmmon-only/getversion.pl > ${S}/module-build

	linux-mod_src_compile
}

src_install() {
	linux-mod_src_install
	insinto /opt/vmware/
	doins ${S}/module-build

	# this adds udev rules for vmmon*
	dodir /etc/udev/rules.d
	echo 'KERNEL=="vmmon*", GROUP="'$VMWARE_GROUP'" MODE=660' > \
	${D}/etc/udev/rules.d/60-vmware.rules || die

	linux-mod_src_install
}
