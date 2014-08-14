package Logos::Generator::Base::Function;
use strict;
use Logos::Generator;

sub originalFunctionName {
	::fileError(-1, "Base::Function does not implement originalFunctionName");
}

sub newFunctionName {
	::fileError(-1, "Base::Function does not implement newFunctionName");
}

sub originalFunctionCall {
	::fileError(-1, "Base::Function does not implement originalFunctionCall");
}

sub declaration {
	::fileError(-1, "Base::Function does not implement declaration");
}

sub initializers {
	::fileError(-1, "Base::Function does not implement initializers");
}

1;
