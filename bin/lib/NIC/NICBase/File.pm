package NIC::NICBase::File;
use parent NIC::NICType;
use strict;

sub type {
	my $self = shift;
	return NIC::NICType::TYPE_FILE;
}

sub create {
	return 0;
}

1;
