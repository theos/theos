package Class;
use strict;
use Logos::BaseClass;
@Class::ISA = ('BaseClass');

sub initializers {
	my $self = shift;
	my $return = "";
	$return .= "Class \$\$".$self->{NAME}." = ".$self->expression."; " if $self->{INST} or $self->{META};
	$return .= "Class \$\$meta\$".$self->{NAME}." = ".$self->metaexpression."; " if $self->{META};
	foreach(@{$self->{METHODS}}) {
		$return .= $_->initializers;
	}
	return $return;
}

1;
