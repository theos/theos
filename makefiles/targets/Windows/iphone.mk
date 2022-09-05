ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

_THEOS_TARGET_PLATFORM_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SDK_NAME := iPhoneOS
_THEOS_TARGET_PLATFORM_FLAG_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SWIFT_NAME := apple-ios

# Determine toolchain to use based on file existence.
ifeq ($(SDKTARGET),)
ifeq ($(call __exists,$(THEOS)/toolchain/$(THEOS_PLATFORM_NAME)/$(THEOS_TARGET_NAME)/bin/arm64-apple-darwin14-ld),$(_THEOS_TRUE))
SDKTARGET ?= arm64-apple-darwin14
else
SDKTARGET ?= armv7-apple-darwin11
endif
endif

SWIFTBINPATH ?= $(THEOS)/toolchain/swift/bin
SDKBINPATH ?= $(THEOS)/toolchain/$(THEOS_PLATFORM_NAME)/$(THEOS_TARGET_NAME)/bin
PREFIX := $(SDKBINPATH)/$(SDKTARGET)-

include $(THEOS_MAKE_PATH)/targets/_common/darwin_head.mk
include $(THEOS_MAKE_PATH)/targets/_common/iphone.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_tail.mk
endif
