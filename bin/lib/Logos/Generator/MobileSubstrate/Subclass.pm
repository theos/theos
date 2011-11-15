package Logos::Generator::MobileSubstrate::Subclass;
use strict;
use Logos::Generator::MobileSubstrate::Class;
use Logos::Subclass;
our @ISA = ('Logos::Subclass', 'Logos::Generator::MobileSubstrate::Class');

# declarations is inherited from Class.

sub initExpr {
	my $self = shift;
	return "objc_allocateClassPair(objc_getClass(\"".$self->superclass."\"), \"".$self->name."\", 0)";
}

sub declarations {
	my $self = shift;
	return $self->Logos::Generator::MobileSubstrate::Class::declarations;
}

sub initializers {
	my $self = shift;
	my $return = "";
	$return .= "{ ";
	$return .= $self->Logos::Generator::MobileSubstrate::Class::initializers." ";
	# <ivars>
	foreach(@{$self->{IVARS}}) {
		$return .= $_->initializers;
	}
	# </ivars>
	foreach(keys %{$self->{PROTOCOLS}}) {
		$return .= "class_addProtocol(".$self->variable.", objc_getProtocol(\"$_\")); ";
	}
	$return .= "objc_registerClassPair(".$self->variable."); ";
	$return .= ::Generator->classReferenceWithScope($self->name, "-")." = ".$self->variable.";";
	$return .= "}";
	return $return;
}

1;
