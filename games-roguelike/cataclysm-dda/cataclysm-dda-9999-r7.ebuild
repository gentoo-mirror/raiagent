# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

#FIXME: C:DDA ships with an undocumented and currently unsupported
#"CMakeLists.txt" for building under CMake. Switch to this makefile when
#confirmed to be reliably working.

# See "COMPILING.md" in the C:DDA repository for compilation instructions.
DESCRIPTION="Roguelike set in a post-apocalyptic world"
HOMEPAGE="http://en.cataclysmdda.com"

LICENSE="CC-BY-SA-3.0"
SLOT="0"
IUSE="
	clang debug lto lua luajit ncurses nls sdl sound test xdg
	kernel_linux kernel_Darwin
"
REQUIRED_USE="
	lua? ( sdl )
	luajit? ( lua )
	sound? ( sdl )
	|| ( ncurses sdl )
"

RDEPEND="
	app-arch/bzip2
	sys-libs/glibc
	sys-libs/zlib
	lua? ( >=dev-lang/lua-5.1:0 )
	luajit? ( dev-lang/luajit:2 )
	ncurses? ( >=sys-libs/ncurses-6.0:0 )
	nls? ( sys-devel/gettext:0[nls] )
	sdl? (
		media-libs/libsdl2:0
		media-libs/sdl2-ttf:0
		media-libs/sdl2-image:0[jpeg,png]
		media-libs/freetype:2
	)
	sound? ( media-libs/sdl2-mixer:0 )
"

# Note that, although GCC also supports LTO via the gold linker, Portage appears
# to provide no means of validating the current GCC to link with gold. *shrug*
DEPEND="${RDEPEND}
	clang? (
		sys-devel/clang
		lto? ( sys-devel/llvm[gold] )
	)
	!clang? ( sys-devel/gcc[cxx] )
"

# Absolute path of the directory containing C:DDA data files.
CATACLYSM_HOME=/usr/share/"${PN}"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3

	EGIT_REPO_URI="https://github.com/CleverRaven/Cataclysm-DDA.git"
	SRC_URI=""
	KEYWORDS=""
else
	# Post-0.9 versions of C:DDA employ capitalized alphabetic letters rather
	# than numbers (e.g., "0.A" rather than "1.0"). Since Portage permits
	# version specifiers to contain only a single suffixing letter prefixed by
	# one or more digits, we:
	#
	# * Encode such versions as "0.9${lowercase_letter}" in ebuild filenames.
	# * In the ebuilds themselves (i.e., here), we:
	#   * Manually strip the "9" in such filenames.
	#   * Uppercase the lowercase letter in such filenames.
	MY_PV="${PV/.9/.}"
	MY_PV="${MY_PV^^}"
	SRC_URI="https://github.com/CleverRaven/Cataclysm-DDA/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~x86"
	S="${WORKDIR}/Cataclysm-DDA-${MY_PV}"
fi

