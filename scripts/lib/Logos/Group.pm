package Group;
use Logos::Class;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{NAME} = undef;
	$self->{EXPLICIT} = 1;
	$self->{INITIALIZED} = 0;
	$self->{CLASSES} = [];
	bless($self, $class);
	return $self;
}

##################### #
# Setters and Getters #
# #####################
sub name {
	my $self = shift;
	if(@_) { $self->{NAME} = shift; }
	return $self->{NAME};
}

sub explicit {
	my $self = shift;
	if(@_) { $self->{EXPLICIT} = shift; }
	return $self->{EXPLICIT};
}

sub initialized {
	my $self = shift;
	if(@_) { $self->{INITIALIZED} = shift; }
	return $self->{INITIALIZED};
}
##### #
# END #
# #####

sub addClass {
	my $self = shift;
	my $name = shift;

	my $class = $self->getClass($name);
	return $class if defined($class);

	$class = Class->new();
	$class->name($name);
	push(@{$self->{CLASSES}}, $class);
	return $class;
}

sub getClass {
	my $self = shift;
	my $name = shift;
	foreach(@{$self->{CLASSES}}) {
		return $_ if $_->name eq $name;
	}
	return undef;
}

sub initializers {
	my $self = shift;
	my $return = "";
	$self->initialized(1);
	$return .= "{";
	foreach(@{$self->{CLASSES}}) {
		$return .= $_->initializers;
	}
	$return .= "}";
	return $return;
}

1;
