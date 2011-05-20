PKG_CMD=		/usr/sbin/pkg register
PKG_DELETE=		/usr/sbin/pkg delete
PKG_INFO=		/usr/sbin/pkg info
PKG_VERSION=		/usr/sbin/pkg version
PKG_CREATE=		/usr/sbin/pkg create
PKG_ADD=		/usr/sbin/pkg add

PKG_SUFX=		.txz

METADIR=		${WRKDIR}/.metadir
MANIFESTF=		${METADIR}/+MANIFEST

PKGPREINSTALL?=		${PKGDIR}/pkg-pre-install
PKGPOSTINSTALL?=	${PKGDIR}/pkg-post-install
PKGPREDEINSTALL?=	${PKGDIR}/pkg-pre-deinstall
PKGPOSTDEINSTALL?=	${PKGDIR}/pkg-post-deinstall
PKGPREUPGRADE?=		${PKGDIR}/pkg-pre-upgrade
PKGPOSTUPGRADE?=	${PKGDIR}/pkg-post-upgrade
PKGUPGRADE?=		${PKGDIR}/pkg-upgrade

ACTUAL-PACKAGE-DEPENDS?= \
	if [ "${_LIB_RUN_DEPENDS}" != "  " ]; then \
		for dir in ${_LIB_RUN_DEPENDS:C,[^:]*:([^:]*):?.*,\1,}; do \
			pkgname=$$(${PKG_INFO} -q $${dir\#\#${PORTSDIR}/}); \
			${ECHO_CMD} @dep $${pkgname%-*} $${dir\#\#${PORTSDIR}/} $${pkgname\#\#*-}; \
			for pkg in $$(${PKG_INFO} -qd $${dir\#\#${PORTSDIR}/}); do\
				origin=$$(${PKG_INFO} -qo $${pkg%-*}); \
				${ECHO_CMD} $${pkg%-*} $$origin $${pkg\#\#*}; \
			done; \
		done; \
	fi

.if !target(fake-pkg)
fake-pkg:
.if !defined(NO_PKG_REGISTER)
	@${ECHO_MSG} "===>   Registering installation for ${PKGNAME}"
	@${MKDIR} ${METADIR}
	@${ECHO_CMD} "@pkg_format_version 0.9" >> ${MANIFESTF}
	@${ECHO_CMD} "@name ${PKGNAMEPREFIX}${PORTNAME}${PKGNAMESUFFIX}" >> ${MANIFESTF}
	@${ECHO_CMD} "@version ${PKGVERSION}" >> ${MANIFESTF}
	@${ECHO_CMD} "@origin ${PKGORIGIN}" >> ${MANIFESTF}
	@${ECHO_CMD} "@comment ${COMMENT}" >> ${MANIFESTF}
	@${ECHO_CMD} "@maintainer ${MAINTAINER}" >> ${MANIFESTF}
	@${ECHO_CMD} "@prefix ${PREFIX}" >> ${MANIFESTF}
.if defined(WWW)
	@${ECHO_CMD} "@www ${WWW}" >> ${MANIFESTF}
.endif
	@${MAKE} -C ${.CURDIR} actual-package-depends | ${GREP} -v -E ${PKG_IGNORE_DEPENDS} | ${SORT} -u -t : -k 2 >> ${MANIFESTF}
.if !defined(DISABLE_CONFLICTS)
.for conflicts in ${CONFLICTS}
	@${ECHO_CMD} "@conflict ${conflicts}" >> ${MANIFESTF}
.endfor
.for conflicts in ${CONFLICTS_INSTALL}
	@${ECHO_CMD} "@conflict ${conflicts}" >> ${MANIFESTF}
.endfor
.endif
.if exists(${PKGINSTALL})
	@${CP} ${PKGINSTALL} ${METADIR}/+INSTALL
.endif
.if exists(${PKGPREINSTALL})
	@${CP} ${PKGPREINSTALL} ${METADIR}/+PRE_INSTALL
.endif
.if exists(${PKGPOSTINSTALL})
	@${CP} ${PKGPOSTINSTALL} ${METADIR}/+POST_INSTALL
.endif
.if exists(${PKGDEINSTALL})
	@${CP} ${PKGDEINSTALL} ${METADIR}/+DEINSTALL
.endif
.if exists(${PKGPREDEINSTALL})
	@${CP} ${PKGPREDEINSTALL} ${METADIR}/+PRE_DEINSTALL
.endif
.if exists(${PKGPOSTDEINSTALL})
	@${CP} ${PKGPOSTDEINSTALL} ${METADIR}/+POST_DEINSTALL
.endif
.if exists(${PKGUPGRADE})
	@${CP} ${PKGUPGRADE} ${METADIR}/+UPGRADE
.endif
.if exists(${PKGPREUPGRADE})
	@${CP} ${PKGPREUPGRADE} ${METADIR}/+PRE_UPGRADE
.endif
.if exists(${PKGPOSTUPGRADE})
	@${CP} ${PKGPOSTUPGRADE} ${METADIR}/+POST_UPGRADE
.endif
	@${CP} ${DESCR} ${METADIR}/+DESC
.if exists(${PKGMESSAGE})
	@${CP} ${PKGMESSAGE} ${METADIR}/+DISPLAY
.endif
.if !defined(NO_MTREE)
	@${CP} ${MTREE_FILE} ${METADIR}/+MTREE_DIRS
.endif
	@${PKG_CMD} -l -m ${METADIR} -f ${TMPPLIST}
.else
	@${DO_NADA}
.endif
.endif

.if !target(check-build-conflicts)
check-build-conflicts:
.if ( defined(CONFLICTS) || defined(CONFLICTS_BUILD) ) && !defined(DISABLE_CONFLICTS) && !defined(DEFER_CONFLICTS_CHECK)
	@found=`${PKG_INFO} -q -go ${CONFLICTS:C/.+/'&'/} ${CONFLICTS_BUILD:C/.+/'&'/}`; \
	conflicts_with=; \
	if [ -n "$${found}" ]; then \
		prfx=`${PKG_INFO} -q -p "$${found}"`; \
		orgn=`${PKG_INFO} -q -o "$${found}"`; \
		if [ "/${PREFIX}" = "/$${prfx}" -a "/${PKGORIGIN}" != "/$${orgn}" ]; then \
			conflicts_with="$${conflicts_with} $${found}"; \
		fi; \
	fi; \
	if [ -n "$${conflicts_with}" ]; then \
		${ECHO_MSG}; \
		${ECHO_MSG} "===>  ${PKGNAME} conflicts with installed package(s): "; \
		for entry in $${conflicts_with}; do \
			${ECHO_MSG} "      $${entry}"; \
		done; \
		${ECHO_MSG}; \
		${ECHO_MSG} "      They will not build together."; \
		${ECHO_MSG} "      Please remove them first with pkg delete."; \
		exit 1;\
	fi
.endif
.endif

.if !target(identify-install-conflicts)
identify-install-conflicts:
.if ( defined(CONFLICTS) || defined(CONFLICTS_INSTALL) ) && !defined(DISABLE_CONFLICTS)
	@found=`${PKG_INFO} -q -go ${CONFLICTS:C/.+/'&'/} ${CONFLICTS_INSTALL:C/.+/'&'/}`; \
	conflicts_with=; \
	if [ -n "$${found}" ]; then \
		prfx=`${PKG_INFO} -q -p "$${found}"`; \
		orgn=`${PKG_INFO} -q -o "$${found}"`; \
		if [ "/${PREFIX}" = "/$${prfx}" -a "/${PKGORIGIN}" != "/$${orgn}" ]; then \
			conflicts_with="$${conflicts_with} $${found}"; \
		fi; \
	fi; \
	if [ -n "$${conflicts_with}" ]; then \
		${ECHO_MSG}; \
		${ECHO_MSG} "===>  ${PKGNAME} conflicts with installed package(s): "; \
		for entry in $${conflicts_with}; do \
			${ECHO_MSG} "      $${entry}"; \
		done; \
		${ECHO_MSG}; \
		${ECHO_MSG} "      They install files into the same place."; \
		${ECHO_MSG} "      You may want to stop build with Ctrl + C."; \
		sleep 10; \
	fi
.endif
.endif

.if !target(check-install-conflicts)
check-install-conflicts:
.if ( defined(CONFLICTS) || defined(CONFLICTS_INSTALL) || ( defined(CONFLICTS_BUILD) && defined(DEFER_CONFLICTS_CHECK) ) ) && !defined(DISABLE_CONFLICTS) 
.if defined(DEFER_CONFLICTS_CHECK)
	@found=`${PKG_INFO} -q -go ${CONFLICTS:C/.+/'&'/} ${CONFLICTS_BUILD:C/.+/'&'/} ${CONFLICTS_INSTALL:C/.+/'&'/}`; \
	conflicts_with=; \
	if [ -n "$${found}" ]; then \
		prfx=`${PKG_INFO} -q -p "$${found}"`; \
		orgn=`${PKG_INFO} -q -o "$${found}"`; \
		if [ "/${PREFIX}" = "/$${prfx}" -a "/${PKGORIGIN}" != "/$${orgn}" ]; then \
			conflicts_with="$${conflicts_with} $${entry}"; \
		fi; \
	fi; \
	if [ -n "$${conflicts_with}" ]; then \
		${ECHO_MSG}; \
		${ECHO_MSG} "===>  ${PKGNAME} conflicts with installed package(s): "; \
		for entry in $${conflicts_with}; do \
			${ECHO_MSG} "      $${entry}"; \
		done; \
		${ECHO_MSG}; \
		${ECHO_MSG} "      Please remove them first with pkg_delete(1)."; \
		exit 1; \
	fi
.else
	@found=`${PKG_INFO} -q -go ${CONFLICTS:C/.+/'&'/} ${CONFLICTS_INSTALL:C/.+/'&'/}`; \
	conflicts_with=; \
	if [ -n "$${found}" ]; then \
		prfx=`${PKG_INFO} -q -p "$${entry}"`; \
		orgn=`${PKG_INFO} -q -o "$${entry}"`; \
		if [ "/${PREFIX}" = "/$${prfx}" -a "/${PKGORIGIN}" != "/$${orgn}" ]; then \
			conflicts_with="$${conflicts_with} $${entry}"; \
		fi; \
	fi; \
	if [ -n "$${conflicts_with}" ]; then \
		${ECHO_MSG}; \
		${ECHO_MSG} "===>  ${PKGNAME} conflicts with installed package(s): "; \
		for entry in $${conflicts_with}; do \
			${ECHO_MSG} "      $${entry}"; \
		done; \
		${ECHO_MSG}; \
		${ECHO_MSG} "      They install files into the same place."; \
		${ECHO_MSG} "      Please remove them first with pkg_delete(1)."; \
		exit 1; \
	fi
.endif # defined(DEFER_CONFLICTS_CHECK)
.endif
.endif

.if !target(do-package)
do-package: ${TMPPLIST}
	@if [ -d ${PACKAGES} ]; then \
		if [ ! -d ${PKGREPOSITORY} ]; then \
			if ! ${MKDIR} ${PKGREPOSITORY}; then \
				${ECHO_MSG} "=> Can't create directory ${PKGREPOSITORY}."; \
				exit 1; \
			fi; \
		fi; \
	fi;
	@__softMAKEFLAGS='${__softMAKEFLAGS:S/'/'\''/g}'; \
	if ${PKG_CREATE} -o ${PKGREPOSITORY} ${PORTNAME}; then \
		if [ -d ${PACKAGES} ]; then \
			cd ${.CURDIR} && eval ${MAKE} $${__softMAKEFLAGS} package-links; \
		fi; \
	else \
		cd ${.CURDIR} && eval ${MAKE} $${__softMAKEFLAGS} delete-package; \
		exit 1; \
	fi
.endif

.if !target(check-already-installed)
check-already-installed:
.if !defined(NO_PKG_REGISTER) && !defined(FORCE_PKG_REGISTER)
		@${ECHO_MSG} "===>  Checking if ${PKGORIGIN} already installed"; \
		pkgname=`${PKG_INFO} -q -O ${PKGORIGIN}`; \
		if [ -n "$${pkgname}" ]; then \
			v=`${PKG_VERSION} -t $${pkgname} ${PKGNAME}`; \
			if [ "w$${v}" = "x<" ]; then \
				${ECHO_CMD} "===>   An older version of ${PKGORIGIN} is already installed ($${found_package})"; \
			else \
				${ECHO_CMD} "===>   ${PKGNAME} is already installed"; \
			fi; \
			${ECHO_MSG} "      You may wish to \`\`make deinstall'' and install this port again"; \
			${ECHO_MSG} "      by \`\`make reinstall'' to upgrade it properly."; \
			${ECHO_MSG} "      If you really wish to overwrite the old port of ${PKGORIGIN}"; \
			${ECHO_MSG} "      without deleting it first, set the variable \"FORCE_PKG_REGISTER\""; \
			${ECHO_MSG} "      in your environment or the \"make install\" command line."; \
			exit 1; \
		fi
.else
	@${DO_NADA}
.endif
.endif


.if !target(deinstall)
deinstall:
	@${ECHO_MSG} "===>  Deinstalling for ${PKGORIGIN}"
	@if ${PKG_INFO} -e ${PKGORIGIN}; then \
		p=`${PKG_INFO} -q ${PKGORIGIN}`; \
		${ECHO_MSG} "===>   Deinstalling $${p}"; \
		${PKG_DELETE} -f ${PKGORIGIN} ; \
	else \
		${ECHO_MSG} "===>   ${PKGBASE} not installed, skipping"; \
	fi
	@${RM} -f ${INSTALL_COOKIE} ${PACKAGE_COOKIE}
.endif

