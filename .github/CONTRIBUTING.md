# Filing an Issue
We always encourage users to report bugs as soon as they experience them. In order to keep everything organized here are some questions you should ask yourself before reporting:

## Common mistakes
* Have you followed everything on <https://theos.dev/install>?
* Have you set up your environment variables? Most importantly, `$THEOS` must be set or nothing will work.
* Do you have an SDK and toolchain installed? If you're using OS X and building for iOS, OS X, Apple Watch, or Apple TV, Xcode provides both of these.
* When you `git clone`d Theos, did you use `--recursive`? Theos uses Git submodules, so if you don't clone the submodules, you're missing a lot. Try running `make update-theos` from a Theos project.

## General issues
* Are you using the latest version of Theos? Run `make update-theos` from a Theos project, then try again.
* Has this issue been reported already? Please check the [list of open issues](https://github.com/theos/theos/issues).

## Advice
If you're sure you've followed all instructions and haven't made any of the common mistakes listed above, here are some guidelines for creating an issue:

* Is this an issue with Theos itself, or a compiler error, or are you looking for help with your code? The Theos issue tracker is for Theos issues only. Try the [GitHub Discussions tab](https://github.com/theos/theos/discussions), [Discord](https://theos.dev/discord), or [Reddit](https://www.reddit.com/r/jailbreakdevelopers).
* When you ask a question, make sure it's not [an XY problem](http://xyproblem.info/).
* Provide as much information as you possibly can.
* Use `make troubleshoot` to quickly create a [Gist](https://gist.github.com/) paste containing the output of `make clean all messages=yes`.
* Issues are formatted by [Markdown](https://guides.github.com/features/mastering-markdown/). If you paste code into your issue, it will probably end up appearing quite broken because it was interpreted as Markdown. Enclose blocks of code with three backticks (\`\`\`) at the start and end to make it a nicely formatted code block.

## In your issue, please:
* List all operating system names and versions involved in the issue, as well as the toolchain, SDK version, and (if applicable) Xcode version.
* List any other software name/version you think may be related.
* Include any error messages you see.
* List steps to reproduce.

The more information you have, the better. Post as much as you can related to the issues to help us resolve it in a timely matter. If you have multiple issues, please file them as separate issues. This will help us sort them out efficiently.

Don't ask a question not related to the topic of the current issue, especially if it's on someone else's issue. This is known as [thread hijacking](http://www.urbandictionary.com/define.php?term=Thread+Hijacking). You should create a new issue, or ask on another discussion forum. To contact a specific developer, find their GitHub profile and look for their email address, or Twitter, etc.

Thanks!

# Contribution Standards
Don't be afraid to contribute to the development of Theos! Even if you don't think you've contributed much, it's still greatly appreciated.

Please make sure you abide by these contribution standards so we can retain a high quality codebase and make it easy for everyone to understand and contribute to the code.

* Follow all coding standards set by existing code in the repo. Using your own preferences over the established ones for the project just ends up making the code messy.
* Use a commit message of the format `[component] Explanation of what changed.`. The component is typically a makefile name, or directory name. The first line of commit messages should not be longer than 70 characters. Any subsequent lines should not be longer than 80 characters.
* An explanation of what the commit's changes do in your commit message is extremely useful. It helps people to more quickly understand what your code is doing.
* When you submit a pull request, be willing to accept criticism. We don't criticise to make you feel bad - we want you to know where you may have made a mistake and this helps you grow as a developer.
