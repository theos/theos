ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone_simulator

# A version specified as a target argument overrides all previous definitions.
_SDKVERSION := $(or $(firstword $(_THEOS_TARGET_ARGS)),$(SDKVERSION))
_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(or $(word 2,$(_THEOS_TARGET_ARGS)),$(TARGET_IPHONEOS_DEPLOYMENT_VERSION),$(_SDKVERSION),3.0)
_THEOS_TARGET_SDK_VERSION := $(or $(_SDKVERSION),latest)

_SDK_DIR := $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneSimulator.platform/Developer/SDKs
_IOS_SDKS := $(sort $(patsubst $(_SDK_DIR)/iPhoneSimulator%.sdk,%,$(wildcard $(_SDK_DIR)/iPhoneSimulator*.sdk)))
_LATEST_SDK := $(word $(words $(_IOS_SDKS)),$(_IOS_SDKS))

ifeq ($(_THEOS_TARGET_SDK_VERSION),latest)
override _THEOS_TARGET_SDK_VERSION := $(_LATEST_SDK)
endif

ifeq ($(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION),latest)
override _THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION := $(_LATEST_SDK)
endif

SYSROOT ?= $(THEOS_PLATFORM_SDK_ROOT)/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(_THEOS_TARGET_SDK_VERSION).sdk

TARGET_CC ?= xcrun -sdk iphonesimulator gcc
TARGET_CXX ?= xcrun -sdk iphonesimulator g++
TARGET_LD ?= xcrun -sdk iphonesimulator g++
TARGET_STRIP ?= xcrun -sdk iphonesimulator strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= "$(shell xcrun -sdk iphonesimulator -find codesign_allocate)"
TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

TARGET_PRIVATE_FRAMEWORK_PATH = $(SYSROOT)/System/Library/PrivateFrameworks

include $(THEOS_MAKE_PATH)/targets/_common/darwin.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_flat_bundle.mk

ifeq ($(IPHONE_SIMULATOR_ROOT),)
internal-install::
	$(info $(MAKE) install for the simulator requires that you set IPHONE_SIMULATOR_ROOT to the root directory of the simulated OS.)
	@exit 1
else
internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "$(IPHONE_SIMULATOR_ROOT)"
endif

ARCHS ?= i386

_TARGET_VERSION_GE_3_2 = $(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 3.2)
_TARGET_VERSION_GE_4_0 = $(shell $(THEOS_BIN_PATH)/vercmp.pl $(_THEOS_TARGET_SDK_VERSION) ge 4.0)
_TARGET_OSX_VERSION_FLAG = -mmacosx-version-min=$(if $(_TARGET_VERSION_GE_4_0),10.6,10.5)
_TARGET_OBJC_ABI_CFLAGS = $(if $(_TARGET_VERSION_GE_3_2),-fobjc-abi-version=2 -fobjc-legacy-dispatch)
_TARGET_OBJC_ABI_LDFLAGS = $(if $(_TARGET_VERSION_GE_3_2),-Xlinker -objc_abi_version -Xlinker 2)

SDKFLAGS := -isysroot $(SYSROOT) $(foreach ARCH,$(ARCHS),-arch $(ARCH)) -D__IPHONE_OS_VERSION_MIN_REQUIRED=__IPHONE_$(subst .,_,$(_THEOS_TARGET_IPHONEOS_DEPLOYMENT_VERSION)) $(_TARGET_OSX_VERSION_FLAG)

TARGET_CFLAGS := $(SDKFLAGS) $(_TARGET_OBJC_ABI_CFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress $(_TARGET_OBJC_ABI_LDFLAGS)
endif
