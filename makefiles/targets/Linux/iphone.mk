ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

SDKTARGET ?= arm-apple-darwin9
SDKBINPATH ?= /opt/iphone-sdk-3.0/prefix/bin
SYSROOT ?= /opt/iphone-sdk-3.0/sysroot

PREFIX := $(SDKBINPATH)/$(SDKTARGET)-

TARGET_CC ?= $(PREFIX)gcc
TARGET_CXX ?= $(PREFIX)g++
TARGET_LD ?= $(PREFIX)g++
TARGET_STRIP ?= $(PREFIX)strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= $(PREFIX)codesign_allocate
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

include $(THEOS_MAKE_PATH)/targets/_common/install_deb_remote.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks

SDKFLAGS := -isysroot $(SYSROOT)
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
