internal-install:: stage
	install.mergeDir "$(THEOS_STAGING_DIR)" "/"

internal-uninstall::
	@echo "$(MAKE) uninstall is not supported when packaging is disabled" >&2
	@exit 1
