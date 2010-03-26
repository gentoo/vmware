# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-player/vmware-player-2.5.3.185404.ebuild,v 1.4 2009/09/25 10:37:05 maekke Exp $

EAPI="2"

inherit eutils versionator fdo-mime gnome2-utils

MY_PN="VMware-Workstation"
MY_PV=$(replace_version_separator 3 - $PV)
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="Emulate a complete PC on your PC without the usual performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/workstation/"
SRC_URI="
	x86? ( with-tools? ( ${MY_PN}-Full-${MY_PV}.i386.bundle ) )
	x86? ( !with-tools? ( ${MY_PN}-${MY_PV}.i386.bundle ) )
	amd64? ( with-tools? ( ${MY_PN}-Full-${MY_PV}.x86_64.bundle ) )
	amd64? ( !with-tools? ( ${MY_PN}-${MY_PV}.x86_64.bundle ) )
	"

LICENSE="vmware"
SLOT="0"
KEYWORDS="-* ~amd64 ~x86"
IUSE="doc vix +with-tools"
RESTRICT="binchecks fetch mirror strip"

# vmware-workstation should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
DEPEND="dev-libs/libxslt"
RDEPEND="
	~app-emulation/vmware-modules-1.0.0.26
	dev-cpp/cairomm
	dev-cpp/libgnomecanvasmm
	dev-cpp/libsexymm
	dev-libs/xmlrpc-c
	net-misc/curl[ares]
	sys-apps/hal
	sys-apps/pciutils
	sys-fs/fuse
	sys-libs/glibc
	>=x11-libs/libview-0.6.2
	x11-libs/libXcursor
	x11-libs/libXft
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	!app-emulation/vmware-server
	!app-emulation/vmware-player
	"

S=${WORKDIR}
VM_INSTALL_DIR="/opt/vmware"

pkg_nofetch() {
	local bundle

	if use with-tools; then
		MY_P=${MY_PN}-Full-${MY_PV}
	fi
	if use x86; then
		bundle="${MY_P}.i386.bundle"
	elif use amd64; then
		bundle="${MY_P}.x86_64.bundle"
	fi

	einfo "Please download the ${bundle} from ${HOMEPAGE}"
	einfo "and place it in ${DISTDIR}"
}

