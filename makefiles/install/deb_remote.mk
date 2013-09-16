internal-install::
	@if [ -z "$(_THEOS_PACKAGE_LAST_FILENAME)" ]; then \
		echo "$(MAKE) install requires that you build a package before you try to install it." >&2; \
		exit 1; \
	fi
	@if [ ! -f "$(_THEOS_PACKAGE_LAST_FILENAME)" ]; then \
		echo "Could not find \"$(_THEOS_PACKAGE_LAST_FILENAME)\" to install. Aborting." >&2; \
		exit 1; \
	fi
	install.exec "cat > /tmp/_theos_install.deb; dpkg -i /tmp/_theos_install.deb && rm /tmp/_theos_install.deb" < "$(_THEOS_PACKAGE_LAST_FILENAME)"
