# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

# This eclass is for all vmware-* ebuilds in the tree and should contain all
# of the common components across the multiple packages.

# Only one package per "product" is allowed to be installed at any given time.

inherit eutils

EXPORT_FUNCTIONS pkg_preinst pkg_postinst pkg_setup src_unpack

export ANY_ANY="vmware-any-any-update101"
#export TOOLS_ANY="vmware-tools-any-update1"
export VMWARE_GROUP=${VMWARE_GROUP:-vmware}

vmware_test_module_failed() {
	eerror "You have an incompatible version of app-emulation/vmware-modules installed!"
	echo
	die "Please run 'emerge -C app-emulation/vmware-modules' before continuing"
}

vmware_test_module_build() {
	if has_version "app-emulation/vmware-modules"; then
		if test ! -e /opt/vmware/module-build; then
			eerror "Unable to determine which package the vmware-modules were compiled for"
			vmware_test_module_failed
		else
			if test "`cat /opt/vmware/module-build`" != $VMWARE_VME; then
				eerror "The vmware-modules on this system were built for a different version of vmware"
				vmware_test_module_failed
			fi
		fi
	fi
}

vmware_create_initd() {
	dodir /etc/${product}/init.d/rc{0,1,2,3,4,5,6}.d
	# This is to fix a problem where if someone merges vmware and then
	# before configuring vmware they upgrade or re-merge the vmware
	# package which would rmdir the /etc/vmware/init.d/rc?.d directories.
	keepdir /etc/${product}/init.d/rc{0,1,2,3,4,5,6}.d
}

vmware_run_questions() {
	vmware_determine_product
	# Questions:
	einfo "Adding answers to /etc/${product}/locations"
	locations="${D}/etc/${product}/locations"
	echo "answer BINDIR ${dir}/bin" >> ${locations}
	echo "answer LIBDIR ${dir}/lib" >> ${locations}
	echo "answer MANDIR ${dir}/man" >> ${locations}
	echo "answer DOCDIR ${dir}/doc" >> ${locations}
	echo "answer SBINDIR ${dir}/sbin" >> ${locations}
	echo "answer RUN_CONFIGURATOR no" >> ${locations}
	echo "answer INITDIR /etc/${product}/init.d" >> ${locations}
	echo "answer INITSCRIPTSDIR /etc/${product}/init.d" >> ${locations}
}

vmware_determine_product() {
	# This is pretty easy, thanks to portage
	shortname=$(echo ${PN} | cut -d- -f2)
	case ${shortname} in
		workstation|server|player)
			product="vmware"
			;;
		server-console|esx-console|gsx-console)
			product="vmware-console"
			;;
		workstation-tools|esx-tools|gsx-tools|server-tools)
			product="vmware-tools"
			;;
		*)
			product="unknown"
			;;
	esac
}

vmware_pkg_setup() {
	vmware_determine_product
	case ${product} in
		vmware)
			# We create a group for VMware users due to bugs #104480 and #106170
			enewgroup "${VMWARE_GROUP}"
			;;
		vmware-tools)
			# We grab our tarball from "CD"
			einfo "You will need ${TARBALL} from the VMware installation."
			einfo "Select VM->Install VMware Tools from VMware's menu."
			cdrom_get_cds ${TARBALL}
			;;
	esac
	# Here we should be doing a test_module_build, as all vmware products need
	# modules compiled.  This is commented until we can get both the products
	# and the tools using the same build system.
	#vmware_test_module_build
}

