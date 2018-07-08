internal-install:: internal-install-check
	$(ECHO_INSTALLING)cat > /tmp/_theos_install.ipa; appinst /tmp/_theos_install.ipa && rm /tmp/_theos_install.ipa < $(_THEOS_PACKAGE_LAST_FILENAME)$(ECHO_END)

internal-uninstall::
	$(ECHO_NOTHING)echo "$(THEOS_PACKAGE_NAME)"$(ECHO_END)
