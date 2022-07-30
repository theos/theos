# Define a variable containing the newline character. We’ll need it below as $(shell) isn’t able to
# return a string containing newlines - they get replaced with spaces.
define ___newline


endef

# Extract the target arguments out of a colon-separated variable. This is done using a scary bit of
# bash magic because we need to retain empty arguments within TARGET, and $(word) collapses spaces.
# It’s still safe enough, under the assumption that the set of expected values in TARGET are finite
# (e.g. tokens such as iphone, and version identifiers such as 15.0).
#
# How it works:
#  1. Inside a shell, creates an array of input values, by substituting the separator character (:)
#     with quotes that delimit the end of one value and start the next one. It would have been much
#     nicer to use readarray, but this was added in bash 4.1 - macOS continues to ship bash 3.2.57.
#  2. We then loop over the array and printf each value as a Make export statement. This is as good
#     as it gets without proper array support in Make.
#  3. Finally, back on the Make side of things, we substitute the delimiter with a newline, so that
#     our string can be successfully evaluated by Make (see ___newline discussion above).
define ___get_target_args
$(subst ;,$(___newline), \
	$(shell \
		args=('$(subst :,' ',$(1))'); \
		for (( i=0; i<$${#args[@]}; i++ )); do \
			if [[ $${args[$$i]} != '' ]]; then \
				printf 'export __THEOS_TARGET_ARG_%s := %s;' "$$i" "$${args[$$i]}"; \
			fi; \
		done \
	) \
)
endef

# Evaluate and export the TARGET arguments. This expects to be passed multiple variables, which are
# sorted in decreasing precedence:
#  1. The TARGET variable, defined by the project’s own Makefile.
#  2. Any schema overrides of TARGET.
#  3. The platform’s default TARGET.
define __eval_target
$(eval \
	$(call ___get_target_args,$(3)) \
	$(call ___get_target_args,$(2)) \
	$(call ___get_target_args,$(1)) \
)
endef
