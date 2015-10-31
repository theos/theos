internal-install:: internal-install-check
	$(ECHO_INSTALLING)true$(ECHO_END)
	$(ECHO_NOTHING)install.exec "cat > /tmp/_theos_install.deb; $(_THEOS_SUDO_COMMAND) dpkg -i /tmp/_theos_install.deb && rm /tmp/_theos_install.deb" < "$(_THEOS_PACKAGE_LAST_FILENAME)"$(ECHO_END)
