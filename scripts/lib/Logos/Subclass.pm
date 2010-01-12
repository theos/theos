package Subclass;
use Logos::Group;
@ISA = "Group";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	$self->{CLASS} = undef;
	$self->{SUPERCLASS} = undef;
	$self->{PROTOCOLS} = {};
	$self->explicit(0);
	bless($self, $class);
	return $self;
}

##################### #
# Setters and Getters #
# #####################
sub class {
	my $self = shift;
	if(@_) { $self->{CLASS} = shift; }
	return $self->{CLASS};
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

sub initializers {
	my $self = shift;
	my $return = "";
	$self->initialized(1);
	$return .= "{ \$".$self->class." = objc_allocateClassPair(objc_getClass(\"".$self->superclass."\"), \"".$self->class."\", 0); ";
	# <ivars>
	# </ivars>
	foreach(keys %{$self->{PROTOCOLS}}) {
		$return .= "class_addProtocol(\$".$self->class.", objc_getProtocol(\"$_\")); ";
	}
	$return .= "objc_registerClassPair(\$".$self->class."); ";
	foreach(keys %{$self->{USEDCLASSES}}) {
		$return .= "Class \$\$$_ = \$$_; ";
	}
	foreach(keys %{$self->{USEDMETACLASSES}}) {
		$return .= "Class \$\$meta\$$_ = object_getClass(\$\$$_); ";
	}
	foreach(@{$self->{METHODS}}) {
		$return .= $_->buildHookCall;
	}
	$return .= "}";
	return $return;
}

1;
