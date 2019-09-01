internal-install:: stage
	$(ECHO_INSTALLING)install.mergeDir "$(THEOS_STAGING_DIR)" "/"$(ECHO_END)

internal-uninstall::
	@$(PRINT_FORMAT_ERROR) "$(MAKE) uninstall is not supported when packaging is disabled" >&2; exit 1
