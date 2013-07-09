package Logos::Generator::MobileSubstrate::Method;
use strict;
use parent qw(Logos::Generator::Base::Method);

use Logos::Util qw(smartSplit);

use Hash::Util::FieldHash;
Hash::Util::FieldHash::fieldhashes \ my (%caches);

use Syntel::Variable;
use Syntel::Function;
use Syntel::Type;
use Syntel::Context;
use Syntel::BlockContext;
use Syntel::ConstantValue;

use Syntel::Lib::C;
use Syntel::Lib::ObjC;
use Syntel::Lib::Substrate;

sub _originalMethodPointerVar {
	my $self = shift;
	my $method = shift;
	my $o = \$caches{$method}->{orig};
	if(!$$o) {
		if(!$method->isNew) {
			$$o = Syntel::Variable->new($self->originalFunctionName($method), Syntel::Type::Function->new($method->return, $method->argtypes)->pointer->withStorageClass("static"));
		}
	}
	return $$o;
}

sub _methodFunction {
	my $self = shift;
	my $method = shift;
	my $o = \$caches{$method}->{func};
	if(!$$o) {
		$$o = Syntel::Function->new($self->newFunctionName($method), Syntel::Type::Function->new($method->return, $method->argtypes)->withStorageClass("static"), $method->argnames);
	}
	return $$o;
}

sub definition {
	my $self = shift;
	my $method = shift;
	my $build = "";
	return $self->_methodFunction($method)->declaration->emit();
}

sub originalCall {
	my $self = shift;
	my $method = shift;
	my $customargs = shift;
	return "" if $method->isNew;

	my @args;
	if($customargs) {
		@args = (@{$method->argnames}[0,1], smartSplit(qr/\s*,\s*/, $customargs));
	} else {
		@args = @{$method->argnames};
	}

	my $call = $self->_originalMethodPointerVar($method)->call(@args);
	return $call->emit;
}

sub declarations {
	my $self = shift;
	my $method = shift;
	my $ctx = Syntel::Context->new();
	my $orig = $self->_originalMethodPointerVar($method);
	$ctx->push($orig->declaration) if $orig;
	$ctx->push($self->_methodFunction($method)->prototype);
	return $ctx->emit;
}

sub initializers {
	my $self = shift;
	my $method = shift;
	my $cgen = Logos::Generator::for($method->class);
	my $classvar = ($method->scope eq "+" ? $cgen->metaVariable : $cgen->variable);
	my $emittable = undef;
	if(!$method->isNew) {
		$emittable =
			$Syntel::Lib::Substrate::MSHookMessageEx->call(
				$classvar,
				$Syntel::Lib::ObjC::_selector->call($method->selector),
				$self->_methodFunction($method)->pointer->cast($Syntel::Lib::ObjC::IMP),
				$self->_originalMethodPointerVar($method)->pointer->cast($Syntel::Lib::ObjC::IMP->pointer)
			);
	} else {
		my $subcontext = $emittable = Syntel::BlockContext->new();
		my $typeEncodingVar = undef;
		if(!$method->type) {
			$typeEncodingVar = Syntel::Variable->new("_typeEncoding", $Syntel::Type::CHAR->array(1024));
			my $i = Syntel::Variable->new("i", $Syntel::Type::INT->withQualifier("unsigned"));

			$subcontext->push($typeEncodingVar->declaration);
			$subcontext->push($i->declaration(0));
			for ($method->return, @{$method->argtypes}) {
				my $expr = undef;
				my $len = undef;
				my $decl = $_->declString;
				my $typeEncoding = Logos::Method::typeEncodingForArgType($decl);
				if(defined $typeEncoding) {
					$expr = synString($typeEncoding);
					$len = synConstant(length $typeEncoding);
				} else {
					$expr = $Syntel::Lib::ObjC::_encode->call($decl);
					$len = $Syntel::Lib::C::strlen->call($expr);
				}
				$subcontext->push($Syntel::Lib::C::memcpy->call($typeEncodingVar->binaryOp("+", $i), $expr, $len));
				$subcontext->push($i->binaryOp("+=", $len));
			}
			$subcontext->push($typeEncodingVar->index($i)->assign(synCharSequence("\\0")));
		} else {
			$typeEncodingVar = Syntel::Variable->new("_typeEncoding", $Syntel::Type::CHAR->array((length $method->type) + 1));
			$subcontext->push($typeEncodingVar->declaration(synString($method->type)));
		}
		$subcontext->push(
			$Syntel::Lib::ObjC::class_addMethod->call(
				$classvar,
				$Syntel::Lib::ObjC::_selector->call($method->selector),
				$self->_methodFunction($method)->pointer->cast($Syntel::Lib::ObjC::IMP),
				$typeEncodingVar
			)
		);
	}
	return $emittable->emit;
}

1;