vmware_src_unpack() {
	# If there is anything to unpack, at all, then we should be using MY_P.
	if [[ -n "${MY_P}" ]]
	then
		unpack "${MY_P}".tar.gz
		cd "${S}"
		if [[ -d "${FILESDIR}/${PV}" ]]
		then
			EPATCH_SUFFIX="patch"
			epatch ${FILESDIR}/${PV}
		fi
		if [[ -n "${PATCHES}" ]]
		then
			for patch in ${PATCHES}
			do
				epatch ${FILESDIR}/${patch}
			done
		fi

		if [[ -n "${ANY_ANY}" ]]
		then
			unpack ${ANY_ANY}.tar.gz
			[[ "${product}" == "vmware" ]] && \
				mv -f ${ANY_ANY}/*.tar ${S}/lib/modules/source
			[[ -e lib/bin/vmware ]] && \
				chmod 755 lib/bin/vmware
			[[ -e bin/vmnet-bridge ]] && \
				chmod 755 bin/vmnet-bridge
			[[ -e lib/bin/vmware-vmx ]] && \
				chmod 755 lib/bin/vmware-vmx
			[[ -e lib/bin-debug/vmware-vmx ]] && \
				chmod 755 lib/bin-debug/vmware-vmx
			if [[ "${RUN_UPDATE}" == "yes" ]]
			then
				cd "${S}"/"${ANY_ANY}"
				./update vmware ../lib/bin/vmware || die
				./update bridge ../bin/vmnet-bridge || die
				./update vmx ../lib/bin/vmware-vmx || die
				./update vmxdebug ../lib/bin-debug/vmware-vmx || die
			fi
		fi
	fi
}

# This will need to be renamed once it is fully functional.
not-vmware_src_install() {
	# We won't want any perl scripts from VMware once we've finally got all
	# of the configuration done, but for now, they're necessary.
	#rm -f bin/*.pl

	# As backwards as this seems, we're installing our icons first.
	if [[ -e lib/share/icons/48x48/apps/${PN}.png ]]
	then
		doicon lib/share/icons/48x48/apps/${PN}.png
	elif [[ -e doc/icon48x48.png ]]
	then
		newicon doc/icon48x48.png ${PN}.png
	elif [[ -e ${DISTDIR}/${product}.png ]]
	then
		newicon ${DISTDIR}/${product}.png ${PN}.png
	fi

	# Since with Gentoo we compile everthing it doesn't make sense to keep
	# the precompiled modules arround. Saves about 4 megs of disk space too.
	rm -rf ${S}/lib/modules/binary
	# We also don't need to keep the icons around, or do we?
	#rm -rf ${S}/lib/share/icons

	# Just like any good monkey, we install the documentation and man pages.
	[[ -d doc ]] && dodoc doc/*
	[[ -d man ]] && cd man
	for x in *
	do
		doman ${x}/* || die "doman"
	done
	cd "${S}"

	# We loop through our directories and copy everything to our system.
	for x in bin lib sbin
	do
		if [[ -e ${S}/${x} ]]
		then
			dodir ${dir}/${x}
			cp -pPR ${S}/${x}/* ${Ddir}/${x} || die "copying ${x}"
		fi
	done

	# If we have an /etc directory, we copy it.
	if [[ -e ${S}/etc ]]
	then
		dodir /etc/${product}
		cp -pPR ${S}/etc/* ${D}/etc/${product}
		fowners root:${VMWARE_GROUP} /etc/${product}
		fperms 770 /etc/${product}
	fi

	# If we have any helper files, we install them.  First, we check for an
	# init script.
	if [[ -e ${FILESDIR}/${PN}.rc ]]
	then
		newinitd ${FILESDIR}/${PN}.rc ${product} || die "newinitd"
	fi
	# Then we check for an environment file.
	if [[ -e ${FILESDIR}/90${PN} ]]
	then
		doenvd ${FILESDIR}/90${PN} || die "doenvd"
	fi
	# Last, we check for any mime files.
	if [[ -e ${FILESDIR}/${PN}.xml ]]
	then
		insinto /usr/share/mime/packages
		doins ${FILESDIR}/${product}.xml || die "mimetypes"
	fi

	# Blame bug #91191 for this one.
	if [[ -e doc/EULA ]]
	then
		insinto ${dir}/doc
		doins doc/EULA || die "copying EULA"
	fi

	# Do we have vmware-ping/vmware-vmx?  If so, make them setuid.
	if [ -x ${Ddir}/bin/vmware-ping ]
	then
		fowners root:${VMWARE_GROUP} ${dir}/bin/vmware-ping
		fperms 4750 ${dir}/bin/vmware-ping
	fi
	if [ -x ${Ddir}/lib/bin/vmware-vmx ]
	then
		fowners root:${VMWARE_GROUP} ${dir}/lib/bin/vmware-vmx
		fperms 4750 ${dir}/lib/bin/vmware-vmx
	fi
	if [ -x ${Ddir}/lib/bin-debug/vmware-vmx ]
	then
		fowners root:${VMWARE_GROUP} ${dir}/lib/bin-debug/vmware-vmx
		fperms 4750 ${dir}/lib/bin-debug/vmware-vmx
	fi

	# This removed the user/group warnings
	chown -R root:0 ${D} || die

	# Setup some udef rules
	if [[ "${product}" == "${vmware}" ]]
	then
		dodir /etc/udev/rules.d
		echo "KERNEL==\"vmmon*\", GROUP=\"${VMWARE_GROUP}\" MODE=660" > \
			${D}/etc/udev/rules.d/60-vmware.rules || die
	fi

	# Set our full name for display and also for our icon
	case ${shortname} in
		workstation)
			FULL_NAME="Workstation"
			;;
		player)
			FULL_NAME="Player"
			;;
		server-console)
			FULL_NAME="Server Console"
			;;
		esx-console)
			FULL_NAME="ESX Console"
			;;
	esac
	# We like desktop icons.
	# TODO: Fix up the icon creation, across the board.
#	make_desktop_entry ${PN} "VMware ${FULL_NAME}"

	# TODO: Replace this junk
	# Everything after this point will hopefully go away once we can rid
	# ourselves of the evil perl configuration scripts.

	# We have to create a bunch of rc directories for the init script
	vmware_create_initd || die "creating rc directories"

	# Now, we copy in our services.sh file
	exeinto /etc/${product}/init.d
	newexe ${ANY_ANY}/services.sh ${product} || die "services.sh"

	# Then we "fix" it.
	dosed -e 's/mknod -m 600/mknod -m 660/' \
		-e '/c 119 "$vHubNr"/ a\
		chown root:vmware /dev/vmnet*\
		' /etc/${product}/init.d/${product} || die

	# Finally, we run the "questions"
	vmware_run_questions || die "running questions"
}

vmware_pkg_preinst() {
	# This must be done after the install to get the mtimes on each file
	# right.

	#Note: it's a bit weird to use ${D} in a preinst script but it should work
	#(drobbins, 1 Feb 2002)

	einfo "Generating /etc/${product}/locations file."
	d=`echo ${D} | wc -c`
	for x in `find ${Ddir} ${D}/etc/${product}` ; do
		x="`echo ${x} | cut -c ${d}-`"
		if [ -d ${D}/${x} ] ; then
			echo "directory ${x}" >> ${D}/etc/${product}/locations
		else
			echo -n "file ${x}" >> ${D}/etc/${product}/locations
			if [ "${x}" == "/etc/${product}/locations" ] ; then
				echo "" >> ${D}/etc/${product}/locations
			elif [ "${x}" == "/etc/${product}/not_configured" ] ; then
				echo "" >> ${D}/etc/${product}/locations
			else
				echo -n " " >> ${D}/etc/${product}/locations
				find ${D}${x} -printf %T@ >> ${D}/etc/${product}/locations
				echo "" >> ${D}/etc/${product}/locations
			fi
		fi
	done
}

vmware_pkg_postinst() {
	update-mime-database /usr/share/mime
	[[ -d /etc/${product} ]] && chown -R root:${VMWARE_GROUP} /etc/${product}

	# This is to fix the problem where the not_configured file doesn't get
	# removed when the configuration is run. This doesn't remove the file
	# It just tells the vmware-config.pl script it can delete it.
	einfo "Updating /etc/${product}/locations"
	for x in /etc/${product}/._cfg????_locations ; do
		if [ -f $x ] ; then
			cat $x >> /etc/${product}/locations
			rm $x
		fi
	done

	# This currently points to the perl scripts, which will eventually go away.
	case $product in
		vmware)
			config_program="vmware-config.pl"
			;;
	esac

	echo
	einfo "You need to run ${dir}/bin/${config_program} to complete the	install."
	echo
	einfo "For VMware Add-Ons just visit"
	einfo "http://www.vmware.com/download/downloadaddons.html"
	echo
	einfo "After configuring, run ${PN} to launch"
	echo
	if [ "${product}" == "vmware" -o "${product}" == "vmware-tools" ]
	then
		einfo "Also note that when you reboot you should run:"
		einfo "/etc/init.d/${product} start"
		einfo "before trying to run ${product}.  Or you could just add it to"
		einfo "the default runlevel:"
		einfo "rc-update add ${product} default"
		echo
		ewarn "VMWare allows for the potential of overwriting files as root.  Only"
		ewarn "give VMWare access to trusted individuals."
		echo
	fi
	ewarn "Remember, in order to run VMware ${FULL_NAME}, you have to"
	ewarn "be in the '${VMWARE_GROUP}' group."
	echo
}

pkg_postrm() {
	echo
	einfo "To remove all traces of ${product} you will need to remove the files"
	einfo "in /etc/${product}, /etc/init.d/${product}, /lib/modules/*/misc/vm*.o,"
	einfo "Don't forget to rmmod the vm* modules, either."
	echo
}