src_prepare() {
	# If this ebuild requires patching to support the compile-time
	# ${USE_XDG_DIR} option, do so on calling default_src_prepare() below.
	local xdg_patch="${FILESDIR}/${P}-USE_XDG_DIR.patch"
	[[ -f "${xdg_patch}" ]] && PATCHES+=( "${xdg_patch}" )

	# If "doc/JSON_LOADING_ORDER.md" is still a symbolic link, replace this
	# link by a copy of its transitive target to avoid "QA Notice" complaints.
	if [[ -L doc/JSON_LOADING_ORDER.md ]]; then
		rm doc/JSON_LOADING_ORDER.md || die '"rm" failed.'
		cp data/json/LOADING_ORDER.md doc/JSON_LOADING_ORDER.md ||
			die '"cp" failed.'
	fi

	#FIXME: Makefiles have changed considerably since this ebuild was first
	#authored. Revise or remove all "sed" operations below that no longer apply. 

	# Strip the following from all makefiles:
	#
	# * Hardcoded optimization (e.g., "-O3", "-Os") and stripping (e.g., "-s").
	# * g++ option "-Werror", converting compiler warnings to errors and hence
	#   failing on the first (inevitable) warning.
	# * The makefile-specific ${BUILD_PREFIX} variable, conflicting with the 
	#   Portage-specific variable of the same name. For disambiguity, this
	#   variable is renamed to a makefile-specific variable name.
	sed -i\
		-e '/\bOPTLEVEL = /s~ -O.~~'\
		-e '/LDFLAGS += /s~ -s~~'\
		-e '/RELEASE_FLAGS = /s~ -Werror~~'\
		-e 's~\bBUILD_PREFIX\b~CATACLYSM_BUILD_PREFIX~'\
		{tests/,}Makefile || die '"sed" failed.'

	# Replace the hardcoded home directory with our Gentoo-specific directory,
	# which *MUST* be suffixed by "/" here to satisfy code requirements.
	sed -i -e 's~^\(\s*update_pathname("datadir", \)[^)]*\(.*\)$~\1"'${CATACLYSM_HOME}'/"\2~g'\
		src/path_info.cpp || die '"sed" failed.'

	# The makefile assumes subdirectories "obj" and "obj/tiles" both exist,
	# which (...of course) they don't. Create these subdirectories manually.
	mkdir -p obj/tiles || die '"mkdir" failed.'

	# Apply user-specific patches and all patches added to ${PATCHES} above.
	default_src_prepare
}

