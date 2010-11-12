#!/bin/bash
ARGV0=$0
[[ -z "$THEOS" ]] && THEOS=$(cd $(dirname $0); cd ..; pwd)
THEOSDIR="$THEOS"

function makeSubstrateStub() {
	PROJECTDIR=$(mktemp -d /tmp/theos.XXXXXX)
	cd $PROJECTDIR
	ln -s "$THEOSDIR" theos

	cat > Makefile << __EOF
include theos/makefiles/common.mk
FRAMEWORK_NAME = CydiaSubstrate
CydiaSubstrate_FILES = Hooker.cc
CydiaSubstrate_INSTALL_PATH = /Library/Frameworks
LIBRARY_NAME = libsubstrate
libsubstrate_FILES = Hooker.cc
libsubstrate_INSTALL_PATH = /usr/lib
include \$(THEOS_MAKE_PATH)/framework.mk
include \$(THEOS_MAKE_PATH)/library.mk

after-libsubstrate-all::
	@\$(TARGET_STRIP) -x -c \$(THEOS_OBJ_DIR)/libsubstrate.dylib

after-CydiaSubstrate-all::
	@\$(TARGET_STRIP) -x -c \$(THEOS_OBJ_DIR)/CydiaSubstrate
__EOF

	cat > Hooker.cc << __EOF
#include <string.h>
#include <sys/types.h>
#include <objc/runtime.h>
bool MSDebug = false;
extern "C" {
void MSHookFunction(void *symbol, void *replace, void **result) { };
void MSFindSymbols(const void *image, size_t count, const char *names[], void *values[]) { }
void *MSFindSymbol(const void *image, const char *name) { return NULL; }

#ifdef __APPLE__
#ifdef __arm__
IMP MSHookMessage(Class _class, SEL sel, IMP imp, const char *prefix = NULL) { return NULL; }
#endif
void MSHookMessageEx(Class _class, SEL sel, IMP imp, IMP *result) { }
#endif
}
__EOF

	unset MAKE MAKELEVEL
	unset TARGET_CC TARGET_CXX TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS
	unset THEOS_PROJECT_DIR
	echo -n " Compiling iPhoneOS CydiaSubstrate stub..."
	( echo -n " default target?"; make libsubstrate target=iphone &> /dev/null; ) ||
		( echo -n " failed, forcing 2.0?"; make libsubstrate target=iphone:2.0 &> /dev/null; ) ||
		( echo -n " failed, forcing 3.0?"; make libsubstrate target=iphone:3.0 &> /dev/null; ) ||
		( echo -n " failed, forcing 3.2?"; make libsubstrate target=iphone:3.2 &> /dev/null; ) ||
		echo -n " failed, what?"
	echo

	if [[ "$(uname -s)" == "Darwin" && "$(uname -p)" != "arm" ]]; then
		echo " Compiling native CydiaSubstrate stub..."
		make CydiaSubstrate target=native > /dev/null
		if [[ -f obj/libsubstrate.dylib ]]; then
			lipo obj/libsubstrate.dylib obj/macosx/CydiaSubstrate -create -output libsubstrate.dylib
		else
			cp obj/macosx/CydiaSubstrate libsubstrate.dylib
		fi
	else
		if [[ -f obj/libsubstrate.dylib ]]; then
			cp obj/libsubstrate.dylib libsubstrate.dylib
		else
			echo "I didn't actually end up with a file here... I should probably bail out."
			exit 1
		fi
	fi

	cp libsubstrate.dylib "$THEOSDIR/lib/libsubstrate.dylib"

	cd "$THEOSDIR"
	rm -rf $PROJECTDIR
}

function copySystemSubstrate() {
	if [[ -f "/Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate" ]]; then
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
extern "C" {
void MSHookFunction(void *symbol, void *replace, void **result);
void MSFindSymbols(const void *image, size_t count, const char *names[], void *values[]);
void *MSFindSymbol(const void *image, const char *name);

#ifdef __APPLE__
#ifdef __arm__
IMP MSHookMessage(Class _class, SEL sel, IMP imp, const char *prefix = NULL);
#endif
void MSHookMessageEx(Class _class, SEL sel, IMP imp, IMP *result);
#endif
}
__EOF
}

function copySystemSubstrateHeader() {
	if [[ -f "/Library/Frameworks/CydiaSubstrate.framework/Headers/CydiaSubstrate.h" ]]; then
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

if ! checkWritability; then
	echo "$THEOSDIR is not writable. Please run $ARGV0 $@ manually, with privileges." 1>&2
	exit 1
fi

echo "Bootstrapping theos..."
if [[ "$1" == "substrate" ]]; then
	[ -f "$THEOSDIR/lib/libsubstrate.dylib" ] || copySystemSubstrate || makeSubstrateStub
	[ -f "$THEOSDIR/include/substrate.h" ] || copySystemSubstrateHeader || makeSubstrateHeader
fi
