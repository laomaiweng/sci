# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"

inherit toolchain-funcs eutils fortran

FORTRAN="g77 gfortran ifc"

DESCRIPTION="A suite of programs for carrying out complete molecular mechanics investigations"
HOMEPAGE="http://ambermd.org/#AmberTools"
SRC_URI="AmberTools-${PV}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="mpi openmp X"
RESTRICT="fetch"

RDEPEND="
	virtual/cblas
	virtual/lapack
	sci-libs/arpack
	sci-libs/cifparse-obj
	sci-chemistry/mopac7
	sci-libs/netcdf
	sci-chemistry/reduce"
DEPEND="${RDEPEND}
	dev-util/byacc
	dev-libs/libf2c
	sys-devel/ucpp"
S="${WORKDIR}/amber11"

pkg_nofetch() {
	einfo "Go to ${HOMEPAGE} and get ${A}"
	einfo "Place it in ${DISTDIR}"
}

pkg_setup() {
	need_fortran "${FORTRAN}"
	if use openmp &&
	[[ $(tc-getCC)$ == *gcc* ]] &&
		( [[ $(gcc-major-version)$(gcc-minor-version) -lt 42 ]] ||
		! has_version sys-devel/gcc[openmp] )
	then
		ewarn "You are using gcc and OpenMP is only available with gcc >= 4.2 "
		ewarn "If you want to build ${PN} with OpenMP, abort now,"
		ewarn "and switch CC to an OpenMP capable compiler"
	fi
	AMBERHOME="${S}"
}

src_prepare() {
	epatch "${FILESDIR}/${P}-gentoo.patch"
	cd AmberTools/src
	rm -r arpack blas lapack fftw-2.1.5 c9x-complex cifparse netcdf pnetcdf reduce ucpp-1.3 || die
}

src_configure() {
	cd AmberTools/src
	sed -e "s:\\\\\$(LIBDIR)/arpack.a:-larpack:g" \
		-e "s:\\\\\$(LIBDIR)/lapack.a:$(pkg-config lapack --libs) -lclapack:g" \
		-e "s:\\\\\$(LIBDIR)/blas.a:$(pkg-config blas cblas --libs):g" \
		-e "s:\\\\\$(LIBDIR)/libdrfftw.a:${EPREFIX}/usr/$(get_libdir)/libdrfftw.a:g" \
		-e "s:\\\\\$(LIBDIR)/libdfftw.a:${EPREFIX}/usr/$(get_libdir)/libdrfftw.a:g" \
		-e "s:CFLAGS=:CFLAGS=${CFLAGS} -DBINTRAJ :g" \
		-e "s:FFLAGS=:FFLAGS=${FFLAGS} :g" \
		-e "s:LDFLAGS=$ldflags:LDFLAGS=${LDFLAGS}:g" \
		-e "s:fc=g77:fc=${FORTRANC}:g" \
		-e "s:NETCDFLIB=\$netcdflib:NETCDFLIB=$(pkg-config netcdf --libs):g" \
		-e "s:NETCDF=\$netcdf:NETCDF=netcdf.mod:g" \
		-e "s:-O3::g" \
		-i configure

	local myconf

	use X || myconf="${myconf} -noX11"

	for x in mpi openmp; do
		use ${x} && myconf="${myconf} -${x}"
	done

	./configure \
		${myconf} \
		-nobintraj \
		gnu
#	$(expr match "$(tc-getCC)" '.*\([a-z]cc\)')
}

src_compile() {
	cd AmberTools/src
	emake -f Makefile || die
}
