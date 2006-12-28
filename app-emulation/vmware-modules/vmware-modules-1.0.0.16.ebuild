# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-emulation/vmware-modules/vmware-modules-1.0.0.15-r1.ebuild,v 1.1 2006/10/17 09:21:11 ikelos Exp $

KEYWORDS="-*"
VMWARE_VER="VME_S1B1"

inherit vmware-mod

VMWARE_MODULE_LIST="vmmon vmnet vmblock"
SRC_URI="http://www.example.com/VMware-workstation-e.x.p-36983.i386.tar.gz"
VMWARE_MOD_DIR="vmware-distrib/lib/modules/source/"

