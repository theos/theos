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

	if(!$name){
		# Use property name if no getter specified
		$name = $property->name;
	}

	# Build function start
	my $build = "static " . $property->type . " _logos_method\$" . $property->group . "\$" . $property->class . "\$" . $name . "\$" . "(" . $property->class . "* self, SEL _cmd){";

	# Build function body

	$build .= " return ";


	if ($property->type =~ /^(BOOL|(unsigned )?char|double|float|CGFloat|(unsigned )?int|NSInteger|unsigned|NSUInteger|(unsigned )?long (long)?|(unsigned )?short|NSRange|CGPoint|CGVector|CGSize|CGRect|CGAffineTransform|UIEdgeInsets|UIOffset|CATransform3D|CMTime(Range|Mapping)?|MKCoordinate(Span)?|SCNVector[34]|SCNMatrix4)$/){
		$build .= "[";
	}

	$build .= "objc_getAssociatedObject(self, &" . $key . ")";

	if ($property->type == "BOOL"){
		$build .= " boolValue]";
	} elsif ($property->type == "char"){
		$build .= " charValue]";
	} elsif ($property->type == "unsigned char"){
		$build .= " unsignedCharValue]";
	} elsif ($property->type == "double"){
		$build .= " doubleValue]";
	} elsif ($property->type =~ /^(float|CGFloat)$/){
		$build .= " floatValue]";
	} elsif ($property->type == "int"){
		$build .= " intValue]";
	} elsif ($property->type == "NSInteger"){
		$build .= " integerValue]";
	} elsif ($property->type =~ /^unsigned( int)?$/){
		$build .= " unsignedIntValue]";
	} elsif ($property->type == "NSUInteger"){
		$build .= " unsignedIntegerValue]";
	} elsif ($property->type == "long"){
		$build .= " longValue]";
	} elsif ($property->type == "unsigned long"){
		$build .= " unsignedLongValue]";
	} elsif ($property->type == "long long"){
		$build .= " longLongValue]";
	} elsif ($property->type == "unsigned long long"){
		$build .= " unsignedLongLongValue]";
	} elsif ($property->type == "short"){
		$build .= " shortValue]";
	} elsif ($property->type == "unsigned short"){
		$build .= " unsignedShortValue]";
	} elsif ($property->type =~ /^(NSRange|CGPoint|CGVector|CGSize|CGRect|CGAffineTransform|UIEdgeInsets|UIOffset|CATransform3D|CMTime(Range|Mapping)?|MKCoordinate(Span)?|SCNVector[34]|SCNMatrix4)$/){
		$build .= " " . $property->type . "Value]";
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

	if(!$name){
		# Capitalize first letter
		$_ = $property->name;
		$_ =~ s/^([a-z])/\u$1/;

		$name = "set" . $_;
	}

	# Remove semicolon
	$name =~ s/://;

	my $build = "static void _logos_method\$" . $property->group . "\$" . $property->class . "\$" . $name . "\$" . "(" . $property->class . "* self, SEL _cmd, " . $property->type . " arg){ ";


	$build .= "objc_setAssociatedObject(self, &" . $key . ", ";

	my $hasOpening = true;

	if ($property->type == "BOOL"){
		$build .= "[NSNumber numberWithBool:";
	} elsif ($property->type == "char"){
		$build .= "[NSNumber numberWithChar:";
	} elsif ($property->type == "unsigned char"){
		$build .= "[NSNumber numberWithUnsignedChar:";
	} elsif ($property->type == "double"){
		$build .= "[NSNumber numberWithDouble:";
	} elsif ($property->type =~ /^(float|CGFloat)$/){
		$build .= "[NSNumber numberWithFloat:";
	} elsif ($property->type == "int"){
		$build .= "[NSNumber numberWithInt:";
	} elsif ($property->type == "NSInteger"){
		$build .= "[NSNumber numberWithInteger:";
	} elsif ($property->type =~ /^unsigned( int)?$/){
		$build .= "[NSNumber numberWithUnsignedInt:";
	} elsif ($property->type == "NSUInteger"){
		$build .= "[NSNumber numberWithUnsignedInteger:";
	} elsif ($property->type == "long"){
		$build .= "[NSNumber numberWithLong:";
	} elsif ($property->type == "unsigned long"){
		$build .= "[NSNumber numberWithUnsignedLong:";
	} elsif ($property->type == "long long"){
		$build .= "[NSNumber numberWithLongLong:";
	} elsif ($property->type == "unsigned long long"){
		$build .= "[NSNumber numberWithUnsignedLongLong:";
	} elsif ($property->type == "short"){
		$build .= "[NSNumber numberWithShort:";
	} elsif ($property->type == "unsigned short"){
		$build .= "[NSNumber numberWithUnsignedShort:";
	} elsif ($property->type =~ /^(NSRange|CGPoint|CGVector|CGSize|CGRect|CGAffineTransform|UIEdgeInsets|UIOffset|CATransform3D|CMTime(Range|Mapping)?|MKCoordinate(Span)?|SCNVector[34]|SCNMatrix4)$/){
		$build .= "[NSValue valueWith " . $property->type . ":";
	} else {
		$hasOpening = false;
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
