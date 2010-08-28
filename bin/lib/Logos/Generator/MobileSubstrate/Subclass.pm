package Subclass;
use Logos::Generator::MobileSubstrate::Class;
use Logos::BaseSubclass;
@Subclass::ISA = ('Class', 'BaseSubclass');

sub initializers {
	my $self = shift;
	my $return = "";
	$return .= "{ \$".$self->name." = objc_allocateClassPair(objc_getClass(\"".$self->superclass."\"), \"".$self->name."\", 0); ";
	# <ivars>
	foreach(@{$self->{IVARS}}) {
		$return .= $_->initializers;
	}
	# </ivars>
	foreach(keys %{$self->{PROTOCOLS}}) {
		$return .= "class_addProtocol(\$".$self->name.", objc_getProtocol(\"$_\")); ";
	}
	$return .= "objc_registerClassPair(\$".$self->name."); ";
	$return .= $self->SUPER::initializers;
	$return .= "}";
	return $return;
}

1;
