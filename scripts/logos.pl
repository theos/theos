#!/usr/bin/env perl

use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Logos::Hook;

# I WARN YOU
# THIS IS UGLY AS SIN
# SIN IS PRETTY UGLY
#
# NO WARRANTY YET

$filename = $ARGV[0];
die "Syntax: $FindBin::Script filename\n" if !$filename;
open(FILE, $filename) or die "Could not open $filename.\n";

@inputlines = ();
@outputlines = ();
$lineno = 1;

$firsthookline = -1;
$ctorline = -1;

@hooks = ();
$numhooks = 0;
%classes = ();

$hassubstrateh = 0;
$ignore = 0;

my $readignore = 0;

my $built = "";
my $building = 0;
READLOOP: while($line = <FILE>) {
	chomp($line);

	if($readignore && $line =~ /^.*?\*\/\s*/) {
		$readignore = 0;
		$line = $';
	}
	if($readignore) { push(@inputlines, ""); next; }

	my @quotes = quotes($line);

	# Delete all single-line /* xxx */ comments.

	# Delete all single-line to-EOL // xxx comments.
	while($line =~ /\/\//g) {
		if(!fallsBetween($-[0], @quotes)) {
			$line = $`;
			@quotes = quotes($line); # Line was modified, re-generate the quotes.
			last;
		}
	}

	while($line =~ /\/\*.*?\*\//g) {
		if(!fallsBetween($-[0], @quotes)) {
			$line = $`.$';
			@quotes = quotes($line); # Line was modified, re-generate the quotes.
		}
	}
	
	# Start of a multi-line /* comment.
	while($line =~ /\/\*.*$/g) {
		if(!fallsBetween($-[0], @quotes)) {
			$line = $`;
			push(@inputlines, $line);
			$readignore = 1;
			next READLOOP;
		}
	}

	if(!$readignore) {
		# Line starts with - (return), start gluing lines together until we find a { or ;...
		if(!$building && $line =~ /^\s*([+-])\s*\(\s*(.*?)\s*\)/ && index($line, "{") == -1 && index($line, ";") == -1) {
			$building = $1;
			$built = $line;
			push(@inputlines, "");
			next;
		} elsif($building) {
			$built .= " ".$line;
			if(index($line,"{") != -1 || index($line,";") != -1) {
				push(@inputlines, $built);
				$building = 0;
				$built = "";
				next;
			}
			push(@inputlines, "");
			next;
		}
		push(@inputlines, $line) if !$readignore;
	}
}

close(FILE);

my $inclass = 0;
my $objc_currently_in = "";
my $last_blockopen = -1;
my $hook_using_objc_syntax = 0;
foreach $line (@inputlines) {
	# Search for a discrete %x% or an open-ended %x (or %x with a { or ; after it)
	if($line =~ /\s*#\s*include\s*[<"]substrate\.h[">]/) {
		$hassubstrateh = 1;
	} elsif($line =~ /^\s*#\s*if\s*0\s*$/) {
		$ignore = 1;
	} elsif($ignore == 1 && $line =~ /^\s*#\s*endif/) {
		$ignore = 0;
	} elsif($ignore == 0) {
		# %hook name
		if($line =~ /^\s*([\@%])(hook)\s+([\$_\w]+)/) {
			$firsthookline = $lineno if $firsthookline == -1;
			$hook_using_objc_syntax = ($1 eq '@');
			die "Error: Nested $1$2 in a $objc_currently_in (opened on line $last_blockopen) at or near line ".$lineno."\n" if $objc_currently_in && $hook_using_objc_syntax;
			$last_blockopen = $lineno;
			$class = $3;
			$inclass = 1;
			$line = $';
			redo;
		# - (return), but only when we're in a %hook.
		} elsif($inclass && $line =~ /^\s*([+-])\s*\(\s*(.*?)\s*\)/) {
			my $scope = $1;
			my $return = $2;
			my $selnametext = $';

			my $curhook = Hook->new();

			$curhook->class($class);
			$classes{$class}++;

			$curhook->scope($scope);
			$curhook->return($return);

			my @selparts = ();

			# word, then an optional: ": (argtype)argname"
			while($selnametext =~ /([\$\w]+)(:[\s]*\((.+?)\)[\s]*([\$\w]+?)(?=(\{|$|\s+)))?/) {
				$keyword = $1;
				push(@selparts, $keyword);
				$curhook->addArgument($3, $4) if $2;
				$selnametext = $';
				last if !$2;
			}

			$curhook->selectorParts(@selparts);
			push(@hooks, $curhook);
			$numhooks++;

			$replacement = $curhook->buildHookFunction;
			$replacement .= $selnametext if $selnametext ne "";
			$line = $replacement;
			redo;
		} elsif($line =~ /[\@%]orig(inal)?([\@%]?)(?=\W?)/) {
			die "Error: $& found outside of a ".($hook_using_objc_syntax?"\@":"%")."hook block at or near line $lineno.\n" if !$inclass;
			my $hasparens = 0;
			my $remaining = $';
			$replacement = "";
			if($remaining) {
				# If we encounter a ) that puts us back at zero, we found a (
				# and have reached its closing ).
				my $parenmatch = $remaining;
				my $pdepth = 0;
				my @pquotes = quotes($parenmatch);
				while($parenmatch =~ /[()]/g) {
					next if fallsBetween($-[0], @pquotes);
					if($& eq "(") { $pdepth++; }
					elsif($& eq ")") {
						$pdepth--;
						if($pdepth == 0) { $hasparens = $+[0]; last; }
					}
				}
			}
			if($hasparens > 0) {
				$parenstring = substr($remaining, 1, $hasparens-2);
				$remaining = substr($remaining, $hasparens);
				$replacement .= $hooks[$#hooks]->buildOriginalCall($parenstring);
			} else {
				$replacement .= $hooks[$#hooks]->buildOriginalCall;
			}
			$replacement .= $remaining;
			$line = $`.$replacement;
			redo;
		} elsif($line =~ /[\@%]log([\@%]?)(?=\W?)/) {
			die "Error: $& found outside of a ".($hook_using_objc_syntax?"\@":"%")."hook block at or near line $lineno.\n" if !$inclass;
			$replacement = $hooks[$#hooks]->buildLogCall;
			$line = $`.$replacement.$';
			redo;
		} elsif($line =~ /[\@%]c(onstruc)?tor([\@%]?)(?=\W?)/) {
			$ctorline = $lineno if $ctorline == -1;
			$line = $`.$';
			redo;
		} elsif($line =~ /[\@%]init([\@%]?)(?=\W?)/) {
			$line = $`.generateConstructorBody().$';
			$ctorline = -2; # "Do not generate a constructor."
			redo;
		# %end (Make it the last thing we check for so we don't terminate something pre-emptively.
		} elsif($line =~ /\@(interface|implementation)/) {
			die "Error: Nested $& in a \@hook (opened on line $last_blockopen) at or near line ".$lineno."\n" if $inclass && $hook_using_objc_syntax;
			$objc_currently_in = $&;
			$last_blockopen = $lineno;
		} elsif($inclass && $line =~ /([\@%])end([\@%]?)/) {
			if($hook_using_objc_syntax == 1 || $1 eq '%') {
				$inclass = 0;
				$line = $`.$';
				redo;
			}
		} elsif(!$inclass && $line =~ /\@end/) {
			$objc_currently_in = "";
		}
	}
	$lineno++;
	push(@outputlines, $line);
}

