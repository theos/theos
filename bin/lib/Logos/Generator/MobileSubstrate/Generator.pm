package Logos::Generator::MobileSubstrate;
use strict;
use Logos::Generator;
our @ISA = ('Logos::Generator');

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
	my $prefix = Logos::sigil($scope eq "+" ? "static_metaclass" : "static_class");
	return $prefix.$classname;
}

1;
