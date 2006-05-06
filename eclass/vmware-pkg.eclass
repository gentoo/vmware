# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Original Author: ikelos
# Purpose: Provide vmware packages a method of shared the vmware-modules package
#

ECLASS="vmware-pkg"
# INHERITED="$INHERITED $ECLASS"

PDEPEND=">=app-emulation/vmware-modules-101"

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
