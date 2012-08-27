package NIC::Formats::NICTar::File;
use parent NIC::NICBase::File;
use strict;

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
	my $filename = $self->{OWNER}->substituteVariables($self->{NAME});
	open(my $nicfile, ">", $filename);
	syswrite $nicfile, $self->{OWNER}->substituteVariables($self->{TARFILE}->get_content);
	close($nicfile);
	chmod($self->{TARFILE}->mode, $filename);
}

1;
