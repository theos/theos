package Generator;
use strict;

sub generateClassList {
	shift;
	my $return = "";
	map $return .= "\@class $_; ", @_;
	return $return;
}

1;
