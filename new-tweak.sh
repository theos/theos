#!/bin/bash

if [ -z $1 ]; then
echo "usage: $0 tweakname"
else

EXTENSION=$1
LEXTENSION=$(echo $1 | tr 'A-Z' 'a-z')
SELF=$(cd ${0%/*} && echo $PWD/${0##*/})
SELFDIR=$(dirname "$SELF")

mkdir -p $LEXTENSION/layout/DEBIAN

cat > $LEXTENSION/layout/DEBIAN/control << __END
Package: com.yourcompany.$LEXTENSION
Name: $EXTENSION
Depends: mobilesubstrate
Version: 0.0.1
Architecture: iphoneos-arm
Description: 
Maintainer: $USER
Author: $USER
Section: Tweaks
__END

cat > $LEXTENSION/Makefile << __END
ifeq (\$(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init
	./framework/git-submodule-recur.sh init
	\$(MAKE) \$(MAKEFLAGS) MAKELEVEL=0 \$@
else

TWEAK_NAME = $EXTENSION
${EXTENSION}_OBJC_FILES = Tweak.m

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

endif
__END

cat > $LEXTENSION/Tweak.m << __END
#import <CaptainHook/CaptainHook.h>

CHDeclareClass(ClassName);

CHDeclareMethod(0, void, ClassName, someMethod)
{
	CHSuper(0, ClassName, someMethod);
}

CHConstructor
{
	CHLoadLateClass(ClassName);
	CHHook(0, ClassName, someMethod);
}

__END

cat > $LEXTENSION/.gitignore << __END
._*
.DS_Store
*.deb
_
obj
.debmake
__END

cd $LEXTENSION

git init
git submodule add git://github.com/rpetrich/theos.git framework
"$SELFDIR/git-submodule-recur.sh" init
git add Tweak.m Makefile layout/DEBIAN/control .gitignore

fi
