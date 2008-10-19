# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-workstation/vmware-workstation-6.0.3.80004.ebuild,v 1.2 2008/04/26 16:29:15 ikelos Exp $

inherit eutils versionator fdo-mime gnome2-utils

MY_PN="VMware-Workstation-$(replace_version_separator 3 - $PV)"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="
	x86? (
		mirror://vmware/software/wkst/${MY_PN}.i386.bundle
		http://download.softpedia.ro/linux/${MY_PN}.i386.bundle )
	amd64? (
		mirror://vmware/software/wkst/${MY_PN}.x86_64.bundle
		http://download.softpedia.ro/linux/${MY_PN}.x86_64.bundle )
	"

LICENSE="vmware"
SLOT="0"
KEYWORDS="-x86 -amd64"
IUSE=""
RESTRICT="strip fetch binchecks"

# vmware-workstation should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
DEPEND=">=dev-lang/python-2.5"
RDEPEND="sys-libs/glibc
	x11-libs/libXrandr
	x11-libs/libXcursor
	x11-libs/libXinerama
	x11-libs/libXi
	x11-libs/libview
	dev-cpp/libsexymm
	dev-cpp/cairomm
	dev-cpp/libgnomecanvasmm
	virtual/xft
	!app-emulation/vmware-player
	!app-emulation/vmware-server
	~app-emulation/vmware-modules-1.0.0.23
	!<app-emulation/vmware-modules-1.0.0.23
	!>=app-emulation/vmware-modules-1.0.0.24
	sys-apps/pciutils"

S=${WORKDIR}/vmware-distrib
VM_INSTALL_DIR="/opt/vmware/workstation"

pkg_setup() {
	if use x86; then
		MY_P="${MY_PN}.i386"
	elif use amd64; then
		MY_P="${MY_PN}.x86_64"
	fi

	if ! built_with_use ">=dev-cpp/gtkmm-2.4" accessibility ; then
		eerror "Rebuild dev-cpp/gtkmm with USE=\"accessibility\""
		die "VMware workstation only works with gtkmm built with USE=\"accessibility\"."
	fi

	if ! built_with_use '>=dev-lang/python-2.5' sqlite; then
		eerror "You need build dev-lang/python with \"sqlite\" USE flag!"
		die "Please rebuild dev-lang/python with sqlite USE flag!"
	fi
}

pkg_nofetch() {
	if use x86; then
		MY_P="${MY_PN}.i386"
	elif use amd64; then
		MY_P="${MY_PN}.x86_64"
	fi

	einfo "Please download the ${MY_P}.bundle from ${HOMEPAGE}"
}

src_unpack() {
	# Unbundle the bundle
	cp "${FILESDIR}"/helpers/* "${WORKDIR}"
	chmod a+x "${WORKDIR}"/*.sh
	"${WORKDIR}"/unbundler.sh "${DISTDIR}/${MY_P}".bundle

	# Patch up the installer
	epatch ${FILESDIR}/${P}-installer.patch

	mkdir ${WORKDIR}/vmware-confdir
}

src_install() {
	dodir /etc/init.d

	#Run the installer
	local INSTALLER="${WORKDIR}/payload/install/vmware-installer"
	local PYOPTS="-W ignore::DeprecationWarning"
	export VMWARE_SKIP_NETWORKING="true"
	python ${PYOPTS} "${INSTALLER}/vmware-installer.py" \
		--set-setting vmware-installer.libconf "${INSTALLER}/lib/libconf" \
		--set-setting initdir "${T}" \
		--set-setting initscriptdir "${D}/etc/init.d" \
		--set-setting prefix "${D}${VM_INSTALL_DIR}" \
		--set-setting sysconfdir "${D}/etc" \
		--install-component "${INSTALLER}" \
		--install-bundle "${DISTDIR}/${MY_P}.bundle" \
		--console --required

	rm -fr "${D}${VM_INSTALL_DIR}/lib/vmware/modules/binary"

	# Redirect all the ${D} paths to / paths"
	sed -i -e "s:${D}::" ${WORKDIR}/vmware-confdir/bootstrap
	
	# Fix up icons/mime/desktop handlers
	dodir /usr/share/
	mv ${D}${VM_INSTALL_DIR}/share/applications ${D}/usr/share/
	rm -f ${D}${VM_INSTALL_DIR}/share/icons/hicolor/{icon-theme.cache,index.theme}
	mv ${D}${VM_INSTALL_DIR}/share/icons ${D}/usr/share/
	dodir /usr/share/mime
	mv ${D}${VM_INSTALL_DIR}/share/mime/{packages,application} ${D}/usr/share/mime
	sed -i -e "s:${D}::" ${D}/usr/share/applications/*.desktop

	# Copy across the temporary /etc/vmware directory
	dodir /etc/vmware/init.d
	cp -r "${WORKDIR}"/vmware-confdir/* "${D}/etc/vmware"
	mv "${D}"/etc/init.d/* "${D}/etc/vmware/init.d"
	newinitd ${FILESDIR}/${PN}-6.5.rc vmware
	touch ${D}/etc/vmware/networking

	# No idea why this happens, but it seems to happen all the time
	ewarn "The following installation segment takes a *very* long time."
	ewarn "Please be patient."
}

pkg_config() {
	${VM_INSTALL_DIR}/bin/vmware-networks --postinstall ${PN},old,new
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update

	ewarn "Before you can use vmware-player, you must configure a default
	network setup."
	ewarn "You can do this by running 'emerge --config ${PN}'."
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
