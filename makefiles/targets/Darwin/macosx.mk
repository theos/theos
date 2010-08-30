ifeq ($(FW_TARGET_LOADED),)
FW_TARGET_LOADED := 1
FW_TARGET_NAME := macosx

SDKBINPATH ?= /usr/bin

TARGET_CC ?= $(SDKBINPATH)/gcc-4.2
TARGET_CXX ?= $(SDKBINPATH)/g++-4.2
TARGET_STRIP ?= $(SDKBINPATH)/strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= $(SDKBINPATH)/codesign_allocate
TARGET_CODESIGN ?=
TARGET_CODESIGN_FLAGS ?=

include $(FW_MAKEDIR)/targets/_common/install_deb_local.mk
include $(FW_MAKEDIR)/targets/_common/darwin.mk

ARCHS ?= i386 x86_64
SDKFLAGS := $(foreach ARCH,$(ARCHS),-arch $(ARCH))
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
