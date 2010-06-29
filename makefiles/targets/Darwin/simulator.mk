ifeq ($(FW_TARGET_LOADED),)
FW_TARGET_LOADED := 1
FW_TARGET_NAME := iphone_simulator

SDKBINPATH ?= /Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin
ifneq ($(words $(_FW_TARGET_ARGS)),0)
# A version specified as a target argument overrides all previous definitions.
override SDKVERSION := $(firstword $(_FW_TARGET_ARGS))
else
SDKVERSION ?= 3.0
endif
SYSROOT ?= /Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator$(SDKVERSION).sdk

TARGET_CC ?= $(SDKBINPATH)/gcc-4.2
TARGET_CXX ?= $(SDKBINPATH)/g++-4.2
TARGET_STRIP ?= $(SDKBINPATH)/strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= $(SDKBINPATH)/codesign_allocate
TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

include $(FW_MAKEDIR)/targets/_common/darwin.mk

ifeq ($(IPHONE_SIMULATOR_ROOT),)
internal-install::
	$(info $(MAKE) install for the simulator requires that you set IPHONE_SIMULATOR_ROOT to the root directory of the simulated OS.)
	@exit 1
else
internal-install:: stage
	install.mergeDir "$(FW_STAGING_DIR)" "$(IPHONE_SIMULATOR_ROOT)"
endif

ARCHS ?= i386
SDKFLAGS := -isysroot $(SYSROOT) $(foreach ARCH,$(ARCHS),-arch $(ARCH)) -D__IPHONE_OS_VERSION_MIN_REQUIRED=__IPHONE_$(subst .,_,$(SDKVERSION))
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress -mmacosx-version-min=10.5
endif
