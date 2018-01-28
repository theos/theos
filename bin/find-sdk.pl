#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use File::Basename;

my $platform_name;
my $theos_sdks_path = "/dev/null";
my $toolchain_sdks_path = "/dev/null";
GetOptions("platform|p=s" => \$platform_name,
	"theos-sdks-path|t=s" => \$theos_sdks_path,
	"toolchain-sdks-path|c=s" => \$toolchain_sdks_path);

die("This script is not meant to be used directly.") if not defined $platform_name;

my %sdks;

while(my $path = glob("{".$toolchain_sdks_path.",".$theos_sdks_path."}/".$platform_name."*.*.sdk")) {
	$sdks{fileparse($path)} = 1;
}

my @final_paths = ();

foreach my $sdk (keys %sdks) {
	my $path;
	push(@final_paths, $toolchain_sdks_path."/".$sdk) if(-d $toolchain_sdks_path."/".$sdk);
	push(@final_paths, $theos_sdks_path."/".$sdk) if(-d $theos_sdks_path."/".$sdk);
}

my @sorted_paths = sort { ($b =~ /(\d+\.\d+)\.sdk$/)[0] <=> ($a =~ /(\d+\.\d+)\.sdk$/)[0] } @final_paths;

print "@sorted_paths\n";
