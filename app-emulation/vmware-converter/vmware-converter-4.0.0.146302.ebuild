# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-workstation/vmware-workstation-5.5.6.80404.ebuild,v 1.2 2008/04/26 16:29:15 ikelos Exp $

inherit vmware eutils versionator

MY_P="VMware-converter-$(replace_version_separator 3 - $PV)"

DESCRIPTION="Converts a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/download/ws/ws5.html"
SRC_URI="${MY_P}.tar.gz"

LICENSE="vmware"
SLOT="0"
KEYWORDS="-*"
IUSE="server client"
RESTRICT="fetch strip"

# vmware-workstation should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
RDEPEND="sys-libs/glibc
	amd64? (
		client? (
			app-emulation/emul-linux-x86-gtklibs 
			)
		)
	x86? (
		client? (
			x11-libs/libXrandr
			x11-libs/libXcursor
			x11-libs/libXinerama
			x11-libs/libXi
			x11-libs/libXft 
			)
		)
	>=dev-lang/perl-5
	sys-apps/pciutils"

S=${WORKDIR}/vmware-converter-distrib

RUN_UPDATE="no"
ANY_ANY=""

dir=/opt/vmware/converter
Ddir=${D}/${dir}

src_unpack() {
	vmware_src_unpack
	cd ${S}
	rmdir sbin

	sed -i -e "s|##{CONFDIR}##|/etc/vmware-converter|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{LIBDIR}##|${VMWARE_INSTALL_DIR}/lib|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{DATADIR}##|/var/lib/vmware-vcenter-converter-standalone|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{LOGDIR}##|/var/log/vmware-vcenter-converter-standalone|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{FORCELOCAL}##|false|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{STANDALONE}##|true|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{LOGINBOX}##|true|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{ENABLE_REMOTE_ACCESS}##|true|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{PROXY_HTTP_PORT}##|80|" ${S}/conf/converter-*.xml
	sed -i -e "s|##{PROXY_HTTPS_PORT}##|443|" ${S}/conf/converter-*.xml
}

src_install() {
	# Sed and install the files in ./conf
	cd ${S}
	insinto /etc/${PN}
	doins etc/icudt38l.dat
	doins conf/*	

	# mkdir libdir and copy over the common stuff

	cd ${S}/lib
	dodir "${VMWARE_INSTALL_DIR}/lib"
	cp -rP common/* "${D}/${VMWARE_INSTALL_DIR}/lib" || die "Failed to copy common files"
	use server && ( cp -rP server/* "${D}/${VMWARE_INSTALL_DIR}/lib" || die "Failed to copy server files" )
	use client && ( cp -rP client/* "${D}/${VMWARE_INSTALL_DIR}/lib" || die "Failed to copy client files" )

	# Symlink everything up
	dodir "${VMWARE_INSTALL_DIR}/bin"
	for i in ${D}/${VMWARE_INSTALL_DIR}/lib/bin/*;
	do
		j=$(basename ${i})
		dosym "${VMWARE_INSTALL_DIR}/lib/bin/${j}" "${VMWARE_INSTALL_DIR}/bin/${j}"
	done

	if $(use server);
	then
		dodir /etc/${PN}/init.d
		exeinto /etc/${PN}/init.d
		doexe ${S}/system_etc/init.d/${PN}
		newinitd ${FILESDIR}/${PN}.rc ${PN}
	fi

	dosym /opt/vmware/converter/lib/configurator/pam.d/${PN} /etc/pam.d/${PN}

	# Finally, we run the "questions"
	vmware_run_questions || die "running questions"
	
	use server && ( echo "answer INSTALL_SERVER yes" >> "${D}${config_dir}/locations" )
	echo "answer ENABLE_REMOTE_ACCESS yes" >> "${D}${config_dir}/locations"
}
