# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit eutils versionator

MY_PV=$(replace_version_separator 3 '-' )
MY_P="${PN/vm/VM}-source-${MY_PV}"
S="${WORKDIR}/${MY_P}"

DESCRIPTION="Open Source VMware View Client"
HOMEPAGE="http://code.google.com/p/vmware-view-open-client/"
SRC_URI="http://vmware-view-open-client.googlecode.com/files/${MY_P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="~x86"
IUSE=""

DEPEND=">=x11-libs/gtk+-2.4.0
		>=dev-libs/libxml2-2.6.0
		>=net-misc/curl-7.16.0
		>=dev-libs/openssl-0.9.8
		>=dev-libs/boost-1.34.1"

RDEPEND=""

src_unpack() {
	unpack ${A}
	cd "${S}"
	epatch "${FILESDIR}/${PV}-curl_easy_getinfo.patch"
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
}
