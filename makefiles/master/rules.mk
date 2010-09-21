.PHONY: all before-all internal-all after-all \
	clean before-clean internal-clean after-clean
ifeq ($(FW_BUILD_DIR),.)
all:: before-all internal-all after-all
else
all:: $(FW_BUILD_DIR) before-all internal-all after-all
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
	rm -rf $(FW_OBJ_DIR)
ifeq ($(MAKELEVEL),0)
	rm -rf "$(FW_STAGING_DIR)"
endif

after-clean::

include $(FW_MAKEDIR)/package.mk

ifeq ($(MAKELEVEL),0)
ifneq ($(FW_BUILD_DIR),.)
ABS_FW_BUILD_DIR = $(shell (unset CDPATH; cd "$(FW_BUILD_DIR)"; pwd))
else
ABS_FW_BUILD_DIR = .
endif
else
ABS_FW_BUILD_DIR = $(strip $(FW_BUILD_DIR))
endif

ifeq ($(_FW_TOP_INVOCATION_DONE),)
export _FW_TOP_INVOCATION_DONE = 1
endif

.PRECIOUS: %.variables %.subprojects

%.variables:
	@ \
instance=$(basename $(basename $*)); \
operation=$(subst .,,$(suffix $(basename $*))); \
type=$(subst -,_,$(subst .,,$(suffix $*))); \
abs_build_dir=$(ABS_FW_BUILD_DIR); \
if [ "$($(basename $(basename $*))_SUBPROJECTS)" != "" ]; then \
  echo Making $$operation in subprojects of $$type $$instance...; \
  for d in $($(basename $(basename $*))_SUBPROJECTS); do \
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
  done; \
 fi; \
echo Making $$operation for $$type $$instance...; \
$(MAKE) --no-print-directory --no-keep-going \
	internal-$${type}-$$operation \
	FW_TYPE=$$type \
	FW_INSTANCE=$$instance \
	FW_OPERATION=$$operation \
	FW_BUILD_DIR=$$abs_build_dir

%.subprojects:
	@ \
instance=$(basename $(basename $*)); \
operation=$(subst .,,$(suffix $(basename $*))); \
type=$(subst -,_,$(subst .,,$(suffix $*))); \
abs_build_dir=$(ABS_FW_BUILD_DIR); \
if [ "$($(basename $(basename $*))_SUBPROJECTS)" != "" ]; then \
  echo Making $$operation in subprojects of $$type $$instance...; \
  for d in $($(basename $(basename $*))_SUBPROJECTS); do \
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
  done; \
 fi
