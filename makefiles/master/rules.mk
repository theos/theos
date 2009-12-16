.PHONY: all before-all internal-all after-all \
	clean before-clean internal-clean after-clean

all:: before-all internal-all after-all
clean:: before-clean internal-clean after-clean

before-all::

internal-all::

after-all::

before-clean::

internal-clean::
	-rm -r $(FW_OBJ_DIR)

after-clean::

.PRECIOUS: %.variables

ifeq ($(MAKELEVEL),0)
ifneq ($(FW_BUILD_DIR),.)
ABS_FW_BUILD_DIR = $(shell (cd "$(FW_BUILD_DIR)"; pwd))
else
ABS_FW_BUILD_DIR = .
endif
else
ABS_FW_BUILD_DIR = $(strip $(FW_BUILD_DIR))
endif

%.variables:
	@ \
instance=$(basename $(basename $*)); \
operation=$(subst .,,$(suffix $(basename $*))); \
type=$(subst -,_,$(subst .,,$(suffix $*))); \
absbuilddir=$(ABS_FW_BUILD_DIR); \
echo Making $$operation for $$type $$instance...; \
$(MAKE) --no-print-directory --no-keep-going \
	internal-$${type}-$$operation \
	FW_TYPE=$$type \
	FW_INSTANCE=$$instance \
	FW_OPERATION=$$operation \
	FW_BUILD_DIR=$$absbuilddir
