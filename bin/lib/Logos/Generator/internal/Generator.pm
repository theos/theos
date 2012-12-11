package Logos::Generator::internal::Generator;
use strict;
use parent qw(Logos::Generator::Base::Generator);

sub findPreamble {
	shift;
	my $aref = shift;
	my @matches = grep(/\s*#\s*include\s*[<"]objc\/message\.h[">]/, @$aref);
	return @matches > 0;
}

sub preamble {
	my $self = shift;
	return join("\n", ($self->SUPER::preamble(), "#include <objc/message.h>"));
}

1;
