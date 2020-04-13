# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils versionator readme.gentoo-r1 gnome2-utils pax-utils systemd vmware-bundle xdg-utils

MY_PN="VMware-Player"
MY_PV=$(get_version_component_range 1-3)
PV_MODULES="308.$(get_version_component_range 2-3)"
PV_BUILD=$(get_version_component_range 4)
MY_P="${MY_PN}-${MY_PV}-${PV_BUILD}"

SYSTEMD_UNITS_TAG="gentoo-02"

DESCRIPTION="Emulate a complete PC without the performance overhead of most emulators"
HOMEPAGE="http://www.vmware.com/products/player/"
BASE_URI="https://softwareupdate.vmware.com/cds/vmw-desktop/player/${MY_PV}/${PV_BUILD}/linux/core/"
SRC_URI="
	${BASE_URI}${MY_P}.x86_64.bundle.tar
	https://github.com/akhuettel/systemd-vmware/archive/${SYSTEMD_UNITS_TAG}.tar.gz -> vmware-systemd-${SYSTEMD_UNITS_TAG}.tgz
"

LICENSE="vmware GPL-2 GPL-3"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="cups doc ovftool +vmware-tools"
RESTRICT="mirror strip"

# vmware should not use virtual/libc as this is a
# precompiled binary package thats linked to glibc.
RDEPEND="
	|| (
		>=media-libs/libjpeg-turbo-1.3.0-r3:0
		>=media-libs/jpeg-6b-r12:62
	)
	media-libs/alsa-lib
	net-print/cups
	x11-libs/libICE
	x11-libs/libSM
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXtst
	x11-libs/startup-notification
	x11-themes/hicolor-icon-theme
	!app-emulation/vmware-workstation
"
PDEPEND="~app-emulation/vmware-modules-${PV_MODULES}
	vmware-tools? ( app-emulation/vmware-tools )"
DEPEND=">=dev-util/patchelf-0.9"

S=${WORKDIR}
VM_INSTALL_DIR="/opt/vmware"

QA_PREBUILT="/opt/*"

QA_WX_LOAD="opt/vmware/lib/vmware/tools-upgraders/vmware-tools-upgrader-32 opt/vmware/lib/vmware/bin/vmware-vmx-stats opt/vmware/lib/vmware/bin/vmware-vmx-debug opt/vmware/lib/vmware/bin/vmware-vmx"

src_unpack() {
	default
	local bundle=${MY_P}.x86_64.bundle

	local component; for component in \
		vmware-player \
		vmware-player-app \
		vmware-player-setup \
		vmware-vmx \
		vmware-network-editor \
		vmware-usbarbitrator
	do
		vmware-bundle_extract-bundle-component "${bundle}" "${component}" "${S}"
	done

	if use ovftool; then
		vmware-bundle_extract-bundle-component "${bundle}" vmware-ovftool
	fi
}

src_prepare() {
	rm -f bin/vmware-modconfig
	rm -rf lib/modules/binary
	# Bug 459566
	mv lib/libvmware-netcfg.so lib/lib/

	# if librsvg is not installed in the system then vmware doesn't start
	pushd >/dev/null .
	einfo "Patching svg_loader.so"
	cd "${S}"/lib/libconf/lib/gtk-2.0/2.10.0/loaders || die
	patchelf --set-rpath "\$ORIGIN/../../../../../lib/librsvg-2.so.2" \
		svg_loader.so || die
	popd >/dev/null

	DOC_CONTENTS="
/etc/env.d is updated during ${PN} installation. Please run:\n
env-update && source /etc/profile\n
Before you can use ${PN}, you must configure a default network setup.
You can do this by running 'emerge --config ${PN}'.\n
To be able to run ${PN} your user must be in the vmware group.\n
"
}

