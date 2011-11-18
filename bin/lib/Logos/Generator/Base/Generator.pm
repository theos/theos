package Logos::Generator::Base::Generator;
use strict;

sub findPreamble {
	#shift;
	#shift;
	#my $aref = shift;
	# Search for a preamble in $aref!
	return 1;
}

sub preamble {
	return ""; # Or whatever you want to plaster to the top of the file.
}

sub generateClassList {
	my $self = shift;
	my $return = "";
	map $return .= "\@class $_; ", @_;
	return $return;
}

sub classReferenceWithScope {
	my $self = shift;
	my $classname = shift;
	my $scope = shift;
	my $prefix = Logos::sigil($scope eq "+" ? "static_metaclass" : "static_class");
	return $prefix.$classname;
}

1;
