TOP_DIR ?= $(shell pwd)
FW_PROJECT_DIR ?= $(TOP_DIR)

FRAMEWORKDIR ?= $(FW_PROJECT_DIR)/framework
FW_SCRIPTDIR := $(FRAMEWORKDIR)/scripts
FW_MAKEDIR := $(FRAMEWORKDIR)/makefiles
FW_LIBDIR := $(FRAMEWORKDIR)/lib
FW_INCDIR := $(FRAMEWORKDIR)/include
export FRAMEWORKDIR FW_SCRIPTDIR FW_MAKEDIR FW_LIBDIR FW_INCDIR
export FW_PROJECT_DIR

uname_s := $(shell uname -s)
uname_p := $(shell uname -p)
FW_PLATFORM_ARCH = $(uname_s)-$(uname_p)
FW_PLATFORM = $(uname_s)
-include $(FW_MAKEDIR)/platform/$(uname_s)-$(uname_p).mk
-include $(FW_MAKEDIR)/platform/$(uname_s).mk

TARGET ?= $(target)
ifeq ($(TARGET),)
TARGET := $(FW_PLATFORM_DEFAULT_TARGET)
endif

-include $(FW_MAKEDIR)/targets/$(FW_PLATFORM_ARCH)/$(TARGET).mk
-include $(FW_MAKEDIR)/targets/$(FW_PLATFORM)/$(TARGET).mk

ifneq ($(FW_TARGET_LOADED),1)
$(error The "$(TARGET)" target is not supported on this platform)
endif

export TARGET_CC TARGET_CXX TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS

# ObjC/++ stuff is not here, it's in instance/rules.mk and only added if there are OBJC/OBJCC objects.
INTERNAL_LDFLAGS = -L$(FW_LIBDIR)

OPTFLAG ?= -O2
DEBUGFLAG ?= -ggdb
ifeq ($(DEBUG),1)
DEBUG_CFLAGS = -DDEBUG $(DEBUGFLAG)
OPTFLAG := $(filter-out -O%, $(OPTFLAG))
TARGET_STRIP = :
PACKAGE_BUILDNAME ?= debug
endif

INTERNAL_CFLAGS = $(OPTFLAG) -I$(FW_INCDIR) -include $(FRAMEWORKDIR)/Prefix.pch -Wall
ifneq ($(GO_EASY_ON_ME),1)
	INTERNAL_CFLAGS += -Werror
endif
INTERNAL_CFLAGS += $(SHARED_CFLAGS)

FW_BUILD_DIR ?= .

# If we're not using the default target, put the output in a folder named after the target.
ifneq ($(FW_TARGET_NAME),$(FW_PLATFORM_DEFAULT_TARGET))
	FW_OBJ_DIR_NAME ?= obj/$(FW_TARGET_NAME)
else
	FW_OBJ_DIR_NAME ?= obj
endif
FW_OBJ_DIR = $(FW_BUILD_DIR)/$(FW_OBJ_DIR_NAME)

FW_STAGING_DIR_NAME ?= _
FW_STAGING_DIR = $(FW_PROJECT_DIR)/$(FW_STAGING_DIR_NAME)

# $(warning ...) expands to the empty string, so the contents of FW_STAGING_DIR are not damaged in this copy.
FW_PACKAGE_STAGING_DIR = $(FW_STAGING_DIR)$(warning FW_PACKAGE_STAGING_DIR is deprecated; please use FW_STAGING_DIR)

FW_SUBPROJECT_PRODUCT = subproject.o

include $(FW_MAKEDIR)/messages.mk
ifneq ($(messages),yes)
	FW_NO_PRINT_DIRECTORY_FLAG = --no-print-directory
else
	FW_NO_PRINT_DIRECTORY_FLAG = 
endif

unexport FW_INSTANCE FW_TYPE

ifneq ($(TARGET_CODESIGN),)
FW_CODESIGN_COMMANDLINE = CODESIGN_ALLOCATE=$(TARGET_CODESIGN_ALLOCATE) $(TARGET_CODESIGN) $(TARGET_CODESIGN_FLAGS)
else
FW_CODESIGN_COMMANDLINE = 
endif

FW_RSYNC_EXCLUDES := --exclude "_MTN" --exclude ".git" --exclude ".svn" --exclude ".DS_Store" --exclude "._.*"

FW_MAKE_PARALLEL_BUILDING ?= yes
