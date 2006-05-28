# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $ Id: $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit vmware eutils

MY_P="VMware-workstation-5.5.1-19175"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="http://vmware-svca.www.conxion.com/software/wkst/${MY_P}.tar.gz
	http://download3.vmware.com/software/wkst/${MY_P}.tar.gz
	http://download.vmware.com/htdocs/software/wkst/${MY_P}.tar.gz
	http://www.vmware.com/download1/software/wkst/${MY_P}.tar.gz
	ftp://download1.vmware.com/pub/software/wkst/${MY_P}.tar.gz
	http://vmware-chil.www.conxion.com/software/wkst/${MY_P}.tar.gz
	http://vmware-heva.www.conxion.com/software/wkst/${MY_P}.tar.gz
	http://vmware.wespe.de/software/wkst/${MY_P}.tar.gz
	ftp://vmware.wespe.de/pub/software/wkst/${MY_P}.tar.gz"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-* amd64 x86"
RESTRICT="nostrip"

ANY_ANY=""
VMWARE_VME="VME_V55"

DEPEND="${RDEPEND} virtual/os-headers"
# vmware-workstation should not use virtual/libc as this is a 
# precompiled binary package thats linked to glibc.
RDEPEND="sys-libs/glibc
	amd64? (
		app-emulation/emul-linux-x86-gtklibs )
	x86? (
		|| (
			(
				x11-libs/libXrandr
				x11-libs/libXcursor
				x11-libs/libXinerama
				x11-libs/libXi )
			virtual/x11 )
		virtual/xft )
	>=dev-lang/perl-5
	!app-emulation/vmware-player
	!app-emulation/vmware-server
	sys-apps/pciutils"
#	>=sys-apps/baselayout-1.11.14"
PDEPEND="app-emulation/vmware-modules"

S=${WORKDIR}/vmware-distrib

dir=/opt/vmware/workstation
Ddir=${D}/${dir}

PATCHES="config.patch config2.patch config3.patch"
RUN_UPDATE="no"

pkg_setup() {
	vmware_test_module_build
	vmware_pkg_setup
}

src_install() {
	dodir ${dir}/bin
	cp -pPR bin/* ${Ddir}/bin

	dodir ${dir}/lib
	cp -dr lib/* ${Ddir}/lib

	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${Ddir}/lib/modules/binary
	# We also don't need to keep the icons around
	rm -rf ${Ddir}/lib/share/icons
	# We set vmware-vmx and vmware-ping suid
	chmod u+s ${Ddir}/bin/vmware-ping
	chmod u+s ${Ddir}/lib/bin/vmware-vmx

	dodoc doc/* || die "dodoc"
	# Fix for bug #91191
	dodir ${dir}/doc
	insinto ${dir}/doc
	doins doc/EULA || die "copying EULA"

	doman ${S}/man/man1/vmware.1.gz || die "doman"

	# vmware service loader
	newinitd ${FILESDIR}/vmware.rc vmware || die "newinitd"

	# vmware enviroment
	doenvd ${FILESDIR}/90vmware-workstation || die "doenvd"

	dodir /etc/vmware/
	cp -pPR etc/* ${D}/etc/vmware/

	vmware_create_initd

	cp -pPR installer/services.sh ${D}/etc/vmware/init.d/vmware || die
	dosed 's/mknod -m 600/mknod -m 660/' /etc/vmware/init.d/vmware || die
	dosed '/c 119 "$vHubNr"/ a\
		chown root:vmware /dev/vmnet*\
		' /etc/vmware/init.d/vmware || die

	insinto ${dir}/lib/icon
	doins ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	doicon ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	insinto /usr/share/mime/packages
	doins ${FILESDIR}/vmware.xml

	make_desktop_entry vmware "VMWare Workstation" ${PN}.png

	dodir /usr/bin
	dosym ${dir}/bin/vmware /usr/bin/vmware

	# this removes the user/group warnings
	chown -R root:0 ${D} || die

	dodir /etc/vmware
	# this makes the vmware-vmx executable only executable by vmware group
	fowners root:vmware ${dir}/lib/bin{,-debug}/vmware-vmx /etc/vmware \
		|| die "Changing permissions"
	fperms 4750 ${dir}/lib/bin{,-debug}/vmware-vmx || die
	fperms 770 /etc/vmware || die

	vmware_run_questions
}

pkg_config() {
	einfo "Running ${dir}/bin/vmware-config.pl"
	${dir}/bin/vmware-config.pl
}

pkg_postinst() {
	vmware_pkg_postinst

	einfo
	einfo "You need to run ${dir}/bin/vmware-config.pl to complete the install."
	einfo
	einfo "For VMware Add-Ons just visit"
	einfo "http://www.vmware.com/download/downloadaddons.html"
	einfo
	einfo "After configuring, type 'vmware' to launch"
	einfo
	einfo "Also note that when you reboot you should run:"
	einfo "/etc/init.d/vmware start"
	einfo "before trying to run vmware.  Or you could just add"
	einfo "it to the default run level:"
	einfo "rc-update add vmware default"
	echo
	ewarn "Remember, in order to run vmware, you have to"
	ewarn "be in the '${VMWARE_GROUP}' group."
	echo
	ewarn "VMWare allows for the potential of overwriting files as root.  Only"
	ewarn "give VMWare access to trusted individuals."
}

pkg_postrm() {
	einfo
	einfo "To remove all traces of vmware you will need to remove the files"
	einfo "in /etc/vmware/, /etc/init.d/vmware, /lib/modules/*/misc/vm*.o,"
	einfo "and .vmware/ in each users home directory. Don't forget to rmmod the"
	einfo "vm* modules, either."
	einfo
}
