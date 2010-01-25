ifeq ($(FW_PLATFORM_LOADED),)
FW_PLATFORM_LOADED := 1

TARGET ?= arm-apple-darwin9
SDKBINPATH ?= /opt/iphone-sdk-3.0/prefix/bin
SYSROOT ?= /opt/iphone-sdk-3.0/sysroot

PREFIX:=$(SDKBINPATH)/$(TARGET)-

CC=$(PREFIX)gcc
CXX=$(PREFIX)g++
STRIP=$(PREFIX)strip
CODESIGN_ALLOCATE=$(PREFIX)codesign_allocate

SDKFLAGS :=

DU_EXCLUDE = --exclude

endif
