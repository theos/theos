package Class;
use strict;
use Logos::BaseClass;
@Class::ISA = ('BaseClass');

# TODO: If overridden, store a global variable.
sub declarations {
	my $self = shift;
	my $return = "";
	foreach(@{$self->{METHODS}}) {
		$return .= $_->declarations;
	}
	return $return;
}

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
