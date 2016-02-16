## Reporting
We always encourage users to report bugs as soon as they see them, but in order to keep everything organized here are some questions you should ask yourself before reporting:
* Have you setup your envoirment variables?
* Do you have an SDK and toolchain installed (Toolchain if on linux)
* Did you do `git clone --recursive https://github.com/theos/theos.git` instead of `git clone https://github.com/theos/theos.git`
* Is this a personal issue? If so please do not make an issue, instead go find help on sites such as reddit or #theos
* Has the issue been reported already?
* whathaveyoutried.com
* xyproblem.info

If you checked all of these questions and are still experiencing issues here is some guidelines for making a report:
* Report with OS, Device, SDK version 
* If it is a build error do `make messages=yes` and post the output (or `make troubleshoot` after a failed build and paste the ghostbin link)
* List steps to reproduce.

The more information you have, the better. Post as much as you can related to the issues to help us resolve it in a timely matter. One issue per bug as well please! This will help us sort out the bugs efficently instead of having them cluttered together in one issue.
