ifeq ($(FW_RULES_LOADED),)
include $(FW_MAKEDIR)/rules.mk
endif

SUBPROJECTS := $(strip $(SUBPROJECTS))
ifneq ($(SUBPROJECTS),)
internal-all internal-stage internal-clean::
	@operation=$(subst internal-,,$@); \
	abs_build_dir=$(ABS_FW_BUILD_DIR); \
	for d in $(SUBPROJECTS); do \
	  echo "Making $$operation in $$d..."; \
	  if [ "$${abs_build_dir}" = "." ]; then \
	    lbuilddir="."; \
	  else \
	    lbuilddir="$${abs_build_dir}/$$d"; \
	  fi; \
	  if $(MAKE) -C $$d $(FW_NO_PRINT_DIRECTORY_FLAG) --no-keep-going $$operation \
		FW_BUILD_DIR="$$lbuilddir" \
	     ; then\
	     :; \
	  else exit $$?; \
	  fi; \
	done;

internal-after-install::
	@operation=$@; \
	abs_build_dir=$(ABS_FW_BUILD_DIR); \
	for d in $(SUBPROJECTS); do \
	  echo "Running post-install rules for $$d..."; \
	  if [ "$${abs_build_dir}" = "." ]; then \
	    lbuilddir="."; \
	  else \
	    lbuilddir="$${abs_build_dir}/$$d"; \
	  fi; \
	  if $(MAKE) -C $$d $(FW_NO_PRINT_DIRECTORY_FLAG) --no-keep-going $$operation \
		FW_BUILD_DIR="$$lbuilddir" \
	     ; then\
	     :; \
	  else exit $$?; \
	  fi; \
	done;
endif
