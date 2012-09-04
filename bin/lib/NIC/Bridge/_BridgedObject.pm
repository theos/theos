package NIC::Bridge::_BridgedObject;
use strict;
use warnings;

use overload '""' => sub {
	my $self = shift;
	return "[".($self->{FOR}//"(undefined)")."]";
};

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $context = shift;
	my $wrapped = shift;
	my $self = { CONTEXT => $context, FOR => $wrapped };
	bless($self, $proto);
	return $self;
}


1;
