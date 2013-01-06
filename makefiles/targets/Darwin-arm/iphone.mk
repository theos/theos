ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

SDKTARGET ?= arm-apple-darwin9
SDKBINPATH ?= /usr/bin
SYSROOT ?= /var/sdk

PREFIX := $(SDKBINPATH)/$(SDKTARGET)-

TARGET_CC ?= $(PREFIX)gcc
TARGET_CXX ?= $(PREFIX)g++
TARGET_LD ?= $(PREFIX)g++
TARGET_STRIP ?= strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= codesign_allocate
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/install_deb_local.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

SDKFLAGS := -isysroot $(SYSROOT)
_THEOS_TARGET_CFLAGS := $(SDKFLAGS)
_THEOS_TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
