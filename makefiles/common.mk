all::

THEOS_PROJECT_DIR ?= $(shell pwd)

_THEOS_RELATIVE_MAKE_PATH := $(dir $(lastword $(MAKEFILE_LIST)))
ifeq ($(THEOS),)
THEOS := $(shell (unset CDPATH; cd $(_THEOS_RELATIVE_MAKE_PATH); cd ..; pwd))
ifneq ($(words $(THEOS)),1) # It's a hack, but it works.
$(shell unlink /tmp/theos &> /dev/null; ln -Ffs "$(THEOS)" /tmp/theos)
THEOS := /tmp/theos
endif
endif
THEOS_MAKE_PATH := $(THEOS)/makefiles
THEOS_BIN_PATH := $(THEOS)/bin
THEOS_LIBRARY_PATH := $(THEOS)/lib
THEOS_INCLUDE_PATH := $(THEOS)/include
THEOS_MODULE_PATH := $(THEOS)/mod
export THEOS THEOS_BIN_PATH THEOS_MAKE_PATH THEOS_LIBRARY_PATH THEOS_INCLUDE_PATH
export THEOS_PROJECT_DIR

export PATH := $(THEOS_BIN_PATH):$(PATH)

# There are some packaging-related variables set here because some of the target install rules rely on them.
ifeq ($(_THEOS_TOP_INVOCATION_DONE),)
_THEOS_HAS_STAGING_LAYOUT := $(shell [ -d "$(THEOS_PROJECT_DIR)/layout" ] && echo 1 || echo 0)
ifeq ($(_THEOS_HAS_STAGING_LAYOUT),1)
	_THEOS_PACKAGE_CONTROL_PATH := $(THEOS_PROJECT_DIR)/layout/DEBIAN/control
else # _THEOS_HAS_STAGING_LAYOUT == 0
	_THEOS_PACKAGE_CONTROL_PATH := $(THEOS_PROJECT_DIR)/control
endif # _THEOS_HAS_STAGING_LAYOUT
_THEOS_CAN_PACKAGE := $(shell [ -f "$(_THEOS_PACKAGE_CONTROL_PATH)" ] && echo 1 || echo 0)
endif # _THEOS_TOP_INVOCATION_DONE
_THEOS_PACKAGE_LAST_VERSION = $(shell THEOS_PROJECT_DIR="$(THEOS_PROJECT_DIR)" $(THEOS_BIN_PATH)/package_version.sh -k -n -o -c "$(_THEOS_PACKAGE_CONTROL_PATH)")

_THEOS_LOAD_MODULES := $(sort $(MODULES) $(THEOS_AUTOLOAD_MODULES))

include $(THEOS_MAKE_PATH)/legacy.mk

uname_s := $(shell uname -s)
uname_p := $(shell uname -p)
_THEOS_PLATFORM_ARCH = $(uname_s)-$(uname_p)
_THEOS_PLATFORM = $(uname_s)
-include $(THEOS_MAKE_PATH)/platform/$(uname_s)-$(uname_p).mk
-include $(THEOS_MAKE_PATH)/platform/$(uname_s).mk
-include $(foreach mod,$(_THEOS_LOAD_MODULES),$(THEOS_MODULE_PATH)/$(mod)/platform/$(uname_s)-$(uname_p).mk)
-include $(foreach mod,$(_THEOS_LOAD_MODULES),$(THEOS_MODULE_PATH)/$(mod)/platform/$(uname_s).mk)

_THEOS_TARGET := $(or $(target),$(TARGET),$(_THEOS_PLATFORM_DEFAULT_TARGET))
ifeq ($(_THEOS_TARGET),)
$(error You did not specify a target, and the "$(THEOS_PLATFORM_NAME)" platform does not define a default target)
endif
_THEOS_TARGET := $(subst :, ,$(_THEOS_TARGET))
_THEOS_TARGET_ARGS := $(wordlist 2,$(words $(_THEOS_TARGET)),$(_THEOS_TARGET))
_THEOS_TARGET := $(firstword $(_THEOS_TARGET))

-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_PLATFORM_ARCH)/$(_THEOS_TARGET).mk
-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_PLATFORM)/$(_THEOS_TARGET).mk
-include $(THEOS_MAKE_PATH)/targets/$(_THEOS_TARGET).mk
-include $(foreach mod,$(_THEOS_LOAD_MODULES),$(THEOS_MODULE_PATH)/$(mod)/targets/$(_THEOS_PLATFORM_ARCH)/$(_THEOS_TARGET).mk)
-include $(foreach mod,$(_THEOS_LOAD_MODULES),$(THEOS_MODULE_PATH)/$(mod)/targets/$(_THEOS_PLATFORM)/$(_THEOS_TARGET).mk)
-include $(foreach mod,$(_THEOS_LOAD_MODULES),$(THEOS_MODULE_PATH)/$(mod)/targets/$(_THEOS_TARGET).mk)

ifneq ($(_THEOS_TARGET_LOADED),1)
$(error The "$(_THEOS_TARGET)" target is not supported on the "$(THEOS_PLATFORM_NAME)" platform)
endif

