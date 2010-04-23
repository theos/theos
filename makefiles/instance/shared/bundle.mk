# Input Variables
# FW_SHARED_BUNDLE_INSTALL_NAME: bundle name and extension
# FW_SHARED_BUNDLE_INSTALL_PATH: bundle install path
# FW_SHARED_BUNDLE_RESOURCE_PATH: bundle resource path (typically just INSTALL_PATH/INSTALL_NAME)
#
# Instance Variables:
# xxx_RESOURCE_FILES: list of resource files to install (why would you use this in favour of xxx_RESOURCE_DIRS? eh.)
# xxx_RESOURCE_DIRS: folders to copy resources from
# 	note a deviation from gnustep-make's xxx_RESOURCE_DIRS which simply specifies resource subdirectories to create
# 	defaults to Resources/ if it exists.

.PHONY: shared-instance-bundle-stage

RESOURCE_FILES := $($(FW_INSTANCE)_RESOURCE_FILES)
RESOURCE_DIRS := $($(FW_INSTANCE)_RESOURCE_DIRS)
ifeq ($(RESOURCE_DIRS),)
ifeq ($(shell [ -d "Resources" ] && echo 1 || echo 0),1)
RESOURCE_DIRS := Resources
else
RESOURCE_DIRS :=
endif
endif

shared-instance-bundle-stage::
	$(ECHO_NOTHING)mkdir -p $(FW_SHARED_BUNDLE_RESOURCE_PATH)$(ECHO_END)
ifneq ($(RESOURCE_FILES),)
	$(ECHO_COPYING_RESOURCE_FILES)for f in $(RESOURCE_FILES); do \
		if [ -f "$$f" -o -d "$$f" ]; then \
			rsync -a "$$f" "$(FW_SHARED_BUNDLE_RESOURCE_PATH)/" $(FW_RSYNC_EXCLUDES); \
		else \
			echo "Warning: ignoring missing bundle resource $$f."; \
		fi; \
	done$(ECHO_END)
endif
ifneq ($(RESOURCE_DIRS),)
	$(ECHO_COPYING_RESOURCE_DIRS)for d in $(RESOURCE_DIRS); do \
		if [ -d "$$d" ]; then \
			rsync -a "$$d/" "$(FW_SHARED_BUNDLE_RESOURCE_PATH)/" $(FW_RSYNC_EXCLUDES); \
		else \
			echo "Warning: ignoring missing bundle resource directory $$d."; \
		fi; \
	done$(ECHO_END)
endif
