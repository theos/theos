package Logos::Generator::internal::Generator;
use strict;
use parent qw(Logos::Generator::Base::Generator);

sub findPreamble {
	my $self = shift;
	my $aref = shift;
	my @matches = grep(/\s*#\s*(import|include)\s*[<"]objc\/message\.h[">]/, @$aref);
	return $self->SUPER::findPreamble($aref) && @matches > 0;
}

sub preamble {
	my $self = shift;
	my $skipIncludes = shift;
	if ($skipIncludes) {
		return $self->SUPER::preamble();
	} else {
		return join("\n", ($self->SUPER::preamble(), "#include <objc/message.h>"));
	}
}

1;
