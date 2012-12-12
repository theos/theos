package Logos::Generator::Base::Generator;
use strict;

sub findPreamble {
	my $self = shift;
	my $aref = shift;
	my @matches = grep(/\s*#\s*(import|include)\s*[<"]logos\/logos\.h[">]/, @$aref);
	return @matches > 0;
}

sub preamble {
	return "#include <logos/logos.h>";
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
	my $prefix = Logos::sigil($scope eq "+" ? "static_metaclass_lookup" : "static_class_lookup");
	return $prefix.$classname."()";
}

1;
