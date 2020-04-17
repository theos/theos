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
ifeq ($(SDKTARGET),)
ifeq ($(call __exists, $(SDKBINPATH)/armv7-apple-darwin11-ld),$(_THEOS_TRUE))
SDKTARGETPREFIX ?= armv7-apple-darwin11-
else ifeq ($(call __exists, $(SDKBINPATH)/arm64-apple-darwin14-ld),$(_THEOS_TRUE))
SDKTARGETPREFIX ?= arm64-apple-darwin14-
else
SDKTARGETPREFIX ?=
TARGET_OPTIONS ?= -target arm64-apple-darwin
endif
endif

PREFIX := $(SDKBINPATH)/$(SDKTARGETPREFIX)

include $(THEOS_MAKE_PATH)/targets/_common/darwin_head.mk
include $(THEOS_MAKE_PATH)/targets/_common/iphone.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_tail.mk

_THEOS_TARGET_CFLAGS += $(TARGET_OPTIONS)
_THEOS_TARGET_CCFLAGS += $(TARGET_OPTIONS)
_THEOS_TARGET_LDFLAGS += $(TARGET_OPTIONS)
endif
