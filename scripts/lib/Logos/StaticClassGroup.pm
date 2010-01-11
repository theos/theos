package StaticClassGroup;
use Logos::Group;
@ISA = "Group";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	$self->name("_staticClass");
	$self->explicit(0);
	$self->{DECLAREDONLYCLASSES} = {};
	bless($self, $class);
	return $self;
}

sub addDeclaredOnlyClass {
	my $self = shift;
	my $class = shift;
	$self->{DECLAREDONLYCLASSES}{$class}++;
}

sub declarations {
	my $self = shift;
	my $return = "";
	return "" if scalar(keys %{$self->{USEDMETACLASSES}}) + scalar(keys %{$self->{USEDCLASSES}}) == 0;
	foreach(keys %{$self->{USEDMETACLASSES}}) {
		$return .= "static Class \$meta\$$_; ";
	}
	foreach(keys %{$self->{USEDCLASSES}}) {
		$return .= "static Class \$$_; ";
	}
	foreach(keys %{$self->{DECLAREDONLYCLASSES}}) {
		$return .= "static Class \$$_; ";
	}
	return $return;
}

sub initializers {
	my $self = shift;
	my $return = "";
	$self->initialized(1);
	return "" if scalar(keys %{$self->{USEDMETACLASSES}}) + scalar(keys %{$self->{USEDCLASSES}}) == 0;
	$return .= "{";
	foreach(keys %{$self->{USEDMETACLASSES}}) {
		$return .= "\$meta\$$_ = objc_getMetaClass(\"$_\"); ";
	}
	foreach(keys %{$self->{USEDCLASSES}}) {
		$return .= "\$$_ = objc_getClass(\"$_\"); ";
	}
	$return .= "}";
	return $return;
}

1;
