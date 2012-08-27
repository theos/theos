package NIC::Formats::NICTar::Directory;
use parent NIC::NICBase::Directory;
use strict;
use File::Path "make_path";

sub _take_init {
	my $self = shift;
	$self->SUPER::_take_init(@_);
	$self->{TARFILE} = undef;
}

sub tarfile {
	my $self = shift;
	if(@_) { $self->{TARFILE} = shift; }
	return $self->{TARFILE};
}

sub create {
	my $self = shift;
	my $dirname = $self->{OWNER}->substituteVariables($self->{NAME});
	make_path($dirname, { mode => $self->{TARFILE}->mode });
}

1;
