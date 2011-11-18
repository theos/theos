package Logos::Generator::MobileSubstrate::Class;
use strict;
use parent qw(Logos::Generator::Base::Class);

sub declarations {
	my $self = shift;
	my $class = shift;
	my $return = "";
	if($class->overridden) {
		$return .= "static Class ".$self->variable($class).", ".$self->metaVariable($class)."; ";
	}
	$return .= $self->SUPER::declarations($class);
	return $return;
}

sub initializers {
	my $self = shift;
	my $class = shift;
	my $return = "";
	if($class->overridden) {
		$return .= $self->variable($class)." = ".$self->_initExpression($class)."; ";
		$return .= $self->metaVariable($class)." = ".$self->_metaInitExpression($class)."; ";
	} else {
		if($class->hasinstancehooks || $class->hasmetahooks) {
			$return .= "Class ".$self->variable($class)." = ".$self->_initExpression($class)."; ";
		}
		if($class->hasmetahooks) {
			$return .= "Class ".$self->metaVariable($class)." = ".$self->_metaInitExpression($class)."; ";
		}
	}
	$return .= $self->SUPER::initializers($class);
	return $return;
}

1;
