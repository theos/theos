FW_SCRIPTDIR := $(FRAMEWORKDIR)/scripts
FW_MAKEDIR := $(FRAMEWORKDIR)/makefiles
FW_LIBDIR := $(FRAMEWORKDIR)/lib
FW_INCDIR := $(FRAMEWORKDIR)/include
export FW_SCRIPTDIR FW_MAKEDIR FW_LIBDIR FW_INCDIR

uname_s := $(shell uname -s)
-include $(FW_MAKEDIR)/platform/$(uname_s).mk
export CC CXX STRIP CODESIGN_ALLOCATE
