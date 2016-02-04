package Logos::Generator::internal::Method;
use strict;
use parent qw(Logos::Generator::Base::Method);

sub superFunctionName {
	my $self = shift;
	my $method = shift;
	return Logos::sigil(($method->scope eq "+" ? "meta_" : "")."super").$method->groupIdentifier."\$".$method->class->name."\$".$method->_new_selector;
}

sub originalCallParams {
	my $self = shift;
	my $method = shift;
	my $customargs = shift;
	return "" if $method->isNew;

	my $build = "(self, _cmd";
	if(defined $customargs && $customargs ne "") {
		$build .= ", ".$customargs;
	} elsif($method->numArgs > 0) {
		$build .= ", ".join(", ",@{$method->argnames});
	}
	$build .= ")";
	return $build;
}

sub definition {
	my $self = shift;
	my $method = shift;
	my $build = "";
	my $selftype = $self->selfTypeForMethod($method);
	my $classref = "";
	my $cgen = Logos::Generator::for($method->class);
	if($method->scope eq "+") {
		$classref = $cgen->superMetaVariable;
	} else {
		$classref = $cgen->superVariable;
	}
	my $arglist = "";
	map $arglist .= ", ".Logos::Method::declarationForTypeWithName($method->argtypes->[$_], $method->argnames->[$_]), (0..$method->numArgs - 1);
	my $parameters = "(".$selftype." self, SEL _cmd".$arglist.")";
	my $return = $self->returnTypeForMethod($method);
	my $functionAttributes = $self->functionAttributesForMethod($method);
	if(!$method->isNew) {
		my $argtypelist = join(", ", @{$method->argtypes});

		$build .= "static ".Logos::Method::declarationForTypeWithName($return, $self->superFunctionName($method).$parameters).$functionAttributes." {";
		my $pointerType = "(*)(".$selftype.", SEL";
		$pointerType .=       ", ".$argtypelist if $argtypelist;
		$pointerType .=   ")";
		$build .=     "return ((".$functionAttributes." ".Logos::Method::declarationForTypeWithName($return, $pointerType).")class_getMethodImplementation(".$classref.",".$self->selectorRef($method->selector)."))";
		$build .=         $self->originalCallParams($method).";";
		$build .= "}";

	}
	$build .= "static ".Logos::Method::declarationForTypeWithName($return, $self->newFunctionName($method).$parameters).$functionAttributes;
	return $build;
}

sub originalCall {
	my $self = shift;
	my $method = shift;
	my $customargs = shift;
	return $self->originalFunctionName($method).$self->originalCallParams($method, $customargs);
}

sub declarations {
	my $self = shift;
	my $method = shift;
	my $build = "";
	if(!$method->isNew) {
		my $selftype = $self->selfTypeForMethod($method);
		my $functionAttributes = $self->functionAttributesForMethod($method);
		$build .= "static ";
		my $name = "";
		$name .= $functionAttributes."(*".$self->originalFunctionName($method).")(".$selftype.", SEL";
		my $argtypelist = join(", ", @{$method->argtypes});
		$name .= ", ".$argtypelist if $argtypelist;
		$name .= ")";
		$build .= Logos::Method::declarationForTypeWithName($self->returnTypeForMethod($method), $name);
		$build .= ";";
	}
	return $build;
}

sub initializers {
	my $self = shift;
	my $method = shift;
	my $cgen = Logos::Generator::for($method->class);
	my $classvar = ($method->scope eq "+" ? $cgen->metaVariable : $cgen->variable);
	my $r = "{ ";
	if(!$method->isNew) {
		my $classargtype = "";
		if($method->scope eq "+") {
			$classargtype = "Class";
		} else {
			$classargtype = $method->class->type;
		}
		$r .= "Class _class = ".$classvar.";";
		$r .= "Method _method = class_getInstanceMethod(_class, ".$self->selectorRef($method->selector)."));";
		$r .= "if (_class) {";
		$r .=   "if (_method) {";
		$r .=     $self->originalFunctionName($method)." = ".$self->superFunctionName($method).";";
		$r .=     "if (!class_addMethod(_class, ".$self->selectorRef($method->selector)."), (IMP)&".$self->newFunctionName($method).", method_getTypeEncoding(_method))) {";
		$r .=       $self->originalFunctionName($method)." = (".$pointertype.")method_getImplementation(_method);";
		$r .=       $self->originalFunctionName($method)." = (".$pointertype.")method_setImplementation(_method, (IMP)&".$self->newFunctionName($method).");";
		$r .=     "}";
		$r .=   "} else {";
		$r .=     "HBLogError(@\"logos: message not found [%s %s]\", \"".$method->class->name."\", \"".$method->selector."\");";
		$r .=   "}";
		$r .= "} else {";
		$r .=   "HBLogError(@\"logos: nil class %s\", \"".$method->class->name."\");";
		$r .= "}";
	} else {
		if(!$method->type) {
			$r .= "char _typeEncoding[1024]; unsigned int i = 0; ";
			for ($method->return, "id", "SEL", @{$method->argtypes}) {
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
			$r .= "const char *_typeEncoding = \"".$method->type."\"; ";
		}
		$r .= "class_addMethod(".$classvar.", ".$self->selectorRef($method->selector).", (IMP)&".$self->newFunctionName($method).", _typeEncoding); ";
	}
	$r .= "}";
	return $r;
}

1;
