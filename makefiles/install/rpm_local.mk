internal-install:: internal-install-check
	$(ECHO_INSTALLING)true$(ECHO_END)
	$(ECHO_NOTHING)install.exec "$(_THEOS_SUDO_COMMAND) rpm -U --replacepkgs --oldpackage \"$(_THEOS_PACKAGE_LAST_FILENAME)\""$(ECHO_END)
