empty :=
space := $(empty) $(empty)

# __cmp function
# 1. If the numbers are the same evaluate to "eq" and stop executaion.  Else:
# 2. Converts numbers to a per-digit space-separated format eg 80 becomes (8 0)
# 3. Tests if either number being compared is longer than one digit.  If so:
#    1. calls ___vercmp_expand_backward to pre-pad any numbers with 0s to make both numbers the same length (1 1 0 cmp 1 becomes 1 1 0 cmp 0 0 1)
#    2. Pre sets comparison result to equal as it will stop comparing as soon as it finds any unequal number
#    3. Calls back to main vercmp if any numbers had multiple digits, otherwise:
#    If not:
#    1. Sorts the two numbers and evaluates to 'lt' if the first number is first, otherwise 'gt'
define __cmp
$(if $(filter $(1),$(2)),eq,$(strip \
 $(eval __CMP_NUM1:=$(subst 0,0 ,$(subst 1,1 ,$(subst 2,2 ,$(subst 3,3 ,$(subst 4,4 ,$(subst 5,5 ,$(subst 6,6 ,$(subst 7,7 ,$(subst 8,8 ,$(subst 9,9 ,$(1)))))))))))) \
 $(eval __CMP_NUM2:=$(subst 0,0 ,$(subst 1,1 ,$(subst 2,2 ,$(subst 3,3 ,$(subst 4,4 ,$(subst 5,5 ,$(subst 6,6 ,$(subst 7,7 ,$(subst 8,8 ,$(subst 9,9 ,$(2)))))))))))) \
 $(if $(filter-out 1,$(words $(__CMP_NUM1)))$(filter-out 1,$(words $(__CMP_NUM2))),$(strip \
   $(call ___vercmp_expand_backward,__CMP_NUM1,$(__CMP_NUM1),$(__CMP_NUM2)) \
   $(call ___vercmp_expand_backward,__CMP_NUM2,$(__CMP_NUM2),$(__CMP_NUM1)) \
   $(eval __CMP_RES:=eq) \
   $(call ___vercmp_presplit,__CMP_NUM1,__CMP_NUM2,__CMP_RES) \
   ),$(if $(filter $(1),$(firstword $(sort $(1) $(2)))),lt,gt) \
  ) \
))
endef

# __vercmp NUMBER OPERATION NUMBER2
# OPERATION is one of: lt, le, eq, ge, gt
#
# 1. Expands the arguments to arrays by splitting on "."
# 2. converts 'le' to 'eq lt' and 'ge' to 'eq gt'
# 3. Pads the ends of the versions with 0s to match length eg: 1 eq 1.0.1 becomes (1 0 0) eq (1 0 1)
# 4. Evaluates to the internal function ___vercmp_presplit that expects the arguments to already have these transformations applied
define __vercmp
$(strip \
$(eval VERCMP_FIRST := $(subst .,$(space),$(1))) \
$(eval VERCMP_OP := $(if $(filter ge,$(2)),eq gt,$(if $(filter le,$(2)),eq lt,$(2)))) \
$(eval VERCMP_SECOND := $(subst .,$(space),$(3))) \
$(eval VERCMP_RES := eq) \
$(call ___vercmp_expand,VERCMP_FIRST,$(VERCMP_FIRST),$(VERCMP_SECOND)) \
$(call ___vercmp_expand,VERCMP_SECOND,$(VERCMP_SECOND),$(VERCMP_FIRST)) \
$(if $(filter $(VERCMP_OP),$(call ___vercmp_presplit,VERCMP_FIRST,VERCMP_SECOND,VERCMP_RES)),1,) \
)
endef

# ___vercmp_presplit TEMP_VERSION_ARRAY_VARIABLE1 TEMP_VERSION_ARRAY_VARIABLE2 TEMP_RESULT_VARIABLE
# 1. Iterates over each word in TEMP_VERSION_ARRAY_VARIABLE1 and, if the current result was eq,
#    1. Extracts the first remaining word from TEMP_VERSION_ARRAY_VARIABLE2 (call it CURRENT_WORD2
#       in this pseudocode) and removes the first word from TEMP_VERSION_ARRAY_VARIABLE2
#    2. Updates the comparison result to be the result of __cmp CURRENT_WORD CURRENT_WORD2
# 2. Evaluates to the value of TEMP_RESULT_VARIABLE
define ___vercmp_presplit
$(strip \
 $(foreach ver1,$(value $(1)),$(if $(filter eq,$(value $(3))), \
  $(eval $(3):=$(call __cmp,$(ver1),$(firstword $(value $(2)))$(eval $(2):=$(wordlist 2,$(words $(value $(2))),$(value $(2)))))) \
 ,)) \
 $(value $(3)) \
)
endef

# ___vercmp_expand WORDLIST1 WORDLIST2
#
# Pads WORDLIST1 with trailing 0 words to be as long as WORDLIST2
#
# 1. Abort if WORDLIST1 already has the same number of words as WORDLIST2
# 2. Abort if WORDLIST1 has fewer words than WORDLIST2
# 3. Add a trailing 0 to WORDLIST1 and call itself again
define ___vercmp_expand
$(if $(filter $(words $(2)),$(words $(3))),, \
$(if $(filter $(words $(3)),$(firstword $(sort $(words $(2)) $(words $(3))))),, \
$(eval $(1) += 0) \
$(call ___vercmp_expand,$(1),$(value $(1)),$(3)) \
) \
)
endef

# ___vercmp_expand_backward WORDLIST1 WORDLIST2
#
# Pads WORDLIST1 with leading 0 words to be as long as WORDLIST2
#
# 1. Abort if WORDLIST1 already has the same number of words as WORDLIST2
# 2. Abort if WORDLIST1 has fewer words than WORDLIST2
# 3. Add a leading 0 to WORDLIST1 and call itself again
define ___vercmp_expand_backward
$(if $(filter $(words $(2)),$(words $(3))),, \
$(if $(filter $(words $(3)),$(firstword $(sort $(words $(2)) $(words $(3))))),, \
$(eval $(1) := 0 $(1)) \
$(call ___vercmp_expand_backward,$(1),$(value $(1)),$(3)) \
) \
)
endef

ifeq (0,1)
# __vercmp test code
$(info 1.8,gt,1.7: $(call __vercmp,1.8,gt,1.7))
$(info 1.7,gt,1.8: $(call __vercmp,1.7,gt,1.8))
$(info 1.8,eq,1.8: $(call __vercmp,1.8,eq,1.8))
$(info 1.8,eq,1.7: $(call __vercmp,1.8,eq,1.7))
$(info 1.8,lt,1.9: $(call __vercmp,1.8,lt,1.9))
$(info 1.8,lt,1.10: $(call __vercmp,1.8,lt,1.10))
$(info 5.0,ge,5.0.1: $(call __vercmp,5.0,ge,5.0.1))
$(info 5.0.1,ge,5.0: $(call __vercmp,5.0.1,ge,5.0))
$(info 5.0,ge,5.0: $(call __vercmp,5.0.1,ge,5.0))
$(info 5.0,le,5.0.1: $(call __vercmp,5.0,le,5.0.1))
$(info 5.0,le,5.0: $(call __vercmp,5.0,le,5.0))
$(info 5.0,le,4.9: $(call __vercmp,5.0.1,le,4.9))
endif
