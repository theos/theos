ifeq ($(FW_TARGET_LOADED),)
FW_TARGET_LOADED := 1
FW_TARGET_NAME := iphone

SDKBINPATH ?= /Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
ifneq ($(words $(_FW_TARGET_ARGS)),0)
# A version specified as a target argument overrides all previous definitions.
override SDKVERSION := $(firstword $(_FW_TARGET_ARGS))
else
SDKVERSION ?= 3.0
endif
SYSROOT ?= /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(SDKVERSION).sdk

TARGET_CC ?= $(SDKBINPATH)/gcc-4.2
TARGET_CXX ?= $(SDKBINPATH)/g++-4.2
TARGET_STRIP ?= $(SDKBINPATH)/strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= $(SDKBINPATH)/codesign_allocate
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

include $(FW_MAKEDIR)/targets/_common/install_deb_remote.mk
include $(FW_MAKEDIR)/targets/_common/darwin.mk

ARCHS ?= armv6
SDKFLAGS := -isysroot $(SYSROOT) $(foreach ARCH,$(ARCHS),-arch $(ARCH)) -D__IPHONE_OS_VERSION_MIN_REQUIRED=__IPHONE_$(subst .,_,$(SDKVERSION))
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
