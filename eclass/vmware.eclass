# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# This eclass is for all vmware-* ebuilds in the tree and should contain all
# of the common components across the multiple packages.

ECLASS="vmware"

vmware_test_module_failed() {

		eerror
		eerror "Please run:"
		eerror
		eerror "   emerge -C app-emulation/vmware-modules"
		eerror
		eerror "before attemping to install this package"
		die "Please run 'emerge -C app-emulation/vmware-modules' before continuing"
}

vmware_test_module_build() {
	if has_version "app-emulation/vmware-modules"; then
		if test ! -e /opt/vmware/module-build; then
			eerror
			eerror "Unable to determine which package"
			eerror "the vmware-modules were compiled for"
			vmware_test_module_failed
		else
			if test "`cat /opt/vmware/module-build`" != $VMWARE_VME; then
				eerror
				eerror "The vmware-modules on this system were"
				eerror "built for a different version of vmware"
				vmware_test_module_failed
			fi
		fi
	fi
}

# These are currently setup for vmware-workstation-tools, but will be adjusted
# to be more generic as they should be reused for each package.

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
	keepdir /etc/vmware/init.d/rc{0,1,2,3,4,5,6}.d
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
	echo "answer INITDIR /etc/vmware/init.d" >> ${locations}
	echo "answer INITSCRIPTSDIR /etc/vmware/init.d" >> ${locations}
}
