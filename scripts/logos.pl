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

my @inputlines = ();
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

@outputlines = ();
$lineno = 1;

$firsthookline = -1;
$ctorline = -1;

%hooks = ( "_ungrouped" => [] );
%inittedGroups = ();
%classes = ();
%metaclasses = ();

$hassubstrateh = 0;
$ignore = 0;

my @nestingstack = ();
my $inclass = 0;
my $last_blockopen = -1;
my $curgroup = "_ungrouped";
my $lastHook;

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
		if($line =~ /^\s*%(hook)\s+([\$_\w]+)/) {
			my $n = checkDoubleNesting($1, @nestingstack);
			nestingError($lineno, $1, $n) if $n;

			$firsthookline = $lineno if $firsthookline == -1;

			nestPush($1, $lineno, \@nestingstack);

			$class = $2;
			$inclass = 1;
			$line = $';
			redo;
		# - (return), but only when we're in a %hook.
		} elsif($line =~ /\s*%(group)\s+([\$_\w]+)/) {
			my $n = checkDoubleNesting($1, @nestingstack);
			nestingError($lineno, $1, $n) if $n;
			nestPush($1, $lineno, \@nestingstack);
			$curgroup = $2;
			$hooks{$curgroup} = [];
			$line = $`.$';
			redo;
		} elsif($inclass && $line =~ /^\s*([+-])\s*\(\s*(.*?)\s*\)/) {
			my $scope = $1;
			my $return = $2;
			my $selnametext = $';

			my $curhook = Hook->new();

			$curhook->class($class);
			if($scope eq "+") {
				$metaclasses{$class}++;
			} else {
				$classes{$class}++;
			}

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
			push(@{$hooks{$curgroup}}, $curhook);
			$lastHook = $curhook;

			$replacement = $curhook->buildHookFunction;
			$replacement .= $selnametext if $selnametext ne "";
			$line = $replacement;
			redo;
		} elsif($line =~ /%orig(inal)?(%?)(?=\W?)/) {
			fileError($lineno, "$& found outside of a %hook") if !nestingContains("hook", @nestingstack);
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
				$replacement .= $lastHook->buildOriginalCall($parenstring);
			} else {
				$replacement .= $lastHook->buildOriginalCall;
			}
			$replacement .= $remaining;
			$line = $`.$replacement;
			redo;
		} elsif($line =~ /%log(%?)(?=\W?)/) {
			fileError($lineno, "$& found outside of a %hook") if !nestingContains("hook", @nestingstack);
			$replacement = $lastHook->buildLogCall;
			$line = $`.$replacement.$';
			redo;
		} elsif($line =~ /%c(onstruc)?tor(%?)(?=\W?)/) {
			fileError($lineno, "$& found inside of a %hook") if nestingContains("hook", @nestingstack);
			$ctorline = $lineno if $ctorline == -1;
			$line = $`.$';
			redo;
		} elsif($line =~ /%init(\((.*?)\))?(%?)(?=\W?)/) {
			my $group = "_ungrouped";
			$group = $2 if $2;
			$line = $`.generateInitLines($group).$';
			$ctorline = -2; # "Do not generate a constructor."
			redo;
		# %end (Make it the last thing we check for so we don't terminate something pre-emptively.
		} elsif($line =~ /%end(%?)/) {
			my $closing = nestPop(\@nestingstack);
			if($closing eq "group") {
				$curgroup = "_ungrouped";
			} elsif($closing eq "hook") {
				$inclass = 0;
			}
			$line = $`.$';
			redo;
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
	if($ctorline == -2) {
		# No-op, do not paste a constructor.
	} elsif($ctorline != -1) {
		$outputlines[$ctorline + $offset - 1] = generateConstructor();
	} else {
		push(@outputlines, generateConstructor());
	}

}

my %unInitHookHash = ();
map { $unInitHookHash{$_} = 1; } (keys %hooks);
map { delete $unInitHookHash{$_}; } (keys %inittedGroups);
my @unInitHooks = keys %unInitHookHash;
my $numUnHooks = @unInitHooks;
fileError(-1, "non-initialized hook group".($numUnHooks == 1 ? "" : "s").": ".join(", ", @unInitHooks)) if $numUnHooks > 0;


splice(@outputlines, 0, 0, "#line 0 \"$filename\"");
foreach $oline (@outputlines) {
	print $oline."\n" if defined($oline);
}

sub generateConstructor {
	my $return = "";
	fileError($ctorline, "Cannot generate an autoconstructor with multiple %groups. Please explicitly create a constructor.") if scalar(keys(%hooks)) > 1;
	$return .= "static __attribute__((constructor)) void _logosLocalInit() { ";
	$return .= "NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; ";
	$return .= generateInitLines("_ungrouped")." ";
	$return .= "[pool drain];";
	$return .= " }";
	return $return;
}

sub generateInitLines {
	my $group = shift;
	$group = "_ungrouped" if !$group;

	fileError($lineno, "re-%init of %group $group") if defined($inittedGroups{$group});
	$inittedGroups{$group} = 1;

	my $return = "";
	fileError($lineno, "%init for an undefined %group $group") if !$hooks{$group};

	map $return .= ${$hooks{$group}}[$_]->buildHookCall, (0..$#{$hooks{$group}});

	return $return;
}

sub generateClassList {
	my $return = "";
	my %uniqclasses = ();
	map { $uniqclasses{$_}++; } keys %metaclasses;
	map { $uniqclasses{$_}++; } keys %classes;

	map $return .= "\@class $_; ", keys %uniqclasses;
	map $return .= generateMetaClassLine($_), keys %metaclasses;
	map $return .= generateClassLine($_), keys %classes;
	return $return;
}

sub generateMetaClassLine {
	my ($class) = @_;
	return "static Class \$meta\$$class = objc_getMetaClass(\"$class\"); ";
}

sub generateClassLine {
	my ($class) = @_;
	return "static Class \$$class = objc_getClass(\"$class\"); ";
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

sub fileError {
	my $curline = shift;
	my $reason = shift;
	die "$filename:".($curline > -1 ? "$curline:" : "")." $reason\n";
}

sub nestingError {
	my $curline = shift;
	my $thisblock = shift;
	my $reason = shift;
	my @parts = split(/:/, $reason);
	fileError $curline, "%$thisblock inside a %".$parts[0].", opened on ".$parts[1];
}

sub checkDoubleNesting {
	my $trying = shift;
	my @stack = @_;
	my $line = nestingContains($trying, @stack);
	return $trying.":".$line if $line;
	return undef;
}

sub nestingContains {
	my $find = shift;
	my @stack = @_;
	my @parts = ();
	foreach $nest (@stack) {
		@parts = split(/:/, $nest);
		return $parts[1] if $find eq $parts[0];
	}
	return undef;
}

sub nestPush {
	my $type = shift;
	my $line = shift;
	my $ref_stack = shift;
	push(@{$ref_stack}, $type.":".$line);
}

sub nestPop {
	my $ref_stack = shift;
	my $outgoing = pop(@{$ref_stack});
	return undef if !$outgoing;
	my @parts = split(/:/, $outgoing);
	return $parts[0];
}
