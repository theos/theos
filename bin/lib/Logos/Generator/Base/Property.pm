package Logos::Generator::Base::Property;
use strict;
use Logos::Util;

sub key {
	my $self = shift;
	my $property = shift;

	my $build = "_logos_property_key\$" . $property->group . "\$" . $property->class . "\$" . $property->name;

	return $build;
}

sub getter {
	my $self = shift;
	my $property = shift;
	my $name = shift;
	my $key = shift;
	my $type = $property->type;

	$type =~ s/\s+$//;

	if(!$name){
		# Use property name if no getter specified
		$name = $property->name;
	}

	# Build function start
	my $build = "__attribute__((used)) "; # If the property is never accessed, clang's optimizer will remove the getter/setter if this attribute isn't specified

	$build .= "static " . $type . " _logos_method\$" . $property->group . "\$" . $property->class . "\$" . $name . "\$" . "(" . $property->class . "* __unused self, SEL __unused _cmd){";

	# Build function body

	$build .= " return ";


	if ($type =~ /^(BOOL|(unsigned )?char|double|float|CGFloat|(unsigned )?int|NSInteger|unsigned|NSUInteger|(unsigned )?long (long)?|(unsigned )?short|NSRange|CGPoint|CGVector|CGSize|CGRect|CGAffineTransform|UIEdgeInsets|UIOffset|CATransform3D|CMTime(Range|Mapping)?|MKCoordinate(Span)?|SCNVector[34]|SCNMatrix4)$/){
		$build .= "[";
	}

	$build .= "objc_getAssociatedObject(self, &" . $key . ")";

	if ($type eq "BOOL"){
		$build .= " boolValue]";
	} elsif ($type eq "char"){
		$build .= " charValue]";
	} elsif ($type eq "unsigned char"){
		$build .= " unsignedCharValue]";
	} elsif ($type eq "double"){
		$build .= " doubleValue]";
	} elsif ($type =~ /^(float|CGFloat)$/){
		$build .= " floatValue]";
	} elsif ($type eq "int"){
		$build .= " intValue]";
	} elsif ($type eq "NSInteger"){
		$build .= " integerValue]";
	} elsif ($type =~ /^unsigned( int)?$/){
		$build .= " unsignedIntValue]";
	} elsif ($type eq "NSUInteger"){
		$build .= " unsignedIntegerValue]";
	} elsif ($type eq "long"){
		$build .= " longValue]";
	} elsif ($type eq "unsigned long"){
		$build .= " unsignedLongValue]";
	} elsif ($type eq "long long"){
		$build .= " longLongValue]";
	} elsif ($type eq "unsigned long long"){
		$build .= " unsignedLongLongValue]";
	} elsif ($type eq "short"){
		$build .= " shortValue]";
	} elsif ($type eq "unsigned short"){
		$build .= " unsignedShortValue]";
	} elsif ($type =~ /^(NSRange|CGPoint|CGVector|CGSize|CGRect|CGAffineTransform|UIEdgeInsets|UIOffset|CATransform3D|CMTime(Range|Mapping)?|MKCoordinate(Span)?|SCNVector[34]|SCNMatrix4)$/){
		$build .= " " . $type . "Value]";
	}

	$build .= "; }";

	return $build;
}

