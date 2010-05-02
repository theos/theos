#!/usr/bin/env perl
# logify.pl
############
# Converts an Objective-C header file (or anything containing a @interface and method definitions)
#+into a Logos input file which causes all function calls to be logged.
#
# Accepts input on stdin or via filename specified on the commandline.

# Lines are only processed if we were in an @interface, so you can run this on a file containing
# an @implementation, as well.
$interface = 0;
while($line = <>) {
	if($line =~ m/^[+-]\s*\((.*?)\).*?(?=;)/ && $interface == 1) {
		print "$& { %log; ".($1 ne "void" ? "return " : "")."%orig; }\n";
	} elsif($line =~ m/^\@interface\s+(.*?)\s*[:(]/ && $interface == 0) {
		print "%hook $1\n";
		$interface = 1;
	} elsif($line =~ m/^\@end/ && $interface == 1) {
		print "%end\n";
		$interface = 0;
	}
}