src_unpack() {
	bundle_extract_component "${DISTDIR}/${A}" vmware-player-app
	bundle_extract_component "${DISTDIR}/${A}" vmware-player-setup
	bundle_extract_component "${DISTDIR}/${A}" vmware-workstation
	if use vix; then
		bundle_extract_component "${DISTDIR}/${A}" vmware-vix
	fi
	if use with-tools; then
		bundle_extract_component "${DISTDIR}/${A}" vmware-tools-freebsd
		bundle_extract_component "${DISTDIR}/${A}" vmware-tools-linux
		bundle_extract_component "${DISTDIR}/${A}" vmware-tools-netware
		bundle_extract_component "${DISTDIR}/${A}" vmware-tools-solaris
		bundle_extract_component "${DISTDIR}/${A}" vmware-tools-windows
		bundle_extract_component "${DISTDIR}/${A}" vmware-tools-winPre2k
	fi
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

	# install documentation
	if use doc; then
		dodoc doc/*
	fi

	# install vmware-config
	cd "${S}"/vmware-player-setup
	insinto "${VM_INSTALL_DIR}"/lib/vmware/setup
	doins vmware-config

	# install vmware-workstation
	cd "${S}"/vmware-workstation

	# install the binaries
	into "${VM_INSTALL_DIR}"
	dobin bin/*

	# install the libraries
	insinto "${VM_INSTALL_DIR}"/lib/vmware
	doins -r lib/*

	# install the ancillaries
	insinto /usr
	doins -r share

	# install documentation
	doman man/man1/vmware.1.gz

	if use doc; then
		dodoc -r doc/*
	fi

	# install vmware-vix
	if use vix; then
		cd "${S}"/vmware-vix
		# install the binary
		into "${VM_INSTALL_DIR}"
		dobin bin/*

		# install the libraries
		insinto "${VM_INSTALL_DIR}"/lib/vmware-vix
		doins -r lib/*

		dosym vmware-vix/libvixAllProducts.so "${VM_INSTALL_DIR}"/lib/libbvixAllProducts.so

		# install headers
		insinto /usr/include/vmware-vix
		doins include/*

		if use doc; then
			dohtml -r doc/*
		fi
	fi

	# install the tools isos
	if use with-tools; then
		insinto "${VM_INSTALL_DIR}"/lib/vmware/isoimages

		local tool ; for tool in vmware-tools-{freebsd,linux,netware,solaris,windows,winPre2k} ; do
			cd "${S}"/${tool}
			doins *.iso *.iso.sig
		done
	fi

	# create symlinks for the various tools
	local tool ; for tool in vmware vmplayer{,-daemon} \
			vmware-{acetool,gksu,fuseUI,modconfig{,-console},netcfg,tray,unity-helper} ; do
		dosym appLoader "${VM_INSTALL_DIR}"/lib/vmware/bin/"${tool}"
	done
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmplayer "${VM_INSTALL_DIR}"/bin/vmplayer
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmware "${VM_INSTALL_DIR}"/bin/vmware

	# fix up permissions
	chmod 0755 "${D}${VM_INSTALL_DIR}"/lib/vmware/{bin/*,lib/{libgksu2.so.0/gksu-run-helper,wrapper-gtk24.sh},setup/*}
	chmod 04711 "${D}${VM_INSTALL_DIR}"/sbin/vmware-authd
	chmod 04711 "${D}${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-vmx*
	if use vix; then
		chmod 0755 "${D}${VM_INSTALL_DIR}"/lib/vmware-vix/setup/*
	fi

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
		player.product.version = "3.0.1"
		product.buildNumber = "${build}"
		product.name = "VMware Workstation"
		workstation.product.version = "${major_minor_revision}"
	EOF

	if use vix; then
		cat >> "${D}"/etc/vmware/config <<-EOF
			vmware.fullpath = "${VM_INSTALL_DIR}/bin/vmware"
			vix.libdir = "${VM_INSTALL_DIR}/lib/vmware-vix"
			vix.config.version = "1"
		EOF
	fi

	# install the init.d script
	local initscript="${T}/vmware.rc"
	sed -e "s:@@BINDIR@@:${VM_INSTALL_DIR}/bin:g" \
		"${FILESDIR}/vmware-${major_minor}.rc" > ${initscript}
	newinitd "${initscript}" vmware

	# fill in variable placeholders
	sed -e "s:@@LIBCONF_DIR@@:${VM_INSTALL_DIR}/lib/vmware/libconf:g" \
		-i "${D}${VM_INSTALL_DIR}"/lib/vmware/libconf/etc/{gtk-2.0/{gdk-pixbuf.loaders,gtk.immodules},pango/pango{.modules,rc}}
	sed -e "s:@@BINARY@@:${VM_INSTALL_DIR}/bin/vmware:g" \
		-i "${D}/usr/share/applications/${PN}.desktop"
	sed -e "s:@@BINARY@@:${VM_INSTALL_DIR}/bin/vmplayer:g" \
		-i "${D}/usr/share/applications/vmware-player.desktop"
	sed -e "s:@@BINARY@@:${VM_INSTALL_DIR}/bin/vmware-netcfg:g" \
		-i "${D}/usr/share/applications/vmware-netcfg.desktop"

	# delete erroneous stuff
	rm -rf "${D}${VM_INSTALL_DIR}"/bin/vmware-modconfig \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libaio.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libarchive.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libart_lgpl_2.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libatk-1.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libatkmm-1.6.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libcairomm-1.0.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libcairo.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libcrypto.so.0.9.8 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libcurl.so.4 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libfontconfig.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libfreetype.so.6 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libfuse.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgailutil.so.17 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgcc_s.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgdkmm-2.4.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgdk_pixbuf-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgdk-x11-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgio-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgiomm-2.4.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgksu2.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libglade-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libglib-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libglibmm-2.4.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libglibmm_generate_extra_defs-2.4.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgmodule-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgnomecanvas-2.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgnomecanvasmm-2.6.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgobject-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgthread-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgtkmm-2.4.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgtk-x11-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libgtop-2.0.so.7 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libpango-1.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libpangocairo-1.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libpangoft2-1.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libpangomm-1.4.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libpangox-1.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libpangoxft-1.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libpng12.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/librsvg-2.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libsexymm.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libsexy.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libsigc-2.0.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libspi.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libssl.so.0.9.8 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libstartup-notification-1.so.0 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libstdc++.so.6 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXau.so.6 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXcomposite.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXcursor.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXdamage.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXdmcp.so.6 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXfixes.so.3 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXft.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXinerama.so.1 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libxml2.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libxmlrpc_client.so.3 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libxmlrpc.so.3 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libxmlrpc_util.so.3 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXrandr.so.2 \
		"${D}${VM_INSTALL_DIR}"/lib/vmware/lib/libXrender.so.1 \
		|| die "failed to remove erroneous stuff"
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
