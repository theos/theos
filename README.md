Theos and Cycript for non-jailbroken iOS devices
================================================
This fork of Theos is designed to work with apps on non-jailbroken iOS devices. You MUST have an Apple iOS Developer account in order to use this (for code-signing purposes).

* You use it just as you would for a jailbroken device tweak (edit Tweak.xm then "make")
* It integrates CydiaSubstrate
* It integrates Cycript
* It patches App Store apps (.ipa files) to load CydiaSubstrate, your tweak, Cycript, etc
* It re-signs the patched app using your Apple iOS Developer certificate
* You can then (re)install the patched app to your jailed device using XCode
* You can remotely attach to Cycript using `cycript -r hostname:31337`

Requirements
============
* iOS device
* Apple Developer account
* XCode with iPhone SDK
* Patience and luck

Quick How-to
============
* Extract and decrypt your target app. Save as a .ipa.
* Check out this project
* Change to the base directory for your new tweak
* Run `/path/to/theos-jailed/bin/nic.pl`
* Configure as you normally would for a regular Theos tweak
* Once done, change into your new tweak directory
* Edit Tweak.xm as necessary
* Run `make` to build your tweak
* Run `./patchapp.sh info /path/to/your/file.ipa`
* Take the information from that and use the Apple Member Center to create a matching Provisionin Profile.
* Save the Provisioning Profile somewhere on your computer.
* Run `.patchapp.sh patch /path/to/your/file.ipa /path/to/your/file.mobileprovision` to inject the tweak into your .ipa
* Install the patched .ipa back onto your device using XCode.


More instructions to follow!

