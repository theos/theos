#!/bin/bash
EXTENSION=$1
LEXTENSION=$(echo $1 | tr 'A-Z' 'a-z')
mkdir $LEXTENSION
cd $LEXTENSION
mkdir -p layout/DEBIAN

cat > layout/DEBIAN/control << __END
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

cat > Makefile << __END
ifeq (\$(shell [ -f ./framework/makefiles/common.mk ] && echo 1 || echo 0),0)
all clean package install::
	git submodule update --init
	framework/git-submodule-recur.sh init
	\$(MAKE) \$(MAKEFLAGS) MAKELEVEL=0 \$@
else

TWEAK_NAME = $EXTENSION
${EXTENSION}_OBJC_FILES = Tweak.m

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk

endif
__END

cat > Tweak.m << __END
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

cat > .gitignore << __END
._*
.DS_Store
*.deb
_
obj
.debmake
__END

git init
git submodule add git://github.com/rpetrich/theos.git framework
`pwd`/framework/git-submodule-recur.sh init
git add Tweak.m Makefile layout/DEBIAN/control .gitignore
