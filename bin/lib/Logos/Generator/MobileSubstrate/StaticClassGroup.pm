package StaticClassGroup;
use Logos::BaseStaticClassGroup;
@ISA = "BaseStaticClassGroup";

sub declarations {
	my $self = shift;
	my $return = "";
	return "" if scalar(keys %{$self->{USEDMETACLASSES}}) + scalar(keys %{$self->{USEDCLASSES}}) + scalar(keys %{$self->{DECLAREDONLYCLASSES}}) == 0;
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
