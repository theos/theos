internal-install:: internal-install-check
	$(ECHO_INSTALLING)true$(ECHO_END)
	$(ECHO_NOTHING)install.exec "cat > /tmp/_theos_install.rpm; $(_THEOS_SUDO_COMMAND) rpm -U --replacepkgs --oldpackage /tmp/_theos_install.rpm && rm /tmp/_theos_install.rpm" < "$(_THEOS_PACKAGE_LAST_FILENAME)"$(ECHO_END)
