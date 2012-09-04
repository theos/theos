package NIC::Bridge::Symlink;
use strict;
use warnings;
use parent qw(NIC::Bridge::NICType);
use NIC::Tie::Method;

sub target :lvalue {
	my $self = shift;
	tie my $tied, 'NIC::Tie::Method', $self->{FOR}, "target";
	$tied;
}

1;
