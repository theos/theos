ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := watchos

_THEOS_TARGET_CC := clang
_THEOS_TARGET_CXX := clang++

_SDK_DIR := $(THEOS_PLATFORM_SDK_ROOT)/Platforms/WatchOS.platform/Developer/SDKs

# A version specified as a target argument overrides all previous definitions.
_SDKVERSION := $(or $(__THEOS_TARGET_ARG_$(word 1,$(_THEOS_TARGET_ARG_ORDER))),$(SDKVERSION_$(THEOS_CURRENT_ARCH)),$(SDKVERSION))
_THEOS_TARGET_SDK_VERSION := $(or $(_SDKVERSION),latest)
_THEOS_TARGET_INCLUDE_SDK_VERSION := $(or $(INCLUDE_SDKVERSION),$(INCLUDE_SDKVERSION_$(THEOS_CURRENT_ARCH)),latest)

_IOS_SDKS := $(sort $(patsubst $(_SDK_DIR)/WatchOS%.sdk,%,$(wildcard $(_SDK_DIR)/WatchOS*.sdk)))

ifeq ($(words $(_IOS_SDKS)),0)
before-all::
	@$(PRINT_FORMAT_ERROR) "You do not have an SDK in $(_SDK_DIR)." >&2; exit 1
endif
_LATEST_SDK := $(lastword $(_IOS_SDKS))

ifeq ($(_THEOS_TARGET_SDK_VERSION),latest)
override _THEOS_TARGET_SDK_VERSION := $(_LATEST_SDK)
endif

ifeq ($(_THEOS_TARGET_INCLUDE_SDK_VERSION),latest)
override _THEOS_TARGET_INCLUDE_SDK_VERSION := $(_LATEST_SDK)
endif

_THEOS_TARGET_DEFAULT_WATCHOS_DEPLOYMENT_VERSION := 9.0
_THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION := 9.0

ifeq ($(_THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION),latest)
override _THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION := $(_LATEST_SDK)
endif

ifeq ($(SYSROOT),)
SYSROOT ?= $(_SDK_DIR)/WatchOS$(_THEOS_TARGET_INCLUDE_SDK_VERSION).sdk
ISYSROOT ?= $(_SDK_DIR)/WatchOS$(_THEOS_TARGET_INCLUDE_SDK_VERSION).sdk
else
ISYSROOT ?= $(SYSROOT)
endif

TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks
TARGET_PRIVATE_FRAMEWORK_INCLUDE_PATH = $(ISYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

TARGET_CC ?= xcrun -sdk watchos $(_THEOS_TARGET_CC)
TARGET_CXX ?= xcrun -sdk watchos $(_THEOS_TARGET_CXX)
TARGET_SWIFT = xcrun -sdk watchos swift
TARGET_LD ?= xcrun -sdk watchos $(_THEOS_TARGET_CXX)
TARGET_STRIP ?= xcrun -sdk watchos strip
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk watchos -find codesign_allocate)"
TARGET_IBTOOL ?= xcrun -sdk watchos ibtool

ARCHS ?= armv7k
NEUTRAL_ARCH = armv7k

MODULESFLAGS := -fmodules -fcxx-modules -fmodule-name=$(THEOS_CURRENT_INSTANCE) -fbuild-session-file=$(_THEOS_BUILD_SESSION_FILE) -fmodules-prune-after=345600 -fmodules-prune-interval=86400 -fmodules-validate-once-per-build-session
IBMODULESFLAGS := --module $(THEOS_CURRENT_INSTANCE)

VERSIONFLAGS := -mwatchos-version-min=$(_THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION)

_THEOS_TARGET_CFLAGS += -isysroot "$(ISYSROOT)" $(SDKFLAGS) $(VERSIONFLAGS) $(MODULESFLAGS)
_THEOS_TARGET_LDFLAGS += -isysroot "$(SYSROOT)" $(SDKFLAGS) $(VERSIONFLAGS) $(LEGACYFLAGS) -multiply_defined suppress
_THEOS_TARGET_SWIFTFLAGS := -sdk "$(ISYSROOT)" $(SDKFLAGS)
_THEOS_TARGET_SWIFT_TARGET := apple-watchos$(_THEOS_TARGET_SDK_VERSION)
_THEOS_TARGET_SWIFT_LDPATH := $(THEOS_PLATFORM_SDK_ROOT)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/watchos
_THEOS_TARGET_SWIFT_OBJPATH := $(THEOS_PLATFORM_SDK_ROOT)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift_static/watchos
_THEOS_TARGET_SWIFT_VERSION = $(shell $(TARGET_SWIFT) --version | head -1 | cut -d' ' -f4)
_THEOS_TARGET_IBFLAGS = --auto-activate-custom-fonts --minimum-deployment-target $(_THEOS_TARGET_SDK_VERSION) $(IBMODULESFLAGS)

_THEOS_TARGET_DEFAULT_PACKAGE_FORMAT := deb

TARGET_INSTALL_REMOTE := $(_THEOS_TRUE)
endif
