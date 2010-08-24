#!/usr/bin/perl

my $VER = "1.0";

use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Getopt::Long;
use Cwd 'abs_path';
use File::Spec;
use File::Find;
use File::Copy;
use User::pwent;
use POSIX qw(getuid);
use Module::Load::Conditional 'can_load';

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

my $_versionstring = "NIC $VER - New Instance Creator";
print $_versionstring,$/;
print "-" x length($_versionstring),$/;

$template = $nicfile if $nicfile ne "";
if(!$template) {
	$template = promptList(undef, "Choose a Template (required)", @templates);
}
$nicfile = "$_templatepath/$template.nic" if $nicfile eq "";
exitWithError("Couldn't open template at path $nicfile") if(! -f $nicfile);

### LOAD THE NICFILE! ###
open(my $nichandle, "<", $nicfile);
my $line = <$nichandle>;
my $nicversion = 1;
if($line =~ /^nic (\w+)$/) {
	$nicversion = $1;
}
seek($nichandle, 0, 0);

my $NICPackage = "NIC$nicversion";
exitWithError("I don't understand NIC version $nicversion!") if(!can_load(modules => {"NIC::Formats::$NICPackage" => undef}));
my $NIC = $NICPackage->new();
$NIC->load($nichandle);
close($nichandle);
### YAY! ###

promptIfMissing(\$project_name, undef, "Project Name (required)");
exitWithError("I can't live without a project name! Aieeee!") if !$project_name;
$clean_project_name = cleanProjectName($project_name);

$package_name = $package_prefix.".".packageNameIze($project_name) if $CONFIG{'skip_package_name'};
promptIfMissing(\$package_name, $package_prefix.".".packageNameIze($project_name), "Package Name");

promptIfMissing(\$username, getUserName(), "Author/Maintainer Name");

my $directory = lc($clean_project_name);
if(-d $directory) {
	my $response;
	promptIfMissing(\$response, "N", "There's already something in $directory. Continue");
	exit 1 if(uc($response) eq "N");
}

$NIC->set("FULLPROJECTNAME", $project_name);
$NIC->set("PROJECTNAME", $clean_project_name);
$NIC->set("PACKAGENAME", $package_name);
$NIC->set("USER", $username);

$NIC->addConstraint("package");

foreach $prompt ($NIC->prompts) {
	# Do we want to import these variables into the NIC automatically? In the format name.VARIABLE?
	# If so, this could become awesome. We could $NIC->get($prompt->{name})
	# and have loaded the variables in a loop beforehand.
	# This would also allow the user to set certain variables (package prefix, username) for different templates.
	my $response = $CONFIG{$NIC->name().".".$prompt->{name}} || undef;
	promptIfMissing(\$response, $prompt->{default}, $prompt->{prompt});
	$NIC->set($prompt->{name}, $response);
}

print "Instantiating $template in ".lc($clean_project_name)."/...",$/;
my $dirname = lc($clean_project_name);
$NIC->build($dirname);
symlink($_theospath, "theos");
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

sub loadConfig {
	open(my $cfh, "<", getHomeDir()."/.nicrc") or return;
	while(<$cfh>) {
		if(/^(.+?)\s*=\s*\"(.*)\"$/) {
			my $key = $1;
			my $value = $2;
			$CONFIG{$key} = $value;
		}
	}
}
