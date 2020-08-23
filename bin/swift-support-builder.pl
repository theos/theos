#!/usr/bin/perl 

# This is a helper script which invokes a command to build the swift-support 
# tools, only if necessary.
#
# Usage: swift-support-builder.pl </path/to/swift-support> <...build command>
#
# If THEOS_NO_SWIFT_CACHE is set to 1, the cache is ignored.

use strict;
use warnings;
use Fcntl qw(:flock);

my $support_dir = shift;
my $lockfile = "$support_dir/.theos_lock";
my $marker = "$support_dir/.theos_build/theos_build_commit";

my $hash = `git -C $support_dir rev-parse HEAD`;
chomp($hash);
($? == 0 && length($hash) == 40) || die("$support_dir is not a valid git repo.");

my $no_cache = defined $ENV{THEOS_NO_SWIFT_CACHE} && $ENV{THEOS_NO_SWIFT_CACHE} == '1';

# The marker file indicates the last version of swift-support that was successfully built
# (identified by its commit hash). If the last successful build corresponds to the current
# commit of swift-support, there's no need to re-build, and we can exit early.
sub check_marker() {
	if (!$no_cache && -e $marker) {
		open(my $marker_fh, '<', $marker) || die($!);
		my $marker_hash = <$marker_fh>;
		if (defined $marker_hash && $marker_hash eq $hash) {
			exit;
		}
	}
}

# Lockless check, since it's safe to read concurrently.
check_marker;

# The file lock ensures only one `swift build` command runs at a time, because SwiftPM
# doesn't accept parallel build invocations. This is required for both parallel make 
# invocations (-j#) as well as multiple Theos projects being built simultaneously.
open(my $lockfile_fh, '>', $lockfile) || die($!);
flock($lockfile_fh, LOCK_EX) || die($!);

# Having acquired the lock, check the marker again in case another process beat us
# to building swift-support.
check_marker;

# The marker file doesn't exist, and we hold the build lock. Let's run the build command.
system(join(' ', @ARGV)) == 0 || die;

# Create the marker file with the commit hash to indicate that we're done.
open(my $marker_fh, '>', $marker);
$marker_fh->print($hash);
