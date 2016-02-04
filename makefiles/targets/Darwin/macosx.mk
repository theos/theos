ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := macosx

_THEOS_TARGET_CC := clang
_THEOS_TARGET_CXX := clang++
_THEOS_TARGET_ARG_ORDER := 2

_THEOS_TARGET_MACOSX_DEPLOYMENT_VERSION := $(__THEOS_TARGET_ARG_$(_THEOS_TARGET_ARG_ORDER))
TARGET_CC ?= xcrun -sdk macosx $(_THEOS_TARGET_CC)
TARGET_CXX ?= xcrun -sdk macosx $(_THEOS_TARGET_CXX)
TARGET_LD ?= xcrun -sdk macosx $(_THEOS_TARGET_CXX)
TARGET_STRIP ?= xcrun -sdk macosx strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk macosx -find codesign_allocate)"
TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

TARGET_PRIVATE_FRAMEWORK_PATH = /System/Library/PrivateFrameworks
TARGET_PRIVATE_FRAMEWORK_INCLUDE_PATH = /System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_hierarchial_bundle.mk

ARCHS ?= i386 x86_64
NEUTRAL_ARCH = i386

SDKFLAGS := $(if $(_THEOS_TARGET_MACOSX_DEPLOYMENT_VERSION),-mmacosx-version-min=$(_THEOS_TARGET_MACOSX_DEPLOYMENT_VERSION))
_THEOS_TARGET_CFLAGS := $(SDKFLAGS)
_THEOS_TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress

export TARGET_INSTALL_REMOTE := $(_THEOS_FALSE)
# Previously, _THEOS_TARGET_DEFAULT_PACKAGE_FORMAT was set to deb for OS X - though that seemed to be a mistake? (OS X doesn't... really use debs?)
export _THEOS_TARGET_DEFAULT_PACKAGE_FORMAT := none
endif
