ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := watchos_simulator

ifeq ($(__THEOS_TARGET_ARG_1),clang)
_THEOS_TARGET_CC := clang
_THEOS_TARGET_CXX := clang++
_THEOS_TARGET_ARG_ORDER := 2 3
else
_THEOS_TARGET_CC := gcc
_THEOS_TARGET_CXX := g++
_THEOS_TARGET_ARG_ORDER := 1 2
endif

# A version specified as a target argument overrides all previous definitions.
_SDKVERSION := $(or $(__THEOS_TARGET_ARG_$(word 1,$(_THEOS_TARGET_ARG_ORDER))),$(SDKVERSION))
_THEOS_TARGET_SDK_VERSION := $(or $(_SDKVERSION),latest)
_THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION := $(or $(__THEOS_TARGET_ARG_$(word 2,$(_THEOS_TARGET_ARG_ORDER))),$(TARGET_WATCHOS_DEPLOYMENT_VERSION),$(_THEOS_TARGET_SDK_VERSION))
_THEOS_TARGET_INCLUDE_SDK_VERSION := $(or $(INCLUDE_SDKVERSION),latest)

_SDK_DIR := $(THEOS_PLATFORM_SDK_ROOT)/Platforms/WatchSimulator.platform/Developer/SDKs
_IOS_SDKS := $(sort $(patsubst $(_SDK_DIR)/WatchSimulator%.sdk,%,$(wildcard $(_SDK_DIR)/WatchSimulator*.sdk)))
_LATEST_SDK := $(word $(words $(_IOS_SDKS)),$(_IOS_SDKS))

ifeq ($(_THEOS_TARGET_SDK_VERSION),latest)
override _THEOS_TARGET_SDK_VERSION := $(_LATEST_SDK)
endif

ifeq ($(_THEOS_TARGET_INCLUDE_SDK_VERSION),latest)
override _THEOS_TARGET_INCLUDE_SDK_VERSION := $(_LATEST_SDK)
endif

ifeq ($(_THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION),latest)
override _THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION := $(_LATEST_SDK)
endif

ifeq ($(SYSROOT),)
SYSROOT ?= $(THEOS_PLATFORM_SDK_ROOT)/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator$(_THEOS_TARGET_SDK_VERSION).sdk
ISYSROOT ?= $(THEOS_PLATFORM_SDK_ROOT)/Platforms/WatchSimulator.platform/Developer/SDKs/WatchSimulator$(_THEOS_TARGET_INCLUDE_SDK_VERSION).sdk
else
ISYSROOT ?= $(SYSROOT)
endif

TARGET_CC ?= xcrun -sdk watchsimulator $(_THEOS_TARGET_CC)
TARGET_CXX ?= xcrun -sdk watchsimulator $(_THEOS_TARGET_CXX)
TARGET_LD ?= xcrun -sdk watchsimulator $(_THEOS_TARGET_CXX)
TARGET_STRIP ?= xcrun -sdk watchsimulator strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk watchsimulator -find codesign_allocate)"
TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks
TARGET_PRIVATE_FRAMEWORK_INCLUDE_PATH = $(ISYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

ifeq ($(WATCHOS_SIMULATOR_ROOT),)
internal-install::
	@$(PRINT_FORMAT_ERROR) "$(MAKE) install for the simulator requires that you set WATCHOS_SIMULATOR_ROOT to the root directory of the simulated OS." >&2
	@exit 1
else
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "$(WATCHOS_SIMULATOR_ROOT)"
endif

ARCHS ?= x86_64
NEUTRAL_ARCH = x86_64

_TARGET_VERSION_FLAG = -mwatchos-simulator-version-min=9.0
_TARGET_OBJC_ABI_CFLAGS = -fobjc-abi-version=2 -fobjc-legacy-dispatch
_TARGET_OBJC_ABI_LDFLAGS = -Xlinker -objc_abi_version -Xlinker 2

MODULESFLAGS := -fmodules -fcxx-modules -fmodule-name=$(THEOS_CURRENT_INSTANCE)
SDKFLAGS := -D__IPHONE_OS_VERSION_MIN_REQUIRED=__IPHONE_$(subst .,_,$(_THEOS_TARGET_WATCHOS_DEPLOYMENT_VERSION)) $(_TARGET_VERSION_FLAG)

_THEOS_TARGET_CFLAGS := -isysroot $(ISYSROOT) $(SDKFLAGS) $(_TARGET_OBJC_ABI_CFLAGS) $(MODULESFLAGS)
_THEOS_TARGET_LDFLAGS := -isysroot $(SYSROOT) $(SDKFLAGS) -multiply_defined suppress $(_TARGET_OBJC_ABI_LDFLAGS) -Xlinker -allow_simulator_linking_to_macosx_dylibs

_THEOS_TARGET_DEFAULT_USE_SUBSTRATE := 0
endif
