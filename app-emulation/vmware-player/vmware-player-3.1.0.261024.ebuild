# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header$

EAPI="2"

inherit eutils versionator fdo-mime gnome2-utils vmware-bundle

MY_PN="VMware-Player"
MY_PV="$(replace_version_separator 3 - $PV)"
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/player/"
SRC_URI="
	x86? ( ${MY_P}.i386.bundle )
	amd64? ( ${MY_P}.x86_64.bundle )
	"

LICENSE="vmware"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE="doc +vmware-tools"
RESTRICT="binchecks fetch strip"

# vmware-workstation should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
RDEPEND="dev-cpp/cairomm
	dev-cpp/glibmm
	dev-cpp/gtkmm
	dev-cpp/libgnomecanvasmm
	dev-cpp/libsexymm
	dev-cpp/pangomm
	dev-libs/atk
	dev-libs/glib
	dev-libs/libsigc++
	dev-libs/libxml2
	dev-libs/openssl
	dev-libs/xmlrpc-c
	gnome-base/libgnomecanvas
	gnome-base/libgtop
	gnome-base/librsvg
	gnome-base/orbit
	media-libs/fontconfig
	media-libs/freetype
	media-libs/libart_lgpl
	media-libs/libpng:1.2
	net-misc/curl[ares]
	sys-devel/gcc
	sys-fs/fuse
	sys-libs/glibc
	sys-libs/zlib
	x11-libs/cairo
	x11-libs/gtk+
	x11-libs/libgksu
	x11-libs/libICE
	x11-libs/libsexy
	x11-libs/libSM
	x11-libs/libview
	x11-libs/libX11
	x11-libs/libXau
	x11-libs/libxcb
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXdmcp
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXft
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libXrender
	x11-libs/libXtst
	x11-libs/pango
	x11-libs/startup-notification
	!app-emulation/vmware-server
	!app-emulation/vmware-workstation"
PDEPEND=">=app-emulation/vmware-modules-1.0.0.27
	vmware-tools? ( app-emulation/vmware-tools )"

S=${WORKDIR}/vmware-player-app
VM_INSTALL_DIR="/opt/vmware"

pkg_nofetch() {
	local bundle

	if use x86; then
		bundle="${MY_P}.i386.bundle"
	elif use amd64; then
		bundle="${MY_P}.x86_64.bundle"
	fi

	einfo "Please download ${bundle}"
	einfo "from ${HOMEPAGE}"
	einfo "and place it in ${DISTDIR}"
}

src_unpack() {
	vmware-bundle_extract-bundle-component "${DISTDIR}/${A}" vmware-player-app
}

src_prepare() {
	rm -f bin/vmware-modconfig
	rm -rf lib/modules/binary

	# remove superfluous libraries
	ebegin 'Removing superfluous libraries'
	cd lib/lib || die
	ldconfig -p | sed 's:^\s\+\([^(]*[^( ]\).*=> /.*$:\1:g;t;d' | xargs -d'\n' -r rm -rf
	eend
}

src_install() {
	local major_minor_revision=$(get_version_component_range 1-3 "${PV}")
	local build=$(get_version_component_range 4 "${PV}")

	# install the binaries
	into "${VM_INSTALL_DIR}"
	dobin bin/* || die "failed to install bin"
	dosbin sbin/* || die "failed to install sbin"

	# install the libraries
	insinto "${VM_INSTALL_DIR}"/lib/vmware
	doins -r lib/* || die "failed to install lib"

	# these two libraries do not like to load from /usr/lib*
	local each ; for each in libcrypto.so.0.9.8 libssl.so.0.9.8 ; do
		if [[ ! -f "${VM_INSTALL_DIR}/lib/vmware/lib/${each}" ]] ; then
			dosym "/usr/$(get_libdir)/${each}" \
				"${VM_INSTALL_DIR}/lib/vmware/lib/${each}/${each}"
		fi
	done

	# install the ancillaries
	insinto /usr
	doins -r share || die "failed to install share"

	# install documentation
	if use doc; then
		dodoc doc/* || die "failed to install docs"
	fi

	# create symlinks for the various tools
	local tool ; for tool in vmplayer{,-daemon} \
			vmware-{acetool,unity-helper,modconfig{,-console},gksu,fuseUI} ; do
		dosym appLoader "${VM_INSTALL_DIR}"/lib/vmware/bin/"${tool}" || die
	done
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmplayer "${VM_INSTALL_DIR}"/bin/vmplayer || die

	# fix up permissions
	chmod 0755 "${D}${VM_INSTALL_DIR}"/lib/vmware/{bin/*,lib/wrapper-gtk24.sh}
	chmod 04711 "${D}${VM_INSTALL_DIR}"/sbin/vmware-authd
	chmod 04711 "${D}${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-vmx*

	# create the environment
	local envd="${T}/90vmware"
	cat > "${envd}" <<-EOF
		PATH='${VM_INSTALL_DIR}/bin'
		ROOTPATH='${VM_INSTALL_DIR}/bin'
	EOF
	doenvd "${envd}" || die

	# create the configuration
	dodir /etc/vmware || die

	cat > "${D}"/etc/vmware/bootstrap <<-EOF
		BINDIR='${VM_INSTALL_DIR}/bin'
		LIBDIR='${VM_INSTALL_DIR}/lib'
	EOF

	cat > "${D}"/etc/vmware/config <<-EOF
		bindir = "${VM_INSTALL_DIR}/bin"
		libdir = "${VM_INSTALL_DIR}/lib/vmware"
		initscriptdir = "/etc/init.d"
		authd.fullpath = "${VM_INSTALL_DIR}/sbin/vmware-authd"
		gksu.rootMethod = "su"
		VMCI_CONFED = "yes"
		VMBLOCK_CONFED = "yes"
		VSOCK_CONFED = "yes"
		NETWORKING = "yes"
		player.product.version = "${major_minor_revision}"
		product.buildNumber = "${build}"
	EOF

	# install the init.d script
	local initscript="${T}/vmware.rc"

	sed -e "s:@@BINDIR@@:${VM_INSTALL_DIR}/bin:g" \
		"${FILESDIR}/vmware-3.0.rc" > "${initscript}" || die
	newinitd "${initscript}" vmware || die

	# fill in variable placeholders
	sed -e "s:@@LIBCONF_DIR@@:${VM_INSTALL_DIR}/lib/vmware/libconf:g" \
		-i "${D}${VM_INSTALL_DIR}"/lib/vmware/libconf/etc/{gtk-2.0/{gdk-pixbuf.loaders,gtk.immodules},pango/pango{.modules,rc}} || die
	sed -e "s:@@BINARY@@:${VM_INSTALL_DIR}/bin/vmplayer:g" \
		-i "${D}/usr/share/applications/${PN}.desktop" || die
}

pkg_config() {
	"${VM_INSTALL_DIR}"/bin/vmware-networks --postinstall ${PN},old,new
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update

	ewarn "/etc/env.d was updated. Please run:"
	ewarn "env-update && source /etc/profile"
	ewarn ""
	ewarn "Before you can use vmware-player, you must configure a default network setup."
	ewarn "You can do this by running 'emerge --config ${PN}'."
}

pkg_prerm() {
	einfo "Stopping ${PN} for safe unmerge"
	/etc/init.d/vmware stop
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
