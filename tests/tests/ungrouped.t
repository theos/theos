#!/usr/bin/env perl
use Logos::Test;
use Test::More 'no_plan';

my $filename = $0;
$filename =~ s/\.(pl|t)$/.xm/;

my $s = Logos::Test::from($filename);
my $logos_state = $s->{state};

is("_ungrouped", $logos_state->{groups}->[0]->name, "First group is _ungrouped.");
