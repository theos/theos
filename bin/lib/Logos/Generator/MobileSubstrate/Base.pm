package Generator;
use strict;

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
