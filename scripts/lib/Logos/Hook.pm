package Hook;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{CLASS} = undef;
	$self->{SCOPE} = undef;
	$self->{RETURN} = undef;
	$self->{SELECTOR} = undef;
	$self->{NEW_SELECTOR} = undef;
	$self->{SELPARTS} = [];
	$self->{ARGNAMES} = [];
	$self->{ARGTYPES} = [];
	$self->{NUM_ARGS} = 0;
	bless($self, $class);
	return $self;
}

sub class {
	my $self = shift;
	if(@_) { $self->{CLASS} = shift; }
	return $self->{CLASS};
}

sub scope {
	my $self = shift;
	if(@_) { $self->{SCOPE} = shift; }
	return $self->{SCOPE};
}

sub return {
	my $self = shift;
	if(@_) { $self->{RETURN} = shift; }
	return $self->{RETURN};
}

sub selector {
	my $self = shift;
	if(@_) { $self->{SELECTOR} = shift; }
	return $self->{SELECTOR};
}

sub new_selector {
	my $self = shift;
	if(@_) { $self->{NEW_SELECTOR} = shift; }
	return $self->{NEW_SELECTOR};
}

sub selparts {
	my $self = shift;
	if(@_) { @{$self->{SELPARTS}} = @_; }
	return @{$self->{SELPARTS}};
}

sub argnames {
	my $self = shift;
	if(@_) { @{$self->{ARGNAMES}} = @_; }
	return @{$self->{ARGNAMES}};
}

sub argtypes {
	my $self = shift;
	if(@_) { @{$self->{ARGTYPES}} = @_; }
	return @{$self->{ARGTYPES}};
}

sub addArgument {
	my $self = shift;
	my ($type, $name) = @_;
	push(@{$self->{ARGTYPES}}, $type);	
	push(@{$self->{ARGNAMES}}, $name);
	$self->{NUM_ARGS}++;
}

sub setSelectorParts {
	my $self = shift;
	my @selparts = @_;
	if(@selparts == 1) {
		$self->{SELECTOR} = $selparts[0];
		$self->{NEW_SELECTOR} = $selparts[0];
	} else {
		$self->{SELECTOR} = join(":", @selparts).":";
		$self->{NEW_SELECTOR} = join("\$", @selparts)."\$";
	}
	@{$self->{SELPARTS}} = @selparts;
}

sub originalFunctionName {
	my $self = shift;
	return "_".$self->{CLASS}."\$".$self->{NEW_SELECTOR};
}

sub newFunctionName {
	my $self = shift;
	return "\$".$self->{CLASS}."\$".$self->{NEW_SELECTOR};
}

sub buildHookFunction {
	my $self = shift;
	my $build = "";
	#$build = "META" if $scope eq "class";
	$build .= "static ".$self->{RETURN}." (*".$self->originalFunctionName.")(".$self->{CLASS}." *, SEL"; 
	my $argtypelist = join(", ", @{$self->{ARGTYPES}});
	$build .= ", ".$argtypelist if $argtypelist;

	my $arglist = "";
	map $arglist .= ", ".$self->{ARGTYPES}[$_]." ".$self->{ARGNAMES}[$_], (0..$self->{NUM_ARGS} - 1);

	$build .= "); static ".$self->{RETURN}." ".$self->newFunctionName."(".$self->{CLASS}." *self, SEL sel".$arglist.")";
	return $build;
}

sub buildOriginalCall {
	my $self = shift;
	my ($customargs) = @_;
	my $build = $self->originalFunctionName."(self, sel";
	if($customargs) {
		$build .= ", ".$customargs;
	} elsif($self->{NUM_ARGS} > 0) {
		$build .= ", ".join(", ",@{$self->{ARGNAMES}});
	}
	$build .= ")";
	return $build;
}

sub buildHookCall {
	my $self = shift;
	return "MSHookMessageEx(\$".$self->{CLASS}.", \@selector(".$self->{SELECTOR}."), (IMP)&".$self->newFunctionName.", (IMP*)&".$self->originalFunctionName.");"
}


sub buildLogCall {
	my $self = shift;
	my $build = "NSLog(\@\"".$self->{CLASS};
	if($self->{NUM_ARGS} > 0) {
		map $build .= " ".$self->{SELPARTS}[$_].":".formatCharForArgType($self->{ARGTYPES}[$_]), (0..$self->{NUM_ARGS} - 1);
		my $argnamelist = join(", ", @{$self->{ARGNAMES}});
		$build .= "\", ".$argnamelist.")";
	} else {
		$build .= " ".$self->{SELECTOR}."\")";
	}
}

sub formatCharForArgType {
	my ($argtype) = @_;
	return "%d" if $argtype =~ /(int|long|bool)/i;
	return "%s" if $argtype =~ /char\s*\*/;
	return "%p" if $argtype =~ /void\s*\*/;
	return "%f" if $argtype =~ /(double|float)/;
	return "%c" if $argtype =~ /char/;
	return "%@";
}

1;
