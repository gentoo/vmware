# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-server-console/vmware-server-console-1.0.0.20925.ebuild,v 1.4 2006/01/04 21:59:43 wolf31o2 Exp $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit eutils versionator

MY_PN="VMware-console"
MY_PV="e.x.p-$(get_version_component_range 4)"
NP="${MY_PN}-${MY_PV}"
FN="VMware-server-linux-client-${MY_PV}"
S="${WORKDIR}/vmware-console-distrib"

DESCRIPTION="VMware Remote Console for Linux"
HOMEPAGE="http://www.vmware.com/"
SRC_URI="http://download3.vmware.com/software/vmserver/${FN}.zip"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
RESTRICT="nostrip"

DEPEND=">=sys-libs/glibc-2.3.5
		virtual/os-headers
		>=dev-lang/perl-5
		app-arch/unzip
	   "
# vmware-server-console should not use virtual/libc as this is a 
# precompiled binary package thats linked to glibc.
RDEPEND=">=sys-libs/glibc-2.3.5
		 amd64? ( app-emulation/emul-linux-x86-gtklibs )
		 !amd64? ( || ( ( x11-libs/libSM
						  x11-libs/libICE
						  x11-libs/libX11
						  x11-libs/libXau
						  x11-libs/libXcursor
						  x11-libs/libXdmcp
						  x11-libs/libXext
						  x11-libs/libXfixes
						  x11-libs/libXft
						  x11-libs/libXi
						  x11-libs/libXrandr
						  x11-libs/libXrender
						  x11-libs/libXt
						  x11-libs/libXtst
	     	  		    )
			  		    virtual/x11
	        		  )
				 )
		 >=dev-lang/perl-5"

dir=/opt/vmware/server/console
Ddir=${D}/${dir}

src_unpack() {
	cd ${WORKDIR}
	unpack ${FN}.zip
	unpack ./${NP}.tar.gz
	cd ${S}
}

src_install() {
	echo 'libdir = "/opt/vmware/server/console/lib"' >etc/config
	
	dodir ${dir}/bin
	cp -pPR ${S}/bin/* ${Ddir}/bin

	dodir ${dir}/lib
	cp -dr ${S}/lib/* ${Ddir}/lib

	dodoc doc/* || die "dodoc"
	# Fix for bug #91191
	dodir ${dir}/doc
	insinto ${dir}/doc
	doins doc/EULA || die "copying EULA"

	doman ${S}/man/man1/vmware-console.1.gz || die "doman"

	# vmware enviroment
	doenvd ${FILESDIR}/99vmware-console || die "doenvd"

	dodir /etc/vmware-console/
	cp -pPR etc/* ${D}/etc/vmware-console/

	insinto ${dir}/lib/icon
	newins ${S}/doc/icon48x48.png ${PN}.png || die
	newicon ${S}/doc/icon48x48.png ${PN}.png || die
	insinto /usr/share/mime/packages
	doins ${FILESDIR}/vmware.xml

	make_desktop_entry vmware-console "VMWare Remote Console" ${PN}.png

	dodir /usr/bin
	dosym ${dir}/bin/vmware-console /usr/bin/vmware-console

	# Questions:
	einfo "Adding answers to /etc/vmware-console/locations"
	locations="${D}/etc/vmware-console/locations"
	echo "answer BINDIR ${dir}/bin" >> ${locations}
	echo "answer LIBDIR ${dir}/lib" >> ${locations}
	echo "answer MANDIR ${dir}/man" >> ${locations}
	echo "answer DOCDIR ${dir}/doc" >> ${locations}
}

pkg_preinst() {
	# This must be done after the install to get the mtimes on each file
	# right. This perl snippet gets the /etc/vmware/locations file code:
	# perl -e "@a = stat('bin/vmware'); print \$a[9]"
	# The above perl line and the find line below output the same thing.
	# I would think the find line is faster to execute.
	# find /opt/vmware/workstation/bin/vmware -printf %T@

	#Note: it's a bit weird to use ${D} in a preinst script but it should work
	#(drobbins, 1 Feb 2002)

	einfo "Generating /etc/vmware-console/locations file."
	d=`echo ${D} | wc -c`
	for x in `find ${Ddir} ${D}/etc/vmware-console` ; do
		x="`echo ${x} | cut -c ${d}-`"
		if [ -d ${D}/${x} ] ; then
			echo "directory ${x}" >> ${D}/etc/vmware-console/locations
		else
			echo -n "file ${x}" >> ${D}/etc/vmware-console/locations
			if [ "${x}" == "/etc/vmware-console/locations" ] ; then
				echo "" >> ${D}/etc/vmware-console/locations
			elif [ "${x}" == "/etc/vmware-console/not_configured" ] ; then
				echo "" >> ${D}/etc/vmware-console/locations
			else
				echo -n " " >> ${D}/etc/vmware-console/locations
				#perl -e "@a = stat('${D}${x}'); print \$a[9]" >> ${D}/etc/vmware-console/locations
				find ${D}${x} -printf %T@ >> ${D}/etc/vmware-console/locations
				echo "" >> ${D}/etc/vmware-console/locations
			fi
		fi
	done
}

pkg_config() {
	einfo "Running ${ROOT}${dir}/bin/vmware-config-console.pl"
	${ROOT}${dir}/bin/vmware-config-console.pl
}

pkg_postinst() {
	update-mime-database "${ROOT}/usr/share/mime"

	# This is to fix the problem where the not_configured file doesn't get
	# removed when the configuration is run. This doesn't remove the file
	# It just tells the vmware-config-console.pl script it can delete it.
	einfo "Updating /etc/vmware-console/locations"
	for x in "${ROOT}/etc/vmware-console/._cfg????_locations" ; do
		if [ -f $x ] ; then
			cat $x >> "${ROOT}/etc/vmware-console/locations"
			rm $x
		fi
	done

	einfo
	einfo "You need to run ${dir}/bin/vmware-config-console.pl to complete the install."
	einfo
	einfo "For VMware Add-Ons just visit"
	einfo "http://www.vmware.com/download/downloadaddons.html"
	einfo
}

pkg_postrm() {
	einfo
	einfo "To remove all traces of vmware you will need to remove the files"
	einfo "in /etc/vmware-console/."
	einfo
}
