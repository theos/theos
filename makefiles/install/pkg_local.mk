internal-install::
	$(ECHO_INSTALLING)true$(ECHO_END)
	@if [ -z "$(_THEOS_PACKAGE_LAST_FILENAME)" ]; then \
		echo "$(MAKE) install requires that you build a package before you try to install it." >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(_THEOS_PACKAGE_LAST_FILENAME)" ]; then \
		echo "Could not find \"$(_THEOS_PACKAGE_LAST_FILENAME)\" to install. Aborting." >&2; \
		exit 1; \
	fi
	$(ECHO_NOTHING)install.exec "$(THEOS_SUDO_COMMAND) sudo installer -pkg \"$(_THEOS_PACKAGE_LAST_FILENAME)\" -target /"$(ECHO_END)

internal-uninstall::
	$(ECHO_NOTHING)install.exec "pkgutil --files \"$(THEOS_PACKAGE_NAME)\" | tail -r | sed 's/^/\//' | sudo xargs rm -d; $(THEOS_SUDO_COMMAND) pkgutil --forget \"$(THEOS_PACKAGE_NAME)\""$(ECHO_END)
