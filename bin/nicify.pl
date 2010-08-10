#!/usr/bin/perl

use warnings;
use File::Find;

@directories = ();
%files = ();
%symlinks = ();

chdir $ARGV[0];
find({wanted => \&processDirectories, follow => 0, no_chdir => 1}, ".");
find({wanted => \&processFiles, follow => 0, no_chdir => 1}, ".");
find({wanted => \&processSymlinks, follow => 0, no_chdir => 1}, ".");

print "nic 1",$/;

if(-f "pre.NIC") {
	open(my $pfh, "<", "pre.NIC");
	while(<$pfh>) {
		print $_;
	}
	close($pfh);
}

foreach $dir (@directories) {
	print "dir $dir",$/;
}

foreach $filename (keys %files) {
	my @lines = split(/\n/, $files{$filename});
	my $ln = scalar(@lines);
	print "file $ln $filename",$/;
	print $files{$filename},$/;
}

foreach $symlink (keys %symlinks) {
	print "symlink \"$symlink\" \"".$symlinks{$symlink}."\"",$/;
}

sub processDirectories {
	return if(! -d $_);
	return if(/\.svn/);
	return if(/^.$/);
	s/^\.\///;
	push(@directories, $_);
}

sub processFiles {
	return if(! -f $_ || -l $_);
	return if(/\.svn/);
	return if(/\.[Nn][Ii][Cc]$/);
	s/^\.\///;
	$files{$_} = slurp($_);
}

sub processSymlinks {
	return if(! -l $_);
	return if(/\.svn/);
	return if(/\.nic$/);
	s/^\.\///;
	$symlinks{$_} = readlink($_);
}

sub slurp {
	my $fn = shift;
	open(my($fh), "<", $fn);
	local $/ = undef;
	my $d = <$fh>;
	return $d;
}
