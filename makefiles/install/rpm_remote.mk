internal-install:: internal-install-check
	install.exec "cat > /tmp/_theos_install.rpm; $(THEOS_SUDO_COMMAND) rpm -U --replacepkgs --oldpackage /tmp/_theos_install.rpm && rm /tmp/_theos_install.rpm" < "$(_THEOS_PACKAGE_LAST_FILENAME)"
