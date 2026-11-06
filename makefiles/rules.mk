ifeq ($(_THEOS_RULES_LOADED),$(_THEOS_FALSE))
_THEOS_RULES_LOADED := 1

ifeq ($(THEOS_CURRENT_INSTANCE),)
	include $(THEOS_MAKE_PATH)/master/rules.mk
else
	include $(THEOS_MAKE_PATH)/instance/rules.mk
endif

ifeq ($(_THEOS_MAKE_PARALLEL_BUILDING), no)
.NOTPARALLEL:
else ifneq ($(_THEOS_MAKE_PARALLEL), yes)
.NOTPARALLEL:
endif

ifeq ($(THEOS_PLATFORM_NAME),windows)
%.mm: %.l.mm
	$(_THEOS_LOGOS_CMD) --script "$(THEOS_BIN_PATH)/logos.pl" --output "$@" $(ALL_LOGOSFLAGS) "$<"

%.mm: %.xmm
	$(_THEOS_LOGOS_CMD) --script "$(THEOS_BIN_PATH)/logos.pl" --output "$@" $(ALL_LOGOSFLAGS) "$<"

%.mm: %.xm
	$(_THEOS_LOGOS_CMD) --script "$(THEOS_BIN_PATH)/logos.pl" --output "$@" $(ALL_LOGOSFLAGS) "$<"

%.m: %.xm
	$(_THEOS_LOGOS_CMD) --script "$(THEOS_BIN_PATH)/logos.pl" --output "$@" $(ALL_LOGOSFLAGS) "$<"
else
%.mm: %.l.mm
	$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@

%.mm: %.xmm
	$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@

%.mm: %.xm
	$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@

%.m: %.xm
	$(THEOS_BIN_PATH)/logos.pl $(ALL_LOGOSFLAGS) $< > $@
endif

ifeq ($(THEOS_PLATFORM_NAME),windows)
_THEOS_MKDIR_CMD = $(_THEOS_MKDIR)
_THEOS_RM_CMD = $(_THEOS_RM)
_THEOS_CP_CMD = $(_THEOS_CP)
_THEOS_MV_CMD = $(_THEOS_MV)
_THEOS_TOUCH_CMD = $(_THEOS_TOUCH)
else
_THEOS_MKDIR_CMD = mkdir -p
_THEOS_RM_CMD = rm
_THEOS_CP_CMD = cp
_THEOS_MV_CMD = mv
_THEOS_TOUCH_CMD = touch
endif

ifneq ($(THEOS_BUILD_DIR),.)
$(THEOS_BUILD_DIR):
	@$(_THEOS_MKDIR_CMD) $(THEOS_BUILD_DIR)
endif

$(THEOS_OBJ_DIR):
	@$(_THEOS_MKDIR_CMD) $@

$(THEOS_OBJ_DIR)/.stamp: $(THEOS_OBJ_DIR)
ifeq ($(THEOS_PLATFORM_NAME),windows)
	@$(_THEOS_MKDIR_CMD) $(dir $@) && $(_THEOS_TOUCH_CMD) $@
else
	@$(_THEOS_MKDIR_CMD) $(dir $@); $(_THEOS_TOUCH_CMD) $@
endif

$(THEOS_OBJ_DIR)/%/.stamp: $(THEOS_OBJ_DIR)
ifeq ($(THEOS_PLATFORM_NAME),windows)
	@$(_THEOS_MKDIR_CMD) $(dir $@) && $(_THEOS_TOUCH_CMD) $@
else
	@$(_THEOS_MKDIR_CMD) $(dir $@); $(_THEOS_TOUCH_CMD) $@
endif

Makefile: ;
$(_THEOS_RELATIVE_MAKE_PATH)%.mk: ;
$(THEOS_MAKE_PATH)/%.mk: ;
$(THEOS_MAKE_PATH)/master/%.mk: ;
$(THEOS_MAKE_PATH)/instance/%.mk: ;
$(THEOS_MAKE_PATH)/instance/shared/%.mk: ;
$(THEOS_MAKE_PATH)/platform/%.mk: ;
$(THEOS_MAKE_PATH)/targets/%.mk: ;
$(THEOS_MAKE_PATH)/targets/%/%.mk: ;

ifneq ($(THEOS_PACKAGE_DIR_NAME),)
$(THEOS_PACKAGE_DIR):
	@$(_THEOS_MKDIR_CMD) "$(THEOS_PACKAGE_DIR)"
endif

endif

# TODO MAKE A BUNCH OF THINGS PHONY
$(eval $(call __mod,rules.mk))
