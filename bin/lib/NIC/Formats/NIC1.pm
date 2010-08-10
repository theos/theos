package NIC1;

sub new {
	my $proto = shift;
	my $fh = shift;
	$class = ref($proto) || $proto;
	my $self = {};
	$self->{DIRECTORIES} = ();
	$self->{FILES} = {};
	$self->{VARIABLES} = {};
	bless($self, $class);
	$self->_load($fh);
	return $self;
}

sub _processLine {
	my $self = shift;
	my $fh = shift;
	my $_ = shift;
	if(/^dir (.+)$/) {
		push(@{$self->{DIRECTORIES}}, $1);
	} elsif(/^file (\d+) (.+)$/) {
		my $lines = $1;
		my $filename = $2;
		my $filedata = "";
		while($lines > 0) {
			$filedata .= <$fh>;
			$lines--;
		}
		$self->{FILES}->{$filename} = $filedata;
	}
}

sub _load {
	my $self = shift;
	my $fh = shift;
	while(<$fh>) {
		$self->_processLine($fh, $_);
	}
}

sub set {
	my $self = shift;
	my $key = shift;
	my $value = shift;
	$self->{VARIABLES}->{$key} = $value;
}

sub get {
	my $self = shift;
	my $key = shift;
	return $self->{VARIABLES}->{$key};
}

sub _substituteVariables {
	my $self = shift;
	my $line = shift;
	foreach $key (keys %{$self->{VARIABLES}}) {
		my $value = $self->{VARIABLES}->{$key};
		$line =~ s/\@\@$key\@\@/$value/g;
	}
	return $line;
}

sub build {
	my $self = shift;
	my $dir = shift;
	mkdir($dir);
	chdir($dir) or die $!;
	foreach $subdir (@{$self->{DIRECTORIES}}) {
		mkdir $self->_substituteVariables($subdir);
	}
	foreach $filename (keys %{$self->{FILES}}) {
		open(my $nicfile, ">", $self->_substituteVariables($filename));
		print $nicfile $self->_substituteVariables($self->{FILES}->{$filename});
		close($nicfile);
	}
}


1;
