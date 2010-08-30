package Method;
use strict;
use Logos::BaseMethod;
@Method::ISA = ('BaseMethod');

sub classname {
	my $self = shift;
	return ($self->{SCOPE} eq "+" ? "meta\$" : "").$self->class->name;
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
	return "_".$self->groupIdentifier."\$".$self->classname."\$".$self->new_selector;
}

sub newFunctionName {
	my $self = shift;
	return "\$".$self->groupIdentifier."\$".$self->classname."\$".$self->new_selector;
}

sub methodSignature {
	my $self = shift;
	my $build = "";
	my $classargtype = "";
	if($self->{SCOPE} eq "+") {
		$classargtype = "Class";
	} else {
		$classargtype = $self->class->type;
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

sub originalCall {
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

sub initializers {
	my $self = shift;
	if(!$self->{NEW}) {
		return "MSHookMessageEx(\$\$".$self->classname.", \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", (IMP*)&".$self->originalFunctionName.");";
	} else {
		return "class_addMethod(\$\$".$self->classname.", \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", \"".$self->{TYPE}."\");";
	}
}

1;