sub setter {
	my $self = shift;
	my $property = shift;
	my $name = shift;
	my $policy = shift;
	my $key = shift;
	my $type = $property->type;

	$type =~ s/\s+$//;

	if(!$name){
		# Capitalize first letter
		$_ = $property->name;
		$_ =~ s/^([a-z])/\u$1/;

		$name = "set" . $_;
	}

	# Remove semicolon
	$name =~ s/://;

	# Build function start

	my $build = "__attribute__((used)) "; # If the property is never accessed, clang's optimizer will remove the getter/setter if this attribute isn't specified
	$build .= "static void _logos_method\$" . $property->group . "\$" . $property->class . "\$" . $name . "\$" . "(" . $property->class . "* __unused self, SEL __unused _cmd, " . $type . " arg){ ";

	# Build function body

	$build .= "objc_setAssociatedObject(self, &" . $key . ", ";

	my $hasOpening = 1;

	if ($type eq "BOOL"){
		$build .= "[NSNumber numberWithBool:";
	} elsif ($type eq "char"){
		$build .= "[NSNumber numberWithChar:";
	} elsif ($type eq "unsigned char"){
		$build .= "[NSNumber numberWithUnsignedChar:";
	} elsif ($type eq "double"){
		$build .= "[NSNumber numberWithDouble:";
	} elsif ($type =~ /^(float|CGFloat)$/){
		$build .= "[NSNumber numberWithFloat:";
	} elsif ($type eq "int"){
		$build .= "[NSNumber numberWithInt:";
	} elsif ($type eq "NSInteger"){
		$build .= "[NSNumber numberWithInteger:";
	} elsif ($type =~ /^unsigned( int)?$/){
		$build .= "[NSNumber numberWithUnsignedInt:";
	} elsif ($type eq "NSUInteger"){
		$build .= "[NSNumber numberWithUnsignedInteger:";
	} elsif ($type eq "long"){
		$build .= "[NSNumber numberWithLong:";
	} elsif ($type eq "unsigned long"){
		$build .= "[NSNumber numberWithUnsignedLong:";
	} elsif ($type eq "long long"){
		$build .= "[NSNumber numberWithLongLong:";
	} elsif ($type eq "unsigned long long"){
		$build .= "[NSNumber numberWithUnsignedLongLong:";
	} elsif ($type eq "short"){
		$build .= "[NSNumber numberWithShort:";
	} elsif ($type eq "unsigned short"){
		$build .= "[NSNumber numberWithUnsignedShort:";
	} elsif ($type =~ /^(NSRange|CGPoint|CGVector|CGSize|CGRect|CGAffineTransform|UIEdgeInsets|UIOffset|CATransform3D|CMTime(Range|Mapping)?|MKCoordinate(Span)?|SCNVector[34]|SCNMatrix4)$/){
		$build .= "[NSValue valueWith" . $type . ":";
	} else {
		$hasOpening = 0;
	}

	$build .= "arg";

	if ($hasOpening){
		$build .= "]";
	}

	$build .= ", ".$policy.")";

	$build .= "; }";

	return $build;
}

sub getters_setters {
	my $self = shift;
	my $property = shift;

	my ($assign, $retain, $nonatomic, $copy, $getter, $setter);


	for(my $i = 0; $i < $property->numattr; $i++){

		my $attr = $property->attributes->[$i];

		if($attr =~ /assign/){
			$assign = 1;
		}elsif($attr =~ /retain/){
			$retain = 1;
		}elsif($attr =~ /nonatomic/){
			$nonatomic = 1;
		}elsif($attr =~ /copy/){
			$copy = 1;
		}elsif($attr =~ /getter=(\w+)/){
			$getter = $1;
		}elsif($attr =~ /setter=(\w+:)/){
			$setter = $1;
		}
	}

	my $policy = "OBJC_ASSOCIATION_";

	if($retain){
		$policy .= "RETAIN";
	}elsif($copy){
		$policy .= "COPY";
	}elsif($assign){
		$policy .= "ASSIGN";
	}else{
		print "error: no 'assign', 'retain', or 'copy' attribu...wait, how did you manage to get here?\n";
	}

	if($nonatomic){
		# The 'assign' attribute appears to be nonatomic by default.
		if(!$assign){
			$policy .= "_NONATOMIC";
		}
	}

	$property->associationPolicy($policy);

	my $build;

	my $key = $self->key($property);
	my $getter_func = $self->getter($property, $getter, $key);
	my $setter_func = $self->setter($property, $setter, $policy, $key);

	$build .= $build . "static char " . $key . ";";
	$build .= $getter_func;
	$build .= $setter_func;


	return $build;
}

sub initializers {
	my $self = shift;
	my $property = shift;

	my ($getter, $setter);

	for(my $i = 0; $i < $property->numattr; $i++){ # This could be more efficient
		my $attr = $property->attributes->[$i];

		if($attr =~ /getter=(\w+)/){
			$getter = $1;
		}elsif($attr =~ /setter=(\w+:)/){
			$setter = $1;
			$setter =~ s/://;
		}
	}

	if(!$setter){
		# Capitalize first letter
		$_ = $property->name;
		$_ =~ s/^([a-z])/\u$1/;

		$setter = "set" . $_;
	}

	if(!$getter){
		# Use property name if no getter specified
		$getter = $property->name;
	}


	my $build = "";

	$build .= "{ ";

	# Getter
	$build .= "class_addMethod(";

	$build .= "_logos_class\$" . $property->group . "\$" . $property->class . ", ";
	$build .= "\@selector(" . $getter . "), " . "(IMP)&" . "_logos_method\$" . $property->group . "\$" . $property->class . "\$" . $getter . "\$, [[NSString stringWithFormat:\@\"%s\@:\", \@encode(".$property->type.")] UTF8String]);";

	# Setter
	$build .= "class_addMethod(";
	$build .= "_logos_class\$" . $property->group . "\$" . $property->class . ", ";

	$build .= "\@selector(" . $setter . ":), " . "(IMP)&" . "_logos_method\$" . $property->group . "\$" . $property->class . "\$" . $setter . "\$, [[NSString stringWithFormat:\@\"v\@:%s\", \@encode(".$property->type.")] UTF8String]);";

	$build .= "} ";

	return $build;
}

1;
