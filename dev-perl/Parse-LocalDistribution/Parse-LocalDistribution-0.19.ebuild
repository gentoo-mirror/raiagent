# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# This ebuild generated by g-cpan 0.16.9

EAPI=5

MODULE_AUTHOR="ISHIGAKI"
MODULE_VERSION="0.19"


inherit perl-module

DESCRIPTION="parses local .pm files as PAUSE does"

LICENSE="|| ( Artistic GPL-1 GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k mips ppc ppc64 riscv s390 sh sparc x86   ppc-aix amd64-linux arm-linux arm64-linux ppc64-linux x86-linux ppc-macos x86-macos x64-macos m68k-mint sparc-solaris sparc64-solaris x64-solaris x86-solaris x64-winnt x86-winnt x64-cygwin x86-cygwin"
IUSE=""

DEPEND=">=dev-perl/Parse-PMFile-0.42
	>=dev-perl/Test-UseAllModules-0.170.0
	dev-perl/ExtUtils-MakeMaker-CPANfile
	dev-lang/perl"
