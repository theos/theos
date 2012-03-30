ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

# A version specified as a target argument overrides all previous definitions.
_SDKVERSION := $(or $(firstword $(_THEOS_TARGET_ARGS)),$(SDKVERSION))
_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(or $(word 2,$(_THEOS_TARGET_ARGS)),$(TARGET_IPHONEOS_DEPLOYMENT_VERSION),$(_SDKVERSION),3.0)
_THEOS_TARGET_SDK_VERSION := $(or $(_SDKVERSION),latest)

_SDK_DIR := $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneOS.platform/Developer/SDKs
_IOS_SDKS := $(sort $(patsubst $(_SDK_DIR)/iPhoneOS%.sdk,%,$(wildcard $(_SDK_DIR)/iPhoneOS*.sdk)))
_LATEST_SDK := $(word $(words $(_IOS_SDKS)),$(_IOS_SDKS))

ifeq ($(_THEOS_TARGET_SDK_VERSION),latest)
override _THEOS_TARGET_SDK_VERSION := $(_LATEST_SDK)
endif

ifeq ($(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION),latest)
override _THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(_LATEST_SDK)
endif

SYSROOT ?= $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$(_THEOS_TARGET_SDK_VERSION).sdk

TARGET_CC ?= xcrun -sdk iphoneos gcc
TARGET_CXX ?= xcrun -sdk iphoneos g++
TARGET_LD ?= xcrun -sdk iphoneos g++
TARGET_STRIP ?= xcrun -sdk iphoneos strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk iphoneos -find codesign_allocate)"
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/install_deb_remote.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

ARCHS ?= armv6

SDKFLAGS := -isysroot "$(SYSROOT)" $(foreach ARCH,$(ARCHS),-arch $(ARCH)) -D__IPHONE_OS_VERSION_MIN_REQUIRED=__IPHONE_$(subst .,_,$(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION)) -miphoneos-version-min=$(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION)
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
