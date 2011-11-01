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

sub _originalMethodPointerDeclaration {
	my $self = shift;
	if(!$self->{NEW}) {
		my $build = "static ";
		my $classargtype = $self->class->type;
		$classargtype = "Class" if $self->{SCOPE} eq "+";
		$build .= $self->{RETURN}." (*".$self->originalFunctionName.")(".$classargtype.", SEL";
		my $argtypelist = join(", ", @{$self->{ARGTYPES}});
		$build .= ", ".$argtypelist if $argtypelist;

		$build .= ")";
		return $build;
	}
	return undef;
}

sub _methodPrototype {
	my $self = shift;
	my $includeArgNames = 0 || shift;
	my $build = "";
	my $classargtype = $self->class->type;
	$classargtype = "Class" if $self->{SCOPE} eq "+";
	my $arglist = "";
	if($includeArgNames == 1) {
		map $arglist .= ", ".$self->{ARGTYPES}[$_]." ".$self->{ARGNAMES}[$_], (0..$self->numArgs - 1);
	} else {
		my $typelist = join(", ", @{$self->{ARGTYPES}});
		$arglist = ", ".$typelist if $typelist;
	}

	$build .= "static ".$self->{RETURN}." ".$self->newFunctionName."(".$classargtype.($includeArgNames?" self":"").", SEL".($includeArgNames?" _cmd":"").$arglist.")";
	return $build;
}

sub definition {
	my $self = shift;
	my $build = "";
	$build .= $self->_methodPrototype(1);
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

sub declarations {
	my $self = shift;
	my $build = "";
	my $orig = $self->_originalMethodPointerDeclaration;
	$build .= $orig."; " if $orig;
	$build .= $self->_methodPrototype."; ";
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
