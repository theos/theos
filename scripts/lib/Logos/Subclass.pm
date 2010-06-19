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
	print STDERR $self->{CLASSES};
	foreach(@{$self->{CLASSES}}) {
		$return .= $_->initializers;
	}
	$return .= "}";
	return $return;
}

1;
