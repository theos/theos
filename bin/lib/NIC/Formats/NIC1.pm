package NIC1;

sub new {
	my $proto = shift;
	my $fh = shift;
	$class = ref($proto) || $proto;
	my $self = {};
	$self->{NAME} = undef;
	$self->{DIRECTORIES} = ();
	$self->{FILES} = {};
	$self->{SYMLINKS} = {};
	$self->{VARIABLES} = {};
	$self->{PROMPTS} = ();
	bless($self, $class);
	$self->_load($fh);
	return $self;
}

sub _processLine {
	my $self = shift;
	my $fh = shift;
	local $_ = shift;
	if(/^name \"(.*)\"$/) {
		$self->{NAME} = $1;
	} elsif(/^dir (.+)$/) {
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
	} elsif(/^prompt (\w+) \"(.*?)\"( \"(.*?)\")?$/) {
		my $key = $1;
		my $prompt = $2;
		my $default = $4 || undef;
		$self->_addPrompt($key, $prompt, $default);
	} elsif(/^symlink \"(.+)\" \"(.+)\"$/) {
		my $name = $1;
		my $dest = $2;
		$self->{SYMLINKS}->{$name} = $dest;
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

sub name {
	my $self = shift;
	return $self->{NAME};
}

sub prompts {
	my $self = shift;
	return @{$self->{PROMPTS}};
}

sub _addPrompt {
	my($self, $key, $prompt, $default) = @_;
	push(@{$self->{PROMPTS}}, {
			name => $key,
			prompt => $prompt,
			default => $default
		});
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
	foreach $symlink (keys %{$self->{SYMLINKS}}) {
		my $name = $self->_substituteVariables($symlink);
		my $dest = $self->_substituteVariables($self->{SYMLINKS}->{$symlink});
		symlink($dest, $name);
	}
}

sub dumpPreamble {
	my $self = shift;
	my $preamblefn = shift;
	open(my $pfh, ">", $preamblefn);
	print $pfh "name \"".$self->{NAME}."\"",$/;
	foreach my $prompt (@{$self->{PROMPTS}}) {
		print $pfh "prompt ".$prompt->{name}." \"".$prompt->{prompt}."\"";
		print $pfh " \"".$prompt->{default}."\"" if defined $prompt->{default};
		print $pfh $/;
	}
	close($pfh);
}

1;
