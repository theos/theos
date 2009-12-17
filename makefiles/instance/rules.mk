.PHONY: before-$(FW_INSTANCE)-all after-$(FW_INSTANCE)-all \
	internal-$(FW_TYPE)-all

OBJCC_OBJS = $(patsubst %.mm,%.mm.o,$($(FW_INSTANCE)_OBJCC_FILES))
OBJC_OBJS = $(patsubst %.m,%.m.o,$($(FW_INSTANCE)_OBJC_FILES))
CC_OBJS = $(patsubst %.cc,%.cc.o,$($(FW_INSTANCE)_CC_FILES))
C_OBJS = $(patsubst %.c,%.c.o,$($(FW_INSTANCE)_C_FILES))

OBJ_FILES = $(strip $(OBJCC_OBJS) $(OBJC_OBJS) $(CC_OBJS) $(C_OBJS) $($(FW_INSTANCE)_OBJ_FILES))
OBJ_FILES_TO_LINK = $(addprefix $(FW_OBJ_DIR)/,$(OBJ_FILES)) $($(FW_INSTANCE)_OBJ_FILES)

ADDITIONAL_CPPFLAGS += $($(FW_TYPE)_CPPFLAGS) $($(FW_INSTANCE)_CPPFLAGS)
ADDITIONAL_CFLAGS += $($(FW_TYPE)_CFLAGS) $($(FW_INSTANCE)_CFLAGS)
ADDITIONAL_OBJCFLAGS += $($(FW_TYPE)_OBJCFLAGS) $($(FW_INSTANCE)_OBJCFLAGS)
ADDITIONAL_CCFLAGS += $($(FW_TYPE)_CCFLAGS) $($(FW_INSTANCE)_CCFLAGS)
ADDITIONAL_OBJCCFLAGS += $($(FW_TYPE)_OBJCCFLAGS) $($(FW_INSTANCE)_OBJCCFLAGS)
ADDITIONAL_LDFLAGS += $($(FW_TYPE)_LDFLAGS) $($(FW_INSTANCE)_LDFLAGS)

# If we have any Objective-C objects, link Foundation and libobjc.
ifneq ($(OBJC_OBJS)$(OBJCC_OBJS),)
	ADDITIONAL_LDFLAGS += -lobjc -framework Foundation -framework CoreFoundation
endif

# In addition, if we have any Objective-C++, add the ObjC++ linker flags.
ifneq ($(OBJCC_OBJS),)
	ADDITIONAL_LDFLAGS += -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors
endif

before-$(FW_INSTANCE)-all::

after-$(FW_INSTANCE)-all::

internal-$(FW_TYPE)-all:: before-$(FW_INSTANCE)-all internal-$(FW_TYPE)-all_ after-$(FW_INSTANCE)-all
