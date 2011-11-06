package Class;
use strict;
use Logos::BaseClass;
@Class::ISA = ('BaseClass');

sub superVariable {
	my $self = shift;
	return $self->variable."\$S";
}

sub superMetaVariable {
	my $self = shift;
	return $self->metaVariable."\$S";
}

sub declarations {
	my $self = shift;
	my $return = "";
	if($self->{OVERRIDDEN}) {
		$return .= "static Class ".$self->variable.", ".$self->metaVariable."; ";
	}
	if($self->hasinstancehooks) {
		$return .= "static Class ".$self->superVariable."; ";
	}
	if($self->hasmetahooks) {
		$return .= "static Class ".$self->superMetaVariable."; ";
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
		if($self->hasinstancehooks || $self->hasmetahooks) {
			$return .= "Class ".$self->variable." = ".$self->_initExpr."; ";
		}
		if($self->hasmetahooks) {
			$return .= "Class ".$self->metaVariable." = ".$self->_metaInitExpr."; ";
		}
	}
	if ($self->hasinstancehooks) {
		$return .= $self->superVariable." = class_getSuperclass(".$self->variable."); ";
	}
	if ($self->hasmetahooks) {
		$return .= $self->superMetaVariable." = class_getSuperclass(".$self->metaVariable."); ";
	}
	foreach(@{$self->{METHODS}}) {
		$return .= $_->initializers;
	}
	return $return;
}

1;
