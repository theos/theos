package NIC::Formats::NICTar::File;
use parent qw(NIC::Formats::NICTar::_TarMixin NIC::NICBase::File);
use strict;

sub _take_init {
	my $self = shift;
	$self->NIC::NICBase::File::_take_init(@_);
	$self->NIC::Formats::NICTar::_TarMixin::_take_init(@_);
}

sub create {
	my $self = shift;
	my $filename = $self->{OWNER}->substituteVariables($self->{NAME});
	open(my $nicfile, ">", $filename) or return 0;
	syswrite $nicfile, $self->{OWNER}->substituteVariables($self->{TARFILE}->get_content);
	close($nicfile);
	chmod($self->mode, $filename);
	return 1;
}

1;
