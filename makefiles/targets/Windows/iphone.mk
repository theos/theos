ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

_THEOS_TARGET_PLATFORM_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SDK_NAME := iPhoneOS
_THEOS_TARGET_PLATFORM_FLAG_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SWIFT_NAME := apple-ios

SWIFTBINPATH ?= $(THEOS)/toolchain/swift/bin
SDKBINPATH ?= $(THEOS)/toolchain/$(THEOS_PLATFORM_NAME)/$(THEOS_TARGET_NAME)/bin
PREFIX := $(SDKBINPATH)/$(SDKTARGET)-

ifneq ($(call __format_validate,$(SWIFTBINPATH)),$(_THEOS_TRUE))
$(ERROR_BEGIN)"$(SWIFTBINPATH) contains spaces which are not allowed in project paths."$(ERROR_END)
else ifneq ($(call __format_validate,$(SDKBINPATH)),$(_THEOS_TRUE))
$(ERROR_BEGIN)"$(SDKBINPATH) contains spaces which are not allowed in project paths."$(ERROR_END)
endif

# Determine toolchain to use based on file existence.
ifeq ($(SDKTARGET),)
ifeq ($(call __exists,$(SDKBINPATH)/arm64-apple-darwin14-ld),$(_THEOS_TRUE))
SDKTARGET ?= arm64-apple-darwin14
else
SDKTARGET ?= armv7-apple-darwin11
endif
endif

include $(THEOS_MAKE_PATH)/targets/_common/darwin_head.mk
include $(THEOS_MAKE_PATH)/targets/_common/iphone.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_tail.mk
endif
