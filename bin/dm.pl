#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Spec;
use Cwd;
use Getopt::Long;
use Pod::Usage;
use Archive::Tar;
use IO::Compress::Gzip;
use IO::Compress::Bzip2;

package NIC::Archive::Tar::File;
use parent "Archive::Tar::File";
sub new {
	my $class = shift;
	my $self = Archive::Tar::File->new(@_);
	bless($self, $class);
	return $self;
}

sub full_path {
	my $self = shift;
	my $full_path = $self->SUPER::full_path(); $full_path = '' unless defined $full_path;
	$full_path =~ s#^#./# if $full_path ne "" && $full_path ne "." && $full_path !~ m#^\./#;
	return $full_path;
}
1;
package main;

our $VERSION = '2.0';

our $_PROGNAME = "dm.pl";

my $ADMINARCHIVENAME = "control.tar.gz";
my $DATAARCHIVENAME = "data.tar";
my $ARCHIVEVERSION = "2.0";

$Archive::Tar::DO_NOT_USE_PREFIX = 1; # use GNU extensions (not POSIX prefix)

our $compression = "gzip";
Getopt::Long::Configure("bundling", "auto_version");
GetOptions('compression|Z=s' => \$compression,
	'build|b' => sub { },
	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-exitstatus => 0, -verbose => 2); })
	or pod2usage(2);

pod2usage(1) if(@ARGV < 2);

my $pwd = Cwd::cwd();
my $indir = File::Spec->rel2abs($ARGV[0]);
my $outfile = $ARGV[1];

die "ERROR: '$indir' is not a directory or does not exist.\n" unless -d $indir;

my $controldir = File::Spec->catpath("", $indir, "DEBIAN");

die "ERROR: control directory '$controldir' is not a directory or does not exist.\n" unless -d $controldir;
my $mode = (lstat($controldir))[2];
die sprintf("ERROR: control directory has bad permissions %03lo (must be >=0755 and <=0775)\n", $mode & 07777) if(($mode & 07757) != 0755);

my $controlfile = File::Spec->catfile($controldir, "control");
die "ERROR: control file '$controlfile' is not a plain file\n" unless -f $controlfile;
my %control_data = read_control_file($controlfile);

die "ERROR: package name has characters that aren't alphanumueric or '-+.'.\n" if($control_data{"package"} =~ m/[^a-zA-Z0-9+-.]/);
die "ERROR: package version ".$control_data{"version"}." doesn't contain any digits.\n" if($control_data{"version"} !~ m/[0-9]/);

foreach my $m ("preinst", "postinst", "prerm", "postrm", "extrainst_") {
	$_ = File::Spec->catfile($controldir, $m);
	next unless -e $_;
	die "ERROR: maintainer script '$m' is not a plain file or symlink\n" unless(-f $_ || -l $_);
	$mode = (lstat)[2];
	die sprintf("ERROR: maintainer script '$m' has bad permissions %03lo (must be >=0555 and <=0775)\n", $mode & 07777) if(($mode & 07557) != 0555)
}

print "$_PROGNAME: building package `".$control_data{"package"}.":".$control_data{"architecture"}."' in `$outfile'\n";

open(my $ar, '>', $outfile) or die $!;

print $ar "!<arch>\n";
print_ar_record($ar, "debian-binary", time, 0, 0, 0100644, 4);
print_ar_file($ar, "$ARCHIVEVERSION\n", 4);

{
	my $tar = Archive::Tar->new();
	$tar->add_files(tar_filelist($controldir));
	my $comp;
	my $zFd = IO::Compress::Gzip->new(\$comp, -Level => 9);
	$tar->write($zFd);
	$zFd->close();
	print_ar_record($ar, $ADMINARCHIVENAME, time, 0, 0, 0100644, length($comp));
	print_ar_file($ar, $comp, length($comp));
} {
	my $tar = Archive::Tar->new();
	$tar->add_files(tar_filelist($indir));
	my $comp;
	my $zFd = compressed_fd(\$comp);
	$tar->write($zFd);
	$zFd->close();
	print_ar_record($ar, compressed_filename($DATAARCHIVENAME), time, 0, 0, 0100644, length($comp));
	print_ar_file($ar, $comp, length($comp));
}

close $ar;

sub print_ar_record {
	my ($fh, $filename, $timestamp, $uid, $gid, $mode, $size) = @_;
	printf $fh "%-16s%-12lu%-6lu%-6lu%-8lo%-10ld`\n", $filename, $timestamp, $uid, $gid, $mode, $size;
	$fh->flush();
}

sub print_ar_file {
	my ($fh, $data, $size) = @_;
	syswrite $fh, $data;
	print $fh "\n" if($size % 2 == 1);
	$fh->flush();
}

sub tar_filelist {
	chdir(shift);
	my @filelist;
	my @symlinks;

	find({wanted => sub {
		return if m#^./DEBIAN#;
		my $tf = NIC::Archive::Tar::File->new(file=>$_);
		push @symlinks, $tf if -l;
		push @filelist, $tf if ! -l;
	}, no_chdir => 1}, ".");
	return (@filelist, @symlinks);
}

sub read_control_file {
	my $filename = shift;
	open(my $fh, '<', $filename) or die "ERROR: can't open control file '$filename'\n";
	my %data;
	while(<$fh>) {
		if(m/^(.*?): (.*)/) {
			$data{lc($1)} = $2;
		}
	}
	close $fh;
	return %data;
}

sub compressed_fd {
	my $sref = shift;
	return IO::Compress::Gzip->new($sref, -Level => 9) if $::compression eq "gzip";
	return IO::Compress::Bzip2->new($sref) if $::compression eq "bzip2";
	open my $fh, ">", $sref;
	return $fh;
}

sub compressed_filename {
	my $fn = shift;
	my $suffix = "";
	$suffix = ".gz" if $::compression eq "gzip";
	$suffix = ".bz2" if $::compression eq "bzip2";
	return $fn.$suffix;
}

__END__

=head1 NAME

dm.pl

=head1 SYNOPSIS

dm.pl [options] <directory> <package>

=head1 OPTIONS

=over 8

=item B<-b>

This option exists solely for compatibility with dpkg-deb.

=item B<-ZE<lt>compressionE<gt>>

Specify the package compression type. Valid values are gzip (default), bzip2 and cat (no compression.)

=item B<--help>, B<-?>

Print a brief help message and exit.

=item B<--man>

Print a manual page and exit.

=back

=head1 DESCRIPTION

B<This program> creates Debian software packages (.deb files) and is a drop-in replacement for dpkg-deb.

=cut