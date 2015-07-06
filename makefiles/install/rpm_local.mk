internal-install:: internal-install-check
	install.exec "$(THEOS_SUDO_COMMAND) rpm -U --replacepkgs --oldpackage \"$(_THEOS_PACKAGE_LAST_FILENAME)\""
