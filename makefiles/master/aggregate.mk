ifeq ($(_THEOS_RULES_LOADED),$(_THEOS_FALSE))
include $(THEOS_MAKE_PATH)/rules.mk
endif

SUBPROJECTS := $(strip $(call __schema_var_all,,SUBPROJECTS))
ifneq ($(SUBPROJECTS),)
internal-all internal-clean:: _OPERATION = $(subst internal-,,$@)
internal-stage internal-after-install internal-after-uninstall:: _OPERATION = $@
internal-all internal-clean internal-stage internal-after-install internal-after-uninstall:: _OPERATION_NAME = $(subst internal-,,$@)

internal-all internal-clean internal-stage internal-after-install internal-after-uninstall::
ifeq ($(OS),Windows_NT)
	+@$(_THEOS_SUBPROJECTS) --make "$(MAKE)" --makefile "$(_THEOS_PROJECT_MAKEFILE_NAME)" --operation "$(_OPERATION)" --build-dir "$(_THEOS_ABSOLUTE_BUILD_DIR)" --cwd "$(THEOS_PROJECT_DIR)" --no-keep-going --subprojects $(SUBPROJECTS)
else
	+@abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
	for d in $(SUBPROJECTS); do \
	  $(PRINT_FORMAT_MAKING) "Making $(_OPERATION_NAME) in $$d"; \
	  if [[ "$${abs_build_dir}" = "." ]]; then \
	    lbuilddir="."; \
	  else \
	    lbuilddir="$${abs_build_dir}/$$d"; \
	  fi; \
		if $(MAKE) -C $$d -f $(_THEOS_PROJECT_MAKEFILE_NAME) --no-keep-going $(_OPERATION) \
		THEOS_BUILD_DIR="$$lbuilddir" \
	     ; then\
	     :; \
	  else exit $$?; \
	  fi; \
	done;
endif
endif

$(eval $(call __mod,master/aggregate.mk))
