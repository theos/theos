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
	if($self->numArgs == 0) {
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
	map $arglist .= ", ".$self->{ARGTYPES}[$_]." ".$self->{ARGNAMES}[$_], (0..$self->numArgs - 1);

	$build .= "static ".$self->{RETURN}." ".$self->newFunctionName."(".$classargtype." self, SEL _cmd".$arglist.")";
	return $build;
}

sub originalCall {
	my $self = shift;
	my $customargs = shift;
	return "" if $self->{NEW};

	my $build = $self->originalFunctionName."(self, _cmd";
	if(defined $customargs && $customargs ne "") {
		$build .= ", ".$customargs;
	} elsif($self->numArgs > 0) {
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
		my $r = "";
		$r .= "{ ";
		if(!$self->{TYPE}) {
			$r .= "char _typeEncoding[1024]; unsigned int i = 0; ";
			for ($self->{RETURN}, "id", "SEL", @{$self->{ARGTYPES}}) {
				my $typeEncoding = BaseMethod::typeEncodingForArgType($_);
				if(defined $typeEncoding) {
					my @typeEncodingBits = split(//, $typeEncoding);
					my $i = 0;
					for my $char (@typeEncodingBits) {
						$r .= "_typeEncoding[i".($i > 0 ? " + $i" : "")."] = '$char'; ";
						$i++;
					}
					$r .= "i += ".(scalar @typeEncodingBits)."; ";
				} else {
					$r .= "memcpy(_typeEncoding + i, \@encode($_), strlen(\@encode($_))); i += strlen(\@encode($_)); ";
				}
			}
			$r .= "_typeEncoding[i] = '\\0'; ";
		} else {
			$r .= "const char *_typeEncoding = \"".$self->{TYPE}."\"; ";
		}
		$r .= "class_addMethod(\$\$".$self->classname.", \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", _typeEncoding); ";
		$r .= "}";
		return $r;
	}
}

1;
