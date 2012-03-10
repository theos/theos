ifeq ($(_THEOS_STAGING_RULES_LOADED),)
_THEOS_STAGING_RULES_LOADED := 1

.PHONY: stage before-stage internal-stage after-stage

stage:: all before-stage internal-stage after-stage

before-stage::
	$(ECHO_NOTHING)rm -rf "$(THEOS_STAGING_DIR)"$(ECHO_END)
	$(ECHO_NOTHING)$(FAKEROOT) -c$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)"$(ECHO_END)

internal-stage::
	$(ECHO_NOTHING)[ -d layout ] && rsync -a "layout/" "$(THEOS_STAGING_DIR)" --exclude "DEBIAN" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE) || true$(ECHO_END)

after-stage::

endif # _THEOS_STAGING_RULES_LOADED
