Makefiles
=========

Introduction
============

PROJECT is a set of Makefiles designed to take away the complexity of building and organizing iPhoneOS projects without the use of Xcode (or even Mac OS X.)

Structure of a Makefile
=======================

Here is an example makefile for a project using PROJECT

    # System variables such as MODULES and TARGET.

    include theos/makefiles/common.mk

    # Instance-related variables such as xxx_FILES.

    TOOL_NAME = Simple
    Simple_FILES = simple.mm

    include $(THEOS_MAKE_PATH)/tool.mk

    # Custom rules

Project Types
=============

Projects are divided into different types, briefly described below. To create a project of a given type, simply include its makefile. For example, to create a command-line tool:

    include theos/makefiles/tool.mk

From one Makefile, you can build multiple types of project (just include both project type makefiles). An example:

    include theos/makefiles/common.mk

    TWEAK_NAME = Simple
    Simple_FILES = Tweak.mm

    TOOL_NAME = simpleutility
    simpleutility_FILES = su.c

    include $(THEOS_MAKE_PATH)/tweak.mk
    include $(THEOS_MAKE_PATH)/tool.mk

You can also build multiple instances of a single project type from one Makefile.

    include theos/makefiles/common.mk

    TWEAK_NAME = Simple Complex
    Simple_FILES = Tweak.mm
    Complex_FILES = 1.mm 2.mm 3.mm 4.mm

    include $(THEOS_MAKE_PATH)/tweak.mk

Aggregate (`aggregate.mk`)
--------------------------

An Aggregate project is a project that consists of several subprojects. Each subproject can be any valid type (including another Aggregate).

`SUBPROJECTS`  
`The SUBPROJECTS` variable defines the directory names that contain the subprojects this Aggregate project should build.

UIKit Applications (`application.mk`)
-------------------------------------

An `application` is an Objective-C program that includes a GUI component, and by default links against UIKit.

Command Line Tools (`tool.mk`)
------------------------------

A `tool` is a program that does not have a GUI component, and differs from an `application` wherein it does not link against UIKit. This project type is intended for command-line tools, daemons, etc.

MobileSubstrate Tweaks (`tweak.mk`)
-----------------------------------

A `tweak` is a dynamic library that links against MobileSubstrate for the purposes of adding and replacing functions and methods at runtime.

Tweaks in PROJECT are often written with the help of the Logos preprocessor.

> **Note**
>
> A `tweak` does not, by default, link against UIKit. If you want to link against UIKit, add it to `xxx_FRAMEWORKS`.

Bundles (`bundle.mk`)
---------------------

A `bundle` is a dynamic library meant to be loaded into another application at runtime, using the NSBundle class.

Frameworks (`framework.mk`)
---------------------------

Dynamic Libraries (`library.mk`)
--------------------------------

Variables
=========

System Constants
----------------

These constants are listed for use in toplevel Makefiles.

`THEOS`; `THEOS_MAKE_PATH`; `THEOS_BIN_PATH`; `THEOS_LIBRARY_PATH`; `THEOS_INCLUDE_PATH`; `THEOS_MODULE_PATH`  
Used for locating other PROJECT resources, such as binaries, scripts, modules and other makefiles.

`THEOS_PLATFORM_NAME`; `THEOS_TARGET_NAME`  
The build platform and the platform being targeted, normalized.

System Variables
----------------

These variables are listed for use in toplevel Makefiles, but if you really want to change them, you can.

`THEOS_BUILD_DIR`  
Build directory (objects are placed in `/`). Defaults to the current directory.

`THEOS_OBJ_DIR_NAME`  
Output file directory name. Defaults to `obj`.

`THEOS_STAGING_DIR`  
Package staging directory. Defaults to `/_`.

`Blah`  
Description

Local Variables
---------------

These variables are not tied to any particular project instance, and can be set either in the toplevel Makefile or in the environment.

`ADDITIONAL_CFLAGS`; `ADDITIONAL_CCFLAGS`; `ADDITIONAL_OBJCFLAGS`; `ADDITIONAL_OBJCCFLAGS`; `ADDITIONAL_LDFLAGS`  
The `ADDITIONAL_FLAGS` variables control additional compilation flags for an entire project. These variables are not passed into subdirectories or subprojects, but can be made to do so with `export`, as in `export
            `.

`CFLAGS`; `CCFLAGS`; `OBJCFLAGS`; `OBJCCFLAGS`; `LDFLAGS`  
The unqualified `FLAGS` variables can be used for additional compilation flags stored in the environment or given on the commandline, as in `make
            =-funroll-loops`.

`OPTFLAG`  
The `OPTFLAG` variable controls optimization. Its default value is `-O2`.

`DEBUG`  
The `DEBUG` variable controls compilation of debug symbols and stripping. When set to `1`, `-ggdb -DDEBUG` is added to the compilation flags, stripping is disabled, and optimization flags are stripped from `OPTFLAG`. Additionally, `+debug` is appended to the package build identifier.

`Blah`  
Description

`Blah`  
Description

`Blah`  
Description

`Blah`  
Description

Project Variables
-----------------

The various project type makefiles all support a common set of variables, described below. In this list, `xxx` is assumed to be the project instance name.

`xxx_FILES`  
The `FILES` variables contain space-delimited lists of the source files comprising the project. Including files with the `.m` or `.mm` extensions causes the Objective-C runtime and Foundation framework to be linked with your project.

The older type-specific `FILES` variables are deprecated in favour of `xxx_FILES`.

`xxx_OBJ_FILES`  
The `OBJ_FILES` variable contains a space-delimited list of precompiled object files (`.o` or library/framework binaries) to be linked with the project.

`xxx_FRAMEWORKS`; `xxx_PRIVATE_FRAMEWORKS`  
The `FRAMEWORKS` variables contain space-delimited lists of frameworks to link with the project, if Objective-C source files are used. Including `PRIVATE_FRAMEWORKS` causes the private Framework directory to be included in the Framework search path.

`xxx_CFLAGS`; `xxx_CCFLAGS`; `xxx_OBJCFLAGS`; `xxx_OBJCCFLAGS`  
The `FLAGS` variables contain flags passed to the compiler for a given filetype.

`xxx_LDFLAGS`  
The `LDFLAGS` variable contains flags passed to the linker for a project.

`Blah`  
Description


