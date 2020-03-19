# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# This ebuild generated by g-cpan 0.16.9

EAPI=5

MODULE_AUTHOR="OVID"
MODULE_VERSION="0.02"


inherit perl-module

DESCRIPTION="\"split\" on steroids"

LICENSE="|| ( Artistic GPL-1 GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k mips ppc ppc64 riscv s390 sh sparc x86   ppc-aix amd64-linux arm-linux arm64-linux ppc64-linux x86-linux ppc-macos x86-macos x64-macos m68k-mint sparc-solaris sparc64-solaris x64-solaris x86-solaris x64-winnt x86-winnt x64-cygwin x86-cygwin"
IUSE=""

DEPEND=">=dev-perl/Sub-Uplevel-0.280.0
	>=dev-perl/Test-Exception-0.430.0
	dev-perl/Module-Build
	dev-lang/perl"
