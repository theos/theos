TARGET ?= arm-apple-darwin9
SDKBINPATH ?= /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
SDKVERSION ?= 3.1.2
#SYSROOT ?= /opt/iphone-sdk-3.0/sysroot
SYSROOT ?= /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVERSION).sdk

CC=$(SDKBINPATH)/gcc-4.2
CXX=$(SDKBINPATH)/g++-4.2
STRIP=$(SDKBINPATH)/strip
CODESIGN_ALLOCATE=$(SDKBINPATH)/codesign_allocate

ARCHS ?= armv6
SDKFLAGS := -isysroot $(SYSROOT) $(foreach ARCH,$(ARCHS),-arch $(ARCH))
SDK_CFLAGS := $(SDKFLAGS)
SDK_OBJCFLAGS := $(SDKFLAGS)
SDK_LDFLAGS := $(SDKFLAGS)

DU_EXCLUDE = -I
