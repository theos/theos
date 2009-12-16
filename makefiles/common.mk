ifeq ($(TOP_DIR),)
	TOP_DIR:=$(shell pwd)
	FRAMEWORKDIR=$(TOP_DIR)/framework
endif

FW_SCRIPTDIR := $(FRAMEWORKDIR)/scripts
FW_MAKEDIR := $(FRAMEWORKDIR)/makefiles
FW_LIBDIR := $(FRAMEWORKDIR)/lib
FW_INCDIR := $(FRAMEWORKDIR)/include
export FRAMEWORKDIR FW_SCRIPTDIR FW_MAKEDIR FW_LIBDIR FW_INCDIR

uname_s := $(shell uname -s)
-include $(FW_MAKEDIR)/platform/$(uname_s).mk
export CC CXX STRIP CODESIGN_ALLOCATE

INTERNAL_LDFLAGS = -lobjc -multiply_defined suppress -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors \
		   -framework Foundation -framework CoreFoundation

ifeq ($(DEBUG),1)
DEBUG_CFLAGS=-DDEBUG -ggdb
STRIP=:
endif

INTERNAL_CFLAGS = -O2 -I$(FW_INCDIR) -include $(FRAMEWORKDIR)/Prefix.pch -Wall -Werror
INTERNAL_CFLAGS += $(SHARED_CFLAGS)

ifeq ($(FW_BUILD_DIR),)
	FW_BUILD_DIR = .
endif
FW_OBJ_DIR = $(FW_BUILD_DIR)/obj

unexport FW_INSTANCE FW_TYPE
