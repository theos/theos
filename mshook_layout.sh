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

svn co http://svn.howett.net/svn/iphone-framework framework

cat > Makefile << __END
TWEAK_NAME = $EXTENSION
${EXTENSION}_OBJCC_FILES = Tweak.mm

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
__END

cat > Tweak.xm << __END
// %hook Blah -(void)blah { ... }
__END
