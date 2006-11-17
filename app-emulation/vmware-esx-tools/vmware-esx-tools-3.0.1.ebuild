# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-workstation-tools/vmware-workstation-tools-5.5.1.ebuild,v 1.2 2006/06/12 20:44:35 wolf31o2 Exp $

inherit eutils

DESCRIPTION="Guest-os tools for VMware ESX"
HOMEPAGE="http://www.vmware.com/"

SRC_URI=""
LICENSE="vmware"
SLOT="0"
KEYWORDS="~amd64 x86"
IUSE="X"
RESTRICT=""

RDEPEND="sys-apps/pciutils"

dir=/opt/vmware/tools
Ddir=${D}/${dir}
TARBALL="VMwareTools-3.0.1-32039.tar.gz"

S=${WORKDIR}/vmware-tools-distrib

vmware_create_initd() {
	dodir /etc/vmware-tools/init.d
	dodir /etc/vmware-tools/init.d/rc0.d
	dodir /etc/vmware-tools/init.d/rc1.d
	dodir /etc/vmware-tools/init.d/rc2.d
	dodir /etc/vmware-tools/init.d/rc3.d
	dodir /etc/vmware-tools/init.d/rc4.d
	dodir /etc/vmware-tools/init.d/rc5.d
	dodir /etc/vmware-tools/init.d/rc6.d

	# This is to fix a problem where if someone merges vmware and then
	# before configuring vmware they upgrade or re-merge the vmware
	# package which would rmdir the /etc/vmware/init.d/rc?.d directories.
	keepdir /etc/vmware-tools/init.d/rc{0,1,2,3,4,5,6}.d
}

vmware_run_questions() {
	# Questions:
	einfo "Adding answers to /etc/vmware/locations"
	locations="${D}/etc/vmware-tools/locations"
	echo "answer BINDIR ${dir}/bin" >> ${locations}
	echo "answer LIBDIR ${dir}/lib" >> ${locations}
	echo "answer MANDIR ${dir}/man" >> ${locations}
	echo "answer DOCDIR ${dir}/doc" >> ${locations}
	echo "answer SBINDIR ${dir}/sbin" >> ${locations}
	echo "answer RUN_CONFIGURATOR no" >> ${locations}
	echo "answer INITDIR /etc/vmware-tools/init.d" >> ${locations}
	echo "answer INITSCRIPTSDIR /etc/vmware-tools/init.d" >> ${locations}
}

pkg_setup() {
	einfo "You will need ${TARBALL} from the VMware installation."
	einfo "Select VM->Install VMware Tools from VMware Workstation's menu."
	cdrom_get_cds ${TARBALL}
}

src_unpack() {
	tar xf "${CDROM_ROOT}"/"${TARBALL}"
#	cd "${S}"
#	epatch "${FILESDIR}"/${P}-config.patch || die "patching"
}

src_install() {
	dodir ${dir}/bin
	cp -pPR bin/* ${Ddir}/bin || die

	dodir ${dir}/lib
	cp -dr lib/* ${Ddir}/lib || die
	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${Ddir}/lib/modules/binary || die

	dodir ${dir}/sbin
	keepdir ${dir}/sbin

	into ${dir}
	# install the binaries
#	dosbin sbin/vmware-checkvm || die
#	dosbin sbin/vmware-guestd || die

	# install the config files
	dodir /etc/vmware-tools
	cp -pPR etc/* ${D}/etc/vmware-tools || die

	# install the init scripts
	newinitd ${FILESDIR}/${PN}.rc vmware-tools || die

	# Environment
	doenvd ${FILESDIR}/90vmware-tools || die

	# if we have X, install the default config
	if use X ; then
		insinto /etc/X11
		doins ${FILESDIR}/xorg.conf
	fi

	vmware_create_initd || die

	cp -pPR installer/services.sh ${D}/etc/vmware-tools/init.d/vmware-tools || die

	vmware_run_questions || die
}

pkg_postinst () {
	# This must be done after the install to get the mtimes on each file
	# right. This perl snippet gets the /etc/vmware/locations file code:
	# perl -e "@a = stat('bin/vmware'); print \$a[9]"
	# The above perl line and the find line below output the same thing.
	# I would think the find line is faster to execute.
	# find /opt/vmware/workstation/bin/vmware -printf %T@

	#Note: it's a bit weird to use ${D} in a preinst script but it should work
	#(drobbins, 1 Feb 2002)

	einfo "Generating /etc/vmware-tools/locations file."
	d=`echo ${D} | wc -c`
	for x in `find ${Ddir} ${D}/etc/vmware-tools` ; do
		x="`echo ${x} | cut -c ${d}-`"
		if [ -d ${D}/${x} ] ; then
			echo "directory ${x}" >> ${D}/etc/vmware-tools/locations
		else
			echo -n "file ${x}" >> ${D}/etc/vmware-tools/locations
			if [ "${x}" == "/etc/vmware-tools/locations" ] ; then
				echo "" >> ${D}/etc/vmware-tools/locations
			elif [ "${x}" == "/etc/vmware-tools/not_configured" ] ; then
				echo "" >> ${D}/etc/vmware-tools/locations
			else
				echo -n " " >> ${D}/etc/vmware-tools/locations
				#perl -e "@a = stat('${D}${x}'); print \$a[9]" >> ${D}/etc/vmware/locations
				find ${D}${x} -printf %T@ >> ${D}/etc/vmware-tools/locations
				echo "" >> ${D}/etc/vmware-tools/locations
			fi
		fi
	done
	einfo "To start using the vmware-tools, please run the following:"
	einfo
	einfo "  ${dir}/bin/vmware-config-tools.pl"
	einfo "  rc-update add vmware-tools default"
	einfo "  /etc/init.d/vmware-tools start"
	einfo
	einfo "Please report all bugs to http://bugs.gentoo.org/"
}
