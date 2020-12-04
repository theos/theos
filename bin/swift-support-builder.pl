#!/usr/bin/perl 

# This is a helper script which invokes a command to build the swift-support 
# tools, only if necessary.
#
# Usage: swift-support-builder.pl </path/to/swift-support> <swift version> <...build command>
#
# If THEOS_NO_SWIFT_CACHE is set to 1, the cache is ignored.

use strict;
use warnings;
use Fcntl qw(:flock);

my $support_dir = shift;
my $lockfile = "$support_dir/.theos_lock";
my $marker = "$support_dir/.theos_build/theos_build_commit";

my $swift_version = shift;

my $hash = `git -C $support_dir rev-parse HEAD`;
chomp($hash);
($? == 0 && length($hash) == 40) || die("$support_dir is not a valid git repo.");

my $computed_marker_value = "$swift_version $hash";

my $no_cache = defined $ENV{THEOS_NO_SWIFT_CACHE} && $ENV{THEOS_NO_SWIFT_CACHE} == '1';

# The marker file indicates the last version of swift-support that was successfully built
# (identified by its commit hash). If the last successful build corresponds to the current
# commit of swift-support, there's no need to re-build, and we can exit early.
sub check_marker() {
	if (!$no_cache && -e $marker) {
		open(my $marker_fh, '<', $marker) || die($!);
		my $marker_value = <$marker_fh>;
		if (defined $marker_value && $marker_value eq $computed_marker_value) {
			exit;
		}
	}
}

# Lockless (fast-path) check. Safe because concurrent reading is okay, and even
# if there's currently a process writing to the marker, the worst-case is that
# this check will end up erroneously failing, but that's fine because the check
# after the lock will succeed.
check_marker;

# The file lock ensures only one `swift build` command runs at a time, because SwiftPM
# doesn't accept parallel build invocations. This is required for both parallel make 
# invocations (-j#) as well as multiple Theos projects being built simultaneously.
open(my $lockfile_fh, '>', $lockfile) || die($!);
flock($lockfile_fh, LOCK_EX) || die($!);

# Having acquired the lock, check the marker again in case another process beat us
# to building swift-support. This can happen if the first check_marker was run while
# another process had acquired the lock but hadn't yet finished building, or hadn't
# finished writing to the marker.
check_marker;

# The marker file doesn't exist, and we hold the build lock. Let's run the build command.
my $build_command = join(' ', @ARGV);
system($build_command) == 0 || die("Failed to build Swift support tools: command failed: $build_command\n");

# Create the marker file with the commit hash to indicate that we're done.
open(my $marker_fh, '>', $marker);
$marker_fh->print($computed_marker_value);
