ifeq ($(FW_TARGET_LOADED),)
FW_TARGET_LOADED := 1
FW_TARGET_NAME := iphone

SDKTARGET ?= arm-apple-darwin9
SDKBINPATH ?= /usr/bin
SYSROOT ?= /var/sdk

PREFIX := $(SDKBINPATH)/$(SDKTARGET)-

TARGET_CC ?= $(PREFIX)gcc
TARGET_CXX ?= $(PREFIX)g++
TARGET_STRIP ?= strip
TARGET_STRIP_FLAGS ?= -x
TARGET_CODESIGN_ALLOCATE ?= codesign_allocate
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

include $(FW_MAKEDIR)/targets/_common/install_deb_local.mk
include $(FW_MAKEDIR)/targets/_common/darwin.mk

SDKFLAGS := -isysroot $(SYSROOT)
TARGET_CFLAGS := $(SDKFLAGS)
TARGET_LDFLAGS := $(SDKFLAGS) -multiply_defined suppress
endif
