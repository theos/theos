ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone_simulator

_THEOS_TARGET_CC := clang
_THEOS_TARGET_CXX := clang++
_THEOS_TARGET_ARG_ORDER := 2 3

# A version specified as a target argument overrides all previous definitions.
_SDKVERSION := $(or $(__THEOS_TARGET_ARG_$(word 1,$(_THEOS_TARGET_ARG_ORDER))),$(SDKVERSION))
_THEOS_TARGET_SDK_VERSION := $(or $(_SDKVERSION),latest)
_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(or $(__THEOS_TARGET_ARG_$(word 2,$(_THEOS_TARGET_ARG_ORDER))),$(TARGET_IPHONEOS_DEPLOYMENT_VERSION),$(_THEOS_TARGET_SDK_VERSION))
_THEOS_TARGET_INCLUDE_SDK_VERSION := $(or $(INCLUDE_SDKVERSION),latest)

_SDK_DIR := $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneSimulator.platform/Developer/SDKs
_IOS_SDKS := $(sort $(patsubst $(_SDK_DIR)/iPhoneSimulator%.sdk,%,$(wildcard $(_SDK_DIR)/iPhoneSimulator*.sdk)))

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

ifeq ($(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION),latest)
override _THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(_LATEST_SDK)
endif

ifeq ($(SYSROOT),)
SYSROOT ?= $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(_THEOS_TARGET_SDK_VERSION).sdk
ISYSROOT ?= $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(_THEOS_TARGET_INCLUDE_SDK_VERSION).sdk
else
ISYSROOT ?= $(SYSROOT)
endif

TARGET_CC ?= xcrun -sdk iphonesimulator $(_THEOS_TARGET_CC)
TARGET_CXX ?= xcrun -sdk iphonesimulator $(_THEOS_TARGET_CXX)
TARGET_LD ?= xcrun -sdk iphonesimulator $(_THEOS_TARGET_CXX)
TARGET_STRIP ?= xcrun -sdk iphonesimulator strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk iphonesimulator -find codesign_allocate)"
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks
TARGET_PRIVATE_FRAMEWORK_INCLUDE_PATH = $(ISYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

ifeq ($(IPHONE_SIMULATOR_ROOT),)
internal-install::
	@$(PRINT_FORMAT_ERROR) "$(MAKE) install for the simulator requires that you set IPHONE_SIMULATOR_ROOT to the root directory of the simulated OS." >&2
	@exit 1
else
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "$(IPHONE_SIMULATOR_ROOT)"
endif

# We have to figure out the target version here, as we need it in the calculation of the deployment version.
_TARGET_VERSION_GE_3_2 = $(call __simplify,_TARGET_VERSION_GE_3_2,$(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 3.2))
_TARGET_VERSION_GE_4_0 = $(call __simplify,_TARGET_VERSION_GE_4_0,$(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 4.0))
_TARGET_VERSION_GE_7_0 = $(call __simplify,_TARGET_VERSION_GE_7_0,$(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 7.0))
_TARGET_VERSION_GE_8_0 = $(call __simplify,_TARGET_VERSION_GE_8_0,$(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 8.0))
_TARGET_VERSION_GE_8_4 = $(call __simplify,_TARGET_VERSION_GE_8_4,$(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 8.4))

ARCHS ?= $(if $(_TARGET_VERSION_GE_8_0),,i386) $(if $(_TARGET_VERSION_GE_7_0),x86_64)
NEUTRAL_ARCH = $(if $(_TARGET_VERSION_GE_8_0),x86_64,i386)

_TARGET_VERSION_FLAG = $(if $(_TARGET_VERSION_GE_7_0),-mios-simulator-version-min=$(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION),-mmacosx-version-min=$(if $(_TARGET_VERSION_GE_4_0),10.6,10.5))
_TARGET_OBJC_ABI_CFLAGS = $(if $(_TARGET_VERSION_GE_3_2),-fobjc-abi-version=2 -fobjc-legacy-dispatch)
_TARGET_OBJC_ABI_LDFLAGS = $(if $(_TARGET_VERSION_GE_3_2),-Xlinker -objc_abi_version -Xlinker 2)

ifeq ($(_TARGET_VERSION_GE_8_4),1)
MODULESFLAGS := -fmodules -fcxx-modules -fmodule-name=$(THEOS_CURRENT_INSTANCE)
else
MODULESFLAGS :=
endif

SDKFLAGS := -D__IPHONE_OS_VERSION_MIN_REQUIRED=__IPHONE_$(subst .,_,$(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION)) $(_TARGET_VERSION_FLAG)

_THEOS_TARGET_CFLAGS := -isysroot $(ISYSROOT) $(SDKFLAGS) $(_TARGET_OBJC_ABI_CFLAGS) $(MODULESFLAGS)
_THEOS_TARGET_LDFLAGS := -isysroot $(SYSROOT) $(SDKFLAGS) -multiply_defined suppress $(_TARGET_OBJC_ABI_LDFLAGS) -Xlinker -allow_simulator_linking_to_macosx_dylibs

_THEOS_TARGET_DEFAULT_USE_SUBSTRATE := 0
endif
