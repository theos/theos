ifeq ($(FW_PLATFORM_LOADED),)
FW_PLATFORM_LOADED := 1

TARGET ?= arm-apple-darwin9
SDKBINPATH ?= /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
SDKVERSION ?= 3.1.2
#SYSROOT ?= /opt/iphone-sdk-3.0/sysroot
SYSROOT ?= /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVERSION).sdk

TARGET_CC ?= $(SDKBINPATH)/gcc-4.2
TARGET_CXX ?= $(SDKBINPATH)/g++-4.2
TARGET_STRIP ?= $(SDKBINPATH)/strip
TARGET_CODESIGN_ALLOCATE ?= $(SDKBINPATH)/codesign_allocate
TARGET_CODESIGN ?= ldid

ARCHS ?= armv6
SDKFLAGS := -isysroot $(SYSROOT) $(foreach ARCH,$(ARCHS),-arch $(ARCH))
SDK_CFLAGS := $(SDKFLAGS)
SDK_LDFLAGS := $(SDKFLAGS)

DU_EXCLUDE = -I

endif
