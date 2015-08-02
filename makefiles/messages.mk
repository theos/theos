NULLSTRING :=
ECHO_PIPEFAIL := set -o pipefail;

ifneq ($(call __theos_bool,$(or $(messages),$(MESSAGES))),$(_THEOS_TRUE))
	ifeq ($(call __executable,unbuffer),$(_THEOS_TRUE))
		ECHO_UNBUFFERED = unbuffer $(NULLSTRING)
		ECHO_END = ) 2>&1 | sed "s/^/  /" )
	else
		ECHO_UNBUFFERED = 
		ECHO_END = ) )
	endif

ifneq ($(THEOS_CURRENT_ARCH),)
	ECHO_COMPILING = @(echo "Compiling $< ($(THEOS_CURRENT_ARCH))..."; $(ECHO_PIPEFAIL) (
	ECHO_LINKING = @(echo "Linking $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE) ($(THEOS_CURRENT_ARCH))..."; $(ECHO_PIPEFAIL) (
	ECHO_LINKING_WITH_STRIP = @(echo "Linking $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE) (with strip, $(THEOS_CURRENT_ARCH))..."; $(ECHO_PIPEFAIL) (
	ECHO_STRIPPING = @(echo "Stripping $(THEOS_CURRENT_INSTANCE) ($(THEOS_CURRENT_ARCH))..."; $(ECHO_PIPEFAIL) (
else
	ECHO_COMPILING = @(echo "Compiling $<..."; $(ECHO_PIPEFAIL) (
	ECHO_LINKING = @(echo "Linking $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE)..."; $(ECHO_PIPEFAIL) (
	ECHO_LINKING_WITH_STRIP = @(echo "Linking $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE) (with strip)..."; $(ECHO_PIPEFAIL) (
	ECHO_STRIPPING = @(echo "Stripping $(THEOS_CURRENT_INSTANCE)..."; $(ECHO_PIPEFAIL) (
endif
	ECHO_MERGING = @(echo "Merging $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE)..."; $(ECHO_PIPEFAIL) (
	ECHO_SIGNING = @(echo "Signing $(THEOS_CURRENT_INSTANCE)...";$(ECHO_PIPEFAIL)(
	ECHO_PREPROCESSING = @(echo "Preprocessing $<...";$(ECHO_PIPEFAIL)(
	ECHO_COPYING_RESOURCE_FILES = @(echo "Copying resource files into the $(_THEOS_CURRENT_TYPE) wrapper...";$(ECHO_PIPEFAIL) (
	ECHO_COPYING_RESOURCE_DIRS = @(echo "Copying resource directories into the $(_THEOS_CURRENT_TYPE) wrapper..."; $(ECHO_PIPEFAIL) (
	ECHO_PRE_UNLOADING = @(echo "Unloading $(PREINSTALL_TARGET_PROCESSES)..."; $(ECHO_PIPEFAIL) (
	ECHO_INSTALLING = @(echo "Installing..."; $(ECHO_PIPEFAIL) (
	ECHO_UNLOADING = @(echo "Unloading $(INSTALL_TARGET_PROCESSES)..."; $(ECHO_PIPEFAIL) (
	ECHO_CLEANING = @(echo "Cleaning..."; $(ECHO_PIPEFAIL) (
	ECHO_NOTHING = @($(ECHO_PIPEFAIL) (

	STDERR_NULL_REDIRECT = 2> /dev/null
	STDOUT_NULL_REDIRECT = > /dev/null

	_THEOS_VERBOSE := $(_THEOS_FALSE)
else
	ECHO_END = 

	ECHO_COMPILING = 
	ECHO_LINKING = 
	ECHO_LINKING_WITH_STRIP = 
	ECHO_STRIPPING = 
	ECHO_MERGING = 
	ECHO_SIGNING = 
	ECHO_PREPROCESSING = 
	ECHO_COPYING_RESOURCE_FILES = 
	ECHO_COPYING_RESOURCE_DIRS = 
	ECHO_INSTALLING = 
	ECHO_UNLOADING = 
	ECHO_CLEANING = 
	ECHO_NOTHING = 

	STDERR_NULL_REDIRECT = 
	STDOUT_NULL_REDIRECT = 

	_THEOS_VERBOSE := $(_THEOS_TRUE)
endif

WARNING_EMPTY_LINKING = @@(echo " Warning! No files to link. Please check your Makefile! Make sure you set $(THEOS_CURRENT_INSTANCE)_FILES (or similar variables)")

# (bundle)
NOTICE_EMPTY_LINKING = @@(echo " Notice: No files to link - creating a bundle containing only resources")

$(eval $(call __mod,messages.mk))
