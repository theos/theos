package Logos::Generator::Base::Property;
use strict;
use Logos::Util;

sub getterName {
	my $self = shift;
	my $property = shift;
	return Logos::sigil("method").$property->group."\$".$property->class."\$".$property->getter;
}

sub setterName {
	my $self = shift;
	my $property = shift;
	return Logos::sigil("method").$property->group."\$".$property->class."\$".$property->setter;
}

sub definition {
	my $self = shift;
	my $property = shift;

	my $build = "";

	# Build getter
	my $getter_func = "__attribute__((used)) "; # If the property is never accessed, clang's optimizer will remove the getter/setter if this attribute isn't specified
	$getter_func .= "static ".$property->type." ".$self->getterName($property)."(".$property->class." * __unused self, SEL __unused _cmd) ";
	$getter_func .= "{ NSValue * value = objc_getAssociatedObject(self, &".$self->getterName($property)."); ".$property->type." rawValue; [value getValue:&rawValue]; return rawValue; }";

	# Build setter
	my $setter_func = "__attribute__((used)) "; # If the property is never accessed, clang's optimizer will remove the getter/setter if this attribute isn't specified
	$setter_func .= "static void ".$self->setterName($property)."(".$property->class." * __unused self, SEL __unused _cmd, ".$property->type." rawValue) ";
	$setter_func .= "{ NSValue * value = [NSValue valueWithBytes:&rawValue objCType:\@encode(".$property->type.")]; objc_setAssociatedObject(self, &".$self->getterName($property).", value, ".$property->associationPolicy."); }";

	$build .= $getter_func;
	$build .= "; ";
	$build .= $setter_func;

	return $build;
}

sub initializers {
	my $self = shift;
	my $property = shift;

	my $build = "{ char _typeEncoding[1024];";

	# Getter
	$build .= " sprintf(_typeEncoding, \"%s\@:\", \@encode(".$property->type."));";
	$build .= " class_addMethod(";
	$build .= Logos::sigil("class").$property->group."\$".$property->class.", ";
	$build .= "\@selector(".$property->getter."), ";
	$build .= "(IMP)&".$self->getterName($property).", ";
	$build .= "_typeEncoding);";

	# Setter
	$build .= " sprintf(_typeEncoding, \"v\@:%s\", \@encode(".$property->type."));";
	$build .= " class_addMethod(";
	$build .= Logos::sigil("class").$property->group."\$".$property->class.", ";
	$build .= "\@selector(".$property->setter.":), ";
	$build .= "(IMP)&".$self->setterName($property).", ";
	$build .= "_typeEncoding);";

	$build .= " } ";

	return $build;
}

1;
