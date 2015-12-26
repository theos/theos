package Logos::Generator::Base::Generator;
use strict;

sub findPreamble {
	my $self = shift;
	my $aref = shift;
	my @matches = grep(/\s*#\s*(import|include)\s*[<"]logos\/logos\.h[">]/, @$aref);
	return @matches > 0;
}

sub preamble {
	return <<END;
#if defined(__clang)
#if __has_feature(objc_arc)
#define _THEOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _THEOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _THEOS_SELF_CONST const
#define _THEOS_RETURN_RETAINED __attribute((ns_returns_retained))
#else
#define _THEOS_SELF_TYPE_NORMAL
#define _THEOS_SELF_TYPE_INIT
#define _THEOS_SELF_CONST
#define _THEOS_RETURN_RETAINED
#endif
#else
#define _THEOS_SELF_TYPE_NORMAL
#define _THEOS_SELF_TYPE_INIT
#define _THEOS_SELF_CONST
#define _THEOS_RETURN_RETAINED
#endif
END
}

sub generateClassList {
	my $self = shift;
	my $return = "";
	map $return .= "\@class $_; ", @_;
	return $return;
}

sub classReferenceWithScope {
	my $self = shift;
	my $classname = shift;
	my $scope = shift;
	my $prefix = Logos::sigil($scope eq "+" ? "static_metaclass_lookup" : "static_class_lookup");
	return $prefix.$classname."()";
}

1;
