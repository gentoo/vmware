# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-workstation-tools/vmware-workstation-tools-4.5.2.ebuild,v 1.3 2006/05/08 13:56:33 wolf31o2 Exp $

inherit vmware eutils

DESCRIPTION="Guest-os tools for VMware Workstation"
HOMEPAGE="http://www.vmware.com/"

# the vmware-tools sources are part of the vmware virtual machine;
# they must be installed by hand
SRC_URI=""
LICENSE="vmware"
SLOT="0"
KEYWORDS="~x86"
IUSE="X"
RESTRICT=""

DEPEND=""
RDEPEND="sys-apps/pciutils"

dir=/opt/vmware/tools
Ddir=${D}/${dir}
etcdir=/etc/vmware-tools
Detcdir=${D}/${etcdir}

TARBALL="vmware-linux-tools.tar.gz"
#VMwareTools-5.0.0-13124.tar.gz

S=${WORKDIR}/vmware-tools-distrib

pkg_setup() {
	einfo "You will need ${TARBALL} from the VMware installation."
	einfo "Select VM->Install VMware Tools from VMware Workstation's menu."
	cdrom_get_cds ${TARBALL}
}

src_unpack() {
	tar xf "${CDROM_ROOT}"/"${TARBALL}"
}

src_install() {
	dodir ${dir}/bin
	cp -pPR bin/* ${Ddir}/bin || die

	dodir ${dir}/lib
	cp -dr lib/* ${Ddir}/lib || die
	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${Ddir}/lib/modules/binary || die

	into ${dir}
	# install the binaries
	dosbin sbin/vmware-checkvm || die
	dosbin sbin/vmware-guestd || die

	# install the config files
	dodir ${etcdir}
	cp -pPR etc/* ${Detcdir} || die

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

	cp -pPR installer/services.sh ${D}/etc/vmware-tools/init.d/vmware || die

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
	einfo "  /usr/bin/vmware-config-tools.pl"
	einfo "  rc-update add vmware-tools default"
	einfo "  /etc/init.d/vmware-tools start"
	einfo
	einfo "Please report all bugs to http://bugs.gentoo.org/"
}
