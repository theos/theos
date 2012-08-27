package NIC::NICBase::Directory;
use parent NIC::NICType;
use strict;
use File::Path "make_path";

sub type {
	my $self = shift;
	return NIC::NICType::TYPE_DIRECTORY;
}

sub create {
	my $self = shift;
	make_path($self->{OWNER}->substituteVariables($self->{NAME})) || return 0;
	return 1;
}


1;

