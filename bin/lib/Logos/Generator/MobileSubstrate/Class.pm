package Class;
use strict;
use Logos::BaseClass;
@Class::ISA = ('BaseClass');

sub declarations {
	my $self = shift;
	my $return = "";
	if($self->{OVERRIDDEN}) {
		$return .= "static Class ".$self->variable.", ".$self->metaVariable."; ";
	}
	foreach(@{$self->{METHODS}}) {
		$return .= $_->declarations;
	}
	return $return;
}

sub initializers {
	my $self = shift;
	my $return = "";
	if($self->{OVERRIDDEN}) {
		$return .= $_->variable." = ".$self->_initExpr."; ";
		$return .= $_->metaVariable." = ".$self->_metaInitExpr."; ";
	} else {
		if($self->{INST} || $self->{META}) {
			$return .= "Class ".$self->variable." = ".$self->_initExpr."; ";
		}
		if($self->{META}) {
			$return .= "Class ".$self->metaVariable." = ".$self->_metaInitExpr."; ";
		}
	}
	foreach(@{$self->{METHODS}}) {
		$return .= $_->initializers;
	}
	return $return;
}

1;
