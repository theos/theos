__THEOS_RULES_MK_VERSION := 1k
ifneq ($(__THEOS_RULES_MK_VERSION),$(__THEOS_COMMON_MK_VERSION))
all::
	@echo "Theos version mismatch! common.mk [version $(or $(__THEOS_COMMON_MK_VERSION),0)] loaded in tandem with rules.mk [version $(or $(__THEOS_RULES_MK_VERSION),0)] Check that \$$\(THEOS\) is set properly!" >&2
	@exit 1
endif

.PHONY: all before-all internal-all after-all \
	clean before-clean internal-clean after-clean update-theos
ifeq ($(THEOS_BUILD_DIR),.)
all:: $(_THEOS_BUILD_SESSION_FILE) before-all internal-all after-all
else
all:: $(THEOS_BUILD_DIR) $(_THEOS_BUILD_SESSION_FILE) before-all internal-all after-all
endif

clean:: before-clean internal-clean after-clean

do:: all package install

before-all::
ifneq ($(SYSROOT),)
	@if [[ ! -d "$(SYSROOT)" ]]; then \
		$(PRINT_FORMAT_ERROR) "Your current SYSROOT, “$(SYSROOT)”, appears to be missing." >&2; \
		exit 1; \
	fi
endif
	@if [[ ! -f "$(THEOS_VENDOR_INCLUDE_PATH)/.git" || ! -f "$(THEOS_VENDOR_LIBRARY_PATH)/.git" ]]; then \
		$(PRINT_FORMAT_ERROR) "The vendor/include and/or vendor/lib directories are missing. Please run \`git submodule update --init --recursive\` in your Theos directory. More information: https://github.com/theos/theos/wiki/Installation." >&2; \
		exit 1; \
	fi
	@if [[ -d "$(THEOS_LEGACY_PACKAGE_DIR)" && ! -d "$(THEOS_PACKAGE_DIR)" ]]; then \
		$(PRINT_FORMAT) "The \"debs\" directory has been renamed to \"packages\". Moving it." >&2; \
		mv "$(THEOS_LEGACY_PACKAGE_DIR)" "$(THEOS_PACKAGE_DIR)" || exit 1; \
	fi

internal-all::

after-all::

before-clean::

internal-clean::
	$(ECHO_CLEANING)rm -rf "$(subst $(_THEOS_OBJ_DIR_EXTENSION),,$(THEOS_OBJ_DIR))"$(ECHO_END)

ifeq ($(shell [[ -f "$(_THEOS_BUILD_SESSION_FILE)" ]] && echo 1),1)
	$(ECHO_NOTHING)rm "$(_THEOS_BUILD_SESSION_FILE)"$(ECHO_END)
	$(ECHO_NOTHING)touch "$(_THEOS_BUILD_SESSION_FILE)"$(ECHO_END)
endif

ifeq ($(MAKELEVEL),0)
	$(ECHO_NOTHING)rm -rf "$(THEOS_STAGING_DIR)"$(ECHO_END)
endif

after-clean::

ifeq ($(MAKELEVEL),0)
ifneq ($(THEOS_BUILD_DIR),.)
_THEOS_ABSOLUTE_BUILD_DIR = $(call __clean_pwd,$(THEOS_BUILD_DIR))
else
_THEOS_ABSOLUTE_BUILD_DIR = .
endif
else
_THEOS_ABSOLUTE_BUILD_DIR = $(strip $(THEOS_BUILD_DIR))
endif

clean-packages:: before-clean-packages internal-clean-packages after-clean-packages

before-clean-packages::

internal-clean-packages::
	$(ECHO_NOTHING)rm -rf $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_*-*_$(THEOS_PACKAGE_ARCH).deb$(ECHO_END)
	$(ECHO_NOTHING)rm -rf $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)-*-*.$(THEOS_PACKAGE_ARCH).rpm$(ECHO_END)

after-clean-packages::

$(_THEOS_BUILD_SESSION_FILE):
	@mkdir -p $(_THEOS_LOCAL_DATA_DIR)

ifeq ($(shell [[ -f "$(_THEOS_BUILD_SESSION_FILE)" ]] || echo 0),0)
	@touch $(_THEOS_BUILD_SESSION_FILE)
endif

.PRECIOUS: %.variables %.subprojects

%.variables: _INSTANCE = $(basename $(basename $*))
%.variables: _OPERATION = $(subst .,,$(suffix $(basename $*)))
%.variables: _TYPE = $(subst -,_,$(subst .,,$(suffix $*)))
%.variables: __SUBPROJECTS = $(strip $(call __schema_var_all,$(_INSTANCE)_,SUBPROJECTS))
%.variables:
	@ \
abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
if [[ "$(__SUBPROJECTS)" != "" ]]; then \
  $(PRINT_FORMAT_MAKING) "Making $(_OPERATION) in subprojects of $(_TYPE) $(_INSTANCE)"; \
  for d in $(__SUBPROJECTS); do \
    d="$${d%:*}"; \
    if [[ "$${abs_build_dir}" = "." ]]; then \
      lbuilddir="."; \
    else \
      lbuilddir="$${abs_build_dir}/$$d"; \
    fi; \
    if $(MAKE) -C $$d -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_NO_PRINT_DIRECTORY_FLAG) --no-keep-going $(_OPERATION) \
        THEOS_BUILD_DIR="$$lbuilddir" \
       ; then\
       :; \
    else exit $$?; \
    fi; \
  done; \
 fi; \
$(PRINT_FORMAT_MAKING) "Making $(_OPERATION) for $(_TYPE) $(_INSTANCE)"; \
$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going \
	internal-$(_TYPE)-$(_OPERATION) \
	_THEOS_CURRENT_TYPE="$(_TYPE)" \
	THEOS_CURRENT_INSTANCE="$(_INSTANCE)" \
	_THEOS_CURRENT_OPERATION="$(_OPERATION)" \
	THEOS_BUILD_DIR="$(_THEOS_ABSOLUTE_BUILD_DIR)"

%.subprojects: _INSTANCE = $(basename $(basename $*))
%.subprojects: _OPERATION = $(subst .,,$(suffix $(basename $*)))
%.subprojects: _TYPE = $(subst -,_,$(subst .,,$(suffix $*)))
%.subprojects: __SUBPROJECTS = $(strip $(call __schema_var_all,$(_INSTANCE)_,SUBPROJECTS))
%.subprojects:
	@ \
abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
if [[ "$(__SUBPROJECTS)" != "" ]]; then \
  $(PRINT_FORMAT_MAKING) "Making $(_OPERATION) in subprojects of $(_TYPE) $(_INSTANCE)"; \
  for d in $(__SUBPROJECTS); do \
    d="$${d%:*}"; \
    if [[ "$${abs_build_dir}" = "." ]]; then \
      lbuilddir="."; \
    else \
      lbuilddir="$${abs_build_dir}/$$d"; \
    fi; \
    if $(MAKE) -C $$d -f $(_THEOS_PROJECT_MAKEFILE_NAME) $(_THEOS_NO_PRINT_DIRECTORY_FLAG) --no-keep-going $(_OPERATION) \
        THEOS_BUILD_DIR="$$lbuilddir" \
       ; then\
       :; \
    else exit $$?; \
    fi; \
  done; \
 fi

update-theos::
	@if [[ ! -d "$(THEOS)/.git" ]]; then \
		$(PRINT_FORMAT_ERROR) "$(THEOS) is not a Git repository. For more information, refer to https://github.com/theos/theos/wiki/Installation#updating." >&2; \
		exit 1; \
	fi

	$(ECHO_NOTHING)$(PRINT_FORMAT_MAKING) "Updating Theos"; \
		cd $(THEOS) && \
		$(THEOS_BIN_PATH)/update-git-repo$(ECHO_END)

	$(ECHO_NOTHING)$(PRINT_FORMAT_MAKING) "Updating submodules"; \
		cd $(THEOS) && \
		git config submodule.fetchJobs 4 && \
		git submodule init && \
		git submodule foreach --recursive $(THEOS_BIN_PATH)/update-git-repo$(ECHO_END)

	$(ECHO_NOTHING)$(PRINT_FORMAT_MAKING) "Running post-update configuration"; \
		cd $(THEOS) && \
		$(THEOS_BIN_PATH)/post-update$(ECHO_END)

troubleshoot::
	@$(PRINT_FORMAT) "Be sure to check the troubleshooting page at https://github.com/theos/theos/wiki/Troubleshooting first."
	@$(PRINT_FORMAT) "For support with build errors, ask on IRC: http://iphonedevwiki.net/index.php/IRC. If you think you've found a bug in Theos, check the issue tracker at https://github.com/theos/theos/issues."
	@echo

ifeq ($(call __executable,ghost),$(_THEOS_TRUE))
	@$(PRINT_FORMAT) "Creating a Ghostbin containing the output of \`make clean all messages=yes\`…"
	$(MAKE) -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-print-directory --no-keep-going clean all messages=yes FORCE_COLOR=yes 2>&1 | ghost -x 2w - ansi
else
	@$(PRINT_FORMAT_ERROR) "You don't have ghost installed. For more information, refer to https://github.com/theos/theos/wiki/Installation#prerequisites." >&2; exit 1
endif

$(eval $(call __mod,master/rules.mk))

ifeq ($(_THEOS_TOP_INVOCATION_DONE),)
export _THEOS_TOP_INVOCATION_DONE = 1
endif
