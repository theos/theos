#Theos
A user-friendly framework for creating open iPhone projects
## Initial Setup
### Mac OS X
1. Download and install iPhone SDK. Be sure to include the iPhone 3.0 SDK version
2. Download and install latest git version from <a href="http://code.google.com/p/git-osx-installer/">Google Code</a>
3. Type `cd ~ && git clone git://github.com/rpetrich/theos.git` inside a shell (via Terminal.app)

## Project Setup

1. Open a command shell and `cd` to the directory where you store your projects
2. `~/theos/new-tweak.sh tweakname` (where _tweakname_ is the name of the new project you are creating)
3. `cd tweakname`

You are now inside the new project's directory

## Using Theos
<table>
 <tr>
  <td><code>make</code></td>
  <td>Builds all targets by compiling the necessary files and linking them</td>
 </tr>
 <tr>
  <td><code>make clean</code></td>
  <td>Cleans all targets and removes temporary files</td>
 </tr>
 <tr>
  <td><code>make&nbsp;package</code></td>
  <td>Creates a debian package using the contents of <tt>layout</tt> directory and the compiled build targets</td>
 </tr>
 <tr>
  <td><code>make&nbsp;update-framework</code></td>
  <td>Updates your project to use the latest version of the theos framework</td>
 </tr>
</table>
