ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := macosx

SDKBINPATH ?= /usr/bin

TARGET_CC ?= $(SDKBINPATH)/gcc-4.2
TARGET_CXX ?= $(SDKBINPATH)/g++-4.2
TARGET_LD ?= $(SDKBINPATH)/g++-4.2
TARGET_STRIP ?= $(SDKBINPATH)/strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= $(SDKBINPATH)/codesign_allocate
TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

TARGET_PRIVATE_FRAMEWORK_PATH = /System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/install_deb_local.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk

ARCHS ?= i386 x86_64
SDKFLAGS := $(foreach ARCH,$(ARCHS),-arch $(ARCH))
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
