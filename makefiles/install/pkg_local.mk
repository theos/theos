internal-install:: internal-install-check
	$(ECHO_INSTALLING)$(SHELL) install.exec "$(_THEOS_SUDO_COMMAND) installer -pkg \"$(_THEOS_PACKAGE_LAST_FILENAME)\" -target /"$(ECHO_END)

internal-uninstall::
	$(ECHO_NOTHING)$(SHELL) install.exec "pkgutil --files \"$(THEOS_PACKAGE_NAME)\" | tail -r | sed 's/^/\//' | sudo xargs rm -d; $(_THEOS_SUDO_COMMAND) pkgutil --forget \"$(THEOS_PACKAGE_NAME)\""$(ECHO_END)
