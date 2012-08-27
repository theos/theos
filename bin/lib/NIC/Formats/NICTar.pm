package NIC::Formats::NICTar;
use parent NIC::NICBase;
use strict;
use NIC::Formats::NICTar::File;
use NIC::Formats::NICTar::Directory;
use NIC::Formats::NICTar::Symlink;
use Archive::Tar;
$Archive::Tar::WARN = 0;

sub new {
	my $proto = shift;
	my $fh = shift;
	my $class = ref($proto) || $proto;

	my $tar = Archive::Tar->new($fh);
	return undef if(!$tar);

	my @_controls = $tar->get_files("./NIC/control", "NIC/control");
	my $control = (scalar @_controls > 0) ? $_controls[0] : undef;
	return undef if(!$control);

	my $self = NIC::NICBase->new();
	$self->{_TAR} = $tar;
	bless($self, $class);

	$self->_processData($control->get_content);
	$self->load();

	return $self;
}

sub _fileClass { "NIC::Formats::NICTar::File"; }
sub _directoryClass { "NIC::Formats::NICTar::Directory"; }
sub _symlinkClass { "NIC::Formats::NICTar::Symlink"; }

sub _processData {
	my $self = shift;
	my $data = shift;
	for(split /\n\r?/, $data) {
		$self->_processLine($_);
	}
}

sub _processLine {
	my $self = shift;
	local $_ = shift;
	if(/^name\s+\"(.*)\"$/ || /^name\s+(.*)$/) {
		$self->name($1);
	} elsif(/^prompt (\w+) \"(.*?)\"( \"(.*?)\")?$/) {
		my $key = $1;
		my $prompt = $2;
		my $default = $4 || undef;
		$self->registerPrompt($key, $prompt, $default);
	} elsif(/^constrain (file )?\"(.+)\" to (.+)$/) {
		my $constraint = $2;
		my $filename = $1;
		$self->registerFileConstraint($filename, $constraint);
	}
}

sub load {
	my $self = shift;
	for($self->{_TAR}->get_files()) {
		next if !$_->name || $_->name =~ /^(\.\/)?NIC/;
		my $n = $_->name;
		$n =~ s/^\.\///;
		next if length $n == 0;
		if($_->is_dir) {
			my $ref = $self->registerDirectory($n);
			$ref->tarfile($_);
		} elsif($_->is_symlink) {
			my $target = $_->linkname;
			$target =~ s/^\.\///;

			my $ref = $self->registerSymlink($n, $target);
			$ref->tarfile($_);
		} elsif($_->is_file) {
			my $ref = $self->registerFile($n);
			$ref->tarfile($_);
		}
	}
}

1;