src_compile() {
	# Options passed to all ncurses- and SDL-specific emake() calls below.
	declare -ga CATACLYSM_EMAKE_NCURSES CATACLYSM_EMAKE_SDL

	# Define ncurses-specific emake() options first.
	CATACLYSM_EMAKE_NCURSES=(
		# Unlike all other paths defined below, ${PREFIX} is compiled into
		# installed binaries and hence *MUST* refer to a run- rather than
		# install-time directory (e.g., relative to ${EROOT} rather than ${ED}).
		PREFIX="${EROOT}"usr

		# Install-time directories. Since ${PREFIX} does *NOT* refer to an
		# install-time directory, all variables defined by the makefile relative
		# to ${PREFIX} *MUST* be redefined here relative to ${ED}.
		BIN_PREFIX="${ED}"/usr/bin
		DATA_PREFIX="${ED}/${CATACLYSM_HOME}"
		LOCALE_DIR="${ED}"/usr/share/locale

		# Link against Portage-provided shared libraries.
		DYNAMIC_LINKING=1

		# Enable tests if requested.
		RUNTESTS=$(usex test 1 0)

		# Unconditionally disable all code style and JSON linting.
		ASTYLE=0
		LINTJSON=0

		# Since Gentoo's ${L10N} USE_EXPAND flag conflicts with this makefile's
		# flag of the same name, temporarily prevent the former from being
		# passed to this makefile by overriding the current user-defined value
		# of ${L10N} with the empty string. Failing to do so results in the
		# following link-time fatal error:
		#
		#     make: *** No rule to make target 'en', needed by 'all'.  Stop.
		L10N=
	)

	# Conditionally set USE flag-dependent options. Since the makefile tests
	# for the existence rather than the value of the corresponding environment
	# variables, these variables must be left undefined rather than defined to
	# some false value (e.g., 0, "False", the empty string) if the corresponding
	# USE flags are disabled.
	use clang && CATACLYSM_EMAKE_NCURSES+=( CLANG=1 )

	# For efficiency, prefer release to debug builds.
	use debug || CATACLYSM_EMAKE_NCURSES+=( RELEASE=1 )

	# If enabling link time optimization, do so.
	use lto && CATACLYSM_EMAKE_NCURSES+=( LTO=1 )

	# Detect the current machine architecture and operating system.
	local cataclysm_arch
	if use kernel_linux; then
		if use amd64; then
			cataclysm_arch=linux64
		elif use x86; then
			cataclysm_arch=linux32
		fi
	elif use kernel_Darwin; then
		cataclysm_arch=osx
	else
		die "Architecture \"${ARCH}\" unsupported."
	fi
	CATACLYSM_EMAKE_NCURSES+=( NATIVE=${cataclysm_arch} )

	# If enabling Lua support, do so. Note that Lua support requires SDL support
	# but, paradoxically, appears to be supported when compiling both SDL *AND*
	# ncurses binaries. (Black magic is black.)
	if use lua; then
		CATACLYSM_EMAKE_NCURSES+=( LUA=1 )

		# If enabling LuaJIT support, do so.
		use luajit && CATACLYSM_EMAKE_NCURSES+=( LUA_BINARY=luajit )
	fi

	# If enabling internationalization, do so.
	if use nls; then
		CATACLYSM_EMAKE_NCURSES+=( LOCALIZE=1 )

		# If the optional Gentoo-specific string global ${LINGUAS} is defined
		# (e.g., in "make.conf"), enable all such whitespace-delimited locales.

		#FIXME: This used to work, but currently causes installation to fail
		#with fatal shell errors resembling:
		#    mkdir -p /var/tmp/portage/games-roguelike/cataclysm-dda-9999-r6/image//usr/share/locale
		#    LOCALE_DIR=/var/tmp/portage/games-roguelike/cataclysm-dda-9999-r6/image//usr/share/locale lang/compile_mo.sh en en_CA
		#    msgfmt: error while opening "lang/po/en.po" for reading: No such file or directory
		#    msgfmt: error while opening "lang/po/en_CA.po" for reading: No such file or directory
		#Since the Cataclysm: DDA script compiling localizations (currently,
		#"lang/compile_mo.sh") cannot be trusted to safely do so for explicitly
		#passed locales, avoid explicitly passing locales for the moment.
		#Uncomment the following statement after upstream resolves this issue.

		#[[ -n "${LINGUAS+x}" ]] &&
		#	CATACLYSM_EMAKE_NCURSES+=( LANGUAGES="${LINGUAS}" )
		CATACLYSM_EMAKE_NCURSES+=( LANGUAGES='all' )
	fi

	# If storing saves and settings in XDG base directories, do so.
	if use xdg; then
		CATACLYSM_EMAKE_NCURSES+=( USE_HOME_DIR=0 USE_XDG_DIR=1 )
	# Else, store saves and settings in home directories.
	else
		CATACLYSM_EMAKE_NCURSES+=( USE_HOME_DIR=1 USE_XDG_DIR=0 )
	fi

	# If enabling ncurses, compile the ncurses-based binary.
	if use ncurses; then
		einfo 'Compiling ncurses interface...'
		emake "${CATACLYSM_EMAKE_NCURSES[@]}"
	fi

	# If enabling SDL, compile the SDL-based binary.
	if use sdl; then
		# Define SDL- *AFTER* ncurses-specific emake() options. The former is a
		# strict superset of the latter.
		CATACLYSM_EMAKE_SDL=(
			"${CATACLYSM_EMAKE_NCURSES[@]}"

			# Enabling tiled output implicitly enables SDL.
			TILES=1
		)

		# If enabling SDL-dependent sound support, do so.
		use sound && CATACLYSM_EMAKE_SDL+=( SOUND=1 )

		# Compile us up the tiled bomb.
		einfo 'Compiling SDL interface...'
		emake "${CATACLYSM_EMAKE_SDL[@]}"
	fi
}

src_test() {
	emake tests || die 'Tests failed.'
}

src_install() {
	# If enabling ncurses, install the ncurses-based binary.
	use ncurses && emake install "${CATACLYSM_EMAKE_NCURSES[@]}"

	# If enabling SDL, install the SDL-based binary.
	use sdl && emake install "${CATACLYSM_EMAKE_SDL[@]}"

	# Replace a symbolic link in the documentation directory to be installed
	# below with the physical target file of that link. These operations are
	# non-essential to the execution of installed binaries and are thus
	# intentionally *NOT* suffixed by "|| die 'cp failed.'"-driven protection.
	rm doc/LOADING_ORDER.md
	cp data/json/LOADING_ORDER.md doc/

	# Recursively install all available documentation.
	dodoc -r README.md doc/*
}
