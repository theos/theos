# Theos
Unified cross-platform iPhone Makefile system. Learn more at the [iPhone Development Wiki](http://iphonedevwiki.net/index.php/Theos).

See [LICENSE](LICENSE) for licensing information.

## Features of this fork
First off - it's important to note that GitHub says this repo is a fork of DHowett/theos. Since forking, [rpetrich's fork](https://github.com/rpetrich/theos) has also been merged, as well as some others here and there.

In a kinda-chronological order of the date the feature was added:

* Header include fallback at `include/_fallback` is used as a last resort; this can be used to provide drop-in replacements for missing SDK headers. (rpetrich)
* `make package FINALPACKAGE=1` will optimise assets (runs [pincrush](https://github.com/DHowett/pincrush) on PNG images, and converts plists to binary format) and generate a package with a "clean" version (ie, no build number). Recommended when building a package you're about to release. (rpetrich/kirb)
* `TWEAK_TARGET_PROCESSES = Preferences MobileMail` is a shortcut for killing a process. (rpetrich)
* Unlike rpetrich's fork, the internal generator (using Objective-C runtime functions directly) is changed back to the Substrate generator (using Substrate's wrappers around the runtime functions to assure future compatibility).
* Each architecture is compiled separately. (rpetrich)
* Different SDKs can be used for different architectures, making it possible to for instance use Xcode 4.4 for armv6 compilation alongside a newer Xcode for armv7/arm64. (rpetrich)
* All generated files are stored in `.theos`, rather than many different directories in the root of the project. (rpetrich)
* `make clean` also removes non-final packages. (rpetrich)
* Makes `dpkg-deb` use lzma compression, because the current format dpkg-deb uses (xz) is not supported by Telesphoreo's old dpkg build. (kirb)
* Packages are output to a subdirectory called `debs`. (kirb)
* Use [hbang/headers](https://github.com/hbang/headers) as a submodule. (kirb)
* Supports the iOS 7 simulator. (kirb)
* Adds a `%property` directive that allows for creating a property on a hooked class. (eswick)
* `File.m_CFLAGS` support, to have compiler flags on one particular file. (rpetrich)
* Provides `IS_IPAD` and `IN_SPRINGBOARD` macros in the prefix header. (kirb)
* Imports Cocoa and AppKit when targeting OS X. (kirb)
* When using iOS SDK 7.0 or newer, and deploying to iOS 5 or newer, Theos defaults to building for armv7 and arm64. (rpetrich/kirb)
* Adds `simbltweak.mk` to help in the building of SIMBL tweaks for OS X. (kirb)
* Removes makedeps support, to avoid non-fatal (but noisy) errors during compilation. (kirb)
* Adds modern app and preference bundle templates. (kirb)
* Adds `%dtor { ... }` directive to run code when the process is deconstructing. (uroboro)
* Improves error handling when an SDK isn't found. (uroboro)
* Adds `%hookf` for hooking functions. [Example](https://github.com/DHowett/theos/pull/106#issuecomment-51284735) (uroboro)
* Supports building rpm packages. (rpetrich)
* Adds `STRIP=0` to not strip on release builds. (rpetrich)
* Adds a stub `libsubstrate.dylib` binary so you don't need to get one yourself. (kirb)
* Kills Cydia if it's open so you don't get frustrated by dpkg status database locked errors. (kirb)
* Fixes lack of a symlink that allows Theos to work on arm64. (kirb)
* Supports Swift compilation and linking. Incomplete as it is uncertain whether Swift libraries are allowed to be distributed via Cydia. (kirb)
* Deprecates `NSLog` in favor of more detailed log macros, `HBLogDebug`, `HBLogInfo`, `HBLogWarn`, and `HBLogError`. (kirb)
* Makes debug builds the default. Use `make DEBUG=0` or `FORRELEASE=1` to build without debug. (kirb)
* Bumps default deployment target to iOS 4.3 when using iOS SDK 6.0 and iOS 5.0 when using iOS SDK 7.0. (kirb)

TL;DR it's pretty awesome, you should use it
