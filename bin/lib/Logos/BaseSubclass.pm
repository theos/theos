package BaseSubclass;
use Logos::BaseClass;
@ISA = "BaseClass";

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
	::fileError(-1, "Generator hasn't implemented Subclass::initializers :(");
	return "";
}

1;
