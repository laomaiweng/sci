# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit eutils flag-o-matic fortran-2 multilib toolchain-funcs

DESCRIPTION="Message-passing parallel language and runtime system"
HOMEPAGE="http://charm.cs.uiuc.edu/"
SRC_URI="http://charm.cs.uiuc.edu/distrib/${P}.tar.gz"

LICENSE="charm"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="cmkopt doc examples smp static-libs tcp"

DEPEND="
	doc? (
	>=app-text/poppler-0.12.3-r3[utils]
	dev-tex/latex2html
	virtual/tex-base )"
RDEPEND=""

FORTRAN_STANDARD="90"

src_prepare() {
	#epatch "${FILESDIR}"/${P}-gcc-4.7.patch

	# For production, disable debugging features.
	CHARM_OPTS="--with-production --build-shared"

	# TCP instead of default UDP for socket comunication
	# protocol
	if use tcp; then
		CHARM_OPTS+=" tcp"
	fi

	# enable direct SMP support using shared memory
	if use smp; then
		CHARM_OPTS+=" smp"
	fi

	# CMK optimization
	if use cmkopt; then
		append-flags -DCMK_OPTIMIZE=1
	fi

	sed \
		-e "/CMK_CF90/s:f90:$(tc-getFC):g" \
		-e "/CMK_CXX/s:g++:$(tc-getCXX):g" \
		-e "/CMK_CC/s:gcc:$(tc-getCC):g" \
		-e '/CMK_F90_MODINC/s:-p:-I:g' \
		-e "/CMK_LD/s:\"$: ${LDFLAGS} \":g" \
		-i src/arch/net-linux*/*sh || die

	sed \
		-e "s:-o conv-cpm:${LDFLAGS} &:g" \
		-e "s:-o charmxi:${LDFLAGS} &:g" \
		-e "s:-o charmrun-silent:${LDFLAGS} &:g" \
		-e "s:-o charmrun-notify:${LDFLAGS} &:g" \
		-e "s:-o charmrun:${LDFLAGS} &:g" \
		-e "s:-o charmd_faceless:${LDFLAGS} &:g" \
		-e "s:-o charmd:${LDFLAGS} &:g" \
		-i \
		src/scripts/Makefile \
		src/arch/net/charmrun/Makefile || die

	append-cflags -DALLOCA_H

	echo "charm opts: ${CHARM_OPTS}"
}

src_compile() {
	# build charmm++ first
	./build charm++ net-linux$( use amd64 && echo "-amd64" ) ${CHARM_OPTS} ${MAKEOPTS} ${CFLAGS} || \
		die "Failed to build charm++"

	# make charmc play well with gentoo before
	# we move it into /usr/bin
	epatch "${FILESDIR}/charm-6.5.0-charmc-gentoo.patch"

	# make pdf/html docs
	if use doc; then
		cd "${S}"/doc
		make doc || die "failed to create pdf/html docs"
	fi
}

src_install() {
	sed -e "s|gentoo-include|${P}|" \
		-e "s|gentoo-libdir|$(get_libdir)|g" \
		-e "s|VERSION|${P}/VERSION|" \
		-i ./src/scripts/charmc || die "failed patching charmc script"

	# In the following, some of the files are symlinks to ../tmp which we need
	# to dereference first (see bug 432834).

	local i

	# Install binaries.
	for i in bin/*; do
		if [[ -L ${i} ]]; then
			i=$( readlink -e "${i}" ) || die
		fi
		dobin "${i}"
	done

	# Install headers.
	insinto /usr/include/${P}
	for i in include/*; do
		if [[ -L ${i} ]]; then
			i=$( readlink -e "${i}" ) || die
		fi
		doins "${i}"
	done

	# Install static libs. Charm has a lot of .o "libs" that it requires at
	# runtime.
	if use static-libs; then
		for i in lib/*.{a,o}; do
			if [[ -L ${i} ]]; then
				i=$( readlink -e "${i}" ) || die
			fi
			dolib "${i}"
		done
	fi

	# Install shared libs.
	for i in lib_so/*; do
		if [[ -L ${i} ]]; then
			i=$( readlink -e "${i}" ) || die
		fi
		dolib.so "${i}"
	done

	# Basic docs.
	dodoc CHANGES README

	# Install examples.
	if use examples; then
		find examples/ -name 'Makefile' | xargs sed \
			-r "s:(../)+bin/charmc:/usr/bin/charmc:" -i || \
			die "Failed to fix examples"
		find examples/ -name 'Makefile' | xargs sed \
			-r "s:./charmrun:./charmrun ++local:" -i || \
			die "Failed to fix examples"
		insinto /usr/share/doc/${PF}/examples
		doins -r examples/charm++/*
	fi

	# Install pdf/html docs
	if use doc; then
		cd "${S}"/doc
		# Install pdfs.
		insinto /usr/share/doc/${PF}/pdf
		doins  doc/pdf/*
		# Install html.
		docinto html
		dohtml -r doc/html/*
	fi
}

pkg_postinst() {
	einfo "Please test your charm installation by copying the"
	einfo "content of /usr/share/doc/${PF}/examples to a"
	einfo "temporary location and run 'make test'."
}