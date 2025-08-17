internal-install:: internal-install-check
	$(ECHO_INSTALLING)install.exec "$(_THEOS_SUDO_COMMAND) installer -pkg \"$(_THEOS_PACKAGE_LAST_FILENAME)\" -target /"$(ECHO_END)

internal-uninstall::
	$(ECHO_NOTHING)install.exec "pkgutil --files \"$(THEOS_PACKAGE_NAME)\" | tail -r | sed 's/^/\//' | tr '\n' '\0' | $(_THEOS_SUDO_COMMAND) xargs -0 rm -d 2> /dev/null; $(_THEOS_SUDO_COMMAND) pkgutil --forget \"$(THEOS_PACKAGE_NAME)\""$(ECHO_END)
