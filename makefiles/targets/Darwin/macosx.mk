ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := macosx

_THEOS_TARGET_MACOSX_DEPLOYMENT_VERSION := $(firstword $(_THEOS_TARGET_ARGS))
TARGET_CC ?= xcrun -sdk macosx gcc
TARGET_CXX ?= xcrun -sdk macosx g++
TARGET_LD ?= xcrun -sdk macosx g++
TARGET_STRIP ?= xcrun -sdk macosx strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk macosx -find codesign_allocate)"
TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

TARGET_PRIVATE_FRAMEWORK_PATH = /System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/install_deb_local.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_hierarchial_bundle.mk

ARCHS ?= i386 x86_64
SDKFLAGS := $(foreach ARCH,$(ARCHS),-arch $(ARCH)) $(if $(_THEOS_TARGET_MACOSX_DEPLOYMENT_VERSION),-mmacosx-version-min=$(_THEOS_TARGET_MACOSX_DEPLOYMENT_VERSION))
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
