package NIC::NICBase::Directory;
use parent NIC::NICType;
use strict;
use File::Path "make_path";

sub type {
	my $self = shift;
	return NIC::NICType::TYPE_DIRECTORY;
}

sub _mode {
	return 0755;
}

sub create {
	my $self = shift;
	make_path($self->{OWNER}->substituteVariables($self->{NAME}), { mode => $self->mode }) or return 0;
	return 1;
}


1;

