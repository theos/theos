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

    my $build = "static " . $property->type . " _logos_method\$" . $property->group . "\$" . $property->class . "\$" . $name . "\$" . "(" . $property->class . "* self, SEL _cmd)";

    $build .= "{ return objc_getAssociatedObject(self, &" . $key . "); ";

    $build .= "}";

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

    my $build = "static void _logos_method\$" . $property->group . "\$" . $property->class . "\$" . $name . "\$" . "(" . $property->class . "* self, SEL _cmd, " . $property->type . " arg)";

    $build .= "{ objc_setAssociatedObject(self, &" . $key . ", arg, " . $policy . "); ";

    $build .= "}";

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
    $build .= $getter_func . "";
    $build .= $setter_func . "";
    
    # Declare property
    # TODO: Put this where it's really supposed to go

    $build .= "\@interface " . $property->class . " () \@property (";

    for(my $i = 0; $i < $property->numattr; $i++){
        my $attr = $property->attributes->[$i];

        if($i != 0){
            $build .= ", ";
        }

        $build .= $attr;
    }

    $build .= ") " . $property->type . " " . $property->name . "; \@end";


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
    $build .= "\@selector(" . $getter . "), " . "(IMP)&" . "_logos_method\$" . $property->group . "\$" . $property->class . "\$" . $getter . "\$, \"@@\:\");";

    # Setter
    $build .= "class_addMethod(";
    $build .= "_logos_class\$" . $property->group . "\$" . $property->class . ", ";

    $build .= "\@selector(" . $setter . ":), " . "(IMP)&" . "_logos_method\$" . $property->group . "\$" . $property->class . "\$" . $setter . "\$, \"v@\:@\");";

    $build .= "} ";

    return $build;
}

1;