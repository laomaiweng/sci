# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=5

inherit cmake-utils versionator

MY_PN="${PN/-/}"
MY_P="${MY_PN}-${PV}"

DESCRIPTION="Advanced molecule editor and visualizer 2"
HOMEPAGE="http://www.openchemistry.org/"
SRC_URI="http://openchemistry.org/files/v$(get_version_component_range 1-2)/${MY_P}.tar.gz"

SLOT="0"
LICENSE="BSD"
KEYWORDS="~amd64 ~x86 ~amd64-linux ~x86-linux"
IUSE="doc opengl qt4 test vtk"

RDEPEND="
	sci-chemistry/molequeue
	sci-libs/chemkit
	"
DEPEND="${RDEPEND}
"

S="${WORKDIR}"/${MY_P}

src_configure() {
	local mycmakeargs=(
		-DBUILD_STATIC_PLUGINS=OFF
		-DUSE_PROTOCALL=OFF
		$(cmake-utils_use_build doc DOCUMENTATION)
		$(cmake-utils_use_use opengl OPENGL)
		$(cmake-utils_use_enable test TESTING)
		$(cmake-utils_use_use qt4 QT)
		$(cmake-utils_use_use vtk VTK)
		)
	cmake-utils_src_configure
}
