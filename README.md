theos-jailed
============

This fork of Theos is designed to work with apps on non-jailbroken iOS devices.

* You use it just as you would for a jailbroken device tweak (edit Tweak.xm then "make")
* It automatically integrates CydiaSubstrate
* It automatically integrates Cycript
* It automatically patches App Store apps (.ipa files) to load CydiaSubstrate, your tweak, Cycript, etc
* It automatically re-signs the patched app using your Apple iOS Developer certificate
* You can then (re)install the patched app to your jailed device using XCode

More instructions to follow!

