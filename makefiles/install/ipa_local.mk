internal-install:: internal-install-check
	$(ECHO_INSTALLING)appinst "$(_THEOS_PACKAGE_LAST_FILENAME)" &> /dev/null$(ECHO_END)

internal-uninstall::
	$(ECHO_NOTHING)echo "$(THEOS_PACKAGE_NAME)"$(ECHO_END)
