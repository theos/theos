package Logos::Generator::Thunk;
use strict;

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://;
	my $fullyQualified = $self->{PACKAGE}."::".$method;
	unshift @_, $self->{OBJECT} if $self->{OBJECT};
	unshift @_, $self->{PACKAGE};
	goto &{$self->{PACKAGE}->can($method)};
}

sub DESTROY {
	my $self = shift;
	goto &{$self->SUPER::DESTROY};
}

sub for {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{PACKAGE} = shift;
	$self->{OBJECT} = shift;
	bless($self, $class);
	return $self;
}

1;
