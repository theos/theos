package NIC::Formats::NIC1::File;
use parent NIC::NICBase::File;
use strict;

sub _take_init {
	my $self = shift;
	$self->{DATA} = undef;
}

sub data {
	my $self = shift;
	my $data = shift;
	$self->{DATA} = $data;
}

sub create {
	my $self = shift;
	my $filename = $self->{OWNER}->substituteVariables($self->name);
	open(my $nicfile, ">", $filename) or return 0;
	print $nicfile $self->{OWNER}->substituteVariables($self->{DATA});
	close($nicfile);
	chmod($self->mode, $filename);
	return 1;
}

1;
