package Hook;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{CLASS} = undef;
	$self->{SCOPE} = undef;
	$self->{RETURN} = undef;
	$self->{SELECTOR_PARTS} = [];
	$self->{ARGNAMES} = [];
	$self->{ARGTYPES} = [];
	$self->{NUM_ARGS} = 0;
	$self->{GROUP} = "_ungrouped";
	bless($self, $class);
	return $self;
}

##################### #
# Setters and Getters #
# #####################
sub class {
	my $self = shift;
	if(@_) { $self->{CLASS} = shift; }
	return ($self->{SCOPE} eq "+" ? "meta\$" : "").$self->{CLASS};
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

sub selectorParts {
	my $self = shift;
	if(@_) { @{$self->{SELECTOR_PARTS}} = @_; }
	return @{$self->{SELECTOR_PARTS}};
}

sub group {
	my $self = shift;
	if(@_) { $self->{GROUP} = shift; }
	return $self->{GROUP};
}

##### #
# END #
# #####

sub addArgument {
	my $self = shift;
	my ($type, $name) = @_;
	push(@{$self->{ARGTYPES}}, $type);	
	push(@{$self->{ARGNAMES}}, $name);
	$self->{NUM_ARGS}++;
}

sub selector {
	my $self = shift;
	if($self->{NUM_ARGS} == 0) {
		return $self->{SELECTOR_PARTS}[0];
	} else {
		return join(":", @{$self->{SELECTOR_PARTS}}).":";
	}
}

sub new_selector {
	my $self = shift;
	if($self->{NUM_ARGS} == 0) {
		return $self->{SELECTOR_PARTS}[0];
	} else {
		return join("\$", @{$self->{SELECTOR_PARTS}})."\$";
	}
}

sub originalFunctionName {
	my $self = shift;
	return "_".$self->class."\$".$self->new_selector;
}

sub newFunctionName {
	my $self = shift;
	return "\$".$self->class."\$".$self->new_selector;
}

sub buildHookFunction {
	my $self = shift;
	my $build = "";
	my $classargtype = "";
	if($self->{SCOPE} eq "+") {
		$classargtype = "Class";
	} else {
		$classargtype = $self->{CLASS}."*";
	}
	$build .= "static ".$self->{RETURN}." (*".$self->originalFunctionName.")(".$classargtype.", SEL"; 
	my $argtypelist = join(", ", @{$self->{ARGTYPES}});
	$build .= ", ".$argtypelist if $argtypelist;

	my $arglist = "";
	map $arglist .= ", ".$self->{ARGTYPES}[$_]." ".$self->{ARGNAMES}[$_], (0..$self->{NUM_ARGS} - 1);

	$build .= "); static ".$self->{RETURN}." ".$self->newFunctionName."(".$classargtype." self, SEL _cmd".$arglist.")";
	return $build;
}

sub buildOriginalCall {
	my $self = shift;
	my ($customargs) = @_;
	my $build = $self->originalFunctionName."(self, _cmd";
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
	return "MSHookMessageEx(\$".$self->class.", \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", (IMP*)&".$self->originalFunctionName.");"
}


sub buildLogCall {
	my $self = shift;
	my $build = "NSLog(\@\"".$self->{SCOPE}."[".$self->{CLASS};
	if($self->{NUM_ARGS} > 0) {
		map $build .= " ".$self->{SELECTOR_PARTS}[$_].":".formatCharForArgType($self->{ARGTYPES}[$_]), (0..$self->{NUM_ARGS} - 1);
		my $argnamelist = join(", ", @{$self->{ARGNAMES}});
		$build .= "]\", ".$argnamelist.")";
	} else {
		$build .= " ".$self->selector."]\")";
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
