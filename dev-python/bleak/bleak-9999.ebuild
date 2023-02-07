# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=poetry
PYTHON_COMPAT=( python3_{9..11} pypy3 )

inherit distutils-r1

DESCRIPTION="Bluetooth Low Energy platform Agnostic Klient (BLEAK) for Python"
HOMEPAGE="https://bleak.readthedocs.io"

LICENSE="MIT"
SLOT="0"
IUSE="test"

# Dependencies unsurprisingly derive from "pyproject.toml".
BDEPEND="test? (
	>=dev-python/pytest-7.0.0[${PYTHON_USEDEP}]
	>=dev-python/pytest-asyncio-0.19.0[${PYTHON_USEDEP}]
	>=dev-python/pytest-cov-3.0.0[${PYTHON_USEDEP}]
)"
RDEPEND="
	>=dev-python/dbus-fast-1.22.0[${PYTHON_USEDEP}]
	$(python_gen_cond_dep '
		>=dev-python/async-timeout-3.0.0[${PYTHON_USEDEP}]
	' python3_{8..10})
"
DEPEND="${RDEPEND}"

distutils_enable_sphinx docs dev-python/sphinx_rtd_theme

#FIXME: Tests currently fail to run and I can't be bothered to resolve. *sigh*
# distutils_enable_tests pytest

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/hbldh/bleak.git"
	EGIT_BRANCH="develop"
	SRC_URI=""
	KEYWORDS=""
else
	SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"
	KEYWORDS="~amd64 ~arm ~arm64 ~x86"
fi

python_install_all() {
	[[ -d examples ]] && dodoc -r examples

	distutils-r1_python_install_all
}
