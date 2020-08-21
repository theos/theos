#!/usr/bin/perl 

# This is a helper script which invokes a command to build the swift-support 
# tools, only if necessary.
#
# Usage: swift-support-builder.pl <lockfile> <marker> <...build command>
#
# Locking is loosely based on https://stackoverflow.com/a/13343904/3769927

use strict;
use warnings;
use Fcntl qw(:flock);

my $lockfile = shift;
my $marker = shift;

open(FH, '>', $lockfile) || die($!);

# Fast path to avoid locking. See below for description of what $marker does.
-e $marker && exit;

# The file lock ensures only one `swift build` command runs at a time, because SwiftPM
# doesn't accept parallel build invocations. This is required for both parallel make 
# invocations (-j#) as well as multiple Theos projects being built simultaneously.
flock(FH, LOCK_EX) || die($!);

# The marker is an indicator that the Swift tools have been built during this "build 
# session" (ie the invocation of `make` by the user). It is created when we build the tools
# successfully, and removed every time a new build session starts (see master/rules.mk).
# This effectively means the build command is run at most once every time the user runs 
# `make`. In most cases, the build command realizes the support tools source hasn't changed 
# and thus does nothing, so it's pretty fast. But there is still *some* overhead, which is 
# why we don't want to run it more than once.
if (! -e $marker) {
	system(@ARGV) == 0 || die;
	{ open(my $marker_fd, '>', $marker) }
}

flock(FH, LOCK_UN);
