#!/usr/bin/perl

use warnings;

$nicfile = $ARGV[0] if($ARGV[0]);
$outputdir = $ARGV[1];
die if !$nicfile || !$outputdir;

buildNic($nicfile, $outputdir);
sub buildNic {
	my $template = shift;
	my $dir = shift;
	mkdir($dir);
	open(my($fh), "<", "$nicfile") or die $!;
	chdir($dir) or die $!;
	while(<$fh>) {
		if(/^dir (.+)$/) {
			mkdir($1);
		} elsif(/^file (\d+) (.+)$/) {
			my $lines = $1;
			my $filename = $2;
			open(my($nicfile), ">", "./$filename");
			while($lines > 0) {
				my $line = <$fh>;
				print $nicfile ($line);
				$lines--;
			}
			close($nicfile);
		}
	}
}
