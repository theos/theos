package NIC::NICBase;
use File::Path "make_path";
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{NAME} = undef;
	$self->{DIRECTORIES} = {};
	$self->{FILES} = {};
	$self->{SYMLINKS} = {};
	$self->{VARIABLES} = {};
	$self->{CONSTRAINTS} = {};
	$self->{PROMPTS} = [];
	bless($self, $class);

	return $self;
}

sub registerDirectory {
	my $self = shift;
	my $name = shift;
	$self->{DIRECTORIES}->{$name}->{NAME} = $name;
	return $self->{DIRECTORIES}->{$name};
}

sub registerFile {
	my $self = shift;
	my $name = shift;
	$self->{FILES}->{$name}->{NAME} = $name;
	return $self->{FILES}->{$name};
}

sub registerSymlink {
	my $self = shift;
	my $name = shift;
	my $target = shift;
	$self->{SYMLINKS}->{$name}->{NAME} = $name;
	$self->{SYMLINKS}->{$name}->{TARGET} = $target;
	return $self->{SYMLINKS}->{$name};
}

sub registerPrompt {
	my($self, $key, $prompt, $default) = @_;
	push(@{$self->{PROMPTS}}, {
			name => $key,
			prompt => $prompt,
			default => $default
		});
}

sub registerFileConstraint {
	my $self = shift;
	my $filename = shift;
	my $constraint = shift;
	$self->{FILES}->{$filename} = {} if !defined $self->{FILES}->{$filename};
	$self->{FILES}->{$filename}->{constraints} = () if !defined $self->{FILES}->{$filename}->{constraints};
	push(@{$self->{FILES}->{$filename}->{constraints}}, $constraint);
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
	if(@_) { $self->{NAME} = shift; }
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
	foreach my $key (keys %{$self->{VARIABLES}}) {
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
	foreach my $directory (values %{$self->{DIRECTORIES}}) {
		next if(!defined $directory->{NAME});
		$self->buildDirectory($directory);
	}
	foreach my $file (values %{$self->{FILES}}) {
		next if(!defined $file->{NAME});
		if(defined $file->{constraints}) {
			if(!$self->_fileMeetsConstraints($file)) {
				next;
			}
		}
		$self->buildFile($file);
	}
	foreach my $symlink (values %{$self->{SYMLINKS}}) {
		next if(!defined $symlink->{NAME});
		$self->buildSymlink($symlink);
	}
}

sub buildDirectory {
	my $self = shift;
	my $directory = shift;
	make_path($self->_substituteVariables($directory->{NAME}));
}

sub buildFile {
	my $self = shift;
	my $file = shift;
	my $filename = $file->{NAME};
	open(my $nicfile, ">", $self->_substituteVariables($filename));
	print $nicfile $self->_substituteVariables($file->{data});
	close($nicfile);
}

sub buildSymlink {
	my $self = shift;
	my $symlink = shift;
	my $name = $self->_substituteVariables($symlink->{NAME});
	my $dest = $self->_substituteVariables($symlink->{TARGET});
	symlink($dest, $name);
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
	foreach my $filename (keys %{$self->{FILES}}) {
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
