package Generator;
use strict;
use Logos::BaseGenerator;
@Method::ISA = ('BaseGenerator');

sub findPreamble {
	shift;
	my $aref = shift;
	my @matches = grep(/\s*#\s*include\s*[<"]substrate\.h[">]/, @$aref);
	return @matches > 0;
}

sub preamble {
	shift;
	return "#include <substrate.h>";
}

sub generateClassList {
	shift;
	my $return = "";
	map $return .= "\@class $_; ", @_;
	return $return;
}

sub classReferenceWithScope {
	shift;
	my $classname = shift;
	my $scope = shift;
	my $prefix = "\$";
	if($scope eq "+") {
		$prefix = "\$meta\$";
	}
	return $prefix.$classname;
}

1;
