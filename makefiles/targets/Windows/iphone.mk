ifeq ($(_THEOS_TARGET_LOADED),)
_THEOS_TARGET_LOADED := 1
THEOS_TARGET_NAME := iphone

_THEOS_TARGET_PLATFORM_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SDK_NAME := iPhoneOS
_THEOS_TARGET_PLATFORM_FLAG_NAME := iphoneos
_THEOS_TARGET_PLATFORM_SWIFT_NAME := apple-ios

SWIFTBINPATH ?= $(THEOS)/toolchain/swift/bin
SDKBINPATH ?= $(THEOS)/toolchain/$(THEOS_PLATFORM_NAME)/$(THEOS_TARGET_NAME)/bin

# A legally user-supplied SDK can live anywhere on Windows; no Apple SDK is bundled.
ifneq ($(strip $(THEOS_LDID)),)
TARGET_CODESIGN := $(THEOS_LDID)
else ifneq ($(_THEOS_LDID),)
TARGET_CODESIGN := $(_THEOS_LDID)
endif

ifneq ($(strip $(THEOS_SDKROOT)),)
SYSROOT ?= $(THEOS_SDKROOT)
ISYSROOT ?= $(THEOS_SDKROOT)
else ifneq ($(strip $(IOS_SDK_ROOT)),)
SYSROOT ?= $(IOS_SDK_ROOT)
ISYSROOT ?= $(IOS_SDK_ROOT)
endif

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

# Only prefix tools when a complete target-prefixed toolchain is present.
# With PATH-based LLVM/LLD, leave PREFIX empty so clang is resolved normally.
ifeq ($(_THEOS_TARGET_SDK_BIN_PREFIX),)
PREFIX :=
else
PREFIX := $(SDKBINPATH)/$(_THEOS_TARGET_SDK_BIN_PREFIX)
endif

include $(THEOS_MAKE_PATH)/targets/_common/darwin_head.mk
include $(THEOS_MAKE_PATH)/targets/_common/iphone.mk
include $(THEOS_MAKE_PATH)/targets/_common/darwin_tail.mk

# Signing is configured before darwin_head.mk so its shared fallback cannot override it.
export THEOS_WINDOWS_ALLOW_NO_SDK

# Clang's Darwin driver resolves -fuse-ld=lld to bundled ld64.lld for Apple targets.
# Keep ld64.lld available on PATH; do not pass the executable filename as the selector.
ifneq ($(strip $(THEOS_LLVM_BIN)),)
PATH := $(THEOS_LLVM_BIN);$(PATH)
export PATH
TARGET_STRIP := llvm-strip.exe
TARGET_DSYMUTIL := dsymutil.exe
endif
ifneq ($(strip $(SYSROOT)),)
before-all::
	@$(_THEOS_WINDOWS_PYTHON) "$(THEOS_BIN_PATH)/theos-windows.py" sdk-info "$(SYSROOT)" --platform iPhoneOS
endif
ifneq ($(call __executable,ld64.lld.exe),$(_THEOS_FALSE))
_THEOS_TARGET_LDFLAGS += -fuse-ld=lld
endif

endif
