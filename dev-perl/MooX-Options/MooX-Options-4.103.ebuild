# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# This ebuild generated by g-cpan 0.16.9

EAPI=5

MODULE_AUTHOR="REHSACK"
MODULE_VERSION="4.103"


inherit perl-module

DESCRIPTION="Explicit Options eXtension for Object Class"

LICENSE="|| ( Artistic GPL-1 GPL-2 GPL-3 )"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k mips ppc ppc64 riscv s390 sh sparc x86   ppc-aix amd64-linux arm-linux arm64-linux ppc64-linux x86-linux ppc-macos x86-macos x64-macos m68k-mint sparc-solaris sparc64-solaris x64-solaris x86-solaris x64-winnt x86-winnt x64-cygwin x86-cygwin"
IUSE=""

DEPEND="dev-perl/Unicode-LineBreak
	dev-perl/Module-Runtime
	dev-perl/Test-Trap
	>=dev-perl/Getopt-Long-Descriptive-0.103.0
	dev-perl/Data-Record
	dev-perl/JSON-MaybeXS
	dev-perl/MooX-Locale-Passthrough
	dev-perl/MRO-Compat
	>=dev-perl/Path-Class-0.360.0
	dev-perl/strictures
	dev-perl/Regexp-Common
	dev-perl/Moo
	dev-lang/perl"
