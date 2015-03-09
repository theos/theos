ifneq ($(call __theos_bool,$(or $(messages),$(MESSAGES))),$(_THEOS_TRUE))
	ECHO_COMPILING = @(echo " Compiling $< ($(THEOS_CURRENT_ARCH))...";
	ECHO_LINKING = @(echo " Linking $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE) ($(THEOS_CURRENT_ARCH))...";
	ECHO_LINKING_WITH_STRIP = @(echo " Linking $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE) (with strip, $(THEOS_CURRENT_ARCH))...";
	ECHO_STRIPPING = @(echo " Stripping $(THEOS_CURRENT_INSTANCE) ($(THEOS_CURRENT_ARCH))...";
	ECHO_MERGING = @(echo " Merging $(_THEOS_CURRENT_TYPE) $(THEOS_CURRENT_INSTANCE)...";
	ECHO_SIGNING = @(echo " Signing $(THEOS_CURRENT_INSTANCE)...";
	ECHO_PREPROCESSING = @(echo " Preprocessing $<...";
	ECHO_COPYING_RESOURCE_FILES = @(echo " Copying resource files into the $(_THEOS_CURRENT_TYPE) wrapper...";
	ECHO_COPYING_RESOURCE_DIRS = @(echo " Copying resource directories into the $(_THEOS_CURRENT_TYPE) wrapper...";
	ECHO_CLEANING = @(echo "Cleaning...";
	ECHO_NOTHING = @(

	STDERR_NULL_REDIRECT = 2> /dev/null
	STDOUT_NULL_REDIRECT = > /dev/null

	ECHO_END = )

	_THEOS_VERBOSE := $(_THEOS_FALSE)
else
	ECHO_COMPILING =
	ECHO_LINKING = 
	ECHO_LINKING_WITH_STRIP = 
	ECHO_STRIPPING = 
	ECHO_MERGING = 
	ECHO_SIGNING = 
	ECHO_PREPROCESSING = 
	ECHO_COPYING_RESOURCE_FILES =
	ECHO_COPYING_RESOURCE_DIRS =
	ECHO_CLEANING =
	ECHO_NOTHING = 
	STDERR_NULL_REDIRECT = 
	STDOUT_NULL_REDIRECT =
	ECHO_END = 

	_THEOS_VERBOSE := $(_THEOS_TRUE)
endif

WARNING_EMPTY_LINKING = @(echo " Warning! No files to link. Please check your Makefile! Make sure you set $(THEOS_CURRENT_INSTANCE)_FILES (or similar variables)")

# (bundle)
NOTICE_EMPTY_LINKING = @(echo " Notice: No files to link - creating a bundle containing only resources")

$(eval $(call __mod,messages.mk))
