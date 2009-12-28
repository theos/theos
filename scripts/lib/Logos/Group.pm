package Group;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{NAME} = undef;
	$self->{EXPLICIT} = 1;
	$self->{INITIALIZED} = 0;
	$self->{HOOKS} = [];
	$self->{NUM_HOOKS} = 0;
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

sub addHook {
	my $self = shift;
	my $hook = shift;
	push(@{$self->{HOOKS}}, $hook);
	$self->{NUM_HOOKS}++;
}

sub initializers {
	my $self = shift;
	my $return = "";
	$self->initialized(1);
	$return .= "{";
	foreach(@{$self->{HOOKS}}) {
		$return .= $_->buildHookCall;
	}
	$return .= "}";
	return $return;
}

1;
