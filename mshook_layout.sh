#!/bin/bash
EXTENSION=$1
LEXTENSION=$(echo $1 | tr 'A-Z' 'a-z')
mkdir $LEXTENSION
cd $LEXTENSION
mkdir -p layout/Library/MobileSubstrate/DynamicLibraries
mkdir -p layout/DEBIAN

cat > layout/DEBIAN/control << __END
Package: net.howett.$LEXTENSION
Name: $EXTENSION
Depends: mobilesubstrate
Version: 1.0.0
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
PWD:=\$(shell pwd)
TOP_DIR:=\$(PWD)
FRAMEWORKDIR=$(TOP_DIR)/framework
tweak=$EXTENSION
include \$(FRAMEWORKDIR)/makefiles/MSMakefile
__END

ln -s /home/dustin/projects/itouch/cydelete/Common.h .
cat > Hook.h << __END
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <DHHookCommon.h>

extern "C" void ${EXTENSION}Initialize();
__END

cat > Hook.mm << __END
#import "Hook.h"

extern "C" void ${EXTENSION}Initialize() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// GET_CLASS(Blah)
	// HOOK_MESSAGE(Blah, blah);

	[pool drain];
}
__END
