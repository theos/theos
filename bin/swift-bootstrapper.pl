#!/usr/bin/perl 

# This is a helper script which invokes a command to bootstrap Theos' Swift tools,
# if and only if necessary.
#
# Usage: swift-bootstrapper.pl </path/to/project> <swift version> <...build command>
#
# If THEOS_NO_SWIFT_CACHE is set to 1, the cache is ignored.

use strict;
use warnings;
use Fcntl qw(:flock);
use File::Path qw(rmtree);
use File::Basename;

my $swift_command = shift;
my $swift_version = `$swift_command --version 2>/dev/null`;
chomp($swift_version);
$swift_version =~ tr{\n}{ };

my $project_dir = shift;
my $project_name = basename($project_dir);
my $lockfile = "$project_dir/.theos_lock";
my $build_dir = "$project_dir/.theos_build";
my $marker = "$build_dir/theos_build_commit";

my $print_command = shift;

my $hash = `git -C $project_dir rev-parse HEAD 2>/dev/null`;
chomp($hash);
if ($? != 0 || length($hash) != 40) {
	# Theos should be a git repo but if it isn't this works as a hacky fallback
	my $hash = `find $project_dir/Sources -type f -print0 | xargs -0 sha1sum | awk '{print \$1}' | sha1sum | head -c 40`;
	chomp($hash);
}

my $computed_marker_value = "$hash $swift_version";

my $cache_flag = $ENV{THEOS_NO_SWIFT_CACHE} // '';
if ($cache_flag eq '3') {
	exit;
}
my $no_cache = $cache_flag eq '1' || $cache_flag eq '2';

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

if ($cache_flag ne '1' && -d $build_dir) {
	rmtree($build_dir);
}

# The marker file doesn't exist, and we hold the build lock. Let's run the build command.
my $build_command = "SPM_THEOS_BUILD=1 $swift_command build -c release --package-path $project_dir --build-path $project_dir/.theos_build";
system($print_command);
system($build_command) == 0 || die("Failed to build $project_name: command failed: $build_command\n");

# Create the marker file with the commit hash to indicate that we're done.
open(my $marker_fh, '>', $marker);
$marker_fh->print($computed_marker_value);
