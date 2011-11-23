package Logos::Generator::Base::Group;
use strict;

sub declarations {
	my $self = shift;
	my $group = shift;
	my $return = "";
	foreach(@{$group->classes}) {
		$return .= Logos::Generator::for($_)->declarations;
	}
	return $return;
}

sub initializers {
	my $self = shift;
	my $group = shift;
	my $return = "{";
	foreach(@{$group->classes}) {
		$return .= Logos::Generator::for($_)->initializers;
	}
	$return .= "}";
	return $return;
}

1;
