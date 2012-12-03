package Logos::Test;
use strict;
use warnings;

use FindBin;
use IPC::Run qw(run timeout);
use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;

use Logos::Group;
use Logos::Class;
use Logos::Method;
use Logos::Patch;
use Logos::Subclass;
use Logos::StaticClassGroup;

my @_dirs = File::Spec->splitdir(__FILE__);
my $_theospath;
while(!$_theospath || ! -f "$_theospath/bin/logos.pl") {
	$#_dirs--;
	$_theospath = File::Spec->catdir(@_dirs);
}

sub from {
	my $file = shift;
	my ($stdin, $stdout, $stderr);
	my $command = ["$_theospath/bin/logos.pl", "-c", "dump=perl", $file];
	run $command, \$stdin, \$stdout, \$stderr, timeout(10);

	my $dump = $stderr;
	my $logos_state;
	eval($dump);
	die $@ if $@;
	return {
		stdout => $stdout,
		stderr => $stderr,
		state => $logos_state,
	};
}

1;
