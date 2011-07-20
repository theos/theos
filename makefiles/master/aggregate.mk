ifeq ($(_THEOS_RULES_LOADED),)
include $(THEOS_MAKE_PATH)/rules.mk
endif

SUBPROJECTS := $(strip $(SUBPROJECTS))
ifneq ($(SUBPROJECTS),)
internal-all internal-stage internal-clean::
	@operation=$(subst internal-,,$@); \
	abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
	for d in $(SUBPROJECTS); do \
	  echo "Making $$operation in $$d..."; \
	  if [ "$${abs_build_dir}" = "." ]; then \
	    lbuilddir="."; \
	  else \
	    lbuilddir="$${abs_build_dir}/$$d"; \
	  fi; \
	  if $(MAKE) -C $$d $(_THEOS_NO_PRINT_DIRECTORY_FLAG) --no-keep-going $$operation \
		THEOS_BUILD_DIR="$$lbuilddir" \
	     ; then\
	     :; \
	  else exit $$?; \
	  fi; \
	done;

internal-after-install::
	@operation=$@; \
	abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
	for d in $(SUBPROJECTS); do \
	  echo "Running post-install rules for $$d..."; \
	  if [ "$${abs_build_dir}" = "." ]; then \
	    lbuilddir="."; \
	  else \
	    lbuilddir="$${abs_build_dir}/$$d"; \
	  fi; \
	  if $(MAKE) -C $$d $(_THEOS_NO_PRINT_DIRECTORY_FLAG) --no-keep-going $$operation \
		THEOS_BUILD_DIR="$$lbuilddir" \
	     ; then\
	     :; \
	  else exit $$?; \
	  fi; \
	done;
endif

$(eval $(call __mod,master/aggregate.mk))
