#!/usr/bin/perl

use warnings;
use FindBin;
use Getopt::Long;
use Cwd 'abs_path';
use File::Spec;
use File::Find;
use File::Copy;
use User::pwent;
use POSIX qw(getuid);

my @_dirs = File::Spec->splitdir(abs_path($FindBin::Bin));
$_dirs[$#_dirs]="templates";
my $_templatepath = File::Spec->catdir(@_dirs);
$#_dirs--;
my $_theospath = File::Spec->catdir(@_dirs);

my @templates = getTemplates();

my %CONFIG = ();
loadConfig();

my $clean_project_name = "";
my $project_name = "";
my $package_prefix = $CONFIG{'package_prefix'};
$package_prefix = "com.yourcompany" if !$package_prefix;
my $package_name = "";
my $username = $CONFIG{'username'};
$username = "" if !$username;
my $template;

my $nicfile = "";

Getopt::Long::Configure("bundling");

GetOptions(	"packagename|p=s" => \$package_name,
		"name|n=s" => \$project_name,
		"user|u=s" => \$username,
		"nic=s" => \$nicfile,
		"template|t=s" => \$template);

$project_name = $ARGV[0] if($ARGV[0]);

print "NIC 0.0.1 - New Instance Creator",$/;
print "--------------------------------",$/;

$template = $nicfile if $nicfile ne "";
if(!$template) {
	$template = promptList(undef, "Choose a Template (required)", @templates);
}
$nicfile = "$_templatepath/$template.nic" if $nicfile eq "";
die "Couldn't open template at path $nicfile" if(! -f $nicfile);

promptIfMissing(\$project_name, undef, "Project Name (required)");
exitWithError("I can't live without a project name! Aieeee!") if !$project_name;
$clean_project_name = cleanProjectName($project_name);

$package_name = $package_prefix.".".packageNameIze($project_name) if $CONFIG{'skip_package_name'};
promptIfMissing(\$package_name, $package_prefix.".".packageNameIze($project_name), "Package Name");

promptIfMissing(\$username, getUserName(), "Authour/Maintainer Name");

my $directory = lc($clean_project_name);
if(-d $directory) {
	my $response;
	promptIfMissing(\$response, "N", "There's already something in $directory. Continue");
	exit 1 if(uc($response) eq "N");
}

print "Instantiating $template in ".lc($clean_project_name)."/...",$/;
buildNic($template);
print "Done.",$/;

sub promptIfMissing {
	my $vref = shift;
	return if(${$vref});

	my $default = shift;
	my $prompt = shift;

	if($default) {
		print $prompt, " [$default]: ";
	} else {
		print $prompt, ": ";
	}

	$| = 1; $_ = <STDIN>;
	chomp;

	if($default) {
		${$vref} = $_ ? $_ : $default;
	} else {
		${$vref} = $_;
	}
}

sub promptList {
	my $default = shift;
	my $prompt = shift;
	my @list = @_;

	$default = -1 if(!defined $default);

	map { print " ".($_==$default?">":" ")."[".($_+1).".] ",$list[$_],$/; } (0..$#list);
	print $prompt,": ";
	$| = 1;
	my $idx = -1;
	while(<STDIN>) {
		chomp;
		if($default > -1 && $_ eq "") {
			$idx = $default;
			last;
		}
		if($_ < 1 || $_ > $#list+1) {
			print "Invalid value.",$/,$prompt,": ";
			next;	
		}
		$idx = $_-1;
		last;
	}
	return $list[$idx];
}

sub exitWithError {
	my $error = shift;
	print STDERR "[error] ", $error, $/;
	exit 1;
}

sub getTemplates {
	our @templates = ();
	find({wanted => \&templateWanted, no_chdir => 1}, $_templatepath);
	sub templateWanted {
		if(-f && /\.nic$/) {
			my $template = substr($_,length($_templatepath)+1);
			$template =~ s/\.nic$//;
			push(@templates, $template);
		}
	}
	return sort @templates;
}

sub packageNameIze {
	my $name = shift;
	$name =~ s/ //g;
	$name =~ s/[^\w\+-.]//g;
	return lc($name);
}

sub cleanProjectName {
	my $name = shift;
	$name =~ s/ //g;
	$name =~ s/\W//g;
	return $name;
}

sub getUserName {
	my $pw = getpw(getuid());
	my ($fullname) = split(/\s*,\s*/, $pw->gecos);
	return $fullname ? $fullname : $pw->name;
}

sub getHomeDir {
	my $pw = getpw(getuid());
	return $pw->dir;
}

sub buildNic {
	my $template = shift;
	my $dir = lc($clean_project_name);
	open(my($fh), "<", $nicfile) or die $!;
	mkdir($dir);
	chdir($dir) or die $!;
	while(<$fh>) {
		if(/^dir (.+)$/) {
			mkdir($1);
		} elsif(/^file (\d+) (.+)$/) {
			my $lines = $1;
			my $filename = $2;
			$filename = substitute($filename);
			open(my($nicfile), ">", "./$filename");
			while($lines > 0) {
				my $line = <$fh>;
				print $nicfile (substitute($line));
				$lines--;
			}
			close($nicfile);
		}
	}
	close($fh);
	symlink($_theospath, "theos");
}

sub substitute {
	my $in = shift;
	$in =~ s/\@\@FULLPROJECTNAME\@\@/$project_name/g;
	$in =~ s/\@\@PROJECTNAME\@\@/$clean_project_name/g;
	$in =~ s/\@\@PACKAGENAME\@\@/$package_name/g;
	$in =~ s/\@\@USER\@\@/$username/g;
	return $in;
}

sub loadConfig {
	open(my $cfh, "<", getHomeDir()."/.nicrc") or return;
	while(<$cfh>) {
		if(/^(\w+)\s*=\s*\"(.*)\"$/) {
			my $key = $1;
			my $value = $2;
			$CONFIG{$key} = $value;
		}
	}
}
