__THEOS_RULES_MK_VERSION := 1r
ifneq ($(__THEOS_RULES_MK_VERSION),$(__THEOS_COMMON_MK_VERSION))
all::
	@echo Theos version mismatch! common.mk [version $(or $(__THEOS_COMMON_MK_VERSION),0)] loaded in tandem with rules.mk [version $(or $(__THEOS_RULES_MK_VERSION),0)] Check that \$$\(THEOS\) is set properly!
	@exit 1
endif

.PHONY: all before-all internal-all after-all \
	clean before-clean internal-clean after-clean update-theos
ifeq ($(THEOS_BUILD_DIR),.)
all:: before-all internal-all after-all
else
all:: $(THEOS_BUILD_DIR) before-all internal-all after-all
endif

clean:: before-clean internal-clean after-clean

do:: package install
	respring

before-all::
ifneq ($(SYSROOT),)
	@[ -d "$(SYSROOT)" ] || { echo "Your current SYSROOT, \"$(SYSROOT)\", appears to be missing."; exit 1; }
endif

internal-all::

after-all::

before-clean::

internal-clean::
ifeq ($(MAKELEVEL),0)
	$(ECHO_CLEANING)rm -rf $(THEOS_OBJ_DIR)$(ECHO_END)
	$(ECHO_NOTHING)rm -rf "$(THEOS_STAGING_DIR)"$(ECHO_END)
	$(ECHO_NOTHING)rm -rf $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_*-*_$(THEOS_PACKAGE_ARCH).deb$(ECHO_END)
	$(ECHO_NOTHING)rm -rf $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)-*-*.$(THEOS_PACKAGE_ARCH).rpm$(ECHO_END)
else
	$(ECHO_NOTHING)rm -rf $(THEOS_OBJ_DIR)$(ECHO_END)
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

.PRECIOUS: %.variables %.subprojects

%.variables: _INSTANCE = $(basename $(basename $*))
%.variables: _OPERATION = $(subst .,,$(suffix $(basename $*)))
%.variables: _TYPE = $(subst -,_,$(subst .,,$(suffix $*)))
%.variables: __SUBPROJECTS = $(strip $(call __schema_var_all,$(_INSTANCE)_,SUBPROJECTS))
%.variables:
	@ \
abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
if [ "$(__SUBPROJECTS)" != "" ]; then \
  echo Making $(_OPERATION) in subprojects of $(_TYPE) $(_INSTANCE)...; \
  for d in $(__SUBPROJECTS); do \
    d="$${d%:*}"; \
    if [ "$${abs_build_dir}" = "." ]; then \
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
echo Making $(_OPERATION) for $(_TYPE) $(_INSTANCE)...; \
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
if [ "$(__SUBPROJECTS)" != "" ]; then \
  echo Making $(_OPERATION) in subprojects of $(_TYPE) $(_INSTANCE)...; \
  for d in $(__SUBPROJECTS); do \
    d="$${d%:*}"; \
    if [ "$${abs_build_dir}" = "." ]; then \
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
	@cd $(THEOS) && git pull origin master && ./git-submodule-recur.sh init

$(eval $(call __mod,master/rules.mk))

ifeq ($(_THEOS_TOP_INVOCATION_DONE),)
export _THEOS_TOP_INVOCATION_DONE = 1
endif
