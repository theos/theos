package Logos::Generator::internal::StaticClassGroup;
use strict;
use Logos::StaticClassGroup;
our @ISA = ('Logos::StaticClassGroup');

sub declarations {
	my $self = shift;
	my $return = "";
	return "" if scalar(keys %{$self->{USEDMETACLASSES}}) + scalar(keys %{$self->{USEDCLASSES}}) + scalar(keys %{$self->{DECLAREDONLYCLASSES}}) == 0;
	foreach(keys %{$self->{USEDMETACLASSES}}) {
		$return .= "static Class ".Logos::sigil("static_metaclass")."$_; ";
	}
	my %coalescedClasses = ();
	$coalescedClasses{$_}++ for(keys %{$self->{USEDCLASSES}});
	$coalescedClasses{$_}++ for(keys %{$self->{DECLAREDONLYCLASSES}});
	foreach(keys %coalescedClasses) {
		$return .= "static Class ".Logos::sigil("static_class")."$_; ";
	}
	return $return;
}

sub initializers {
	my $self = shift;
	my $return = "";
	return "" if scalar(keys %{$self->{USEDMETACLASSES}}) + scalar(keys %{$self->{USEDCLASSES}}) == 0;
	$return .= "{";
	foreach(keys %{$self->{USEDMETACLASSES}}) {
		$return .= Logos::sigil("static_metaclass")."$_ = objc_getMetaClass(\"$_\"); ";
	}
	foreach(keys %{$self->{USEDCLASSES}}) {
		$return .= Logos::sigil("static_class")."$_ = objc_getClass(\"$_\"); ";
	}
	$return .= "}";
	return $return;
}

1;
