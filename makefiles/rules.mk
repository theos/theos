ifeq ($(FW_RULES_LOADED),)
FW_RULES_LOADED := 1

ifeq ($(FW_INSTANCE),)
	include $(FW_MAKEDIR)/master/rules.mk
	-include $(foreach mod,$(_FW_MODULES),$(FW_MODDIR)/$(mod)/master/rules.mk)
else
	include $(FW_MAKEDIR)/instance/rules.mk
	-include $(foreach mod,$(_FW_MODULES),$(FW_MODDIR)/$(mod)/instance/rules.mk)
endif

ALL_CFLAGS = $(INTERNAL_CFLAGS) $(TARGET_CFLAGS) $(ADDITIONAL_CFLAGS) $(AUXILIARY_CFLAGS) $(DEBUG_CFLAGS) $(CFLAGS)
ALL_CCFLAGS = $(ADDITIONAL_CCFLAGS) $(CCFLAGS)
ALL_OBJCFLAGS = $(INTERNAL_OBJCFLAGS) $(TARGET_OBJCFLAGS) $(ADDITIONAL_OBJCFLAGS) $(AUXILIARY_OBJCFLAGS) $(DEBUG_CFLAGS) $(OBJCFLAGS)
ALL_OBJCCFLAGS = $(ADDITIONAL_OBJCCFLAGS) $(OBJCCFLAGS)

ALL_LDFLAGS = $(INTERNAL_LDFLAGS) $(ADDITIONAL_LDFLAGS) $(AUXILIARY_LDFLAGS) $(TARGET_LDFLAGS) $(DEBUG_LDFLAGS) $(LDFLAGS)

ifeq ($(FW_MAKE_PARALLEL_BUILDING), no)
.NOTPARALLEL:
else
ifneq ($(_FW_MAKE_PARALLEL), yes)
.NOTPARALLEL:
endif
endif

.SUFFIXES:

.SUFFIXES: .m .mm .c .cc .cpp .xm

$(FW_OBJ_DIR)/%.m.o: %.m
	$(ECHO_COMPILING)$(TARGET_CXX) -x objective-c -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $< -o $@$(ECHO_END)

$(FW_OBJ_DIR)/%.mm.o: %.mm
	$(ECHO_COMPILING)$(TARGET_CXX) -c $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $< -o $@$(ECHO_END)

$(FW_OBJ_DIR)/%.c.o: %.c
	$(ECHO_COMPILING)$(TARGET_CXX) -x c -c $(ALL_CFLAGS) $< -o $@$(ECHO_END)

$(FW_OBJ_DIR)/%.cc.o: %.cc
	$(ECHO_COMPILING)$(TARGET_CXX) -c $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(FW_OBJ_DIR)/%.cpp.o: %.cpp
	$(ECHO_COMPILING)$(TARGET_CXX) -c $(ALL_CFLAGS) $(ALL_CCFLAGS) $< -o $@$(ECHO_END)

$(FW_OBJ_DIR)/%.xm.o: %.xm
	$(ECHO_LOGOS)$(FW_BINDIR)/logos.pl $< > $(FW_OBJ_DIR)/$<.mm$(ECHO_END)
	$(ECHO_COMPILING)$(TARGET_CXX) -c -I"$(shell pwd)" $(ALL_CFLAGS) $(ALL_OBJCFLAGS) $(ALL_CCFLAGS) $(ALL_OBJCCFLAGS) $(FW_OBJ_DIR)/$<.mm -o $@$(ECHO_END)
	$(ECHO_NOTHING)rm $(FW_OBJ_DIR)/$<.mm$(ECHO_END)

%.mm: %.l.mm
	$(FW_BINDIR)/logos.pl $< > $@

%.mm: %.xmm
	$(FW_BINDIR)/logos.pl $< > $@

%.mm: %.xm
	$(FW_BINDIR)/logos.pl $< > $@

%.m: %.xm
	$(FW_BINDIR)/logos.pl $< > $@

ifneq ($(FW_BUILD_DIR),.)
$(FW_BUILD_DIR):
	@mkdir -p $(FW_BUILD_DIR)
endif

$(FW_OBJ_DIR):
	@cd $(FW_BUILD_DIR); mkdir -p $(FW_OBJ_DIR_NAME)

$(FW_OBJ_DIR)/.stamp: $(FW_OBJ_DIR)
	@touch $@

$(FW_OBJ_DIR)/%/.stamp: $(FW_OBJ_DIR)
	@mkdir -p $(dir $@); touch $@

Makefile: ;
framework/makefiles/*.mk: ;
$(FW_MAKEDIR)/*.mk: ;
$(FW_MAKEDIR)/master/*.mk: ;
$(FW_MAKEDIR)/instance/*.mk: ;
$(FW_MAKEDIR)/platform/*.mk: ;

endif

# TODO MAKE A BUNCH OF THINGS PHONY
-include $(foreach mod,$(_FW_MODULES),$(FW_MODDIR)/$(mod)/rules.mk)
