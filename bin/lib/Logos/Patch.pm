package Logos::Patch;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{LINE} = -1;
	$self->{RANGE} = [];
	$self->{SUBREF} = undef;
	bless($self, $class);
	return $self;
}

##################### #
# Setters and Getters #
# #####################
sub line {
	my $self = shift;
	if(@_) { $self->{LINE} = shift; }
	return $self->{LINE};
}

sub range {
	my $self = shift;
	if(@_) { @{$self->{RANGE}} = @_; }
	return $self->{RANGE};
}

sub start {
	my $self = shift;
	if(@_) { $self->{RANGE}[0] = shift; }
	return $self->{RANGE}[0];
}

sub end {
	my $self = shift;
	if(@_) { $self->{RANGE}[1] = shift; }
	return $self->{RANGE}[1];
}

sub subref {
	my $self = shift;
	if(@_) { $self->{SUBREF} = shift; }
	return $self->{SUBREF};
}

##### #
# END #
# #####

1;
