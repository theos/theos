# if the project defines no value for ARCHS, and the target makefile hasn’t already set a default
# ARCHS, set it to the value of NEUTRAL_ARCH
ARCHS ?= $(NEUTRAL_ARCH)

# determine the SYSROOT (for linking) and ISYSROOT (for compiling, I for “include”) like so:
# SYSROOT: check for theos/sdks/BlahX.Y.sdk, or Xcode.app/…/SDKs/BlahX.Y.sdk, or leave empty so we
# show an error
# ISYSROOT: check for theos/sdks/BlahA.B.sdk, or Xcode.app/…/SDKs/BlahA.B.sdk, or use the same value
# as SYSROOT if not defined
ifeq ($(SYSROOT),)
SYSROOT := $(or $(wildcard $(THEOS_SDKS_PATH)/$(_THEOS_TARGET_PLATFORM_SDK_NAME)$(_THEOS_TARGET_SDK_VERSION).sdk),$(wildcard $(THEOS_PLATFORM_SDK_ROOT)/Platforms/$(_THEOS_TARGET_PLATFORM_SDK_NAME).platform/Developer/SDKs/$(_THEOS_TARGET_PLATFORM_SDK_NAME)$(_THEOS_TARGET_SDK_VERSION).sdk))
endif
ifeq ($(ISYSROOT),)
ISYSROOT := $(or $(wildcard $(THEOS_SDKS_PATH)/$(_THEOS_TARGET_PLATFORM_SDK_NAME)$(_THEOS_TARGET_INCLUDE_SDK_VERSION).sdk),$(wildcard $(THEOS_PLATFORM_SDK_ROOT)/Platforms/$(_THEOS_TARGET_PLATFORM_SDK_NAME).platform/Developer/SDKs/$(_THEOS_TARGET_PLATFORM_SDK_NAME)$(_THEOS_TARGET_INCLUDE_SDK_VERSION).sdk),$(SYSROOT))
endif

TARGET_PRIVATE_FRAMEWORK_PATH ?= $(SYSROOT)/System/Library/PrivateFrameworks
TARGET_PRIVATE_FRAMEWORK_INCLUDE_PATH ?= $(ISYSROOT)/System/Library/PrivateFrameworks

# if the toolchain is capable of using clang modules, define the flags that enable modules
ifeq ($(_THEOS_DARWIN_CAN_USE_MODULES),$(_THEOS_TRUE))
	MODULESFLAGS := -fmodules -fcxx-modules -fmodule-name=$(THEOS_CURRENT_INSTANCE) -fbuild-session-file=$(_THEOS_BUILD_SESSION_FILE) \
		-fmodules-prune-after=345600 -fmodules-prune-interval=86400 -fmodules-validate-once-per-build-session
endif

ifneq ($(_THEOS_DARWIN_STABLE_SWIFT_VERSION),)
ifeq ($(call __vercmp,$(_THEOS_TARGET_OS_DEPLOYMENT_VERSION),ge,$(_THEOS_DARWIN_STABLE_SWIFT_VERSION)),1)
	_THEOS_DARWIN_HAS_STABLE_SWIFT := $(_THEOS_TRUE)
endif
endif

_THEOS_TARGET_SWIFT_TARGET := $(_THEOS_TARGET_PLATFORM_SWIFT_NAME)$(_THEOS_TARGET_OS_DEPLOYMENT_VERSION)$(_THEOS_TARGET_PLATFORM_SWIFT_SUFFIX)

ifeq ($(_THEOS_TARGET_USE_CLANG_TARGET_FLAG),$(_THEOS_TRUE))
	VERSIONFLAGS := -target $(THEOS_CURRENT_ARCH)-$(_THEOS_TARGET_SWIFT_TARGET)
else
	VERSIONFLAGS := -m$(_THEOS_TARGET_PLATFORM_FLAG_NAME)-version-min=$(_THEOS_TARGET_OS_DEPLOYMENT_VERSION)
endif

_THEOS_TARGET_CFLAGS := -isysroot "$(ISYSROOT)" $(VERSIONFLAGS) $(_THEOS_TARGET_CC_CFLAGS)
_THEOS_TARGET_CCFLAGS := $(_TARGET_LIBCPP_CCFLAGS)
_THEOS_TARGET_LDFLAGS := -isysroot "$(SYSROOT)" $(VERSIONFLAGS) $(LEGACYFLAGS) -multiply_defined suppress $(_TARGET_LIBSWIFT_LDFLAGS)
ifneq ($(filter %++,$(TARGET_LD)),)
_THEOS_TARGET_LDFLAGS += $(_TARGET_LIBCPP_LDFLAGS)
endif

