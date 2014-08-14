package Logos::Function;
use strict;

sub new {
	my $proto = shift;
	my $function = ref($proto) || $proto;
	my $self = {};
	$self->{NAME} = undef;
	$self->{RETVAL} = undef;
	$self->{ARGS} = [];
	$self->{GROUP} = undef;
	bless($self, $function);
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

sub retval {
	my $self = shift;
	if(@_) { $self->{RETVAL} = shift; }
	return $self->{RETVAL};
}

sub args {
	my $self = shift;
	return $self->{ARGS};
}

sub group {
	my $self = shift;
	if(@_) { $self->{GROUP} = shift; }
	return $self->{GROUP};
}

##### #
# END #
# #####

sub addArg {
	my $self = shift;
	my $arg = shift;
	push(@{$self->{ARGS}}, $arg);
}

1;
