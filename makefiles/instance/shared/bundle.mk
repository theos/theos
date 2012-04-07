# Input Variables
# THEOS_SHARED_BUNDLE_INSTALL_NAME: bundle name and extension
# THEOS_SHARED_BUNDLE_INSTALL_PATH: bundle install path
# THEOS_SHARED_BUNDLE_RESOURCE_PATH: bundle resource path (typically just INSTALL_PATH/INSTALL_NAME)
#
# Instance Variables:
# xxx_RESOURCE_FILES: list of resource files to install (why would you use this in favour of xxx_RESOURCE_DIRS? eh.)
# xxx_RESOURCE_DIRS: folders to copy resources from
# 	note a deviation from gnustep-make's xxx_RESOURCE_DIRS which simply specifies resource subdirectories to create
# 	defaults to Resources/ if it exists.

.PHONY: shared-instance-bundle-stage

_RESOURCE_FILES := $(or $($(THEOS_CURRENT_INSTANCE)_BUNDLE_RESOURCES),$($(THEOS_CURRENT_INSTANCE)_RESOURCE_FILES))
_RESOURCE_DIRS := $(or $($(THEOS_CURRENT_INSTANCE)_BUNDLE_RESOURCE_DIRS),$($(THEOS_CURRENT_INSTANCE)_RESOURCE_DIRS))
ifeq ($(_RESOURCE_DIRS),)
ifeq ($(shell [ -d "Resources" ] && echo 1 || echo 0),1)
_RESOURCE_DIRS := Resources
else
_RESOURCE_DIRS :=
endif
endif

shared-instance-bundle-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)$(_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY)"$(ECHO_END)
ifneq ($(_RESOURCE_FILES),)
	$(ECHO_COPYING_RESOURCE_FILES)for f in $(_RESOURCE_FILES); do \
		if [ -f "$$f" -o -d "$$f" ]; then \
			rsync -a "$$f" "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)$(_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY)/" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE); \
		else \
			echo "Warning: ignoring missing bundle resource $$f."; \
		fi; \
	done$(ECHO_END)
endif
ifneq ($(_RESOURCE_DIRS),)
	$(ECHO_COPYING_RESOURCE_DIRS)for d in $(_RESOURCE_DIRS); do \
		if [ -d "$$d" ]; then \
			rsync -a "$$d/" "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)$(_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY)/" $(_THEOS_RSYNC_EXCLUDE_COMMANDLINE); \
		else \
			echo "Warning: ignoring missing bundle resource directory $$d."; \
		fi; \
	done$(ECHO_END)
endif
ifneq ($(_THEOS_TARGET_BUNDLE_INFO_PLIST_SUBDIRECTORY),$(_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY))
	$(ECHO_NOTHING)if [ -f "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)$(_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY)/Info.plist" ]; then\
		mv "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)$(_THEOS_TARGET_BUNDLE_RESOURCE_SUBDIRECTORY)/Info.plist" "$(THEOS_SHARED_BUNDLE_RESOURCE_PATH)$(_THEOS_TARGET_BUNDLE_INFO_PLIST_SUBDIRECTORY)/Info.plist";\
	fi$(ECHO_END)
endif