# if toolchain has prefix, point clang to the ld we want to use
ifneq ($(_THEOS_TARGET_SDK_BIN_PREFIX),)
_THEOS_TARGET_LDFLAGS += -fuse-ld=$(SDKBINPATH)/$(_THEOS_TARGET_SDK_BIN_PREFIX)ld
endif

_THEOS_TARGET_SWIFTFLAGS := -sdk "$(SYSROOT)" $(_THEOS_TARGET_CC_SWIFTFLAGS)
# we *dont* want to readlink here because if the user has a dual toolchain setup then iphone/bin/swiftc
# might symlink the host one, but we want to use the iphone res dir and not the host one
_THEOS_TARGET_SWIFT_RESOURCE_DIR := $(dir $(shell type -p $(TARGET_SWIFTC)))../lib/swift
_THEOS_TARGET_SWIFT_LDPATHS = $(call __simplify,_THEOS_TARGET_SWIFT_LDPATHS,$(_THEOS_TARGET_SWIFT_RESOURCE_DIR)/$(_THEOS_TARGET_PLATFORM_NAME) /usr/lib/swift)

ifeq ($(call __exists,$(_THEOS_TARGET_SWIFT_RESOURCE_DIR)),$(_THEOS_TRUE))
_THEOS_TARGET_SWIFTFLAGS += -resource-dir $(_THEOS_TARGET_SWIFT_RESOURCE_DIR)
_THEOS_TARGET_CFLAGS += -resource-dir $(_THEOS_TARGET_SWIFT_RESOURCE_DIR)/clang
_THEOS_TARGET_LDFLAGS += -resource-dir $(_THEOS_TARGET_SWIFT_RESOURCE_DIR)/clang
endif

ifeq ($(_THEOS_TARGET_USE_APPLE_LIBSWIFT),$(_THEOS_TRUE))
	_THEOS_TARGET_LDFLAGS += $(foreach path,$(_THEOS_TARGET_SWIFT_LDPATHS),-L$(path))
else
ifeq ($(call __executable,$(TARGET_SWIFTC)),$(_THEOS_TRUE))
	_THEOS_TARGET_SWIFT_VERSION = $(call __simplify,_THEOS_TARGET_SWIFT_VERSION,$(shell $(TARGET_SWIFTC) --version 2>/dev/null | head -1 | cut -d'v' -f2 | cut -d' ' -f2 | cut -d'-' -f1))
ifeq ($(firstword $(subst ., ,$(_THEOS_TARGET_SWIFT_VERSION))),4)
	_THEOS_TARGET_SWIFT_VERSION_PATH = $(_THEOS_TARGET_SWIFT_VERSION)
else
	_THEOS_TARGET_SWIFT_VERSION_PATH = stable
endif
	_THEOS_TARGET_SWIFT_LDFLAGS = $(call __simplify,_THEOS_TARGET_SWIFT_LDFLAGS,-rpath /usr/lib/swift -rpath /usr/lib/libswift/$(_THEOS_TARGET_SWIFT_VERSION_PATH))
endif
endif

ifeq ($(_THEOS_TARGET_DARWIN_BUNDLE_TYPE),hierarchial)
	_THEOS_TARGET_BUNDLE_INFO_PLIST_SUBDIRECTORY := /Contents
	_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY := /Contents/Resources
	_THEOS_TARGET_BUNDLE_FRAMEWORK_SUBDIRECTORY := /Contents/Frameworks
	_THEOS_TARGET_BUNDLE_BINARY_SUBDIRECTORY := /Contents/MacOS
	_THEOS_TARGET_BUNDLE_HEADERS_SUBDIRECTORY := /Contents/Headers
else
	_THEOS_TARGET_BUNDLE_INFO_PLIST_SUBDIRECTORY :=
	_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY :=
	_THEOS_TARGET_BUNDLE_FRAMEWORK_SUBDIRECTORY :=
	_THEOS_TARGET_BUNDLE_BINARY_SUBDIRECTORY :=
	_THEOS_TARGET_BUNDLE_HEADERS_SUBDIRECTORY := /Headers
endif
