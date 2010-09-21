all::

TOP_DIR ?= $(shell pwd)
FW_PROJECT_DIR ?= $(TOP_DIR)

ifeq ($(FRAMEWORKDIR),)
_FW_RELATIVE_MAKE_DIR = $(dir $(lastword $(MAKEFILE_LIST)))
FRAMEWORKDIR := $(shell (unset CDPATH; cd $(_FW_RELATIVE_MAKE_DIR); cd ..; pwd))
ifneq ($(words $(FRAMEWORKDIR)),1) # It's a hack, but it works.
$(shell ln -Ffs "$(FRAMEWORKDIR)" /tmp/theos)
FRAMEWORKDIR := /tmp/theos
endif
endif
FW_MAKEDIR := $(FRAMEWORKDIR)/makefiles
FW_BINDIR := $(FRAMEWORKDIR)/bin
FW_LIBDIR := $(FRAMEWORKDIR)/lib
FW_INCDIR := $(FRAMEWORKDIR)/include
FW_MODDIR := $(FRAMEWORKDIR)/mod
export FRAMEWORKDIR FW_BINDIR FW_MAKEDIR FW_LIBDIR FW_INCDIR
export FW_PROJECT_DIR

export PATH := $(FW_BINDIR):$(PATH)

# There are some packaging-related variables set here because some of the target install rules rely on them.
ifeq ($(_FW_TOP_INVOCATION_DONE),)
FW_HAS_LAYOUT := $(shell [ -d "$(FW_PROJECT_DIR)/layout" ] && echo 1 || echo 0)
ifeq ($(FW_HAS_LAYOUT),1)
	FW_PACKAGE_CONTROL_PATH := $(FW_PROJECT_DIR)/layout/DEBIAN/control
else # FW_HAS_LAYOUT == 0
	FW_PACKAGE_CONTROL_PATH := $(FW_PROJECT_DIR)/control
endif # FW_HAS_LAYOUT
FW_CAN_PACKAGE := $(shell [ -f "$(FW_PACKAGE_CONTROL_PATH)" ] && echo 1 || echo 0)
endif # FW_TOP_INVOCATION_DONE

_FW_MODULES := $(sort $(MODULES) $(THEOS_AUTOLOAD_MODULES))

uname_s := $(shell uname -s)
uname_p := $(shell uname -p)
FW_PLATFORM_ARCH = $(uname_s)-$(uname_p)
FW_PLATFORM = $(uname_s)
-include $(FW_MAKEDIR)/platform/$(uname_s)-$(uname_p).mk
-include $(FW_MAKEDIR)/platform/$(uname_s).mk

_FW_TARGET := $(or $(target),$(TARGET),$(FW_PLATFORM_DEFAULT_TARGET))
ifeq ($(_FW_TARGET),)
$(error You did not specify a target, and the "$(FW_PLATFORM_NAME)" platform does not define a default target)
endif
_FW_TARGET := $(subst :, ,$(_FW_TARGET))
_FW_TARGET_ARGS := $(wordlist 2,$(words $(_FW_TARGET)),$(_FW_TARGET))
_FW_TARGET := $(firstword $(_FW_TARGET))

-include $(FW_MAKEDIR)/targets/$(FW_PLATFORM_ARCH)/$(_FW_TARGET).mk
-include $(FW_MAKEDIR)/targets/$(FW_PLATFORM)/$(_FW_TARGET).mk
-include $(FW_MAKEDIR)/targets/$(_FW_TARGET).mk
-include $(foreach mod,$(_FW_MODULES),$(FW_MODDIR)/$(mod)/targets/$(FW_PLATFORM_ARCH)/$(_FW_TARGET).mk)
-include $(foreach mod,$(_FW_MODULES),$(FW_MODDIR)/$(mod)/targets/$(FW_PLATFORM)/$(_FW_TARGET).mk)
-include $(foreach mod,$(_FW_MODULES),$(FW_MODDIR)/$(mod)/targets/$(_FW_TARGET).mk)

ifneq ($(FW_TARGET_LOADED),1)
$(error The "$(_FW_TARGET)" target is not supported on the "$(FW_PLATFORM_NAME)" platform)
endif

_FW_TARGET_NAME_DEFINE := $(shell echo "$(FW_TARGET_NAME)" | tr 'a-z' 'A-Z')

export TARGET_CC TARGET_CXX TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS

# ObjC/++ stuff is not here, it's in instance/rules.mk and only added if there are OBJC/OBJCC objects.
INTERNAL_LDFLAGS = -L$(FW_LIBDIR)

OPTFLAG ?= -O2
DEBUGFLAG ?= -ggdb
ifeq ($(DEBUG),1)
DEBUG_CFLAGS = -DDEBUG $(DEBUGFLAG)
DEBUG_LDFLAGS = $(DEBUGFLAG)
OPTFLAG := $(filter-out -O%, $(OPTFLAG))
TARGET_STRIP = :
PACKAGE_BUILDNAME ?= debug
endif

INTERNAL_CFLAGS = -DTARGET_$(_FW_TARGET_NAME_DEFINE)=1 $(OPTFLAG) -I$(FW_INCDIR) -include $(FRAMEWORKDIR)/Prefix.pch -Wall
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

FW_RSYNC_EXCLUDES := --exclude "_MTN" --exclude ".git" --exclude ".svn" --exclude ".DS_Store" --exclude "._*"

FW_MAKE_PARALLEL_BUILDING ?= yes

-include $(foreach mod,$(_FW_MODULES),$(FRAMEWORKDIR)/mod/$(mod)/common.mk)
