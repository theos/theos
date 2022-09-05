ifeq ($(_THEOS_PLATFORM_LOADED),$(_THEOS_FALSE))
_THEOS_PLATFORM_LOADED := 1
_THEOS_PLATFORM_HAS_XCODE := $(call __executable,xcode-select)

# Darwin is the common platform for macOS and iOS (and derivatives). Xcode is only available on
# macOS. If xcode-select is present, treat the platform like macOS, otherwise treat it like iOS.
THEOS_PLATFORM_NAME := $(if $(_THEOS_PLATFORM_HAS_XCODE),macosx,iphone)

ifneq ($(THEOS_CURRENT_ARCH),)
ifneq ($(THEOS_PLATFORM_SDK_ROOT_$(THEOS_CURRENT_ARCH)),)
THEOS_PLATFORM_SDK_ROOT = $(THEOS_PLATFORM_SDK_ROOT_$(THEOS_CURRENT_ARCH))
endif
endif

ifeq ($(_THEOS_PLATFORM_HAS_XCODE),$(_THEOS_TRUE))
ifeq ($(THEOS_PLATFORM_SDK_ROOT),)
	THEOS_PLATFORM_SDK_ROOT := $(shell xcode-select -print-path)
endif
	# To have xcrun use our customized THEOS_PLATFORM_SDK_ROOT
	export DEVELOPER_DIR = $(THEOS_PLATFORM_SDK_ROOT)
endif

_THEOS_PLATFORM_DEFAULT_TARGET := iphone

# Long flags are a GNUism. We can use this to tell whether to use GNU du or BSD du flags.
ifeq ($(shell du --version >/dev/null 2>&1 && echo 1),1)
	_THEOS_PLATFORM_DU_EXCLUDE := --exclude
else
	_THEOS_PLATFORM_DU_EXCLUDE := -I
endif

ifeq ($(call __executable,md5),$(_THEOS_TRUE))
	_THEOS_PLATFORM_MD5SUM := md5
else
	_THEOS_PLATFORM_MD5SUM := md5sum
endif

ifeq ($(call __executable,open),$(_THEOS_TRUE))
	_THEOS_PLATFORM_SHOW_IN_FILE_MANAGER := open -R
endif

THEOS_SUDO_COMMAND ?= sudo
_THEOS_PLATFORM_GET_LOGICAL_CORES := sysctl -n hw.ncpu
endif
