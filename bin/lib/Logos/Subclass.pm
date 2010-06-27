package Subclass;
use Logos::Class;
@ISA = "Class";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	$self->{SUPERCLASS} = undef;
	$self->{PROTOCOLS} = {};
	$self->{IVARS} = [];
	bless($self, $class);
	return $self;
}

##################### #
# Setters and Getters #
# #####################
sub name {
	my $self = shift;
	if(@_) {
		$self->{NAME} = shift;
		$self->expression("\$".$self->{NAME});
		$self->metaexpression("object_getClass(\$".$self->{NAME}.")");
	}
	return $self->{NAME};
}

sub superclass {
	my $self = shift;
	if(@_) { $self->{SUPERCLASS} = shift; }
	return $self->{SUPERCLASS};
}
##### #
# END #
# #####

sub addProtocol {
	my $self = shift;
	my $protocol = shift;
	$self->{PROTOCOLS}{$protocol}++;
}

sub addIvar {
	my $self = shift;
	my $ivar = shift;
	$ivar->class($self);
	push(@{$self->{IVARS}}, $ivar);
}

sub getIvarNamed {
	my $self = shift;
	my $name = shift;
	foreach(@{$self->{IVARS}}) {
		return $_ if $_->name eq $name;
	}
	return undef;
}

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
