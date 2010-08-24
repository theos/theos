#!/usr/bin/perl

use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";

use Module::Load::Conditional 'can_load';

$nicfile = $ARGV[0] if($ARGV[0]);
$outputdir = $ARGV[1];
if(!$nicfile || !$outputdir) {
	exitWithError("Syntax: $0 nicfile outputdir");
}

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

$NIC->build($outputdir);
$NIC->dumpPreamble("pre.NIC");

sub exitWithError {
	my $error = shift;
	print STDERR "[error] ", $error, $/;
	exit 1;
}
