package Logos::Generator::internal::Method;
use strict;
use Logos::Method;
our @ISA = ('Logos::Method');

sub superFunctionName {
	my $self = shift;
	return Logos::sigil(($self->{SCOPE} eq "+" ? "meta_" : "")."super").$self->groupIdentifier."\$".$self->class->name."\$".$self->_new_selector;
}

sub originalCallParams {
	my $self = shift;
	my $customargs = shift;
	return "" if $self->{NEW};

	my $build = "(self, _cmd";
	if(defined $customargs && $customargs ne "") {
		$build .= ", ".$customargs;
	} elsif($self->numArgs > 0) {
		$build .= ", ".join(", ",@{$self->{ARGNAMES}});
	}
	$build .= ")";
	return $build;
}

sub definition {
	my $self = shift;
	my $build = "";
	my $classargtype = "";
	my $classref = "";
	if($self->{SCOPE} eq "+") {
		$classargtype = "Class";
		$classref = $self->class->superMetaVariable;
	} else {
		$classargtype = $self->class->type;
		$classref = $self->class->superVariable;
	}
	my $arglist = "";
	map $arglist .= ", ".$self->declarationForTypeWithName($self->{ARGTYPES}[$_], $self->{ARGNAMES}[$_]), (0..$self->numArgs - 1);
	my $parameters = "(".$classargtype." self, SEL _cmd".$arglist.")";
	if(!$self->{NEW}) {
		my $argtypelist = join(", ", @{$self->{ARGTYPES}});

		$build .= "static ".$self->declarationForTypeWithName($self->{RETURN}, $self->superFunctionName.$parameters)." {";
		my $pointerType = "(*)(".$classargtype.", SEL";
		$pointerType .=       ", ".$argtypelist if $argtypelist;
		$pointerType .=   ")";
		$build .=     "return ((".$self->declarationForTypeWithName($self->{RETURN}, $pointerType).")class_getMethodImplementation(".$classref.", \@selector(".$self->selector.")))";
		$build .=         $self->originalCallParams.";";
		$build .= "}";
	
	}
	$build .= "static ".$self->declarationForTypeWithName($self->{RETURN}, $self->newFunctionName.$parameters);
	return $build;
}

sub originalCall {
	my $self = shift;
	return $self->originalFunctionName.$self->originalCallParams;
}

sub declarations {
	my $self = shift;
	my $build = "";
	if(!$self->{NEW}) {
		my $classargtype = "";
		if($self->{SCOPE} eq "+") {
			$classargtype = "Class";
		} else {
			$classargtype = $self->class->type;
		}
		$build .= "static ";
		my $name = "";
		$name .= "(*".$self->originalFunctionName.")(".$classargtype.", SEL";
		my $argtypelist = join(", ", @{$self->{ARGTYPES}});
		$name .= ", ".$argtypelist if $argtypelist;
		$name .= ")";
		$build .= $self->declarationForTypeWithName($self->{RETURN}, $name).";";
	}
	return $build;
}

sub initializers {
	my $self = shift;
	my $classvar = ($self->{SCOPE} eq "+" ? $self->class->metaVariable : $self->class->variable);
	my $r = "{ ";
	if(!$self->{NEW}) {
		my $classargtype = "";
		if($self->{SCOPE} eq "+") {
			$classargtype = "Class";
		} else {
			$classargtype = $self->class->type;
		}
		my $_pointertype = "(*)(".$classargtype.", SEL";
		my $argtypelist = join(", ", @{$self->{ARGTYPES}});
		$_pointertype .= ", ".$argtypelist if $argtypelist;
		$_pointertype .= ")";
		my $pointertype = $self->declarationForTypeWithName($self->{RETURN}, $_pointertype);
		$r .= "Class _class = ".$classvar.";";
		$r .= "Method _method = class_getInstanceMethod(_class, \@selector(".$self->selector."));";
		$r .= "if (_method) {";
		$r .=     $self->originalFunctionName." = ".$self->superFunctionName.";";
		$r .=     "if (!class_addMethod(_class, \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", method_getTypeEncoding(_method))) {";
		$r .=         $self->originalFunctionName." = (".$pointertype.")method_getImplementation(_method);";
		$r .=         $self->originalFunctionName." = (".$pointertype.")method_setImplementation(_method, (IMP)&".$self->newFunctionName.");";
		$r .=     "}";
		$r .= "}";
	} else {
		if(!$self->{TYPE}) {
			$r .= "char _typeEncoding[1024]; unsigned int i = 0; ";
			for ($self->{RETURN}, "id", "SEL", @{$self->{ARGTYPES}}) {
				my $typeEncoding = Logos::Method::typeEncodingForArgType($_);
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
		$r .= "class_addMethod(".$classvar.", \@selector(".$self->selector."), (IMP)&".$self->newFunctionName.", _typeEncoding); ";
	}
	$r .= "}";
	return $r;
}

1;
