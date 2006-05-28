# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $ Id: $

# Unlike many other binary packages the user doesn't need to agree to a licence
# to download VMWare. The agreeing to a licence is part of the configure step
# which the user must run manually.

inherit eutils

S=${WORKDIR}/vmware-distrib
ANY_ANY="vmware-any-any-update101"
NP="VMware-workstation-4.5.3-19414"
DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="http://vmware-svca.www.conxion.com/software/wkst/${NP}.tar.gz
	http://download3.vmware.com/software/wkst/${NP}.tar.gz
	http://download.vmware.com/htdocs/software/wkst/${NP}.tar.gz
	http://www.vmware.com/download1/software/wkst/${NP}.tar.gz
	ftp://download1.vmware.com/pub/software/wkst/${NP}.tar.gz
	http://vmware-chil.www.conxion.com/software/wkst/${NP}.tar.gz
	http://vmware-heva.www.conxion.com/software/wkst/${NP}.tar.gz
	http://vmware.wespe.de/software/wkst/${NP}.tar.gz
	ftp://vmware.wespe.de/pub/software/wkst/${NP}.tar.gz
	http://ftp.cvut.cz/vmware/${ANY_ANY}.tar.gz
	http://ftp.cvut.cz/vmware/obselete/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/${ANY_ANY}.tar.gz
	http://knihovny.cvut.cz/ftp/pub/vmware/obselete/${ANY_ANY}.tar.gz
	mirror://gentoo/vmware.png"

LICENSE="vmware"
IUSE=""
SLOT="0"
KEYWORDS="-* amd64 x86"
RESTRICT="nostrip"

DEPEND="virtual/os-headers"

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
	sys-apps/pciutils"
#	>=sys-apps/baselayout-1.11.14"

dir=/opt/vmware/workstation
Ddir=${D}/${dir}
VMWARE_GROUP=${VMWARE_GROUP:-vmware}

pkg_setup() {
	# This is due to both bugs #104480 and #106170
	enewgroup "${VMWARE_GROUP}"
}

src_unpack() {
	unpack ${NP}.tar.gz
	cd ${S}
	# Patch to resolve problems with VMware finding its distributed libraries.
	# Patch submitted to bug #59035 by Georgi Georgiev <chutz@gg3.net>
	epatch ${FILESDIR}/${P}-librarypath.patch
	epatch ${FILESDIR}/${PN}-5.5.1.19175-config3.patch
	unpack ${ANY_ANY}.tar.gz
	mv -f ${ANY_ANY}/*.tar ${S}/lib/modules/source/
	cd ${S}/${ANY_ANY}
	chmod 755 ../lib/bin/vmware ../bin/vmnet-bridge ../lib/bin/vmware-vmx ../lib/bin-debug/vmware-vmx
	# vmware any96 still doesn't patch the vmware binary
	#./update vmware ../lib/bin/vmware || die
	./update bridge ../bin/vmnet-bridge || die
	./update vmx ../lib/bin/vmware-vmx || die
	./update vmxdebug ../lib/bin-debug/vmware-vmx || die
}

src_install() {
	dodir ${dir}/bin
	cp -pPR bin/* ${Ddir}/bin

	dodir ${dir}/lib
	cp -dr lib/* ${Ddir}/lib
	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${Ddir}/lib/modules/binary
	# We also remove the rpath libgdk_pixbuf stuff, to resolve bug #81344.
	perl -pi -e 's#/tmp/rrdharan/out#/opt/vmware/null/#sg' \
		${Ddir}/lib/lib/libgdk_pixbuf.so.2/lib{gdk_pixbuf.so.2,pixbufloader-{xpm,png}.so.1.0.0} \
		|| die "Removing rpath"
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

	dodir /etc/vmware/init.d
	dodir /etc/vmware/init.d/rc0.d
	dodir /etc/vmware/init.d/rc1.d
	dodir /etc/vmware/init.d/rc2.d
	dodir /etc/vmware/init.d/rc3.d
	dodir /etc/vmware/init.d/rc4.d
	dodir /etc/vmware/init.d/rc5.d
	dodir /etc/vmware/init.d/rc6.d
	cp -pPR installer/services.sh ${D}/etc/vmware/init.d/vmware || die
	dosed 's/mknod -m 600/mknod -m 660/' /etc/vmware/init.d/vmware || die
	dosed '/c 119 "$vHubNr"/ a\
		chown root:vmware /dev/vmnet*\
		' /etc/vmware/init.d/vmware || die

	# This is to fix a problem where if someone merges vmware and then
	# before configuring vmware they upgrade or re-merge the vmware
	# package which would rmdir the /etc/vmware/init.d/rc?.d directories.
	keepdir /etc/vmware/init.d/rc{0,1,2,3,4,5,6}.d

	# A simple icon I made
	insinto ${dir}/lib/icon
	doins ${DISTDIR}/vmware.png || die
	doicon ${DISTDIR}/vmware.png || die

	make_desktop_entry vmware "VMWare Workstation" vmware.png

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

	# this adds udev rules for vmmon*
	dodir /etc/udev/rules.d
	echo 'KERNEL=="vmmon*", GROUP="vmware" MODE=660' > \
		${D}/etc/udev/rules.d/60-vmware.rules || die

	# Questions:
	einfo "Adding answers to /etc/vmware/locations"
	locations="${D}/etc/vmware/locations"
	echo "answer BINDIR ${dir}/bin" >> ${locations}
	echo "answer LIBDIR ${dir}/lib" >> ${locations}
	echo "answer MANDIR ${dir}/man" >> ${locations}
	echo "answer DOCDIR ${dir}/doc" >> ${locations}
	echo "answer RUN_CONFIGURATOR no" >> ${locations}
	echo "answer INITDIR /etc/vmware/init.d" >> ${locations}
	echo "answer INITSCRIPTSDIR /etc/vmware/init.d" >> ${locations}
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

	einfo "Generating /etc/vmware/locations file."
	d=`echo ${D} | wc -c`
	for x in `find ${Ddir} ${D}/etc/vmware` ; do
		x="`echo ${x} | cut -c ${d}-`"
		if [ -d ${D}/${x} ] ; then
			echo "directory ${x}" >> ${D}/etc/vmware/locations
		else
			echo -n "file ${x}" >> ${D}/etc/vmware/locations
			if [ "${x}" == "/etc/vmware/locations" ] ; then
				echo "" >> ${D}/etc/vmware/locations
			elif [ "${x}" == "/etc/vmware/not_configured" ] ; then
				echo "" >> ${D}/etc/vmware/locations
			else
				echo -n " " >> ${D}/etc/vmware/locations
				#perl -e "@a = stat('${D}${x}'); print \$a[9]" >> ${D}/etc/vmware/locations
				find ${D}${x} -printf %T@ >> ${D}/etc/vmware/locations
				echo "" >> ${D}/etc/vmware/locations
			fi
		fi
	done
}

pkg_config() {
	einfo "Running ${dir}/bin/vmware-config.pl"
	${dir}/bin/vmware-config.pl
}

pkg_postinst() {
	# This is to fix the problem where the not_configured file doesn't get
	# removed when the configuration is run. This doesn't remove the file
	# It just tells the vmware-config.pl script it can delete it.
	einfo "Updating /etc/vmware/locations"
	for x in /etc/vmware/._cfg????_locations ; do
		if [ -f $x ] ; then
			cat $x >> /etc/vmware/locations
			rm $x
		fi
	done

	einfo
	einfo "You need to run ${dir}/bin/vmware-config.pl"
	einfo "to complete the install."
	echo
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
