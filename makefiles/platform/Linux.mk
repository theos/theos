ifeq ($(FW_PLATFORM_LOADED),)
FW_PLATFORM_LOADED := 1

TARGET ?= arm-apple-darwin9
SDKBINPATH ?= /opt/iphone-sdk-3.0/prefix/bin
SYSROOT ?= /opt/iphone-sdk-3.0/sysroot

PREFIX := $(SDKBINPATH)/$(TARGET)-

TARGET_CC ?= $(PREFIX)gcc
TARGET_CXX ?= $(PREFIX)g++
TARGET_STRIP ?= $(PREFIX)strip
TARGET_CODESIGN_ALLOCATE ?= $(PREFIX)codesign_allocate
TARGET_CODESIGN ?= ldid
TARGET_CODESIGN_FLAGS ?= -S

SDKFLAGS :=

DU_EXCLUDE = --exclude

endif
