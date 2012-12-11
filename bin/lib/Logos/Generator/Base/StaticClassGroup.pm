package Logos::Generator::Base::StaticClassGroup;
use strict;

sub _methodForClassWithScope {
	my $self = shift;
	my $class = shift;
	my $scope = shift;
	my $return = "";
	my $methodname = Logos::sigil($scope eq "+" ? "static_metaclass_lookup" : "static_class_lookup").$class;
	my $lookupMethod = $scope eq "+" ? "objc_getMetaClass" : "objc_getClass";
	return "LOGOS_INLINE Class ".$methodname."(void) { static Class _klass; if(!_klass) { _klass = ".$lookupMethod."(\"".$class."\"); } return _klass; }";
}

sub declarations {
	my $self = shift;
	my $group = shift;
	my $return = "";
	return "" if scalar(keys %{$group->usedMetaClasses}) + scalar(keys %{$group->usedClasses}) + scalar(keys %{$group->declaredOnlyClasses}) == 0;
	foreach(keys %{$group->usedMetaClasses}) {
		$return .= $self->_methodForClassWithScope($_, "+");
	}
	foreach(keys %{$group->usedClasses}) {
		$return .= $self->_methodForClassWithScope($_, "-");
	}
	return $return;
}

sub initializers {
	return "";
}

1;
