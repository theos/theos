package Logos::Generator::Base::Function;
use Logos::Generator;
use strict;

sub initializers {
	my $self = shift;
	my $function = shift;
	my $return = "";
	$return .= "MSHookFunction(".$function->name.", &_logos_function\$".$function->group->name."\$_".$function->name.", &_logos_orig_function\$".$function->group->name."\$_".$function->name.")); ";
	return $return;
}

1;
