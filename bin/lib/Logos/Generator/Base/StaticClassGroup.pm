package Logos::Generator::Base::StaticClassGroup;
use strict;

sub declarations {
	my $self = shift;
	my $group = shift;
	my $return = "";
	return "" if scalar(keys %{$group->usedMetaClasses}) + scalar(keys %{$group->usedClasses}) + scalar(keys %{$group->declaredOnlyClasses}) == 0;
	foreach(keys %{$group->usedMetaClasses}) {
		$return .= "static Class ".Logos::sigil("static_metaclass")."$_; ";
	}
	my %coalescedClasses = ();
	$coalescedClasses{$_}++ for(keys %{$group->usedClasses});
	$coalescedClasses{$_}++ for(keys %{$group->declaredOnlyClasses});
	foreach(keys %coalescedClasses) {
		$return .= "static Class ".Logos::sigil("static_class")."$_; ";
	}
	return $return;
}

sub initializers {
	my $self = shift;
	my $group = shift;
	my $return = "";
	return "" if scalar(keys %{$group->usedMetaClasses}) + scalar(keys %{$group->usedClasses}) == 0;
	$return .= "{";
	foreach(keys %{$group->usedMetaClasses}) {
		$return .= Logos::sigil("static_metaclass")."$_ = objc_getMetaClass(\"$_\"); ";
	}
	foreach(keys %{$group->usedClasses}) {
		$return .= Logos::sigil("static_class")."$_ = objc_getClass(\"$_\"); ";
	}
	$return .= "}";
	return $return;
}

1;
