ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := macosx

_THEOS_TARGET_PLATFORM_NAME := macosx
_THEOS_TARGET_PLATFORM_SDK_NAME := MacOSX
_THEOS_TARGET_PLATFORM_FLAG_NAME := macosx
_THEOS_TARGET_PLATFORM_SWIFT_NAME := apple-macosx
_THEOS_TARGET_DARWIN_BUNDLE_TYPE := hierarchial

TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

TARGET_INSTALL_REMOTE := $(_THEOS_FALSE)
_THEOS_TARGET_DEFAULT_PACKAGE_FORMAT := pkg

include $(THEOS_MAKE_PATH)/targets/_common/darwin_head.mk

# We have to figure out the target version here, as we need it in the calculation of the deployment version.
_TARGET_VERSION_GE_10_8 := $(call __simplify,_TARGET_VERSION_GE_10_8,$(call __vercmp,$(_THEOS_TARGET_SDK_VERSION),ge,10.8))
_TARGET_VERSION_GE_10_11 := $(call __simplify,_TARGET_VERSION_GE_10_11,$(call __vercmp,$(_THEOS_TARGET_SDK_VERSION),ge,10.11))
_TARGET_VERSION_GE_10_14 := $(call __simplify,_TARGET_VERSION_GE_10_14,$(call __vercmp,$(_THEOS_TARGET_SDK_VERSION),ge,10.14))
_TARGET_VERSION_GE_10_15 := $(call __simplify,_TARGET_VERSION_GE_10_15,$(call __vercmp,$(_THEOS_TARGET_SDK_VERSION),ge,10.15))

# For compatibility reasons, the macOS 11.0 SDK lives a double life, sometimes presenting itself as
# the macOS 10.16 SDK. Since 11.0 is greater than 10.16, this will catch both version numbers.
_TARGET_VERSION_GE_11_0 := $(call __simplify,_TARGET_VERSION_GE_11_0,$(call __vercmp,$(_THEOS_TARGET_SDK_VERSION),ge,10.16))

ifeq ($(_TARGET_VERSION_GE_10_8),1)
	_THEOS_TARGET_DEFAULT_OS_DEPLOYMENT_VERSION := 10.6
else
	_THEOS_TARGET_DEFAULT_OS_DEPLOYMENT_VERSION := 10.5
endif

ifeq ($(_TARGET_VERSION_GE_11_0),1)
	ARCHS ?= x86_64 arm64
	NEUTRAL_ARCH := x86_64
else ifeq ($(_TARGET_VERSION_GE_10_14),1)
	ARCHS ?= x86_64
	NEUTRAL_ARCH := x86_64
else
	ARCHS ?= i386 x86_64
	NEUTRAL_ARCH := i386
endif

ifeq ($(_TARGET_VERSION_GE_10_15),1)
	_THEOS_DARWIN_CAN_USE_MODULES := $(_THEOS_TRUE)
endif

ifeq ($(_TARGET_VERSION_GE_10_15),1)
	_THEOS_TARGET_USE_CLANG_TARGET_FLAG := $(_THEOS_TRUE)
endif

include $(THEOS_MAKE_PATH)/targets/_common/darwin_tail.mk
endif
