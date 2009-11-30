TARGET ?= arm-apple-darwin9
SDKBINPATH ?= /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
SYSROOT ?= /opt/iphone-sdk-3.0/sysroot

CC=$(SDKBINPATH)/gcc-4.2
CXX=$(SDKBINPATH)/g++-4.2
STRIP=$(SDKBINPATH)/strip
CODESIGN_ALLOCATE=$(SDKBINPATH)/codesign_allocate

SDKFLAGS := -isysroot $(SYSROOT) -arch armv6
