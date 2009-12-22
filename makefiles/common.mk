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
-include $(FW_MAKEDIR)/platform/$(uname_s).mk
export CC CXX STRIP CODESIGN_ALLOCATE

# ObjC/++ stuff is not here, it's in instance/rules.mk and only added if there are OBJC/OBJCC objects.
INTERNAL_LDFLAGS = -multiply_defined suppress -L$(FW_LIBDIR)

ifeq ($(DEBUG),1)
DEBUG_CFLAGS=-DDEBUG -ggdb
STRIP=:
endif

INTERNAL_CFLAGS = -O2 -I$(FW_INCDIR) -include $(FRAMEWORKDIR)/Prefix.pch -Wall
ifneq ($(GO_EASY_ON_ME),1)
	INTERNAL_CFLAGS += -Werror
endif
INTERNAL_CFLAGS += $(SHARED_CFLAGS)

FW_BUILD_DIR ?= .
FW_OBJ_DIR_NAME ?= obj
FW_OBJ_DIR = $(FW_BUILD_DIR)/$(FW_OBJ_DIR_NAME)

FW_PACKAGE_STAGING_DIR ?= $(FW_PROJECT_DIR)/_

include $(FW_MAKEDIR)/messages.mk
ifneq ($(messages),yes)
	FW_NO_PRINT_DIRECTORY_FLAG = --no-print-directory
else
	FW_NO_PRINT_DIRECTORY_FLAG = 
endif

unexport FW_INSTANCE FW_TYPE
