#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::Harness;
runtests(glob("tests/*.t"));
