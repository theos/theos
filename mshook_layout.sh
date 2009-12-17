#!/bin/bash
EXTENSION=$1
LEXTENSION=$(echo $1 | tr 'A-Z' 'a-z')
mkdir $LEXTENSION
cd $LEXTENSION
mkdir -p layout/DEBIAN

cat > layout/DEBIAN/control << __END
Package: net.howett.$LEXTENSION
Name: $EXTENSION
Depends: mobilesubstrate
Version: 0.0.1
Architecture: iphoneos-arm
Description: 
Maintainer: Dustin Howett <dustin@howett.net>
Author: Dustin Howett <dustin@howett.net>
Section: Tweaks
dev: dustinhowett
Sponsor: thebigboss.org <http://thebigboss.org>
__END

svn co http://svn.howett.net/svn/iphone-framework framework

cat > Makefile << __END
TWEAK_NAME = $EXTENSION
${EXTENSION}_OBJCC_FILES = Tweak.mm

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
__END

cat > Tweak.mm << __END
#import <DHHookCommon.h>

//DHLateClass(Blah);

//HOOK(Blah, blah, void) { ... }

static _Constructor void ${EXTENSION}Initialize() {
	DHScopedAutoreleasePool();
	//DHHookMessage(Blah, blah);
}
__END
