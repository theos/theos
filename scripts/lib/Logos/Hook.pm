package Hook;
use strict;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{CLASS} = undef;
	$self->{SCOPE} = undef;
	$self->{RETURN} = undef;
	$self->{GROUP_IDENTIFIER} = undef;
	$self->{SELECTOR_PARTS} = [];
	$self->{ARGNAMES} = [];
	$self->{ARGTYPES} = [];
	$self->{NUM_ARGS} = 0;
	$self->{GROUP} = "_ungrouped";
	$self->{NEW} = 0;
	$self->{TYPE} = "";
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

sub groupIdentifier {
	my $self = shift;
	if(@_) { $self->{GROUP_IDENTIFIER} = shift; }
	return $self->{GROUP_IDENTIFIER};
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

sub setNew {
	my $self = shift;
	if(@_) { $self->{NEW} = shift; }
	return $self->{NEW};
}

sub isNew {
	my $self = shift;
	return $self->{NEW};
}

sub type {
	my $self = shift;
	if(@_) { $self->{TYPE} = shift; }
	return $self->{TYPE};
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
	return "_".$self->groupIdentifier."\$".$self->class."\$".$self->new_selector;
}

sub newFunctionName {
	my $self = shift;
	return "\$".$self->groupIdentifier."\$".$self->class."\$".$self->new_selector;
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
	if(!$self->{NEW}) {
		$build .= "static ".$self->{RETURN}." (*".$self->originalFunctionName.")(".$classargtype.", SEL"; 
		my $argtypelist = join(", ", @{$self->{ARGTYPES}});
		$build .= ", ".$argtypelist if $argtypelist;

		$build .= ");"
	}
	my $arglist = "";
	map $arglist .= ", ".$self->{ARGTYPES}[$_]." ".$self->{ARGNAMES}[$_], (0..$self->{NUM_ARGS} - 1);

	$build .= "static ".$self->{RETURN}." ".$self->newFunctionName."(".$classargtype." self, SEL _cmd".$arglist.")";
	return $build;
}

sub buildOriginalCall {
	my $self = shift;
	my ($customargs) = @_;
	return "" if $self->{NEW};

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
	if(!$self->{NEW}) {
		return "MSHookMessageEx(\$".$self->class.", \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", (IMP*)&".$self->originalFunctionName.");";
	} else {
		return "class_addMethod(\$".$self->class.", \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", \"".$self->{TYPE}."\");";
	}
}


sub buildLogCall {
	my $self = shift;
	my $build = "NSLog(\@\"".$self->{SCOPE}."[".$self->{CLASS};
	if($self->{NUM_ARGS} > 0) {
		map $build .= " ".$self->{SELECTOR_PARTS}[$_].":".formatCharForArgType($self->{ARGTYPES}[$_]), (0..$self->{NUM_ARGS} - 1);
		# This builds a list of args by making sure the format char isn't -- (or, what we're using for non-operational types)
		# Map (in list context) "format char == -- ? nothing : arg name" over the indices of the arg list.
		my @newarglist = map(formatCharForArgType($self->{ARGTYPES}[$_]) eq "--" ? undef : $self->{ARGNAMES}[$_], (0..$self->{NUM_ARGS} - 1));
		my $argnamelist = join(", ", grep(defined($_), @newarglist));
		$build .= "]\", ".$argnamelist.")";
	} else {
		$build .= " ".$self->selector."]\")";
	}
}

sub formatCharForArgType {
	my $argtype = shift;
	return "%d" if $argtype =~ /\b(int|long|bool)\b/i;
	return "%s" if $argtype =~ /\bchar\b\s*\*/;
	return "%p" if $argtype =~ /\bvoid\b\s*\*/;
	return "%f" if $argtype =~ /\b(double|float)\b/;
	return "%c" if $argtype =~ /\bchar\b/;
	return "--" if $argtype =~ /\b(CG\w*|CF\w*|void)\b/;
	return "%@";
}

1;
