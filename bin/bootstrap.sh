#!/bin/bash
bootstrap_version=2

ARGV0=$0
[[ -z "$THEOS" ]] && THEOS=$(cd $(dirname $0); cd ..; pwd)
THEOSDIR="$THEOS"

function makeSubstrateStub() {
	PROJECTDIR=$(mktemp -d /tmp/theos.XXXXXX)
	cd $PROJECTDIR
	ln -s "$THEOSDIR" theos

	cat > Makefile << __EOF
override TARGET_CODESIGN:=
ifneq (\$(target),native)
override ARCHS=arm
endif

include theos/makefiles/common.mk
FRAMEWORK_NAME = CydiaSubstrate
CydiaSubstrate_FILES = Hooker.cc
CydiaSubstrate_INSTALL_PATH = /Library/Frameworks
CydiaSubstrate_LDFLAGS = -dynamiclib -install_name /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate
ifeq (\$(THEOS_CURRENT_INSTANCE),CydiaSubstrate)
override AUXILIARY_LDFLAGS:=
endif
LIBRARY_NAME = libsubstrate
libsubstrate_FILES = Hooker.cc
libsubstrate_INSTALL_PATH = /usr/lib
ifeq (\$(THEOS_PLATFORM_NAME),macosx)
libsubstrate_LDFLAGS = -Wl,-allow_sub_type_mismatches
endif
include \$(THEOS_MAKE_PATH)/framework.mk
include \$(THEOS_MAKE_PATH)/library.mk

after-libsubstrate-all::
	@\$(TARGET_STRIP) -x -c \$(THEOS_OBJ_DIR)/libsubstrate.dylib
	@mkdir -p \$(THEOS_PROJECT_DIR)/_out
	@cp \$(THEOS_OBJ_DIR)/libsubstrate.dylib \$(THEOS_PROJECT_DIR)/_out/libsubstrate.dylib

after-CydiaSubstrate-all::
	@\$(TARGET_STRIP) -x -c \$(THEOS_SHARED_BUNDLE_BINARY_PATH)/CydiaSubstrate
	@mkdir -p \$(THEOS_PROJECT_DIR)/_out
	@cp \$(THEOS_SHARED_BUNDLE_BINARY_PATH)/CydiaSubstrate \$(THEOS_PROJECT_DIR)/_out/CydiaSubstrate
__EOF

	cat > Hooker.cc << __EOF
typedef void *id;
typedef void *SEL;
typedef void *Class;
typedef id (*IMP)(id, SEL);

bool MSDebug = false;
extern "C" {
typedef const void *MSImageRef;
void MSHookFunction(void *symbol, void *replace, void **result) { };
void *MSFindSymbol(const void *image, const char *name) { return (void*)0; }
MSImageRef MSGetImageByName(const char *file) { return (MSImageRef)0; }

#ifdef __APPLE__
#ifdef __arm__
IMP MSHookMessage(Class _class, SEL sel, IMP imp, const char *prefix = (char *)0) { return (IMP)0; }
#endif
void MSHookMessageEx(Class _class, SEL sel, IMP imp, IMP *result) { }
#endif
}
__EOF

	unset MAKE MAKELEVEL
	unset TARGET_CC TARGET_CXX TARGET_LD TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS
	unset THEOS_BUILD_DIR THEOS_OBJ_DIR THEOS_OBJ_DIR_NAME
	unset THEOS_PROJECT_DIR
	echo -n " Compiling iPhoneOS CydiaSubstrate stub..."
	( echo -n " default target?"; make libsubstrate target=iphone &> /dev/null; ) ||
		echo -n " failed, what?"
	echo

	if [[ "$(uname -s)" == "Darwin" && "$(uname -p)" != "arm" ]]; then
		echo " Compiling native CydiaSubstrate stub..."
		make CydiaSubstrate target=native > /dev/null
	fi

	files=(_out/*)
	if [[ ${#files[*]} -eq 0 ]]; then
		echo "I didn't actually end up with a file here... I should probably bail out."
		exit 1
	elif [[ ${#files[*]} -eq 1 ]]; then
		cp _out/* libsubstrate.dylib
	else
		lipo _out/* -create -output libsubstrate.dylib
	fi

	cp libsubstrate.dylib "$THEOSDIR/lib/libsubstrate.dylib"

	cd "$THEOSDIR"
	rm -rf $PROJECTDIR
}

function copySystemSubstrate() {
	if [[ -f "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" ]]; then
		echo " Copying system CydiaSybstrate..."
		cp "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" "$THEOSDIR/lib/libsubstrate.dylib"
		return 0
	else
		return 1
	fi
}

function makeSubstrateHeader() {
	echo " Generating substrate.h header..."
	cat > "$THEOSDIR/include/substrate.h" << __EOF
#include <string.h>
#include <sys/types.h>
#include <objc/runtime.h>
#ifdef __cplusplus
#define _default(x) = x
extern "C" {
#else
#define _default(x)
#endif
typedef const void *MSImageRef;
void MSHookFunction(void *symbol, void *replace, void **result);
void *MSFindSymbol(const void *image, const char *name);
MSImageRef MSGetImageByName(const char *file);

#ifdef __APPLE__
#ifdef __arm__
IMP MSHookMessage(Class _class, SEL sel, IMP imp, const char *prefix _default(NULL));
#endif
void MSHookMessageEx(Class _class, SEL sel, IMP imp, IMP *result);
#endif
#ifdef __cplusplus
}
#endif
__EOF
}

function copySystemSubstrateHeader() {
	if [[ -f "/Library/Frameworks/CydiaSubstrate.framework/Headers/CydiaSubstrate.h" ]]; then
		echo " Copying system CydiaSubstrate header..."
		cp "/Library/Frameworks/CydiaSubstrate.framework/Headers/CydiaSubstrate.h" "$THEOSDIR/include/substrate.h"
		return 0
	else
		return 1
	fi
}

function checkWritability() {
	if ! touch "$THEOSDIR/.perm" &> /dev/null; then
		retval=1
		return 1
	fi
	rm "$THEOSDIR/.perm" &> /dev/null
	return 0
}

function getCurrentBootstrapVersion {
	v=1
	if [[ -f "$THEOSDIR/.bootstrap" ]]; then
		v=$(< "$THEOSDIR/.bootstrap")
	fi
	echo -n "$v"
}

function bootstrapSubstrate {
	[ -f "$THEOSDIR/lib/libsubstrate.dylib" ] || copySystemSubstrate || makeSubstrateStub
	[ -f "$THEOSDIR/include/substrate.h" ] || copySystemSubstrateHeader || makeSubstrateHeader
	echo -n "$bootstrap_version" > "$THEOSDIR/.bootstrap"
}

if ! checkWritability; then
	echo "$THEOSDIR is not writable. Please run \`$ARGV0 $@\` manually, with privileges." 1>&2
	exit 1
fi

# The use of 'p' denotes a query.
# http://en.wikipedia.org/wiki/P_convention

if [[ "$1" == "substrate" ]]; then
	echo "Bootstrapping CydiaSubstrate..."
	bootstrapSubstrate
elif [[ "$1" == "version-p" ]]; then
	echo -n $(getCurrentBootstrapVersion)
elif [[ "$1" == "newversion-p" ]]; then
	echo -n "$bootstrap_version"
elif [[ "$1" == "update-p" ]]; then
	test $(getCurrentBootstrapVersion) -lt $bootstrap_version; exit $?
#elif [[ "$1" == "update" ]]; then
	#echo "Updating CydiaSubstrate..."
	#bootstrapSubstrate
fi
