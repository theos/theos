package NIC::NICBase::Symlink;
use parent NIC::NICType;
use strict;

sub _take_init {
	my $self = shift;
	$self->{TARGET} = shift // undef;
}

sub type {
	my $self = shift;
	return NIC::NICType::TYPE_SYMLINK;
}

sub target {
	my $self = shift;
	if(@_) { $self->{TARGET} = shift; }
	return $self->{TARGET};
}

sub create {
	my $self = shift;
	my $name = $self->{OWNER}->substituteVariables($self->{NAME});
	my $dest = $self->{OWNER}->substituteVariables($self->{TARGET});
	symlink($dest, $name) or return 0;
	return 1;
}

1;