src_install() {
	local major_minor=$(get_version_component_range 1-2 "${PV}")

	# revdep-rebuild entry
	insinto /etc/revdep-rebuild
	echo "SEARCH_DIRS_MASK=\"${VM_INSTALL_DIR}\"" >> ${T}/10${PN}
	doins "${T}"/10${PN}

	# install the binaries
	into "${VM_INSTALL_DIR}"
	dobin bin/*

	# install the libraries
	insinto "${VM_INSTALL_DIR}"/lib/vmware
	doins -r lib/*

	# bug 616958
	# system libs don't work anymore with embedeed zlib because it doesn't support ZLIB_1.2.9,
	# add this hack to bypass embedded zlib which is always loaded and required during startup
	# of vmware since 12.5.x
	dosym /$(get_libdir)/libz.so.1 \
			"${VM_INSTALL_DIR}"/lib/vmware/lib/libz.so.1/libz.so.1

	# install the ancillaries
	insinto /usr
	doins -r share

	if use cups; then
		exeinto $(cups-config --serverbin)/filter
		doexe extras/thnucups

		insinto /etc/cups
		doins -r etc/cups/*
	fi

	if use doc; then
		dodoc doc/*
	fi

	exeinto "${VM_INSTALL_DIR}"/lib/vmware/setup
	doexe vmware-config

	# install ovftool
	if use ovftool; then
		cd "${S}"

		insinto "${VM_INSTALL_DIR}"/lib/vmware-ovftool
		doins -r vmware-ovftool/*

		chmod 0755 "${D}${VM_INSTALL_DIR}"/lib/vmware-ovftool/{ovftool,ovftool.bin}
		dosym "${D}${VM_INSTALL_DIR}"/lib/vmware-ovftool/ovftool "${VM_INSTALL_DIR}"/bin/ovftool
	fi

	# create symlinks for the various tools
	local tool ; for tool in thnuclnt vmplayer{,-daemon} \
			vmware-{acetool,modconfig{,-console},gksu,fuseUI} ; do
		dosym appLoader "${VM_INSTALL_DIR}"/lib/vmware/bin/"${tool}"
	done
	dosym "${VM_INSTALL_DIR}"/lib/vmware/bin/vmplayer "${VM_INSTALL_DIR}"/bin/vmplayer
	dosym "${VM_INSTALL_DIR}"/lib/vmware/icu /etc/vmware/icu

	# fix permissions
	fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware/bin/{appLoader,fusermount,launcher.sh,mkisofs,vmware-remotemks}
	fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware/lib/wrapper-gtk24.sh
	fperms 0755 "${VM_INSTALL_DIR}"/lib/vmware/lib/libgksu2.so.0/gksu-run-helper
	fperms 4711 "${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-vmx{,-debug,-stats}

	pax-mark -m "${D}${VM_INSTALL_DIR}"/lib/vmware/bin/vmware-vmx

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
		player.product.version = "${MY_PV}"
		product.buildNumber = "${PV_BUILD}"
	EOF

	# install the init.d script
	local initscript="${T}/vmware.rc"
	sed -e "s:@@BINDIR@@:${VM_INSTALL_DIR}/bin:g" \
		"${FILESDIR}/vmware-${major_minor}.rc" > "${initscript}" || die
	newinitd "${initscript}" vmware

	# fill in variable placeholders
	sed -e "s:@@LIBCONF_DIR@@:${VM_INSTALL_DIR}/lib/vmware/libconf:g" \
		-i "${D}${VM_INSTALL_DIR}"/lib/vmware/libconf/etc/{gtk-2.0/{gdk-pixbuf.loaders,gtk.immodules},pango/pango{.modules,rc}} || die
	sed -e "s:@@BINARY@@:${VM_INSTALL_DIR}/bin/vmplayer:g" \
		-e "/^Encoding/d" \
		-i "${D}/usr/share/applications/vmware-player.desktop" || die

	# install systemd unit files
	systemd_dounit "${WORKDIR}/systemd-vmware-${SYSTEMD_UNITS_TAG}/"*.{service,target}

	readme.gentoo_create_doc
}

pkg_config() {
	"${VM_INSTALL_DIR}"/bin/vmware-networks --postinstall ${PN},old,new
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	gnome2_icon_cache_update
	readme.gentoo_print_elog

	ewarn "${P} is using an old version of libgcrypt library which"
	ewarn "has been removed from portage due to security reasons"
	ewarn "(see also bugs #567382 or #656372)."
	ewarn "This version of vmware is not going to be fixed upstream (EOL)"
	ewarn "so you're exposed to security issues!"
}

pkg_prerm() {
	einfo "Stopping ${PN} for safe unmerge"
	/etc/init.d/vmware stop
}

pkg_postrm() {
	xdg_desktop_database_update
	xdg_mimeinfo_database_update
	gnome2_icon_cache_update
}
