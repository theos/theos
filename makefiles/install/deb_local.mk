internal-install:: internal-install-check
	$(ECHO_INSTALLING)true$(ECHO_END)
	$(ECHO_NOTHING)install.exec "$(_THEOS_SUDO_COMMAND) dpkg -i \"$(_THEOS_PACKAGE_LAST_FILENAME)\""$(ECHO_END)
