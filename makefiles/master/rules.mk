.PHONY: all before-all internal-all after-all \
	clean before-clean internal-clean after-clean
ifeq ($(THEOS_BUILD_DIR),.)
all:: before-all internal-all after-all
else
all:: $(THEOS_BUILD_DIR) before-all internal-all after-all
endif

clean:: before-clean internal-clean after-clean

before-all::
ifneq ($(SYSROOT),)
	@[ -d "$(SYSROOT)" ] || { echo "Your current SYSROOT, \"$(SYSROOT)\", appears to be missing."; exit 1; }
endif

internal-all::

after-all::

before-clean::

internal-clean::
	rm -rf $(THEOS_OBJ_DIR)
ifeq ($(MAKELEVEL),0)
	rm -rf "$(THEOS_STAGING_DIR)"
endif

after-clean::

include $(THEOS_MAKE_PATH)/stage.mk
include $(THEOS_MAKE_PATH)/package.mk

ifeq ($(MAKELEVEL),0)
ifneq ($(THEOS_BUILD_DIR),.)
_THEOS_ABSOLUTE_BUILD_DIR = $(shell (unset CDPATH; cd "$(THEOS_BUILD_DIR)"; pwd))
else
_THEOS_ABSOLUTE_BUILD_DIR = .
endif
else
_THEOS_ABSOLUTE_BUILD_DIR = $(strip $(THEOS_BUILD_DIR))
endif

.PRECIOUS: %.variables %.subprojects

%.variables:
	@ \
instance=$(basename $(basename $*)); \
operation=$(subst .,,$(suffix $(basename $*))); \
type=$(subst -,_,$(subst .,,$(suffix $*))); \
abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
if [ "$($(basename $(basename $*))_SUBPROJECTS)" != "" ]; then \
  echo Making $$operation in subprojects of $$type $$instance...; \
  for d in $($(basename $(basename $*))_SUBPROJECTS); do \
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
  done; \
 fi; \
echo Making $$operation for $$type $$instance...; \
$(MAKE) --no-print-directory --no-keep-going \
	internal-$${type}-$$operation \
	_THEOS_CURRENT_TYPE=$$type \
	THEOS_CURRENT_INSTANCE=$$instance \
	_THEOS_CURRENT_OPERATION=$$operation \
	THEOS_BUILD_DIR=$$abs_build_dir

%.subprojects:
	@ \
instance=$(basename $(basename $*)); \
operation=$(subst .,,$(suffix $(basename $*))); \
type=$(subst -,_,$(subst .,,$(suffix $*))); \
abs_build_dir=$(_THEOS_ABSOLUTE_BUILD_DIR); \
if [ "$($(basename $(basename $*))_SUBPROJECTS)" != "" ]; then \
  echo Making $$operation in subprojects of $$type $$instance...; \
  for d in $($(basename $(basename $*))_SUBPROJECTS); do \
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
  done; \
 fi

$(eval $(call __mod,master/rules.mk))

ifeq ($(_THEOS_TOP_INVOCATION_DONE),)
export _THEOS_TOP_INVOCATION_DONE = 1
endif
