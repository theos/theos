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
	$self->{CONSTRAINTS} = {};
	$self->{PROMPTS} = ();
	bless($self, $class);
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
		$self->{FILES}->{$filename} = {} if !defined $self->{FILES}->{$filename};
		$self->{FILES}->{$filename}->{data} = $filedata;
	} elsif(/^prompt (\w+) \"(.*?)\"( \"(.*?)\")?$/) {
		my $key = $1;
		my $prompt = $2;
		my $default = $4 || undef;
		$self->_addPrompt($key, $prompt, $default);
	} elsif(/^symlink \"(.+)\" \"(.+)\"$/) {
		my $name = $1;
		my $dest = $2;
		$self->{SYMLINKS}->{$name} = $dest;
	} elsif(/^constrain file \"(.+)\" to (.+)$/) {
		my $constraint = $2;
		my $filename = $1;
		$self->{FILES}->{$filename} = {} if !defined $self->{FILES}->{$filename};
		$self->{FILES}->{$filename}->{constraints} = () if !defined $self->{FILES}->{$filename}->{constraints};
		push(@{$self->{FILES}->{$filename}->{constraints}}, $constraint);
	}
}

sub load {
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

sub addConstraint {
	my $self = shift;
	my $constraint = shift;
	$self->{CONSTRAINTS}->{$constraint} = 1;
}

sub removeConstraint {
	my $self = shift;
	my $constraint = shift;
	delete $self->{CONSTRAINTS}->{$constraint};
}

sub _addPrompt {
	my($self, $key, $prompt, $default) = @_;
	push(@{$self->{PROMPTS}}, {
			name => $key,
			prompt => $prompt,
			default => $default
		});
}

sub _constraintMatch {
	my $self = shift;
	my $constraint = shift;
	my $negated = 0;
	if(substr($constraint, 0, 1) eq "!") {
		$negated = 1;
		substr($constraint, 0, 1, "");
	}
	return 0 if(!$negated && (!defined $self->{CONSTRAINTS}->{$constraint} || $self->{CONSTRAINTS}->{$constraint} != 1));
	return 0 if($negated && (defined $self->{CONSTRAINTS}->{$constraint} || $self->{CONSTRAINTS}->{$constraint} != 0));
	return 1;
}

sub _fileMeetsConstraints {
	my $self = shift;
	my $file = shift;
	foreach (@{$file->{constraints}}) {
		return 0 if !$self->_constraintMatch($_);
	}
	return 1;
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
		my $file = $self->{FILES}->{$filename};
		if(defined $file->{constraints}) {
			if(!$self->_fileMeetsConstraints($file)) {
				next;
			}
		}
		open(my $nicfile, ">", $self->_substituteVariables($filename));
		print $nicfile $self->_substituteVariables($file->{data});
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
	foreach $filename (keys %{$self->{FILES}}) {
		my $file = $self->{FILES}->{$filename};
		if(!defined $file->{constraints}) {
			next;
		}
		foreach (@{$file->{constraints}}) {
			print $pfh "constrain file \"".$filename."\" to ".$_,$/
		}
	}
	close($pfh);
}

1;
