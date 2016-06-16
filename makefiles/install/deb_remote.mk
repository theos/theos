internal-install:: internal-install-check
	$(ECHO_INSTALLING)install.exec "cat > /tmp/_theos_install.deb; $(THEOS_SUDO_COMMAND) dpkg -i /tmp/_theos_install.deb && rm /tmp/_theos_install.deb" < "$(_THEOS_PACKAGE_LAST_FILENAME)"$(ECHO_END)

internal-uninstall::
	$(ECHO_NOTHING)install.exec "$(THEOS_SUDO_COMMAND) dpkg -r \"$(THEOS_PACKAGE_NAME)\""$(ECHO_END)