if($firsthookline != -1) {
	my $offset = 0;
	if(!$hassubstrateh) {
		splice(@outputlines, $firsthookline - 1, 0, "#include <substrate.h>");
		$offset++;
	}
	splice(@outputlines, $firsthookline - 1 + $offset, 0, generateClassList());
	$offset++;
	splice(@outputlines, $firsthookline - 1 + $offset, 0, "#line $firsthookline \"$filename\"");
	$offset++;
	my $ctor = generateConstructor();
	if($ctorline == -2) {
		# No-op, do not paste a constructor.
	} elsif($ctorline != -1) {
		$outputlines[$ctorline + $offset - 1] = $ctor;
	} else {
		push(@outputlines, $ctor);
	}

}

splice(@outputlines, 0, 0, "#line 0 \"$filename\"");
foreach $oline (@outputlines) {
	print $oline."\n" if defined($oline);
}

sub generateConstructor {
	my $return = "";
	$return .= "static __attribute__((constructor)) void _logosLocalInit() { ";
	$return .= "NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; ";
	$return .= generateConstructorBody()." ";
	$return .= "[pool drain];";
	$return .= " }";
	return $return;
}

sub generateConstructorBody {
	my $return = "";
	map $return .= $hooks[$_]->buildHookCall, (0..$#hooks);
	return $return;
}

sub generateClassList {
	my $return = "";
	map $return .= generateClassLine($_), keys %classes;
	return $return;
}

sub generateClassLine {
	my ($class) = @_;
	return "\@class $class; static Class \$$class = objc_getClass(\"$class\");";
}

sub quotes {
	my ($line) = @_;
	my @quotes = ();
	while($line =~ /(?<!\\)\"/g) {
		push(@quotes, $-[0]);
	}
	return @quotes;
}

sub fallsBetween {
	my $idx = shift;
	while(@_ > 0) {
		my $start = shift;
		my $end = shift;
		return 1 if ($start < $idx && (!defined($end) || $end > $idx))
	}
	return 0;
}
