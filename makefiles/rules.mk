ifeq ($(FW_RULES_LOADED),)
FW_RULES_LOADED := 1

ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/rules.mk
else
	include $(FW_MAKEDIR)/instance/rules.mk
endif

ALL_CFLAGS = $(INTERNAL_CFLAGS) $(ADDITIONAL_CFLAGS) $(AUXILIARY_CFLAGS) $(SDK_CFLAGS) $(DEBUG_CFLAGS)
ALL_CCFLAGS =
ALL_OBJCFLAGS = $(INTERNAL_OBJCFLAGS) $(ADDITIONAL_OBJCFLAGS) $(AUXILIARY_OBJCFLAGS) $(SDK_OBJCFLAGS) $(DEBUG_CFLAGS)
ALL_OBJCCFLAGS = 

ALL_LDFLAGS = $(INTERNAL_LDFLAGS) $(ADDITIONAL_LDFLAGS) $(AUXILIARY_LDFLAGS) $(SDK_LDFLAGS)

.SUFFIXES:

.SUFFIXES: .m .mm .c .cc

$(FW_OBJ_DIR)/%.m.o: %.m
	$(CXX) -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $< -o $@

$(FW_OBJ_DIR)/%.mm.o: %.mm
	$(CXX) -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_OBJCCFLAGS) $< -o $@

$(FW_OBJ_DIR)/%.c.o: %.c
	$(CXX) -c $(ALL_CFLAGS) $(ALL_CFLAGS) $< -o $@

$(FW_OBJ_DIR)/%.cc.o: %.cc
	$(CXX) -c $(ALL_CFLAGS) $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@

ifneq ($(FW_BUILD_DIR),.)
$(FW_BUILD_DIR):
	@mkdir -p $(FW_BUILD_DIR)
endif

$(FW_OBJ_DIR):
	@cd $(FW_BUILD_DIR); mkdir -p $(FW_OBJ_DIR)

Makefile: ;
framework/makefiles/*.mk: ;
$(FW_MAKEDIR)/*.mk: ;
$(FW_MAKEDIR)/master/*.mk: ;
$(FW_MAKEDIR)/instance/*.mk: ;
$(FW_MAKEDIR)/platform/*.mk: ;

endif

# TODO MAKE A BUNCH OF THINGS PHONY
