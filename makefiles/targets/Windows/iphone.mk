ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

_THEOS_TARGET_PLATFORM_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SDK_NAME := iPhoneOS
_THEOS_TARGET_PLATFORM_FLAG_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SWIFT_NAME := apple-ios

SWIFTBINPATH ?= $(THEOS)/toolchain/swift/bin
SDKBINPATH ?= $(THEOS)/toolchain/$(THEOS_PLATFORM_NAME)/$(THEOS_TARGET_NAME)/bin

# Determine toolchain to use based on file existence.
ifeq ($(_THEOS_TARGET_SDK_BIN_PREFIX),)
ifeq ($(call __exists,$(SDKBINPATH)/armv7-apple-darwin11-ld),$(_THEOS_TRUE))
_THEOS_TARGET_SDK_BIN_PREFIX ?= armv7-apple-darwin11-
else ifeq ($(call __exists,$(SDKBINPATH)/arm64-apple-darwin14-ld),$(_THEOS_TRUE))
_THEOS_TARGET_SDK_BIN_PREFIX ?= arm64-apple-darwin14-
else
# toolchain has no prefix so we are responsible of supplying target triple to clang for cross compiling
_THEOS_TARGET_USE_CLANG_TARGET_FLAG := $(_THEOS_TRUE)
endif
endif

PREFIX := $(SDKBINPATH)/$(_THEOS_TARGET_SDK_BIN_PREFIX)

include $(THEOS_MAKE_PATH)/targets/_common/darwin_head.mk
include $(THEOS_MAKE_PATH)/targets/_common/iphone.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_tail.mk

endif
