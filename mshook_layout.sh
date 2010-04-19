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

svn co http://svn.howett.net/svn/theos/trunk framework

cat > Makefile << __END
TWEAK_NAME = $EXTENSION
${EXTENSION}_OBJCC_FILES = Tweak.mm

include framework/makefiles/common.mk
include framework/makefiles/tweak.mk
__END

cat > Tweak.xm << __END
/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave conseqeuences!
%end
*/

__END
