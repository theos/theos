package Logos::Property;
use strict;

##################### #
# Setters and Getters #
# #####################

sub new{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{CLASS} = undef;
	$self->{GROUP} = undef;
	$self->{NAME} = undef;
	$self->{TYPE} = undef;
	$self->{NUMATTR} = undef;
	$self->{ASSOCIATIONPOLICY} = undef;
	$self->{ATTRIBUTES} = [];
	bless($self, $class);
	return $self;
}

sub class {
	my $self = shift;
	if(@_) { $self->{CLASS} = shift; }
	return $self->{CLASS};
}

sub group {
	my $self = shift;
	if(@_) { $self->{GROUP} = shift; }
	return $self->{GROUP};
}

sub name {
	my $self = shift;
	if(@_) { $self->{NAME} = shift; }
	return $self->{NAME};
}

sub type {
	my $self = shift;
	if(@_) { $self->{TYPE} = shift; }
	return $self->{TYPE};
}

sub numattr {
	my $self = shift;
	if(@_) { $self->{NUMATTR} = shift; }
	return $self->{NUMATTR};
}

sub attributes {
	my $self = shift;
	if(@_) { @{$self->{ATTRIBUTES}} = @_; }
	return $self->{ATTRIBUTES};
}

sub associationPolicy {
	my $self = shift;
	if (@_) { $self->{ASSOCIATIONPOLICY} = shift; }
	return $self->{ASSOCIATIONPOLICY};
}

##### #
# END #
# #####

1;
