#!/usr/bin/env perl
use Logos::Test;
use Test::More 'no_plan';

my $filename = $0;
$filename =~ s/\.(pl|t)$/.xm/;

my $s = Logos::Test::from($filename);
my $logos_state = $s->{state};

#static void _logos_method$_ungrouped$Logging$charp$charpp$charppp$void$voidp$voidpp$inttype$unknown_int$object_id$object_unknown$array_whatever$array_int$array_id$(Logging* self, SEL _cmd, char * a, char ** b, char *** c, void d, void* e, void ** f, int g, UIInterfaceOrientation h, id i, NSString * j, void *[] l, int[32] m, id[] n) {
#NSLog(@"-[<Logging: %p> charp:%s charpp:%p charppp:%p void:-- voidp:%p voidpp:%p inttype:%d unknown_int:0x%x object_id:%@ object_unknown:%@ array_whatever:%p
#array_int:%p array_id:%p]", self, a, b, c, e, f, g, (unsigned int)h, i, j, l, m, n);
my $method = $logos_state->{groups}->[0]->classes->[0]->methods->[0];
my @argtypes = @{$method->argtypes};
is(Logos::Method::formatCharForArgType($argtypes[0]), "%s", "arg 0 is valid");
is(Logos::Method::formatCharForArgType($argtypes[1]), "%p", "arg 1 is valid");
is(Logos::Method::formatCharForArgType($argtypes[2]), "%p", "arg 2 is valid");
is(Logos::Method::formatCharForArgType($argtypes[3]), "--", "arg 3 is valid");
is(Logos::Method::formatCharForArgType($argtypes[4]), "%p", "arg 4 is valid");
is(Logos::Method::formatCharForArgType($argtypes[5]), "%p", "arg 5 is valid");
is(Logos::Method::formatCharForArgType($argtypes[6]), "%d", "arg 6 is valid");
is(Logos::Method::formatCharForArgType($argtypes[7]), "0x%x", "arg 7 is valid");
is(Logos::Method::formatCharForArgType($argtypes[8]), "%@", "arg 8 is valid");
is(Logos::Method::formatCharForArgType($argtypes[9]), "%@", "arg 9 is valid");
is(Logos::Method::formatCharForArgType($argtypes[10]), "%p", "arg 10 is valid");
is(Logos::Method::formatCharForArgType($argtypes[11]), "%p", "arg 11 is valid");
is(Logos::Method::formatCharForArgType($argtypes[12]), "%p", "arg 12 is valid");
