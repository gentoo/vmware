# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id: vmware-server-1.0.0.23869.ebuild 44 2006-05-10 19:44:01Z ikelos $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit vmware eutils versionator

VMWARE_VME="VME_S1B1"

MY_PN="VMware-server"
MY_PV="e.x.p-$(get_version_component_range 4)"
NP="${MY_PN}-${MY_PV}"
S="${WORKDIR}/vmware-server-distrib"

DESCRIPTION="VMware Server for Linux"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://download3.vmware.com/software/vmserver/${NP}.tar.gz
		 http://dev.gentoo.org/~ikelos/devoverlay-distfiles/${P}-rpath-corrected-libs.tar.bz2"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-*"
RESTRICT="nostrip"

DEPEND=">=sys-libs/glibc-2.3.5
	>=dev-lang/perl-5
	sys-apps/pciutils
	sys-apps/findutils
	virtual/os-headers"
# vmware-server should not use virtual/libc as this is a 
# precompiled binary package thats linked to glibc.
RDEPEND=">=sys-libs/glibc-2.3.5
	amd64? ( app-emulation/emul-linux-x86-baselibs
	         app-emulation/emul-linux-x86-gtklibs 
		   )
	!amd64 ( || ( ( x11-libs/libX11
			x11-libs/libXtst
			x11-libs/libXext
			x11-libs/libXt 
			x11-libs/libICE
			x11-libs/libSM
			x11-libs/libXrender
		      )
		      ( virtual/x11 
			virtual/xft
		      )
		    )
	       )
	>=dev-lang/perl-5
	!app-emulation/vmware-player
	!app-emulation/vmware-workstation
	sys-apps/pciutils
	virtual/pam
	sys-apps/xinetd"
PDEPEND=">=app-emulation/vmware-modules-101"

dir=/opt/vmware/server
Ddir=${D}/${dir}

EPATCH_SOURCE=${FILESDIR}/${P}

pkg_setup() {
	vmware_pkg_setup
	vmware_test_module_build
}

src_unpack() {
	unpack ${A}
	cd ${S}
	
	epatch ${FILESDIR}/${PV}

	# patch the vmware /etc/pam.d file to ensure that only 
	# vmware group members can log in
	cp ${FILESDIR}/vmware-authd ${S}/etc/pam.d/vmware-authd
}

src_install() {
	dodir ${dir}/bin
	cp -pPR ${S}/bin/* ${Ddir}/bin

	dodir ${dir}/sbin
	cp -pPR ${S}/sbin/* ${Ddir}/sbin

	dodir ${dir}/lib
	cp -dr ${S}/lib/* ${Ddir}/lib

	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${Ddir}/lib/modules/binary
	# We also don't need to keep the icons around
	rm -rf ${Ddir}/lib/share/icons
	# We set vmware-vmx and vmware-ping suid
	chmod u+s ${Ddir}/bin/vmware-ping
	# chmod u+s ${Ddir}/lib/bin/vmware-vmx
	# chmod u+s ${Ddir}/sbin/vmware-authd

	dodoc doc/* || die "dodoc"
	# Fix for bug #91191
	dodir ${dir}/doc
	insinto ${dir}/doc
	doins doc/EULA || die "copying EULA"

	doman ${S}/man/man1/vmware.1.gz || die "doman"

	# vmware service loader
	newinitd ${FILESDIR}/${product}.rc ${product} || die "newinitd"

	# vmware enviroment
	doenvd ${FILESDIR}/90${product}-server || die "doenvd"

	# Fix the amd64 emulation pam stuff
	use amd64 && dosed ":pam_:/emul/linux/x86/lib/security/pam_:" /etc/pam.d/vmware-authd

	dodir /etc/vmware/
	cp -pPR etc/* ${D}/etc/vmware/
	echo "${VMWARE_GROUP}" > ${D}/etc/vmware/vmwaregroup

	vmware_create_initd

	dosym /etc/init.d/xinetd /etc/vmware/init.d
	cp -pPR installer/services.sh ${D}/etc/vmware/init.d/vmware || die

	#insinto ${dir}/lib/icon
	#doins ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	#doicon ${S}/lib/share/icons/48x48/apps/${PN}.png || die
	insinto /usr/share/mime/packages
	doins ${FILESDIR}/vmware.xml

	# make_desktop_entry vmware "VMWare Server" ${PN}.png

	dodir /usr/bin
	dosym ${dir}/bin/vmware /usr/bin/vmware

	# this removes the user/group warnings
	chown -R root:0 ${D} || die

	dodir /etc/vmware
	# this makes the vmware-vmx executable only executable by vmware group
	fowners root:${VMWARE_GROUP} ${dir}/sbin/vmware-authd ${dir}/lib/bin{,-debug}/vmware-vmx /etc/vmware \
		|| die "Changing permissions"
	fperms 4750 ${dir}/lib/bin{,-debug}/vmware-vmx ${dir}/sbin/vmware-authd || die
	fperms 770 /etc/vmware || die

	# this adds udev rules for vmmon*
	dodir /etc/udev/rules.d
	echo 'KERNEL=="vmmon*", GROUP="'${VMWARE_GROUP}'" MODE=660' > \
		${D}/etc/udev/rules.d/60-vmware.rules || die

	vmware_run_questions
}

pkg_config() {
	einfo "Running ${ROOT}${dir}/bin/vmware-config.pl"
	${ROOT}${dir}/bin/vmware-config.pl
}

pkg_postinst() {
	vmware_pkg_postinst
	einfo
	einfo "You need to run ${dir}/bin/vmware-config.pl to complete the install."
	einfo
	einfo "For VMware Add-Ons just visit"
	einfo "http://www.vmware.com/download/downloadaddons.html"
	einfo
	einfo "Remember by default xinetd only allows connections from localhost"
	einfo "To allow external users access to vmware-server you must edit"
	einfo "    /etc/xinetd.d/vmware-authd"
	einfo "and specify a new 'only_from' line"
	einfo
	einfo "Also note that when you reboot you should run:"
	einfo "    /etc/init.d/vmware start"
	einfo "before trying to run vmware.  Or you could just add"
	einfo "it to the default run level:"
	einfo "rc-update add vmware default"
	echo
	ewarn "Remember, in order to connect to vmware-server, you have to"
	ewarn "be in the '${VMWARE_GROUP}' group."
	echo
	ewarn "VMWare allows for the potential of overwriting files as root.  Only"
	ewarn "give VMWare access to trusted individuals."
	echo
	ewarn "VMWare also has issues when running on a JFS filesystem.  For more"
	ewarn "information see http://bugs.gentoo.org/show_bug.cgi?id=122500#c94"
}

pkg_postrm() {
	einfo
	einfo "To remove all traces of vmware you will need to remove the files"
	einfo "in /etc/vmware/, /etc/init.d/vmware, /lib/modules/*/misc/vm*.{ko,o},"
	einfo "and .vmware/ in each users home directory. Don't forget to rmmod the"
	einfo "vm* modules, either."
	einfo
}
