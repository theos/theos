# Theos
Unified cross-platform iPhone Makefile system. Learn more at the [iPhone Development Wiki](http://iphonedevwiki.net/index.php/Theos). *"kirb’s amalgamation of all the things"* –rpetrich

See [LICENSE](LICENSE) for licensing information.

## Environment
Please note that Theos symlinks are not made by default by this Theos fork in new projects created by NIC. You must set and export the `$THEOS` variable in your environment. [See below](#wheres-the-theos-symlink) for details.

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
* Adds `%hookf` for hooking functions. [Example](https://github.com/DHowett/theos/pull/106#issuecomment-52142951) (uroboro)
* Supports building rpm packages. (rpetrich)
* Adds `STRIP=0` to not strip on release builds. (rpetrich)
* Adds a stub `libsubstrate.dylib` binary so you don't need to get one yourself. (kirb)
* Kills Cydia if it's open so you don't get frustrated by dpkg status database locked errors. (kirb)
* Fixes lack of a symlink that allows Theos to work on arm64. (kirb)
* Supports Swift compilation and linking. Incomplete as it is uncertain whether Swift libraries are allowed to be distributed via Cydia. (kirb)
* Deprecates `NSLog` in favor of more detailed log macros, `HBLogDebug`, `HBLogInfo`, `HBLogWarn`, and `HBLogError`. (kirb)
* Makes debug builds the default. Use `make DEBUG=0` or `FORRELEASE=1` to build without debug. (kirb)
* Bumps default deployment target to iOS 4.3 when using iOS SDK 6.0 and iOS 5.0 when using iOS SDK 7.0. (kirb)
* Includes NIC templates from [DHowett, conradev, WillFour20](https://github.com/DHowett/theos-nic-templates); [uroboro](https://github.com/uroboro/nicTemplates); and [bensge, kirb](https://github.com/sharedInstance/iOS-7-Notification-Center-Widget-Template).
* Supports building for iOS on Windows. (coolstar)
* Theos symlinks are no longer made within projects. The `$THEOS` environment variable is used instead. (kirb)
* `target_USE_SUBSTRATE = 0` can be used to switch tweaks to the internal generator and not link against Substrate. (kirb)
* Default rules, variables, etc. can be set in `~/.theosrc` (a makefile). (kirb)
* `make show` opens the operating system's file manager and highlights the latest package. (kirb)

TL;DR it's pretty awesome, you should use it

## FAQ
### Fork of Theos? Why? Didn't saurik say those are bad™?
There has been a lack of development on Theos recently, there were already a few patches I made and left uncommitted for a few years, and some fixes were critically needed for new SDKs and for dependencies such as dpkg-deb to continue to work with Telesphoreo's horribly outdated dpkg. From there it grew to other features I desired, and wanted to see more of the community taking advantage of, such as debug builds by default, optimisation of particular file types in release builds, and Swift compilation. The fork has significantly matured to the point that it would be hard to merge it back into the original Theos repo, and it also pulls in commits from [rpetrich's Theos fork](https://github.com/rpetrich/theos) which was created when Theos was still in its early days and moving away from its original name of "iphone-framework".

And besides, why would it be bad to give back so many improvements to the community?

Moving along…

### How do I switch to this Theos fork?
Hopefully you set up Theos by cloning the Git repository. First – please be sure to move the `include` directory in your existing Theos to elsewhere for now. Since this directory is a Git submodule pointing at the [hbang/headers](https://github.com/hbang/headers) repo, Git will complain about a merge conflict. You can move your headers back there if you want afterwards.

Now, simply change the remote repo and pull:

```shell
git remote set-url origin git@github.com:kirb/theos.git
git pull origin master
```

Then grab the `include` submodule like so:

```shell
git submodule update --init --remote
```

Alternatively, on OS X, you can grab Theos from Homebrew. Just `brew install hbang/repo/theos`, and it'll be installed to `/usr/local/theos` (or equivalent for your Homebrew prefix).

### All of my package versions contain `+debug` now! How do I stop this?
This fork is attempting to encourage using debug builds by default, rather than release builds. Building as a debug build provides more ease in using debuggers on the code, enables debug logging with `HBLogDebug()`, and makes syslog output colored so it's easier to find in a sea of other log messages.

To disable debug mode, pass `DEBUG=0` as part of your command line to `make`. When you make a release build with `FOR_RELEASE=1` or `FINALPACKAGE=1`, debug will also be disabled (and the build number is also removed so your version number is cleaner).

### NSLog() is deprecated? What? How do I log now?
Like the above situation, this fork also aims to encourage developers to specify a "level" along with their logs. The levels are:

* **HBLogDebug** – used to log data that is useful during development, but not useful in a released package.
* **HBLogInfo** – used to log informational messages that do not indicate a problem.
* **HBLogWarn** – used to indicate a problem that can be recovered from
* **HBLogError** – used to indicate a problem that can not be recovered from.

All of these macros are used exactly the same way as NSLog – all that changes is the *name* of the function you call.

Here's a practical example of all of these in use:

```logos
- (UIImage *)iconForBundleIdentifier:(NSString *)bundleIdentifier {
    HBLogInfo(@"looking up icon for %@", bundleIdentifier);

    SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationForBundleIdentifier:bundleIdentifier];

    if (!app) {
        HBLogError(@"could not retrieve app instance for %@", bundleIdentifier);
        return nil;
    }

    HBLogDebug(@"app for %@ is %@", bundleIdentifier, app);

    SBApplicationIcon *appIcon = [[[%c(SBApplicationIcon) alloc] initWithApplication:app] autorelease];
    UIImage *icon = [appIcon getIconImage:SBApplicationIconFormatSpotlight];

    if (icon) {
        return icon;
    } else {
        HBLogWarn(@"no spotlight icon was found. falling back to default icon");

        icon = [appIcon getIconImage:SBApplicationIconFormatDefault];

        if (!icon) {
            HBLogError(@"couldn't get a default icon - giving up");
        }

        return icon;
    }
}
```

It is hoped that this will encourage more carefully considered logging that is convenient to both the developer and users reading their syslogs. Not logging at all only makes it harder for you to track down issues – please consider using this!

### I built a package using Swift, but it crashes on my phone. Why?
This fork is ready in terms of supporting *building* Swift packages; however, the Swift runtime is not available in Cydia. The reasoning for this is that many of us have been unable to find a definitive license detailing distribution of these libraries and thus it is best to stay away from releasing them.

There *is* good news, however. Swift 2.0 is to be released as an open source product, and so that means once Swift 2.0 is released (and not in beta), runtime libraries will begin to become available in Cydia.

Until then, you can play around with Swift by copying the libraries to your device manually:

```shell
ssh device "mkdir -p /usr/lib/libswift/1.2"
rsync -rav "$(xcode-select -print-path)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/iphoneos" device:/usr/lib/libswift/1.2
```

This assumes you're using Xcode 6.3, which includes Swift 1.2. Change the version in the path if not. You can find out what version your copy of Xcode has with `swift --version`.

### Windows support? Whoa. How do I use that?
Refer to [the sharedInstance post](http://sharedinstance.net/2013/12/build-on-windows/) on setting this up.

### Where's the `theos` symlink?
This fork has opted to not use this symlink any longer because of a few reasons. First, there are a fair few "noisy" files dropped in the root of a project by standard Theos; this fork prefers to have as few of those as possile (and you may have noticed some are now stashed into the `.theos` directory). Second, this feels like a hack, and it can be very different between developers and even between each of a developer's devices as Theos can be located anywhere. It's also easy to unintentionally commit this symlink to source control or not know that this shouldn't be committed to source control.

Of course, this does mean you must set and export `$THEOS` in your environment. Do this in your shell's profile or environment script (for instance `~/.bash_profile` or `~/.zshrc`) to ensure it's always set and you don't have to worry about it. It might look like this:

```shell
export THEOS=/usr/local/theos
```