_THEOS_TARGET_NAME_DEFINE := $(shell echo "$(THEOS_TARGET_NAME)" | tr 'a-z' 'A-Z')

export TARGET_CC TARGET_CXX TARGET_LD TARGET_STRIP TARGET_CODESIGN_ALLOCATE TARGET_CODESIGN TARGET_CODESIGN_FLAGS

THEOS_TARGET_INCLUDE_PATH := $(THEOS_INCLUDE_PATH)/$(THEOS_TARGET_NAME)
THEOS_TARGET_LIBRARY_PATH := $(THEOS_LIBRARY_PATH)/$(THEOS_TARGET_NAME)
_THEOS_TARGET_HAS_INCLUDE_PATH := $(shell [ -d "$(THEOS_TARGET_INCLUDE_PATH)" ] && echo 1)
_THEOS_TARGET_HAS_LIBRARY_PATH := $(shell [ -d "$(THEOS_TARGET_LIBRARY_PATH)" ] && echo 1)

# ObjC/++ stuff is not here, it's in instance/rules.mk and only added if there are OBJC/OBJCC objects.
INTERNAL_LDFLAGS = $(if $(_THEOS_TARGET_HAS_LIBRARY_PATH),-L$(THEOS_TARGET_LIBRARY_PATH) )-L$(THEOS_LIBRARY_PATH)

OPTFLAG ?= -O2
DEBUGFLAG ?= -ggdb
ifeq ($(DEBUG),1)
DEBUG_CFLAGS = -DDEBUG $(DEBUGFLAG)
DEBUG_LDFLAGS = $(DEBUGFLAG)
OPTFLAG := $(filter-out -O%, $(OPTFLAG))
TARGET_STRIP = :
PACKAGE_BUILDNAME ?= debug
endif

INTERNAL_CFLAGS = -DTARGET_$(_THEOS_TARGET_NAME_DEFINE)=1 $(OPTFLAG) $(if $(_THEOS_TARGET_HAS_INCLUDE_PATH),-I$(THEOS_TARGET_INCLUDE_PATH) )-I$(THEOS_INCLUDE_PATH) -include $(THEOS)/Prefix.pch -Wall
ifneq ($(GO_EASY_ON_ME),1)
	INTERNAL_CFLAGS += -Werror
endif
INTERNAL_CFLAGS += $(SHARED_CFLAGS)

THEOS_BUILD_DIR ?= .

# If we're not using the default target, put the output in a folder named after the target.
ifneq ($(THEOS_TARGET_NAME),$(_THEOS_PLATFORM_DEFAULT_TARGET))
	THEOS_OBJ_DIR_NAME ?= obj/$(THEOS_TARGET_NAME)
else
	THEOS_OBJ_DIR_NAME ?= obj
endif
THEOS_OBJ_DIR = $(THEOS_BUILD_DIR)/$(THEOS_OBJ_DIR_NAME)

THEOS_STAGING_DIR_NAME ?= _
THEOS_STAGING_DIR = $(THEOS_PROJECT_DIR)/$(THEOS_STAGING_DIR_NAME)
_SPACE :=
_SPACE += 
_THEOS_ESCAPED_STAGING_DIR = $(subst $(_SPACE),\ ,$(THEOS_STAGING_DIR))

ifeq ($(THEOS_PACKAGE_DIR_NAME),)
THEOS_PACKAGE_DIR = $(THEOS_BUILD_DIR)
else
THEOS_PACKAGE_DIR = $(THEOS_BUILD_DIR)/$(THEOS_PACKAGE_DIR_NAME)
endif

# $(warning ...) expands to the empty string, so the contents of THEOS_STAGING_DIR are not damaged in this copy.
FW_PACKAGE_STAGING_DIR = $(THEOS_STAGING_DIR)$(warning FW_PACKAGE_STAGING_DIR is deprecated; please use THEOS_STAGING_DIR)

THEOS_SUBPROJECT_PRODUCT = subproject.o

include $(THEOS_MAKE_PATH)/messages.mk
ifneq ($(messages),yes)
	_THEOS_NO_PRINT_DIRECTORY_FLAG = --no-print-directory
else
	_THEOS_NO_PRINT_DIRECTORY_FLAG = 
endif

unexport THEOS_CURRENT_INSTANCE _THEOS_CURRENT_TYPE

ifneq ($(TARGET_CODESIGN),)
_THEOS_CODESIGN_COMMANDLINE = CODESIGN_ALLOCATE=$(TARGET_CODESIGN_ALLOCATE) $(TARGET_CODESIGN) $(TARGET_CODESIGN_FLAGS)
else
_THEOS_CODESIGN_COMMANDLINE = 
endif

THEOS_RSYNC_EXCLUDES ?= _MTN .git .svn .DS_Store ._*
_THEOS_RSYNC_EXCLUDE_COMMANDLINE := $(foreach exclude,$(THEOS_RSYNC_EXCLUDES),--exclude "$(exclude)")

_THEOS_MAKE_PARALLEL_BUILDING ?= yes

-include $(foreach mod,$(_THEOS_LOAD_MODULES),$(THEOS)/mod/$(mod)/common.mk)
