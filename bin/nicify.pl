#!/usr/bin/perl

use warnings;
use File::Find;

@directories = ();
%files = ();

chdir $ARGV[0];
find({wanted => \&processDirectories, follow => 0, no_chdir => 1}, ".");
find({wanted => \&processFiles, follow => 0, no_chdir => 1}, ".");

foreach $dir (@directories) {
	print "dir $dir",$/;
}

foreach $filename (keys %files) {
	my @lines = split(/\n/, $files{$filename});
	my $ln = scalar(@lines);
	print "file $ln $filename",$/;
	print $files{$filename},$/;
}

sub processDirectories {
	return if(! -d $_);
	return if(/\.svn/);
	return if(/^.$/);
	s/^\.\///;
	push(@directories, $_);
}

sub processFiles {
	return if(! -f $_);
	return if(/\.svn/);
	return if(/\.nic$/);
	s/^\.\///;
	$files{$_} = slurp($_);
}

sub slurp {
	my $fn = shift;
	open(my($fh), "<", $fn);
	local $/ = undef;
	my $d = <$fh>;
	return $d;
}
