# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-player/vmware-player-2.5.3.185404.ebuild,v 1.4 2009/09/25 10:37:05 maekke Exp $

EAPI="2"

inherit eutils versionator fdo-mime gnome2-utils

MY_PN="VMware-Player-$(replace_version_separator 3 - $PV)"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/desktop/ws_features.html"
SRC_URI="
	x86? ( mirror://vmware/software/vmplayer/${MY_PN}.i386.bundle )
	amd64? ( mirror://vmware/software/vmplayer/${MY_PN}.x86_64.bundle )
	"

LICENSE="vmware"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE=""
RESTRICT="binchecks fetch strip"

# vmware-workstation should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
DEPEND="dev-libs/libxslt"
RDEPEND="
	~app-emulation/vmware-modules-1.0.0.26
	dev-cpp/cairomm
	dev-cpp/libgnomecanvasmm
	dev-cpp/libsexymm
	sys-libs/glibc
	sys-apps/pciutils
	>=x11-libs/libview-0.6.2
	x11-libs/libXcursor
	x11-libs/libXft
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	!app-emulation/vmware-server
	!app-emulation/vmware-workstation
	"

S=${WORKDIR}
VM_INSTALL_DIR="/opt/vmware"

pkg_nofetch() {
	if use x86; then
		MY_P="${MY_PN}.i386"
	elif use amd64; then
		MY_P="${MY_PN}.x86_64"
	fi

	einfo "Please download the ${MY_P}.bundle from ${HOMEPAGE}"
}

src_unpack() {
	bundle_extract_component "${DISTDIR}/${A}" vmware-player-app
}

src_prepare() {
	rm -rf "${S}"/vmware-player-app/lib/modules/binary
}

src_install() {
	local major_minor=$(get_version_component_range 1-2 "${PV}")
	local major_minor_revision=$(get_version_component_range 1-3 "${PV}")
	local build=$(get_version_component_range 4 "${PV}")

	cd "${S}"/vmware-player-app

	# install the binaries
	into "${VM_INSTALL_DIR}"
	dobin bin/*
	dosbin sbin/*

	# install the libraries
	insinto "${VM_INSTALL_DIR}"/lib/vmware
	doins -r lib/*

	# install the ancillaries
	insinto /usr
	doins -r share

	# create symlinks for the various tools
	local tool ; for tool in vmplayer{,-daemon} \
			vmware-{acetool,unity-helper,modconfig{,-console},gksu,fuseUI} ; do
		dosym appLoader "${VM_INSTALL_DIR}"/lib/vmware/bin/"${tool}"
	done
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmplayer "${VM_INSTALL_DIR}"/bin/vmplayer

	# fix up permissions
	chmod 0755 "${D}${VM_INSTALL_DIR}"/lib/vmware/{bin/*,lib/{libgksu2.so.0/gksu-run-helper,wrapper-gtk24.sh}}
	chmod 04711 "${D}${VM_INSTALL_DIR}"/sbin/vmware-authd
	chmod 04711 "${D}${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-vmx*

	# create the environment
	local envd="${T}/90vmware"
	cat > "${envd}" <<-EOF
		PATH='${VM_INSTALL_DIR}/bin'
		ROOTPATH='${VM_INSTALL_DIR}/bin'
	EOF
	doenvd "${envd}"

	# create the configuration
	dodir /etc/vmware

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
		"${FILESDIR}/vmware-${major_minor}.rc" > ${initscript}
	newinitd "${initscript}" vmware

	# fill in variable placeholders
	sed -e "s:@@LIBCONF_DIR@@:${VM_INSTALL_DIR}/lib/vmware/libconf:g" \
		-i "${D}${VM_INSTALL_DIR}"/lib/vmware/libconf/etc/{gtk-2.0/{gdk-pixbuf.loaders,gtk.immodules},pango/pango{.modules,rc}}
	sed -e "s:@@BINARY@@:${VM_INSTALL_DIR}/bin/vmplayer:g" \
		-i "${D}/usr/share/applications/${PN}.desktop"

	# install documentation
	dodoc doc/*
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

	ewarn "env.d was updated. Please run:"
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

bundle_extract_component() {
	local -i bundle_size=$(stat -L -c'%s' "${1}")
	local -i bundle_manifestOffset=$(od -An -j$((bundle_size-36)) -N4 -tu4 "${1}")
	local -i bundle_manifestSize=$(od -An -j$((bundle_size-40)) -N4 -tu4 "${1}")
	local -i bundle_dataOffset=$(od -An -j$((bundle_size-44)) -N4 -tu4 "${1}")
	local -i bundle_dataSize=$(od -An -j$((bundle_size-52)) -N8 -tu8 "${1}")
	tail -c+$((bundle_manifestOffset+1)) "${1}" 2> /dev/null | head -c$((bundle_manifestSize)) |
		xsltproc "${FILESDIR}"/list-bundle-components.xsl - |
		while read -r component_offset component_size component_name ; do
			if [[ ${component_name} == ${2} ]] ; then
				ebegin "Extracting '${component_name}' component from '$(basename "${1}")'"
				declare -i component_manifestOffset=$(od -An -j$((bundle_dataOffset+component_offset+9)) -N4 -tu4 "${1}")
				declare -i component_manifestSize=$(od -An -j$((bundle_dataOffset+component_offset+13)) -N4 -tu4 "${1}")
				declare -i component_dataOffset=$(od -An -j$((bundle_dataOffset+component_offset+17)) -N4 -tu4 "${1}")
				declare -i component_dataSize=$(od -An -j$((bundle_dataOffset+component_offset+21)) -N8 -tu8 "${1}")
				tail -c+$((bundle_dataOffset+component_offset+component_manifestOffset+1)) "${1}" 2> /dev/null |
					head -c$((component_manifestSize)) | xsltproc "${FILESDIR}"/list-component-files.xsl - |
					while read -r file_offset file_compressedSize file_uncompressedSize file_path ; do
						if [[ ${file_path} ]] ; then
							echo -n '.'
							file_path="${component_name}/${file_path}"
							mkdir -p "$(dirname "${file_path}")"
							tail -c+$((bundle_dataOffset+component_offset+component_dataOffset+file_offset+1)) "${1}" 2> /dev/null |
								head -c$((file_compressedSize)) | gzip -cd > "${file_path}"
						fi
					done
				echo ; eend
			fi
		done
}
